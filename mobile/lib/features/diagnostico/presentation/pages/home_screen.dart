import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/diagnostico_visuals.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/diagnostico_badge.dart';
import '../../../../core/widgets/info_pill.dart';
import '../controllers/home_controller.dart';
import '../widgets/observacao_field.dart';
import 'historico_screen.dart';
import 'mapa_screen.dart';

class HomeScreen extends StatefulWidget {
  final String talhaoAtual;
  const HomeScreen({super.key, required this.talhaoAtual});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final HomeController _controller = HomeController();
  final TextEditingController _obsController = TextEditingController();

  CameraController? _cam;
  bool _camReady = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.solicitarPermissoesIniciais();
      await _initCamera();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cam?.dispose();
    _obsController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = _cam;
    if (cam == null || !cam.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      cam.dispose();
      if (mounted) setState(() { _cam = null; _camReady = false; });
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty || !mounted) return;
      final ctrl = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      if (!mounted) { await ctrl.dispose(); return; }
      setState(() { _cam = ctrl; _camReady = true; });
    } catch (_) {}
  }

  Future<void> _capturar() async {
    final cam = _cam;
    if (cam == null || !_camReady || _isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final xFile = await cam.takePicture();
      if (mounted) {
        await _controller.processarImagemDaCamera(
            File(xFile.path), widget.talhaoAtual);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _salvar() async {
    final ok = await _controller.salvar(observacao: _obsController.text);
    if (!mounted) return;
    if (ok) {
      _obsController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leitura salva com sucesso!'),
          backgroundColor: AppColors.syncSuccess,
        ),
      );
    }
  }

  void _descartar() {
    _controller.descartar();
    _obsController.clear();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.talhaoAtual),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Mapa de ocorrências',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MapaScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Histórico de leituras',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        HistoricoScreen(talhaoInicial: widget.talhaoAtual))),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  _buildPreviewArea(),
                  const SizedBox(height: AppSpacing.xl),
                  ..._buildEstado(_controller.status),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Preview (câmera embarcada ou imagem capturada) ───────────────────────

  Widget _buildPreviewArea() {
    final status = _controller.status;
    final image = _controller.image;

    // Imagem capturada — mostra a foto
    if (image != null &&
        (status == DiagnosticoStatus.revisao ||
            status == DiagnosticoStatus.processando)) {
      return _StaticImage(image: image);
    }

    // Câmera embarcada — estados inicial e erro
    if (_camReady && _cam != null) {
      return _EmbeddedCamera(
        controller: _cam!,
        isCapturing: _isCapturing,
        onCapture: _capturar,
      );
    }

    // Placeholder enquanto câmera inicializa
    return _PlaceholderPreview(loading: !_camReady);
  }

  // ── Estado da tela ────────────────────────────────────────────────────────

  List<Widget> _buildEstado(DiagnosticoStatus status) {
    switch (status) {
      case DiagnosticoStatus.processando:
        return const [_LoadingCard()];

      case DiagnosticoStatus.revisao:
        return [
          _DiagnosticoRevisaoCard(
            resultado: _controller.resultado,
            confiancaValor: _controller.confiancaValor,
            localizacao: _controller.localizacaoTexto,
          ),
          const SizedBox(height: AppSpacing.lg),
          ObservacaoField(controller: _obsController),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Descartar',
                  icon: Icons.delete_outline,
                  variant: AppButtonVariant.secondary,
                  onPressed: _controller.salvando ? null : _descartar,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: 'Salvar',
                  icon: Icons.check,
                  loading: _controller.salvando,
                  onPressed: _salvar,
                ),
              ),
            ],
          ),
        ];

      case DiagnosticoStatus.erro:
        return [
          _MessageCard(
            titulo: _controller.resultado,
            subtitulo: _controller.mensagemErro,
            isErro: true,
          ),
          const SizedBox(height: AppSpacing.md),
          ..._botoesCaptura(),
        ];

      case DiagnosticoStatus.inicial:
        return _botoesCaptura();
    }
  }

  List<Widget> _botoesCaptura() {
    return [
      AppButton(
        label: _isCapturing ? 'Capturando...' : 'Capturar foto',
        icon: Icons.camera_alt_outlined,
        loading: _isCapturing,
        onPressed: (_camReady && !_isCapturing) ? _capturar : null,
      ),
      const SizedBox(height: AppSpacing.md),
      AppButton(
        label: 'Escolher da galeria',
        icon: Icons.photo_library_outlined,
        variant: AppButtonVariant.secondary,
        onPressed: () => _controller.pickFromGaleria(widget.talhaoAtual),
      ),
    ];
  }
}

