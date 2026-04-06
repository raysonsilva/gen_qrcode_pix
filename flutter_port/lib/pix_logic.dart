import 'dart:convert';

class PixData {
  final String key;
  final String receiverName;
  final String receiverCity;
  final String? amount;
  final String? description;
  final String? txid;

  PixData({
    required this.key,
    required this.receiverName,
    required this.receiverCity,
    this.amount,
    this.description,
    this.txid,
  });
}

class PixUtils {
  static String _formatField(String id, String value) {
    final length = value.length.toString().padLeft(2, '0');
    return '$id$length$value';
  }

  static String _calculateCrc16(String data) {
    int crc = 0xFFFF;
    int polynomial = 0x1021;

    for (int i = 0; i < data.length; i++) {
      int b = data.codeUnitAt(i);
      for (int j = 0; j < 8; j++) {
        bool bit = ((b >> (7 - j)) & 1) == 1;
        bool c15 = ((crc >> 15) & 1) == 1;
        crc <<= 1;
        if (c15 ^ bit) crc ^= polynomial;
      }
    }

    crc &= 0xFFFF;
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  static String _normalize(String text) {
    // Simples remoção de acentos para Dart (exemplo básico)
    var withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var withoutDia = 'AAAAAAaaaaaaOOOOOOOoooooooEEEEeeeeecCdDIIIIiiiiUUUUuuuuNnSsYyyZz';
    for (int i = 0; i < withDia.length; i++) {
      text = text.replaceAll(withDia[i], withoutDia[i]);
    }
    return text;
  }

  static String generatePayload(PixData data) {
    List<String> parts = [];

    // 00: Payload Format Indicator
    parts.add(_formatField('00', '01'));

    // 26: Merchant Account Information
    String gui = _formatField('00', 'br.gov.bcb.pix');
    String key = _formatField('01', data.key);
    String description = data.description != null && data.description!.isNotEmpty 
        ? _formatField('02', data.description!) 
        : '';
    parts.add(_formatField('26', '$gui$key$description'));

    // 52: Merchant Category Code
    parts.add(_formatField('52', '0000'));

    // 53: Transaction Currency (986 = BRL)
    parts.add(_formatField('53', '986'));

    // 54: Transaction Amount
    if (data.amount != null && data.amount!.isNotEmpty) {
      double? val = double.tryParse(data.amount!.replaceAll(',', '.'));
      if (val != null && val > 0) {
        parts.add(_formatField('54', val.toStringAsFixed(2)));
      }
    }

    // 58: Country Code
    parts.add(_formatField('58', 'BR'));

    // 59: Merchant Name
    String cleanName = _normalize(data.receiverName);
    if (cleanName.length > 25) cleanName = cleanName.substring(0, 25);
    parts.add(_formatField('59', cleanName));

    // 60: Merchant City
    String cleanCity = _normalize(data.receiverCity);
    if (cleanCity.length > 15) cleanCity = cleanCity.substring(0, 15);
    parts.add(_formatField('60', cleanCity));

    // 62: Additional Data Field Template
    String txid = data.txid != null && data.txid!.isNotEmpty 
        ? data.txid! 
        : '***';
    if (txid.length > 25) txid = txid.substring(0, 25);
    parts.add(_formatField('62', _formatField('05', txid)));

    // 63: CRC16
    String payloadWithoutCrc = parts.join('') + '6304';
    String crc = _calculateCrc16(payloadWithoutCrc);
    
    return '$payloadWithoutCrc$crc';
  }
}
