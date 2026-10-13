import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';

import '../domain/question.dart';

class PlatformQuestionImageCropper implements QuestionImageCropper {
  const PlatformQuestionImageCropper();

  @override
  Future<String?> crop(String path) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 92,
        maxWidth: 2400,
        maxHeight: 2400,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Soruyu kırp',
            toolbarColor: const Color(0xFF4F3FE6),
            toolbarWidgetColor: const Color(0xFFFFFFFF),
            activeControlsWidgetColor: const Color(0xFF4F3FE6),
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Soruyu kırp',
            doneButtonTitle: 'Tamam',
            cancelButtonTitle: 'Vazgeç',
            aspectRatioLockEnabled: false,
            aspectRatioPresets: const [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
            ],
          ),
        ],
      );
      return cropped?.path;
    } on MissingPluginException {
      debugPrint('Hatora cropper unavailable: MissingPluginException');
      // Native cropper unavailable: keep the captured photo usable.
      return path;
    } on PlatformException {
      debugPrint('Hatora cropper unavailable: PlatformException');
      // Do not strand the user on the capture screen if the native editor
      // cannot be presented on a particular device.
      return path;
    }
  }
}
