import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../services/share_service.dart';
import '../../../theme/app_theme.dart';

class QrSection extends StatelessWidget {
  final String payload;
  final GlobalKey repaintKey;
  final VoidCallback onSave;
  final bool isSaving;

  const QrSection({
    super.key,
    required this.payload,
    required this.repaintKey,
    required this.onSave,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasPayload = payload.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: hasPayload ? AppColors.primary.withAlpha(90) : cs.outline,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ── QR / placeholder ──────────────────────────────────────────────
          RepaintBoundary(
            key: repaintKey,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: hasPayload
                  ? _QrBox(payload: payload)
                  : const _QrPlaceholder(),
            ),
          ),
          if (hasPayload) ...[
            const SizedBox(height: 10),
            Text(
              'Aponte a câmera do app do banco para escanear',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          // ── Ações ─────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _Btn(
                  icon: Icons.bookmark_add_rounded,
                  label: 'Salvar',
                  primary: true,
                  loading: isSaving,
                  enabled: hasPayload,
                  onPressed: onSave,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Btn(
                  icon: Icons.copy_rounded,
                  label: 'Copia e Cola',
                  enabled: hasPayload,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: payload));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código PIX copiado!')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Btn(
            icon: Icons.share_rounded,
            label: 'Compartilhar QR Code',
            fullWidth: true,
            enabled: hasPayload,
            onPressed: () async {
              final boundary =
                  repaintKey.currentContext?.findRenderObject()
                      as RenderRepaintBoundary?;
              if (boundary == null) return;
              try {
                await ShareService.shareQrCode(boundary);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao compartilhar: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── QR renderizado ────────────────────────────────────────────────────────────
class _QrBox extends StatelessWidget {
  final String payload;
  const _QrBox({required this.payload});

  @override
  Widget build(BuildContext context) {
    // QR Code precisa de fundo branco e módulos pretos para garantir leitura
    // pelos apps bancários, independente do tema do sistema.
    const qrFg = Color(0xFF1A1F2E);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(55),
            blurRadius: 28,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: QrImageView(
        key: ValueKey(payload),
        data: payload,
        version: QrVersions.auto,
        size: 210,
        backgroundColor: Colors.white,
        padding: EdgeInsets.zero,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: qrFg),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: qrFg,
        ),
      ),
    );
  }
}

// ── Placeholder ───────────────────────────────────────────────────────────────
class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 238,
      height: 238,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_2_rounded,
            size: 64,
            color: cs.onSurfaceVariant.withAlpha(80),
          ),
          const SizedBox(height: 10),
          Text(
            'Preencha os campos\npara gerar o QR Code',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurfaceVariant.withAlpha(140),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botão reutilizável ────────────────────────────────────────────────────────
class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final bool loading;
  final bool enabled;
  final bool fullWidth;

  const _Btn({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.loading = false,
    this.enabled = true,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = primary ? AppColors.primary : cs.surfaceContainerHighest;
    final fg = primary ? AppColors.onPrimary : cs.onSurface;
    final effectiveEnabled = enabled && !loading;

    Widget inner = Container(
      height: 48,
      decoration: BoxDecoration(
        color: effectiveEnabled ? bg : bg.withAlpha(80),
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        border: primary ? null : Border.all(color: cs.outline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          loading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              : Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );

    inner = InkWell(
      onTap: effectiveEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
      child: inner,
    );

    if (fullWidth) return SizedBox(width: double.infinity, child: inner);
    return inner;
  }
}