// ── Câmera embarcada no quadro ────────────────────────────────────────────

class _EmbeddedCamera extends StatelessWidget {
  final CameraController controller;
  final bool isCapturing;
  final VoidCallback onCapture;

  const _EmbeddedCamera({
    required this.controller,
    required this.isCapturing,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Preview preenchendo o quadrado (crop central)
            _SquareCameraPreview(controller: controller),

            // Marcadores de canto
            const IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: _CornerPainter(),
              ),
            ),

            // Instrução + flash de captura
            if (isCapturing)
              Container(color: Colors.white.withValues(alpha: 0.35))
            else
              Align(
                alignment: const Alignment(0, 0.88),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Enquadre a folha',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        letterSpacing: 0.3),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SquareCameraPreview extends StatelessWidget {
  final CameraController controller;
  const _SquareCameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = controller.value.previewSize;
    if (size == null) return const SizedBox.expand();

    // previewSize é em orientação landscape; no portrait, invertemos.
    final double w = size.height;
    final double h = size.width;

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: w,
        height: h,
        child: CameraPreview(controller),
      ),
    );
  }
}

// ── Marcadores de canto (overlay leve) ───────────────────────────────────

class _CornerPainter extends CustomPainter {
  const _CornerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF66BB6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const pad = 12.0;
    const arm = 22.0;
    final l = pad, t = pad, r = size.width - pad, b = size.height - pad;

    // Superior-esquerdo
    canvas.drawLine(Offset(l, t + arm), Offset(l, t), paint);
    canvas.drawLine(Offset(l, t), Offset(l + arm, t), paint);
    // Superior-direito
    canvas.drawLine(Offset(r - arm, t), Offset(r, t), paint);
    canvas.drawLine(Offset(r, t), Offset(r, t + arm), paint);
    // Inferior-esquerdo
    canvas.drawLine(Offset(l, b - arm), Offset(l, b), paint);
    canvas.drawLine(Offset(l, b), Offset(l + arm, b), paint);
    // Inferior-direito
    canvas.drawLine(Offset(r - arm, b), Offset(r, b), paint);
    canvas.drawLine(Offset(r, b), Offset(r, b - arm), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Imagem estática capturada ─────────────────────────────────────────────

class _StaticImage extends StatelessWidget {
  final File image;
  const _StaticImage({required this.image});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Image.file(image, fit: BoxFit.cover),
      ),
    );
  }
}

// ── Placeholder enquanto câmera inicializa ────────────────────────────────

class _PlaceholderPreview extends StatelessWidget {
  final bool loading;
  const _PlaceholderPreview({this.loading = false});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.outline, width: 2),
        ),
        child: Center(
          child: loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_outlined,
                        size: 64, color: AppColors.textTertiary),
                    const SizedBox(height: AppSpacing.md),
                    Text('Iniciando câmera...',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Cards auxiliares ──────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.lg),
            Text('Analisando amostra...',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('Processando imagem e localização',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticoRevisaoCard extends StatelessWidget {
  final String resultado;
  final double confiancaValor;
  final String localizacao;

  const _DiagnosticoRevisaoCard({
    required this.resultado,
    required this.confiancaValor,
    required this.localizacao,
  });

  @override
  Widget build(BuildContext context) {
    final visual = DiagnosticoVisual.fromResultado(resultado);
    final temGps =
        localizacao.isNotEmpty && localizacao != 'GPS indisponível';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: DiagnosticoBadge(resultado: resultado)),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Precisão da análise',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text('${(confiancaValor * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: visual.color, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: confiancaValor.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(visual.color),
              ),
            ),
            if (temGps) ...[
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: InfoPill(
                  icon: Icons.location_on_outlined,
                  text: localizacao,
                  color: AppColors.info,
                  background: AppColors.infoContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final bool isErro;

  const _MessageCard({
    required this.titulo,
    required this.subtitulo,
    required this.isErro,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = isErro ? AppColors.danger : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          if (isErro) ...[
            const Icon(Icons.error_outline, color: AppColors.danger, size: 32),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(color: color),
          ),
          if (subtitulo.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitulo,
                textAlign: TextAlign.center, style: textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
