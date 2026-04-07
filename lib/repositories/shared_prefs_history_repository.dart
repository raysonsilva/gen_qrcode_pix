import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pix_entry.dart';
import 'history_repository.dart';

class SharedPrefsHistoryRepository implements HistoryRepository {
  static const _key = 'pix_history';
  static const _maxEntries = 50;

  @override
  Future<List<PixEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => PixEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> save(PixEntry entry) async {
    final entries = await getAll();
    final alreadyExists = entries.any(
      (e) =>
          e.key == entry.key &&
          e.amount == entry.amount &&
          e.txid == entry.txid,
    );
    if (alreadyExists) throw const DuplicateEntryException();

    final updated = [entry, ...entries].take(_maxEntries).toList();
    await _persist(updated);
  }

  @override
  Future<void> update(PixEntry entry) async {
    final entries = await getAll();
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) throw StateError('Entry not found: ${entry.id}');
    entries[index] = entry;
    await _persist(entries);
  }

  @override
  Future<void> delete(String id) async {
    final entries = await getAll();
    final updated = entries.where((e) => e.id != id).toList();
    await _persist(updated);
  }

  Future<void> _persist(List<PixEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}

class DuplicateEntryException implements Exception {
  const DuplicateEntryException();
  @override
  String toString() => 'Já existe no histórico com os mesmos dados.';
}
