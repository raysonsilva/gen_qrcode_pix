import 'package:flutter/foundation.dart';
import '../models/pix_entry.dart';
import '../repositories/history_repository.dart';
import '../repositories/shared_prefs_history_repository.dart';
import '../services/pix_payload_service.dart';

enum PixControllerStatus { idle, loading, error }

class PixController extends ChangeNotifier {
  PixController({HistoryRepository? repository})
    : _repository = repository ?? SharedPrefsHistoryRepository();

  final HistoryRepository _repository;

  PixFormData _formData = const PixFormData();
  PixFormData get formData => _formData;

  String _payload = '';
  String get payload => _payload;

  List<PixEntry> _history = [];
  List<PixEntry> get history => List.unmodifiable(_history);

  PixControllerStatus _status = PixControllerStatus.idle;
  PixControllerStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  PixFormState _formState = PixFormState.clean;
  PixFormState get formState => _formState;

  bool get isEditing => _formState == PixFormState.editing;

  String? _editingEntryId;
  String? get editingEntryId => _editingEntryId;

  PixFormData? _consolidatedFormData;

  Future<void> init() async {
    _status = PixControllerStatus.loading;
    notifyListeners();
    _history = await _repository.getAll();
    _status = PixControllerStatus.idle;
    notifyListeners();
  }

  void updateForm(PixFormData data) {
    _formData = data;
    _payload = data.isValid ? PixPayloadService.generate(data) : '';

    if (_consolidatedFormData != null) {
      _formState = _formData == _consolidatedFormData
          ? PixFormState.consolidated
          : PixFormState.editing;
    } else {
      _formState = _formData.isEmpty
          ? PixFormState.clean
          : PixFormState.editing;
      if (_formState == PixFormState.clean) {
        _editingEntryId = null;
      }
    }

    notifyListeners();
  }

  void loadFromEntry(PixEntry entry) {
    _formData = PixFormData(
      key: entry.key,
      receiverName: entry.receiverName,
      receiverCity: entry.receiverCity,
      amount: entry.amount,
      description: entry.description,
      txid: entry.txid,
    );
    _payload = PixPayloadService.generate(_formData);
    _editingEntryId = entry.id;
    _consolidatedFormData = _formData;
    _formState = PixFormState.consolidated;
    _clearError();
    notifyListeners();
  }

  void clearForm() {
    _formData = const PixFormData();
    _payload = '';
    _editingEntryId = null;
    _consolidatedFormData = null;
    _formState = PixFormState.clean;
    _clearError();
    notifyListeners();
  }

  Future<bool> saveToHistory() async {
    if (_payload.isEmpty) return false;
    try {
      final existingEntry = _findEditingEntry();

      final isEssentialSame =
          existingEntry != null &&
          _formData.key == existingEntry.key &&
          _formData.amount == existingEntry.amount &&
          _formData.txid == existingEntry.txid;

      PixEntry entry;

      if (isEssentialSame) {
        entry = PixEntry(
          id: existingEntry.id,
          key: _formData.key,
          receiverName: _formData.receiverName,
          receiverCity: _formData.receiverCity,
          amount: _formData.amount,
          description: _formData.description,
          txid: _formData.txid,
          payload: _payload,
          createdAt: existingEntry.createdAt,
          updatedAt: DateTime.now(),
        );
        await _repository.update(entry);
      } else {
        entry = PixEntry.create(
          key: _formData.key,
          receiverName: _formData.receiverName,
          receiverCity: _formData.receiverCity,
          amount: _formData.amount,
          description: _formData.description,
          txid: _formData.txid,
          payload: _payload,
        );
        await _repository.save(entry);
      }

      _history = await _repository.getAll();
      _editingEntryId = entry.id;
      _consolidatedFormData = _formData;
      _formState = PixFormState.consolidated;
      _clearError();
      notifyListeners();
      return true;
    } on DuplicateEntryException catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteFromHistory(String id) async {
    await _repository.delete(id);
    if (_editingEntryId == id) {
      _editingEntryId = null;
      _consolidatedFormData = null;
      _formState = _formData.isEmpty
          ? PixFormState.clean
          : PixFormState.editing;
    }
    _history = await _repository.getAll();
    notifyListeners();
  }

  PixEntry? _findEditingEntry() {
    if (_editingEntryId == null) return null;
    for (final entry in _history) {
      if (entry.id == _editingEntryId) return entry;
    }
    return null;
  }

  void clearError() => _clearError();

  void _clearError() {
    _errorMessage = null;
  }
}
