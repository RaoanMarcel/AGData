import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/diagnostico_visuals.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/diagnostico_badge.dart';
import '../../../../core/widgets/info_pill.dart';
import '../controllers/home_controller.dart';
import 'historico_screen.dart';
import 'mapa_screen.dart';

class HomeScreen extends StatefulWidget {
  final String talhaoAtual;
  const HomeScreen({super.key, required this.talhaoAtual});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.solicitarPermissoesIniciais();
    });
  }

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
                MaterialPageRoute(builder: (context) => const MapaScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Histórico de leituras',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
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
                  _ImagePreview(image: _controller.image),
                  const SizedBox(height: AppSpacing.xl),
                  _ResultArea(controller: _controller),
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton(
                    label: 'Capturar foto',
                    icon: Icons.camera_alt_outlined,
                    onPressed: _controller.loading
                        ? null
                        : () => _controller.pickAndProcessImage(
                            ImageSource.camera, widget.talhaoAtual),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Escolher da galeria',
                    icon: Icons.photo_library_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: _controller.loading
                        ? null
                        : () => _controller.pickAndProcessImage(
                            ImageSource.gallery, widget.talhaoAtual),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Área quadrada de pré-visualização da imagem (ou placeholder de captura).
class _ImagePreview extends StatelessWidget {
  final File? image;
  const _ImagePreview({required this.image});

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null;
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: hasImage ? AppColors.primary : AppColors.outline,
            width: 2,
          ),
          image: hasImage
              ? DecorationImage(image: FileImage(image!), fit: BoxFit.cover)
              : null,
        ),
        child: hasImage
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined,
                      size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: AppSpacing.md),
                  Text('Pronto para analisar',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
      ),
    );
  }
}

/// Área de resultado: loading, diagnóstico estruturado ou mensagem de estado.
class _ResultArea extends StatelessWidget {
  final HomeController controller;
  const _ResultArea({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.loading) {
      return const _LoadingCard();
    }

    final temDiagnostico = controller.image != null &&
        DiagnosticoVisual.isConhecido(controller.resultado);

    if (temDiagnostico) {
      return _DiagnosticoCard(
        resultado: controller.resultado,
        confianca: controller.confianca,
        localizacao: controller.localizacaoTexto,
      );
    }

    // Estado inicial ou de erro (o controller zera a imagem em erros).
    final isErro = controller.resultado.contains('ERRO') ||
        controller.resultado.startsWith('SEM ');
    return _MessageCard(
      titulo: controller.resultado,
      subtitulo: controller.confianca,
      isErro: isErro,
    );
  }
}

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

class _DiagnosticoCard extends StatelessWidget {
  final String resultado;
  final String confianca;
  final String localizacao;

  const _DiagnosticoCard({
    required this.resultado,
    required this.confianca,
    required this.localizacao,
  });

  @override
  Widget build(BuildContext context) {
    final temGps =
        localizacao.isNotEmpty && localizacao != 'GPS indisponível';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            DiagnosticoBadge(resultado: resultado),
            const SizedBox(height: AppSpacing.md),
            Text(confianca,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            if (temGps) ...[
              const SizedBox(height: AppSpacing.md),
              InfoPill(
                icon: Icons.location_on_outlined,
                text: localizacao,
                color: AppColors.info,
                background: AppColors.infoContainer,
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
            const Icon(Icons.error_outline,
                color: AppColors.danger, size: 32),
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
