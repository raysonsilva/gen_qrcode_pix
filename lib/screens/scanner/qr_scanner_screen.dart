import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/pix_parser_service.dart';
import '../../models/pix_entry.dart';
import '../../widgets/qr_corner_painter.dart';
import '../../theme/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _detected = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;

    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null) return;

    final parsed = PixParserService.parse(rawValue);

    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR Code não reconhecido como PIX.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _detected = true);
    Navigator.of(context).pop<PixFormData>(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ler QR Code PIX'),
        actions: [
          _ScanBtn(
            icon: Icons.flash_on_rounded,
            tooltip: 'Flash',
            onPressed: () => _controller.toggleTorch(),
          ),
          _ScanBtn(
            icon: Icons.flip_camera_android_rounded,
            tooltip: 'Virar câmera',
            onPressed: () => _controller.switchCamera(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          _buildOverlay(context),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: cs.surface.withAlpha(220),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cs.outline),
                ),
                child: Text(
                  'Aponte para um QR Code PIX',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    const cutoutSize = 260.0;
    final screenSize = MediaQuery.of(context).size;
    final cutoutLeft = (screenSize.width - cutoutSize) / 2;
    final cutoutTop = (screenSize.height - cutoutSize) / 2 - 60;
    const cornerSize = 24.0;
    const thickness = 4.0;
    const color = AppColors.primary;

    return Stack(
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Positioned(
                top: cutoutTop,
                left: cutoutLeft,
                child: Container(
                  width: cutoutSize,
                  height: cutoutSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: cutoutTop,
          left: cutoutLeft,
          child: SizedBox(
            width: cornerSize,
            height: cornerSize,
            child: CustomPaint(
              painter: QrCornerPainter(
                color: color,
                thickness: thickness,
                top: true,
                left: true,
              ),
            ),
          ),
        ),
        Positioned(
          top: cutoutTop,
          left: cutoutLeft + cutoutSize - cornerSize,
          child: SizedBox(
            width: cornerSize,
            height: cornerSize,
            child: CustomPaint(
              painter: QrCornerPainter(
                color: color,
                thickness: thickness,
                top: true,
                left: false,
              ),
            ),
          ),
        ),
        Positioned(
          top: cutoutTop + cutoutSize - cornerSize,
          left: cutoutLeft,
          child: SizedBox(
            width: cornerSize,
            height: cornerSize,
            child: CustomPaint(
              painter: QrCornerPainter(
                color: color,
                thickness: thickness,
                top: false,
                left: true,
              ),
            ),
          ),
        ),
        Positioned(
          top: cutoutTop + cutoutSize - cornerSize,
          left: cutoutLeft + cutoutSize - cornerSize,
          child: SizedBox(
            width: cornerSize,
            height: cornerSize,
            child: CustomPaint(
              painter: QrCornerPainter(
                color: color,
                thickness: thickness,
                top: false,
                left: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const _ScanBtn({
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
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
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
