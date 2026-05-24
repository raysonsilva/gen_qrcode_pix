import 'package:uuid/uuid.dart';

enum PixFormState { clean, editing, consolidated }

class PixEntry {
  final String id;
  final String key;
  final String receiverName;
  final String receiverCity;
  final String amount;
  final String description;
  final String txid;
  final String payload;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PixEntry({
    required this.id,
    required this.key,
    required this.receiverName,
    required this.receiverCity,
    required this.amount,
    required this.description,
    required this.txid,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PixEntry.create({
    required String key,
    required String receiverName,
    required String receiverCity,
    required String amount,
    required String description,
    required String txid,
    required String payload,
  }) {
    final now = DateTime.now();
    return PixEntry(
      id: const Uuid().v4(),
      key: key,
      receiverName: receiverName,
      receiverCity: receiverCity,
      amount: amount,
      description: description,
      txid: txid,
      payload: payload,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory PixEntry.fromJson(Map<String, dynamic> json) {
    return PixEntry(
      id: json['id'] as String,
      key: json['key'] as String,
      receiverName: json['receiverName'] as String,
      receiverCity: json['receiverCity'] as String,
      amount: json['amount'] as String? ?? '',
      description: json['description'] as String? ?? '',
      txid: json['txid'] as String? ?? '',
      payload: json['payload'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(
        (json['updatedAt'] as String?) ?? json['createdAt'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'key': key,
    'receiverName': receiverName,
    'receiverCity': receiverCity,
    'amount': amount,
    'description': description,
    'txid': txid,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  PixEntry copyWith({
    String? key,
    String? receiverName,
    String? receiverCity,
    String? amount,
    String? description,
    String? txid,
    String? payload,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PixEntry(
      id: id,
      key: key ?? this.key,
      receiverName: receiverName ?? this.receiverName,
      receiverCity: receiverCity ?? this.receiverCity,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      txid: txid ?? this.txid,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Dados de formulário ainda não persistidos
class PixFormData {
  final String key;
  final String receiverName;
  final String receiverCity;
  final String amount;
  final String description;
  final String txid;

  const PixFormData({
    this.key = '',
    this.receiverName = '',
    this.receiverCity = '',
    this.amount = '',
    this.description = '',
    this.txid = '',
  });

  /// TXID válido: vazio ou apenas letras/números, entre 1 e 25 caracteres.
  bool get isTxidValid =>
      txid.isEmpty || RegExp(r'^[a-zA-Z0-9]{1,25}$').hasMatch(txid);

  bool get isValid =>
      key.isNotEmpty &&
      receiverName.isNotEmpty &&
      receiverCity.isNotEmpty &&
      isTxidValid;

  bool get isEmpty =>
      key.isEmpty &&
      receiverName.isEmpty &&
      receiverCity.isEmpty &&
      amount.isEmpty &&
      description.isEmpty &&
      txid.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is PixFormData &&
      key == other.key &&
      receiverName == other.receiverName &&
      receiverCity == other.receiverCity &&
      amount == other.amount &&
      description == other.description &&
      txid == other.txid;

  @override
  int get hashCode =>
      Object.hash(key, receiverName, receiverCity, amount, description, txid);

  PixFormData copyWith({
    String? key,
    String? receiverName,
    String? receiverCity,
    String? amount,
    String? description,
    String? txid,
  }) {
    return PixFormData(
      key: key ?? this.key,
      receiverName: receiverName ?? this.receiverName,
      receiverCity: receiverCity ?? this.receiverCity,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      txid: txid ?? this.txid,
    );
  }
}
