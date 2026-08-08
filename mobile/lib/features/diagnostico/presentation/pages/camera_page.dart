import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Câmera nativa in-app com overlay de enquadramento para diagnóstico de folhas.
/// Retorna um [File] com a foto capturada via [Navigator.pop], ou null se cancelado.
class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  List<CameraDescription>? _cameras;
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  bool _isReady = false;
  bool _isCapturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
      if (mounted) setState(() => _isReady = false);
    } else if (state == AppLifecycleState.resumed) {
      final cameras = _cameras;
      if (cameras != null && cameras.isNotEmpty) {
        _setupController(cameras[_selectedCameraIndex]);
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      _cameras = cameras;
      if (cameras.isEmpty) {
        if (mounted) setState(() => _error = 'Nenhuma câmera disponível.');
        return;
      }
      await _setupController(cameras.first);
    } catch (e) {
      if (mounted) setState(() => _error = 'Erro ao inicializar a câmera.');
    }
  }

  Future<void> _setupController(CameraDescription camera) async {
    final prev = _controller;
    if (prev != null) {
      if (mounted) setState(() => _isReady = false);
      _controller = null;
      await prev.dispose();
    }

    final ctrl = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await ctrl.initialize();
      await ctrl.setFlashMode(_flashMode);
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() {
        _controller = ctrl;
        _isReady = true;
      });
    } catch (e) {
      await ctrl.dispose();
      if (mounted) setState(() => _error = 'Falha ao abrir câmera.');
    }
  }

  Future<void> _capture() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      final xFile = await ctrl.takePicture();
      if (mounted) Navigator.pop(context, File(xFile.path));
    } catch (e) {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _toggleFlash() async {
    final ctrl = _controller;
    if (ctrl == null || !_isReady) return;
    final next =
        _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await ctrl.setFlashMode(next);
    setState(() => _flashMode = next);
  }

  Future<void> _flipCamera() async {
    final cameras = _cameras;
    if (cameras == null || cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras.length;
    await _setupController(cameras[_selectedCameraIndex]);
  }

  Future<void> _onTapToFocus(
      TapDownDetails details, BoxConstraints constraints) async {
    final ctrl = _controller;
    if (ctrl == null || !_isReady) return;
    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    try {
      if (ctrl.value.exposurePointSupported) {
        await ctrl.setExposurePoint(offset);
      }
      if (ctrl.value.focusPointSupported) {
        await ctrl.setFocusPoint(offset);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Camera preview ──────────────────────────────────────
            if (_isReady && _controller != null)
              LayoutBuilder(
                builder: (ctx, constraints) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _onTapToFocus(d, constraints),
                  child: CameraPreview(_controller!),
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // ── Overlay: máscara escura + moldura + marcadores ──────
            if (_isReady)
              const IgnorePointer(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _OverlayPainter(),
                ),
              ),

            // ── Controles superiores ────────────────────────────────
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ControlButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      _ControlButton(
                        icon: _flashMode == FlashMode.off
                            ? Icons.flash_off_rounded
                            : Icons.flash_on_rounded,
                        active: _flashMode != FlashMode.off,
                        onTap: _isReady ? _toggleFlash : null,
                      ),
                      if (_cameras != null && _cameras!.length > 1) ...[
                        const SizedBox(width: 8),
                        _ControlButton(
                          icon: Icons.flip_camera_ios_rounded,
                          onTap: _isReady ? _flipCamera : null,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Instrução (abaixo da moldura) ───────────────────────
            if (_isReady)
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: const Alignment(0, 0.38),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha:0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Enquadre a folha na moldura',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Botão de captura ────────────────────────────────────
            Positioned(
              bottom: 44,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _isReady && !_isCapturing ? _capture : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isCapturing ? Colors.white54 : Colors.white,
                      border: Border.all(color: Colors.white70, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.35),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _isCapturing
                        ? const Center(
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black45,
                              ),
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Desenha a máscara semi-transparente com a moldura de enquadramento recortada
/// e os marcadores de canto em verde.
class _OverlayPainter extends CustomPainter {
  const _OverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final frameW = size.width * 0.78;
    final frameRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - size.height * 0.05),
      width: frameW,
      height: frameW,
    );
    const radius = Radius.circular(10);

    // Máscara escura com buraco transparente no centro
    final maskPaint = Paint()
      ..color = Colors.black.withValues(alpha:0.60);
    final maskPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(frameRect, radius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(maskPath, maskPaint);

    // Borda sutil da moldura
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, radius),
      Paint()
        ..color = Colors.white.withValues(alpha:0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Marcadores de canto em verde
    final cornerPaint = Paint()
      ..color = const Color(0xFF66BB6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const arm = 26.0;
    final l = frameRect.left;
    final t = frameRect.top;
    final r = frameRect.right;
    final b = frameRect.bottom;

    // Superior-esquerdo
    canvas.drawLine(Offset(l, t + arm), Offset(l, t), cornerPaint);
    canvas.drawLine(Offset(l, t), Offset(l + arm, t), cornerPaint);
    // Superior-direito
    canvas.drawLine(Offset(r - arm, t), Offset(r, t), cornerPaint);
    canvas.drawLine(Offset(r, t), Offset(r, t + arm), cornerPaint);
    // Inferior-esquerdo
    canvas.drawLine(Offset(l, b - arm), Offset(l, b), cornerPaint);
    canvas.drawLine(Offset(l, b), Offset(l + arm, b), cornerPaint);
    // Inferior-direito
    canvas.drawLine(Offset(r - arm, b), Offset(r, b), cornerPaint);
    canvas.drawLine(Offset(r, b), Offset(r, b - arm), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Botão circular de controle (flash, virar câmera, voltar).
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool active;

  const _ControlButton({
    required this.icon,
    this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? Colors.amber.withValues(alpha:0.9)
              : Colors.black.withValues(alpha:0.55),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
