import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Result of copying a picked file into app storage.
class StoredAttachmentFile {
  const StoredAttachmentFile({
    required this.relativePath,
    required this.fileName,
    this.mimeType,
  });

  final String relativePath;
  final String fileName;
  final String? mimeType;
}

/// Stores task/event attachment files under app documents.
class AttachmentFileStore {
  AttachmentFileStore({this._picker});

  final ImagePicker? _picker;
  static const String _subdir = 'task_attachments';
  static const String _filesSubdir = 'attachment_files';

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

  /// Picks any file and stores a copy under app documents.
  Future<StoredAttachmentFile?> pickAndStoreFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final PlatformFile picked = result.files.single;
    final String? sourcePath = picked.path;
    if (sourcePath == null || sourcePath.isEmpty) {
      return null;
    }
    final Directory dir = await _filesDir();
    final String ext = p.extension(picked.name);
    final String storedName =
        '${DateTime.now().microsecondsSinceEpoch}$ext';
    final String absolute = p.join(dir.path, storedName);
    await File(sourcePath).copy(absolute);
    return StoredAttachmentFile(
      relativePath: p.join(_filesSubdir, storedName),
      fileName: picked.name,
      mimeType: picked.extension != null && picked.extension!.isNotEmpty
          ? 'application/${picked.extension}'
          : null,
    );
  }

  Future<Directory> _filesDir() async {
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory dir = Directory(p.join(base.path, _filesSubdir));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
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

  Future<String> copyStoredFileForReopen(String relativePath) async {
    final File source = await resolveFile(relativePath);
    final Directory dir = await _filesDir();
    final String name =
        '${DateTime.now().microsecondsSinceEpoch}${p.extension(source.path)}';
    final String absolute = p.join(dir.path, name);
    await source.copy(absolute);
    return p.join(_filesSubdir, name);
  }
}
