import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static Future<void> shareQrCode(RenderRepaintBoundary boundary) async {
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null)
      throw Exception('Falha ao capturar imagem do QR Code.');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/qrcode_pix.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'QR Code PIX'),
    );
  }
}
