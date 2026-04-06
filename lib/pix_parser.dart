/// Parser de payload PIX (EMV/TLV)
/// Extrai os campos relevantes de um QR Code PIX estático ou dinâmico.
class PixParser {
  /// Retorna null se o payload não for um PIX válido.
  static PixParsedData? parse(String payload) {
    try {
      final fields = _parseTlv(payload);

      // ID 00 deve ser "01" (Payload Format Indicator)
      if (fields['00'] != '01') return null;

      // ID 26: Merchant Account Information (contém a chave PIX)
      final mai = fields['26'];
      if (mai == null) return null;

      final maiFields = _parseTlv(mai);

      // GUI deve ser "br.gov.bcb.pix"
      final gui = maiFields['00'] ?? '';
      if (!gui.contains('br.gov.bcb.pix')) return null;

      final key = maiFields['01'] ?? '';
      final description = maiFields['02'] ?? '';

      // ID 54: valor
      final amount = fields['54'] ?? '';

      // ID 59: nome do recebedor
      final name = fields['59'] ?? '';

      // ID 60: cidade
      final city = fields['60'] ?? '';

      // ID 62: additional data (txid em 05)
      final additionalData = fields['62'];
      String txid = '';
      if (additionalData != null) {
        final addFields = _parseTlv(additionalData);
        txid = addFields['05'] ?? '';
        if (txid == '***') txid = '';
      }

      return PixParsedData(
        key: key,
        receiverName: name,
        receiverCity: city,
        amount: amount,
        description: description,
        txid: txid,
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> _parseTlv(String data) {
    final result = <String, String>{};
    int i = 0;
    while (i + 4 <= data.length) {
      final id = data.substring(i, i + 2);
      final lengthStr = data.substring(i + 2, i + 4);
      final length = int.tryParse(lengthStr);
      if (length == null) break;
      final end = i + 4 + length;
      if (end > data.length) break;
      final value = data.substring(i + 4, end);
      result[id] = value;
      i = end;
    }
    return result;
  }
}

class PixParsedData {
  final String key;
  final String receiverName;
  final String receiverCity;
  final String amount;
  final String description;
  final String txid;

  const PixParsedData({
    required this.key,
    required this.receiverName,
    required this.receiverCity,
    required this.amount,
    required this.description,
    required this.txid,
  });
}
