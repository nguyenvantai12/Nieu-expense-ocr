import 'dart:io';

import 'package:image_picker/image_picker.dart';

class CameraCaptureException implements Exception {
  const CameraCaptureException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Service to handle capturing and picking images from the device.
class CameraCaptureService {
  final ImagePicker _picker = ImagePicker();

  /// Captures an image from the camera.
  /// Returns the file path or null if cancelled/denied.
  Future<String?> captureFromCamera() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    return image?.path;
  }

  /// Picks an image from the gallery.
  /// Returns the file path or null if cancelled/denied.
  Future<String?> pickFromGallery() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    return image?.path;
  }

  /// Restores an image if Android recreated MainActivity while the picker ran.
  Future<String?> retrieveLostImage() async {
    if (!Platform.isAndroid) return null;

    final response = await _picker.retrieveLostData();
    if (response.exception case final exception?) {
      throw CameraCaptureException(
        'Không thể khôi phục ảnh đã chọn: ${exception.message ?? exception.code}',
      );
    }
    return response.file?.path;
  }
}
