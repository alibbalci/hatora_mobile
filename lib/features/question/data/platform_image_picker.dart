import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../../core/error/app_failure.dart';
import '../domain/question.dart';

class PlatformImagePicker implements ImagePickerService {
  PlatformImagePicker(
    this.picker, {
    required this.cropper,
    required this.takePhoto,
  });
  final ImagePicker picker;
  final QuestionImageCropper cropper;

  /// Uygulamanın kamera ekranını açar; kırpılmış fotoğrafın yolunu döner.
  final Future<String?> Function() takePhoto;
  Future<SelectedImage> _map(XFile file) async {
    if (await file.length() > 8 * 1024 * 1024) {
      throw const AppFailure(FailureKind.validation, code: 'FILE_TOO_LARGE');
    }
    final bytes = await file.readAsBytes();
    // Cropper'ın iOS'ta ürettiği geçici dosyanın adı uzantısız olabilir;
    // MIME türünü başlıktan da tanıyıp JPEG çıktısını kabul et.
    final type = lookupMimeType(file.name, headerBytes: bytes) ??
        (bytes.length >= 3 &&
                bytes[0] == 0xFF &&
                bytes[1] == 0xD8 &&
                bytes[2] == 0xFF
            ? 'image/jpeg'
            : null);
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
      if (origin == ImageOrigin.camera) {
        // Kamera ekranı fotoğrafı kendi içinde kırpıp yolunu döner.
        final path = await takePhoto();
        return path == null ? null : await _map(XFile(path));
      }
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 90,
      );
      if (file == null) return null;
      // UIImagePickerController kapanış animasyonu bitmeden yeni bir
      // UIViewController sunulursa iOS kırpıcıyı göstermeyebilir.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      final path = await cropper.crop(file.path);
      return path == null ? null : await _map(XFile(path));
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
