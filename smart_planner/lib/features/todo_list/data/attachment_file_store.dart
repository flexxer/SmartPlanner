import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Stores task attachment images under app documents.
class AttachmentFileStore {
  AttachmentFileStore({this._picker});

  final ImagePicker? _picker;
  static const String _subdir = 'task_attachments';

  ImagePicker get picker => _picker ?? ImagePicker();

  Future<Directory> _attachmentsDir() async {
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory dir = Directory(p.join(base.path, _subdir));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Picks an image and returns a path relative to documents dir.
  Future<String?> pickAndStoreImage() async {
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) {
      return null;
    }
    final Directory dir = await _attachmentsDir();
    final String name =
        '${DateTime.now().microsecondsSinceEpoch}${p.extension(file.path)}';
    final String absolute = p.join(dir.path, name);
    await File(file.path).copy(absolute);
    return p.join(_subdir, name);
  }

  Future<File> resolveFile(String relativePath) async {
    final Directory base = await getApplicationDocumentsDirectory();
    return File(p.join(base.path, relativePath));
  }

  Future<void> deleteIfExists(String relativePath) async {
    try {
      final File file = await resolveFile(relativePath);
      if (file.existsSync()) {
        await file.delete();
      }
    } on Object {
      // Best-effort cleanup.
    }
  }

  Future<String> copyImageForReopen(String relativePath) async {
    final File source = await resolveFile(relativePath);
    final Directory dir = await _attachmentsDir();
    final String name =
        '${DateTime.now().microsecondsSinceEpoch}${p.extension(source.path)}';
    final String absolute = p.join(dir.path, name);
    await source.copy(absolute);
    return p.join(_subdir, name);
  }
}
