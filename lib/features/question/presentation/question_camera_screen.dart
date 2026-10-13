import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';

/// TR: Soruyu çeken uygulama içi kamera. Deklanşörden hemen sonra kırpma
///     ekranı açılır; "Tamam" kırpılmış yolu döndürür, "Vazgeç" yeniden
///     çekime izin verir. Kapatılırsa null döner.
/// EN: In-app camera for capturing a question. The cropper opens right after
///     the shutter; "Tamam" pops with the cropped path, "Vazgeç" allows a
///     retake. Closing pops with null.
class QuestionCameraScreen extends ConsumerStatefulWidget {
  const QuestionCameraScreen({super.key});

  @override
  ConsumerState<QuestionCameraScreen> createState() =>
      _QuestionCameraScreenState();
}

class _QuestionCameraScreenState extends ConsumerState<QuestionCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  FlashMode _flash = FlashMode.off;
  bool _busy = false;
  bool _starting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_controller == null && _error == null) _start();
      return;
    }
    final controller = _controller;
    if (state != AppLifecycleState.inactive ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }
    // TR: Uygulama arka plana giderken kamerayı serbest bırak.
    // EN: Release the camera while the app is not in the foreground.
    setState(() => _controller = null);
    controller.dispose();
  }

  Future<void> _start() async {
    if (_controller != null || _starting) return;
    _starting = true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _error = 'Bu cihazda kamera bulunamadı.');
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await _applyFlash(controller, _flash);
      if (!mounted || _controller != null) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _error = null;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(
        () => _error = switch (e.code) {
          'CameraAccessDenied' ||
          'CameraAccessDeniedWithoutPrompt' ||
          'CameraAccessRestricted' =>
            'Kamera erişimini cihaz ayarlarından aç.',
          _ => 'Kamera açılamadı. Kapatıp tekrar dene.',
        },
      );
    } finally {
      _starting = false;
    }
  }

  Future<void> _applyFlash(CameraController controller, FlashMode mode) async {
    try {
      await controller.setFlashMode(mode);
    } on CameraException {
      // Flaşı olmayan kameralarda sessizce yoksay.
    }
  }

  Future<void> _toggleFlash() async {
    final next = switch (_flash) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      _ => FlashMode.off,
    };
    setState(() => _flash = next);
    final controller = _controller;
    if (controller != null) await _applyFlash(controller, next);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final photo = await controller.takePicture();
      await controller.pausePreview();
      final path = await ref.read(questionImageCropperProvider).crop(photo.path);
      if (path != photo.path) _deleteQuietly(photo.path);
      if (!mounted) return;
      if (path != null) {
        context.pop(path);
        return;
      }
      // Vazgeç: aynı ekranda yeniden çekime dön.
      await _resumePreview();
    } on CameraException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf çekilemedi. Tekrar dene.')),
      );
      await _resumePreview();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resumePreview() async {
    try {
      await _controller?.resumePreview();
    } on CameraException {
      // Önizleme zaten çalışıyorsa veya kamera kapandıysa yoksay.
    }
  }

  void _deleteQuietly(String path) {
    File(path).delete().then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (ready)
              _CoverPreview(controller: controller)
            else if (_error == null)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            if (ready) const _QuestionFrame(),
            if (_error != null) _CameraError(message: _error!),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        _RoundIconButton(
                          icon: Icons.close,
                          tooltip: 'Kapat',
                          onPressed: _busy ? null : () => context.pop(),
                        ),
                        const Expanded(
                          child: Text(
                            'Soruyu çek',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _RoundIconButton(
                          icon: switch (_flash) {
                            FlashMode.auto => Icons.flash_auto,
                            FlashMode.always => Icons.flash_on,
                            _ => Icons.flash_off,
                          },
                          tooltip: 'Flaş',
                          onPressed: ready && !_busy ? _toggleFlash : null,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (ready)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Text(
                        'Soruyu çerçevenin içine al',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: _ShutterButton(
                      busy: _busy,
                      onPressed: ready && !_busy ? _capture : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.controller});
  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    var scale = size.aspectRatio * controller.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;
    return ClipRect(
      child: Transform.scale(
        scale: scale,
        child: Center(child: CameraPreview(controller)),
      ),
    );
  }
}

class _QuestionFrame extends StatelessWidget {
  const _QuestionFrame();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 200),
      child: CustomPaint(painter: _FrameCorners()),
    ),
  );
}

class _FrameCorners extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final x in [0.0, size.width]) {
      for (final y in [0.0, size.height]) {
        final dx = x == 0 ? 1.0 : -1.0, dy = y == 0 ? 1.0 : -1.0;
        final p = Path()
          ..moveTo(x + dx * 34, y)
          ..lineTo(x + dx * 12, y)
          ..quadraticBezierTo(x, y, x, y + dy * 12)
          ..lineTo(x, y + dy * 34);
        canvas.drawPath(p, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon),
    color: Colors.white,
    disabledColor: Colors.white38,
    style: IconButton.styleFrom(
      backgroundColor: Colors.black38,
      fixedSize: const Size(46, 46),
    ),
  );
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.busy, required this.onPressed});
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Fotoğraf çek',
    child: GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 78,
        height: 78,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onPressed == null && !busy ? Colors.white38 : Colors.white,
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.accent,
                  ),
                )
              : null,
        ),
      ),
    ),
  );
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.no_photography_outlined,
            color: Colors.white70,
            size: 40,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    ),
  );
}
