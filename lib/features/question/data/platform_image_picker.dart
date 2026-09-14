import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../../core/error/app_failure.dart';
import '../domain/question.dart';

class PlatformImagePicker implements ImagePickerService {
  PlatformImagePicker(this.picker);
  final ImagePicker picker;
  Future<SelectedImage> _map(XFile file) async {
    final bytes = await file.readAsBytes();
    final type = lookupMimeType(file.name, headerBytes: bytes);
    if (!{'image/jpeg', 'image/png', 'image/webp'}.contains(type)) {
      throw const AppFailure(
        FailureKind.validation,
        code: 'UNSUPPORTED_FILE_TYPE',
      );
    }
    return SelectedImage(bytes: bytes, name: file.name, mimeType: type!);
  }

  @override
  Future<SelectedImage?> pick(ImageOrigin origin) async {
    try {
      final file = await picker.pickImage(
        source: origin == ImageOrigin.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 2400,
        imageQuality: 90,
      );
      return file == null ? null : await _map(file);
    } on PlatformException {
      throw const AppFailure(FailureKind.validation, code: 'IMAGE_PERMISSION');
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure(FailureKind.unknown);
    }
  }

  @override
  Future<SelectedImage?> recover() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final result = await picker.retrieveLostData();
      if (result.exception != null) throw const AppFailure(FailureKind.unknown);
      final files = result.files;
      return files == null || files.isEmpty ? null : await _map(files.first);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure(FailureKind.unknown);
    }
  }
}
