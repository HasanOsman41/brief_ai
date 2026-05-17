// lib/helpers/backup_helper.dart
import 'dart:io';
import 'package:brief_ai/data/local/database_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  /// Get the database file path
  Future<String> _getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return path.join(documentsDirectory.path, 'brief_ai.db');
  }

  /// Get the images directory path
  Future<String> _getImagesDirectoryPath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(documentsDirectory.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir.path;
  }

  /// Export backup - zip database file and images folder
  Future<bool> exportBackup(BuildContext context) async {
    try {
      // Request storage permission if needed
      if (Platform.isAndroid || Platform.isIOS) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (context.mounted) {
            _showPermissionDeniedDialog(context);
          }
          return false;
        }
      }

      // Close database connection to ensure no locks
      await DatabaseHelper().close();

      // Get database file
      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception('Database file not found');
      }

      // Get images directory
      final imagesDirPath = await _getImagesDirectoryPath();
      final imagesDir = Directory(imagesDirPath);

      // Create temporary directory for backup
      final tempDir = await getTemporaryDirectory();
      final backupTempDir = Directory(
        path.join(
          tempDir.path,
          'backup_temp_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      await backupTempDir.create(recursive: true);

      // Copy database file to temp directory
      final tempDbFile = File(path.join(backupTempDir.path, 'brief_ai.db'));
      await dbFile.copy(tempDbFile.path);

      // Copy images folder to temp directory
      if (await imagesDir.exists()) {
        final tempImagesDir = Directory(
          path.join(backupTempDir.path, 'images'),
        );
        await _copyDirectory(imagesDir, tempImagesDir);
      }

      // Create zip file
      final zipFile = await _createZipFile(backupTempDir);

      // Let user choose where to save the zip file
      String? outputPath;

      if (Platform.isAndroid || Platform.isIOS) {
        String? selectedDirectory = await FilePicker.getDirectoryPath();
        if (selectedDirectory == null) {
          // User cancelled
          await backupTempDir.delete(recursive: true);
          return false;
        }

        final fileName =
            'briefai_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
        outputPath = '$selectedDirectory/$fileName';
      } else {
        // Desktop fallback - save to documents directory
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'briefai_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
        outputPath = '${directory.path}/$fileName';
      }

      // Copy zip file to user selected location
      final outputFile = File(outputPath!);
      await zipFile.copy(outputFile.path);

      // Clean up temp directory
      await backupTempDir.delete(recursive: true);

      if (context.mounted) {
        _showSuccessDialog(context, outputPath);
      }

      // Reopen database connection
      await DatabaseHelper().database;

      return true;
    } catch (e) {
      debugPrint('Export error: $e');
      if (context.mounted) {
        _showErrorDialog(context, 'Export failed: $e');
      }
      // Try to reopen database
      try {
        await DatabaseHelper().database;
      } catch (_) {}
      return false;
    }
  }

  /// Create zip file from backup directory
  Future<File> _createZipFile(Directory sourceDir) async {
    final tempDir = await getTemporaryDirectory();
    final zipPath = path.join(
      tempDir.path,
      'backup_${DateTime.now().millisecondsSinceEpoch}.zip',
    );

    // Create archive
    final archive = Archive();

    // Add all files from source directory
    await _addDirectoryToArchive(sourceDir, archive, sourceDir.path);

    // Write zip file
    final zipFile = File(zipPath);
    final zipData = ZipEncoder().encode(archive);
    await zipFile.writeAsBytes(zipData);

    return zipFile;
  }

  /// Recursively add directory contents to archive
  Future<void> _addDirectoryToArchive(
    Directory dir,
    Archive archive,
    String basePath,
  ) async {
    final List<FileSystemEntity> entities = await dir.list().toList();

    for (final entity in entities) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: basePath);
        final fileBytes = await entity.readAsBytes();
        final archiveFile = ArchiveFile(
          relativePath,
          fileBytes.length,
          fileBytes,
        );
        archive.addFile(archiveFile);
      } else if (entity is Directory) {
        await _addDirectoryToArchive(entity, archive, basePath);
      }
    }
  }

  /// Copy directory recursively
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    final List<FileSystemEntity> entities = await source.list().toList();

    for (final entity in entities) {
      if (entity is File) {
        final destFile = File(
          path.join(destination.path, path.basename(entity.path)),
        );
        await entity.copy(destFile.path);
      } else if (entity is Directory) {
        final destDir = Directory(
          path.join(destination.path, path.basename(entity.path)),
        );
        await _copyDirectory(entity, destDir);
      }
    }
  }

  /// Import backup - extract zip file and restore database and images
  Future<bool> importBackup(BuildContext context) async {
    try {
      // Request storage permission
      if (Platform.isAndroid || Platform.isIOS) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (context.mounted) {
            _showPermissionDeniedDialog(context);
          }
          return false;
        }
      }

      // Let user pick backup zip file
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        dialogTitle: 'Select backup file',
      );

      if (result == null) {
        // User cancelled
        return false;
      }

      final zipFilePath = result.files.single.path!;

      // Close database connection
      await DatabaseHelper().close();

      // Create temporary directory for extraction
      final tempDir = await getTemporaryDirectory();
      final extractDir = Directory(
        path.join(
          tempDir.path,
          'restore_temp_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      await extractDir.create(recursive: true);

      // Read zip file
      final zipFile = File(zipFilePath);
      final zipBytes = await zipFile.readAsBytes();

      // Extract zip
      final archive = ZipDecoder().decodeBytes(zipBytes);

      // Extract all files to temporary directory
      for (final file in archive) {
        if (file.isFile) {
          final extractedFile = File(path.join(extractDir.path, file.name));
          await extractedFile.create(recursive: true);
          await extractedFile.writeAsBytes(file.content as List<int>);
        }
      }

      // Get target database path
      final targetDbPath = await _getDatabasePath();
      final targetImagesDirPath = await _getImagesDirectoryPath();

      // Backup current data before restore (optional safety backup)
      final safetyBackupDir = Directory(
        path.join(
          (await getTemporaryDirectory()).path,
          'safety_backup_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      await safetyBackupDir.create();

      // Backup current database if exists
      final currentDbFile = File(targetDbPath);
      if (await currentDbFile.exists()) {
        await currentDbFile.copy(
          path.join(safetyBackupDir.path, 'brief_ai.db.backup'),
        );
      }

      // Backup current images if exists
      final currentImagesDir = Directory(targetImagesDirPath);
      if (await currentImagesDir.exists()) {
        final safetyImagesDir = Directory(
          path.join(safetyBackupDir.path, 'images'),
        );
        await _copyDirectory(currentImagesDir, safetyImagesDir);
      }

      // Restore database from extracted files
      final extractedDbFile = File(path.join(extractDir.path, 'brief_ai.db'));
      if (await extractedDbFile.exists()) {
        // Delete current database if exists
        if (await currentDbFile.exists()) {
          await currentDbFile.delete();
        }
        // Copy extracted database to target location
        await extractedDbFile.copy(targetDbPath);
      } else {
        throw Exception('Database file not found in backup');
      }

      // Restore images folder
      final extractedImagesDir = Directory(
        path.join(extractDir.path, 'images'),
      );
      if (await extractedImagesDir.exists()) {
        // Delete current images directory if exists
        if (await currentImagesDir.exists()) {
          await currentImagesDir.delete(recursive: true);
        }
        // Create fresh images directory
        await currentImagesDir.create(recursive: true);
        // Copy extracted images to target location
        await _copyDirectory(extractedImagesDir, currentImagesDir);
      }

      // Clean up temp directory
      await extractDir.delete(recursive: true);

      // Reopen database connection
      await DatabaseHelper().database;

      if (context.mounted) {
        _showRestoreSuccessDialog(context);
      }

      return true;
    } catch (e) {
      debugPrint('Import error: $e');
      if (context.mounted) {
        _showErrorDialog(context, 'Import failed: $e');
      }
      // Try to reopen database
      try {
        await DatabaseHelper().database;
      } catch (_) {}
      return false;
    }
  }

  /// Delete all data - delete database file and images folder
  Future<bool> deleteAllData(BuildContext context) async {
    try {
      // Show confirmation dialog first
      final confirmed = await _showDeleteConfirmationDialog(context);
      if (!confirmed) return false;

      // Close database connection
      await DatabaseHelper().close();

      // Delete database file
      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      // Delete images directory
      final imagesDirPath = await _getImagesDirectoryPath();
      final imagesDir = Directory(imagesDirPath);
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }

      // Recreate empty database (this will create new tables)
      await DatabaseHelper().database;

      // Recreate images directory
      await Directory(imagesDirPath).create(recursive: true);

      if (context.mounted) {
        _showDeleteSuccessDialog(context);
      }

      return true;
    } catch (e) {
      debugPrint('Delete error: $e');
      if (context.mounted) {
        _showErrorDialog(context, 'Delete failed: $e');
      }
      // Try to reopen database
      try {
        await DatabaseHelper().database;
      } catch (_) {}
      return false;
    }
  }

  // Dialog helpers
  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'Are you sure you want to delete all your data?\n\n'
          'This action cannot be undone and will delete:\n'
          '• All documents\n'
          '• All images\n'
          '• All app data',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }

  void _showSuccessDialog(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your data has been successfully backed up.'),
            const SizedBox(height: 8),
            const Text('Backup includes:'),
            const SizedBox(height: 4),
            const Text('• Database file', style: TextStyle(fontSize: 12)),
            const Text('• All images', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              'Saved to:\n$filePath',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRestoreSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Successful'),
        content: const Text(
          'Your data has been successfully restored.\n\n'
          'The app will refresh to show your restored data.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Trigger a refresh of the UI
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Data Deleted'),
        content: const Text(
          'All your data has been permanently deleted.\n\n'
          'The app has been reset to its initial state.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Storage permission is required to backup and restore your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
