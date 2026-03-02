import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FileStorageService {
  static final FileStorageService instance = FileStorageService._();
  FileStorageService._();

  Future<List<String>> copyToAppStorage(List<String> tempPaths) async {
    final dir = await getApplicationDocumentsDirectory();
    final scansDir = Directory(path.join(dir.path, 'scans'));
    if (!await scansDir.exists()) await scansDir.create(recursive: true);

    final permanentPaths = <String>[];
    for (final tempPath in tempPaths) {
      final file = File(tempPath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = path.join(scansDir.path, '$timestamp.jpg');
      await file.copy(newPath);
      permanentPaths.add(newPath);
    }
    return permanentPaths;
  }
}
