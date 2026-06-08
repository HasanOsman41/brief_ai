// lib/services/backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:brief_ai/data/local/database_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class BackupService {
  final DatabaseHelper _dbHelper;

  BackupService({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Let user pick a folder and create backup there
  /// Returns the path to the created backup file, or null if cancelled
  ///
  /// No runtime storage permission is required: `FilePicker.getDirectoryPath`
  /// uses the Storage Access Framework on Android and the system Files picker
  /// on iOS — both grant per-action access without a permission dialog.
  Future<String?> createBackup({
    String? backupFileName,
    Function(double)? onProgress, // Optional progress callback (0.0 to 1.0)
  }) async {
    // Let user pick destination folder
    final selectedDir = await FilePicker.getDirectoryPath(
      dialogTitle: 'Select Backup Destination',
      lockParentWindow: true,
    );

    if (selectedDir == null) {
      // User cancelled
      return null;
    }

    return await _createBackupToPath(
      selectedDir,
      backupFileName: backupFileName,
      onProgress: onProgress,
    );
  }

  Future<String> _createBackupToPath(
    String destinationDir, {
    String? backupFileName,
    Function(double)? onProgress,
  }) async {
    // Ensure database is closed before backup
    await _dbHelper.close();

    final fileName =
        backupFileName ??
        'brief_ai_backup_${DateTime.now().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '')}.zip';
    final backupPath = path.join(destinationDir, fileName);

    // Create temp directory for staging backup contents
    final appDocsDir = await getApplicationDocumentsDirectory();
    final tempDir = path.join(
      appDocsDir.path,
      'temp_backup_${DateTime.now().millisecondsSinceEpoch}',
    );
    await Directory(tempDir).create(recursive: true);

    try {
      onProgress?.call(0.1);

      // 1. Copy database file
      final dbPath = await _dbHelper.getDatabasePath();
      if (await File(dbPath).exists()) {
        await File(dbPath).copy(path.join(tempDir, 'brief_ai.db'));
      }
      onProgress?.call(0.3);

      // 2. Copy images directory
      final imagesDir = await _dbHelper.getImagesDirectoryPath();
      if (await Directory(imagesDir).exists()) {
        await _copyDirectory(
          Directory(imagesDir),
          path.join(tempDir, 'images'),
          onProgress: (progress) => onProgress?.call(0.3 + (progress * 0.4)),
        );
      }
      onProgress?.call(0.7);

      // 3. Create metadata
      final metadata = {
        'backupDate': DateTime.now().toIso8601String(),
        'databaseVersion': 1,
        'imageCount': await _countImagesInDirectory(imagesDir),
      };
      await File(
        path.join(tempDir, 'metadata.json'),
      ).writeAsString(jsonEncode(metadata));

      onProgress?.call(0.85);

      // 4. Create ZIP archive
      await _createZipArchive(tempDir, backupPath);

      onProgress?.call(1.0);

      return backupPath;
    } catch (e) {
      // Clean up on error
      if (await Directory(tempDir).exists()) {
        await Directory(tempDir).delete(recursive: true);
      }
      if (await File(backupPath).exists()) {
        await File(backupPath).delete();
      }
      rethrow;
    } finally {
      // Clean up temp directory
      if (await Directory(tempDir).exists()) {
        await Directory(tempDir).delete(recursive: true);
      }
      // Reopen database
      await _dbHelper.database;
    }
  }

  /// Let user pick a backup file and restore from it
  /// Returns true if restore was successful
  ///
  /// Same as [createBackup]: SAF / iOS Files picker — no runtime permission.
  Future<bool> restoreBackup({Function(double)? onProgress}) async {
    // Let user pick backup file
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      dialogTitle: 'Select Backup File to Restore',
      lockParentWindow: true,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return false; // User cancelled
    }

    final backupPath = result.files.first.path;
    if (backupPath == null) {
      throw Exception('Could not get path to selected backup file');
    }

    return await restoreBackupFromPath(backupPath, onProgress: onProgress);
  }

  /// Restore from a specific backup file path
  Future<bool> restoreBackupFromPath(
    String backupFilePath, {
    Function(double)? onProgress,
  }) async {
    if (!await File(backupFilePath).exists()) {
      throw Exception('Backup file not found: $backupFilePath');
    }

    // Close current database
    await _dbHelper.close();

    final appDocsDir = await getApplicationDocumentsDirectory();
    final tempDir = path.join(
      appDocsDir.path,
      'temp_restore_${DateTime.now().millisecondsSinceEpoch}',
    );
    await Directory(tempDir).create(recursive: true);

    try {
      onProgress?.call(0.1);

      // 1. Extract ZIP
      await _extractZipArchive(backupFilePath, tempDir);
      onProgress?.call(0.3);

      // 2. Verify & read metadata
      final metadataPath = path.join(tempDir, 'metadata.json');
      if (await File(metadataPath).exists()) {
        final metadata = jsonDecode(await File(metadataPath).readAsString());
        print('📦 Restoring backup from: ${metadata['backupDate']}');
        print('🖼️  Image count in backup: ${metadata['imageCount']}');
      }
      onProgress?.call(0.4);

      // 3. Restore database
      final dbPath = await _dbHelper.getDatabasePath();
      final backupDb = path.join(tempDir, 'brief_ai.db');

      if (!await File(backupDb).exists()) {
        throw Exception('Database file missing in backup');
      }

      if (await File(dbPath).exists()) {
        await File(dbPath).delete();
      }
      await File(backupDb).copy(dbPath);
      onProgress?.call(0.7);

      // 4. Restore images
      final imagesDir = await _dbHelper.getImagesDirectoryPath();
      final backupImages = path.join(tempDir, 'images');

      if (await Directory(backupImages).exists()) {
        if (await Directory(imagesDir).exists()) {
          await Directory(imagesDir).delete(recursive: true);
        }
        await _copyDirectory(
          Directory(backupImages),
          imagesDir,
          onProgress: (progress) => onProgress?.call(0.7 + (progress * 0.25)),
        );
      }
      onProgress?.call(0.95);

      // 5. Reinitialize database
      await _dbHelper.database;
      onProgress?.call(1.0);

      return true;
    } catch (e) {
      print('❌ Restore failed: $e');
      // Try to recover database state
      await _dbHelper.database;
      rethrow;
    } finally {
      // Cleanup
      if (await Directory(tempDir).exists()) {
        await Directory(tempDir).delete(recursive: true);
      }
    }
  }

  /// Get info about a backup file without restoring
  Future<Map<String, dynamic>?> getBackupInfo(String backupFilePath) async {
    if (!await File(backupFilePath).exists()) return null;

    final appDocsDir = await getApplicationDocumentsDirectory();
    final tempDir = path.join(
      appDocsDir.path,
      'temp_info_${DateTime.now().millisecondsSinceEpoch}',
    );
    await Directory(tempDir).create(recursive: true);

    try {
      // Extract only metadata.json
      final bytes = await File(backupFilePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final metadataFile = archive.firstWhere(
        (f) => f.name == 'metadata.json',
        orElse: () => throw Exception('No metadata found'),
      );

      if (metadataFile.isFile) {
        final content = utf8.decode(metadataFile.content as List<int>);
        final metadata = jsonDecode(content) as Map<String, dynamic>;

        final stats = await File(backupFilePath).stat();
        return {
          ...metadata,
          'fileName': path.basename(backupFilePath),
          'fileSize': stats.size,
          'fileModified': stats.modified,
        };
      }
      return null;
    } catch (e) {
      print('Error reading backup info: $e');
      return null;
    } finally {
      if (await Directory(tempDir).exists()) {
        await Directory(tempDir).delete(recursive: true);
      }
    }
  }

  /// Delete a backup file
  Future<bool> deleteBackup(String backupFilePath) async {
    if (await File(backupFilePath).exists()) {
      await File(backupFilePath).delete();
      return true;
    }
    return false;
  }

  /// Delete all app data: database and images directory
  /// Returns true if deletion was successful
  Future<bool> deleteAllData() async {
    try {
      // 1. Close current database connection first
      await _dbHelper.close();

      // 2. Delete database file
      final dbPath = await _dbHelper.getDatabasePath();
      if (await File(dbPath).exists()) {
        await File(dbPath).delete();
      }

      // 3. Delete images directory and all contents
      final imagesDir = await _dbHelper.getImagesDirectoryPath();
      if (await Directory(imagesDir).exists()) {
        await Directory(imagesDir).delete(recursive: true);
      }

      // 4. Reinitialize fresh database with empty tables
      await _dbHelper.database;

      // 5. Recreate images directory for future use
      await Directory(imagesDir).create(recursive: true);

      print('✅ All data deleted successfully');
      return true;
    } catch (e) {
      print('❌ Failed to delete all data: $e');
      // Try to recover database state
      try {
        await _dbHelper.database;
      } catch (_) {}
      return false;
    }
  }
  // ==================== Helper Methods ====================

  Future<int> _countImagesInDirectory(String dirPath) async {
    if (!await Directory(dirPath).exists()) return 0;
    int count = 0;
    await for (final entity in Directory(dirPath).list(recursive: true)) {
      if (entity is File &&
          (entity.path.endsWith('.jpg') ||
              entity.path.endsWith('.jpeg') ||
              entity.path.endsWith('.png'))) {
        count++;
      }
    }
    return count;
  }

  Future<void> _copyDirectory(
    Directory source,
    String destination, {
    Function(double)? onProgress,
  }) async {
    if (!await source.exists()) return;
    await Directory(destination).create(recursive: true);

    final files = await source
        .list(recursive: true)
        .where((e) => e is File)
        .cast<File>()
        .toList();

    final total = files.length;
    int current = 0;

    for (final file in files) {
      final relative = path.relative(file.path, from: source.path);
      final newPath = path.join(destination, relative);
      await Directory(path.dirname(newPath)).create(recursive: true);
      await file.copy(newPath);

      current++;
      if (onProgress != null && total > 0) {
        onProgress(current / total);
      }
    }
  }

  Future<void> _createZipArchive(String sourceDir, String outputPath) async {
    final encoder = ZipFileEncoder();
    encoder.create(outputPath);
    await _addToZip(encoder, Directory(sourceDir), sourceDir);
    await encoder.close();
  }

  Future<void> _addToZip(
    ZipFileEncoder encoder,
    Directory dir,
    String rootDir,
  ) async {
    await for (final entity in dir.list(recursive: false)) {
      if (entity is File) {
        final relative = path.relative(entity.path, from: rootDir);
        encoder.addFile(entity, relative);
      } else if (entity is Directory) {
        await _addToZip(encoder, entity, rootDir);
      }
    }
  }

  Future<void> _extractZipArchive(String zipPath, String extractTo) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        final filePath = path.join(extractTo, filename);
        File(filePath)
          ..create(recursive: true)
          ..writeAsBytes(data);
      } else if (file.isDirectory) {
        await Directory(path.join(extractTo, filename)).create(recursive: true);
      }
    }
  }
}
