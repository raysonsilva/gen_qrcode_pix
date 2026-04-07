import '../models/pix_entry.dart';

abstract class HistoryRepository {
  Future<List<PixEntry>> getAll();
  Future<void> save(PixEntry entry);
  Future<void> update(PixEntry entry);
  Future<void> delete(String id);
}
