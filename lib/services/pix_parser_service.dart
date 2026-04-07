import '../models/pix_entry.dart';

class PixParserService {
  /// Retorna null se o payload não for um PIX válido.
  static PixFormData? parse(String payload) {
    try {
      final fields = _tlv(payload);
      if (fields['00'] != '01') return null;

      final mai = fields['26'];
      if (mai == null) return null;

      final maiFields = _tlv(mai);
      if (!(maiFields['00'] ?? '').contains('br.gov.bcb.pix')) return null;

      final additionalData = fields['62'];
      String txid = '';
      if (additionalData != null) {
        final raw = _tlv(additionalData)['05'] ?? '';
        txid = raw == '***' ? '' : raw;
      }

      return PixFormData(
        key: maiFields['01'] ?? '',
        receiverName: fields['59'] ?? '',
        receiverCity: fields['60'] ?? '',
        amount: fields['54'] ?? '',
        description: maiFields['02'] ?? '',
        txid: txid,
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> _tlv(String data) {
    final result = <String, String>{};
    int i = 0;
    while (i + 4 <= data.length) {
      final id = data.substring(i, i + 2);
      final length = int.tryParse(data.substring(i + 2, i + 4));
      if (length == null) break;
      final end = i + 4 + length;
      if (end > data.length) break;
      result[id] = data.substring(i + 4, end);
      i = end;
    }
    return result;
  }
}
