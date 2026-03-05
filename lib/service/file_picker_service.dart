import 'package:image_picker/image_picker.dart';

class FilePickerService {
  final ImagePicker _picker = ImagePicker();
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      return image;
    } catch (e) {
      return null;
    }
  }

  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      return image;
    } catch (e) {
      return null;
    }
  }

  Future<XFile?> pickFile() async {
    try {
      final XFile? file = await _picker.pickMedia();
      return file;
    } catch (e) {
      return null;
    }
  }
}
