import 'package:image_picker/image_picker.dart';

String _guessMimeType(String path) {
  final ext = path.split('.').last.toLowerCase();
  switch (ext) {
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    default:
      return 'application/octet-stream';
  }
}

String mimeTypeForFile(XFile file) {
  final mimeType = file.mimeType;
  if (mimeType != null && mimeType.isNotEmpty) return mimeType;
  return _guessMimeType(file.path);
}

String extensionForMimeType(String mimeType) {
  switch (mimeType) {
    case 'image/png':
      return '.png';
    case 'image/webp':
      return '.webp';
    case 'image/gif':
      return '.gif';
    case 'image/jpeg':
      return '.jpg';
    default:
      return '.bin';
  }
}
