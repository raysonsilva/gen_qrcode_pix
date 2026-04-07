import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../controllers/pix_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/pix_entry.dart';
import '../../repositories/shared_prefs_history_repository.dart';
import '../scanner/qr_scanner_screen.dart';
import 'widgets/pix_form_section.dart';
import 'widgets/qr_section.dart';
import 'widgets/history_section.dart';
import '../../theme/app_theme.dart';

class PixGeneratorScreen extends StatefulWidget {
  final ThemeController themeController;

  const PixGeneratorScreen({super.key, required this.themeController});

  @override
  State<PixGeneratorScreen> createState() => _PixGeneratorScreenState();
}

class _PixGeneratorScreenState extends State<PixGeneratorScreen> {
  late final PixController _controller;
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSaving = false;
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _controller = PixController(repository: SharedPrefsHistoryRepository());
    _controller.addListener(_onControllerUpdate);
    _controller.init();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = 'v${info.version}+${info.buildNumber}';
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final saved = await _controller.saveToHistory();
    if (mounted) {
      setState(() => _isSaving = false);
      if (saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Code salvo no histórico.')),
        );
      } else if (_controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        );
        _controller.clearError();
      }
    }
  }

  Future<void> _onSelectHistory(PixEntry entry) async {
    if (_controller.isEditing) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
          title: const Text('Descartar alterações?'),
          content: const Text(
            'O formulário tem dados não salvos. '
            'Deseja descartá-los e carregar este item do histórico?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );

      if (confirmed == true) _controller.loadFromEntry(entry);
      return;
    }

    final incoming = PixFormData(
      key: entry.key,
      receiverName: entry.receiverName,
      receiverCity: entry.receiverCity,
      amount: entry.amount,
      description: entry.description,
      txid: entry.txid,
    );

    final current = _controller.formData;
    if (current == incoming) return;

    _controller.loadFromEntry(entry);
  }

  Future<void> _openScanner() async {
    final result = await Navigator.of(context).push<PixFormData>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result != null) {
      _controller.updateForm(result);
    }
  }

  void _cycleTheme() {
    final next = switch (widget.themeController.mode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    widget.themeController.setMode(next);
  }

  void _clearForm() {
    _controller.clearForm();
  }

  IconData _themeIcon() => switch (widget.themeController.mode) {
    ThemeMode.light => Icons.light_mode_rounded,
    ThemeMode.dark => Icons.dark_mode_rounded,
    _ => Icons.brightness_auto_rounded,
  };

  String _themeTooltip() => switch (widget.themeController.mode) {
    ThemeMode.light => 'Modo claro',
    ThemeMode.dark => 'Modo escuro',
    _ => 'Seguir sistema',
  };

  @override
  Widget build(BuildContext context) {
    final isLoading = _controller.status == PixControllerStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.qr_code_rounded,
                color: AppColors.onPrimary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text('QR PIX'),
          ],
        ),
        actions: [
          if (_controller.formState != PixFormState.clean)
            _AppBarBtn(
              icon: Icons.close_rounded,
              tooltip: 'Limpar formulário',
              onPressed: _clearForm,
            ),
          if (_controller.formState != PixFormState.clean)
            const SizedBox(width: 6),
          ListenableBuilder(
            listenable: widget.themeController,
            builder: (_, __) => _AppBarBtn(
              icon: _themeIcon(),
              tooltip: _themeTooltip(),
              onPressed: _cycleTheme,
            ),
          ),
          const SizedBox(width: 6),
          _AppBarBtn(
            icon: Icons.qr_code_scanner_rounded,
            tooltip: 'Ler QR Code PIX',
            onPressed: _openScanner,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                32 + MediaQuery.of(context).padding.bottom,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                PixFormSection(
                  initialData: _controller.formData,
                  formState: _controller.formState,
                  onChanged: _controller.updateForm,
                ),
                const SizedBox(height: 16),
                QrSection(
                  payload: _controller.payload,
                  repaintKey: _repaintKey,
                  onSave: _save,
                  isSaving: _isSaving,
                ),
                if (_controller.history.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  HistorySection(
                    entries: _controller.history,
                    editingEntryId: _controller.editingEntryId,
                    isFormEditing: _controller.isEditing,
                    onSelect: _onSelectHistory,
                    onDelete: _controller.deleteFromHistory,
                  ),
                ],
                if (_appVersion != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _appVersion!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _AppBarBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _AppBarBtn({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outline),
          ),
          child: Icon(icon, size: 19, color: cs.onSurface),
        ),
      ),
    );
  }
}
