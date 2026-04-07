import '../models/pix_entry.dart';

class PixPayloadService {
  static String generate(PixFormData data) {
    final parts = <String>[];

    parts.add(_field('00', '01'));

    final gui = _field('00', 'br.gov.bcb.pix');
    final key = _field('01', data.key);
    final descNorm = _normalize(data.description);
    final desc = descNorm.isNotEmpty
        ? _field('02', descNorm.substring(0, descNorm.length.clamp(0, 36)))
        : '';
    parts.add(_field('26', '$gui$key$desc'));

    parts.add(_field('52', '0000'));
    parts.add(_field('53', '986'));

    final amount = double.tryParse(data.amount.replaceAll(',', '.'));
    if (amount != null && amount > 0) {
      parts.add(_field('54', amount.toStringAsFixed(2)));
    }

    parts.add(_field('58', 'BR'));
    final nameNorm = _normalize(data.receiverName);
    parts.add(
      _field('59', nameNorm.substring(0, nameNorm.length.clamp(0, 25))),
    );
    final cityNorm = _normalize(data.receiverCity);
    parts.add(
      _field('60', cityNorm.substring(0, cityNorm.length.clamp(0, 15))),
    );

    final txidNorm = _normalize(data.txid);
    final txid = txidNorm.isNotEmpty
        ? txidNorm.substring(0, txidNorm.length.clamp(0, 25))
        : '***';
    parts.add(_field('62', _field('05', txid)));

    final withoutCrc = '${parts.join('')}6304';
    return '$withoutCrc${_crc16(withoutCrc)}';
  }

  static String _field(String id, String value) {
    final len = value.length.toString().padLeft(2, '0');
    return '$id$len$value';
  }

  static String _crc16(String data) {
    int crc = 0xFFFF;
    const poly = 0x1021;
    for (int i = 0; i < data.length; i++) {
      int b = data.codeUnitAt(i);
      for (int j = 0; j < 8; j++) {
        final bit = ((b >> (7 - j)) & 1) == 1;
        final c15 = ((crc >> 15) & 1) == 1;
        crc <<= 1;
        if (c15 ^ bit) crc ^= poly;
      }
    }
    return (crc & 0xFFFF).toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  static String _normalize(String text) {
    const from = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const to = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuNnSsYyyZz';
    var result = text;
    for (int i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result;
  }
}
