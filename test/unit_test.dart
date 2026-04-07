import 'package:flutter_test/flutter_test.dart';
import 'package:qrpix/controllers/pix_controller.dart';
import 'package:qrpix/models/pix_entry.dart';
import 'package:qrpix/repositories/history_repository.dart';
import 'package:qrpix/services/pix_payload_service.dart';
import 'package:qrpix/services/pix_parser_service.dart';

void main() {
  group('PixPayloadService', () {
    test('generates a valid PIX payload with required fields', () {
      final data = PixFormData(
        key: 'test@email.com',
        receiverName: 'João Silva',
        receiverCity: 'São Paulo',
      );
      final payload = PixPayloadService.generate(data);

      expect(payload, isNotEmpty);
      expect(payload, startsWith('000201'));
      // CRC16 is 4 hex chars after 6304
      expect(payload, matches(r'.*6304[0-9A-F]{4}$'));
    });

    test('includes amount when provided', () {
      final data = PixFormData(
        key: 'test@email.com',
        receiverName: 'Maria',
        receiverCity: 'Rio',
        amount: '42.50',
      );
      final payload = PixPayloadService.generate(data);
      expect(payload, contains('42.50'));
    });

    test('omits amount field when empty', () {
      final data = PixFormData(
        key: 'test@email.com',
        receiverName: 'Maria',
        receiverCity: 'Rio',
      );
      final payload = PixPayloadService.generate(data);
      // Field 54 is the amount field — should not appear
      final withoutCrc = payload.substring(0, payload.length - 8);
      expect(withoutCrc, isNot(contains('5406')));
    });

    test('normalizes accented characters in name and city', () {
      final data = PixFormData(
        key: 'chave',
        receiverName: 'Ângelo',
        receiverCity: 'Brasília',
      );
      final payload = PixPayloadService.generate(data);
      expect(payload, contains('Angelo'));
      expect(payload, contains('Brasilia'));
    });

    test('normalizes accented characters in description', () {
      final data = PixFormData(
        key: 'chave',
        receiverName: 'Nome',
        receiverCity: 'Cidade',
        description: 'Almoço jovens',
      );
      final payload = PixPayloadService.generate(data);
      expect(payload, contains('Almoco jovens'));
      expect(payload, isNot(contains('ç')));
    });

    test('normalizes accented characters in txid', () {
      final data = PixFormData(
        key: 'chave',
        receiverName: 'Nome',
        receiverCity: 'Cidade',
        txid: 'PAGÃOFÉRIAS',
      );
      final payload = PixPayloadService.generate(data);
      expect(payload, isNot(matches(r'[^\x00-\x7F]')));
    });

    test('payload contains only ASCII characters', () {
      final data = PixFormData(
        key: 'bdfe3b44-5b9a-480d-aa10-15fcaba66dc2',
        receiverName: 'IASD Central de Palmas',
        receiverCity: 'Palmas',
        description: 'Almoço jovens',
        txid: 'MINJOVEM042026',
      );
      final payload = PixPayloadService.generate(data);
      for (final ch in payload.runes) {
        expect(
          ch,
          lessThan(128),
          reason: 'Payload contains non-ASCII char: ${String.fromCharCode(ch)}',
        );
      }
    });

    test('generated payload can be round-tripped through parser', () {
      final original = PixFormData(
        key: 'cpf@pix.com',
        receiverName: 'Test User',
        receiverCity: 'Curitiba',
        amount: '10.00',
        description: 'Teste',
        txid: 'PEDIDO001',
      );
      final payload = PixPayloadService.generate(original);
      final parsed = PixParserService.parse(payload);

      expect(parsed, isNotNull);
      expect(parsed!.key, equals(original.key));
      expect(parsed.receiverName, equals(original.receiverName));
      expect(parsed.receiverCity, equals(original.receiverCity));
      expect(parsed.amount, equals(original.amount));
      expect(parsed.description, equals(original.description));
      expect(parsed.txid, equals(original.txid));
    });
  });

  group('PixParserService', () {
    test('returns null for non-PIX payload', () {
      expect(PixParserService.parse('not a pix payload'), isNull);
      expect(PixParserService.parse(''), isNull);
      expect(PixParserService.parse('https://example.com'), isNull);
    });

    test('returns null when MAI is missing', () {
      // Valid-looking TLV but no field 26 (MAI)
      const fakePayload =
          '00020152040000530398658604BR5903Ana6003SAO62070503***6304XXXX';
      final result = PixParserService.parse(fakePayload);
      expect(result, isNull);
    });

    test('parses real-world PIX payload correctly', () {
      // Manually constructed minimal valid PIX payload
      final data = PixFormData(
        key: '11999998888',
        receiverName: 'Fulano',
        receiverCity: 'Manaus',
      );
      final payload = PixPayloadService.generate(data);
      final parsed = PixParserService.parse(payload);

      expect(parsed, isNotNull);
      expect(parsed!.key, '11999998888');
      expect(parsed.receiverName, 'Fulano');
      expect(parsed.receiverCity, 'Manaus');
    });

    test('returns empty txid when payload uses placeholder ***', () {
      final data = PixFormData(
        key: 'k@k.com',
        receiverName: 'K',
        receiverCity: 'K',
        txid: '', // empty → will be stored as ***
      );
      final payload = PixPayloadService.generate(data);
      final parsed = PixParserService.parse(payload);
      expect(parsed!.txid, equals(''));
    });
  });

  group('PixFormData', () {
    test('isValid requires key, name and city', () {
      expect(
        const PixFormData(
          key: 'k',
          receiverName: 'n',
          receiverCity: 'c',
        ).isValid,
        isTrue,
      );
      expect(
        const PixFormData(
          key: '',
          receiverName: 'n',
          receiverCity: 'c',
        ).isValid,
        isFalse,
      );
      expect(
        const PixFormData(
          key: 'k',
          receiverName: '',
          receiverCity: 'c',
        ).isValid,
        isFalse,
      );
      expect(
        const PixFormData(
          key: 'k',
          receiverName: 'n',
          receiverCity: '',
        ).isValid,
        isFalse,
      );
    });

    test('copyWith updates only specified fields', () {
      const original = PixFormData(
        key: 'k',
        receiverName: 'n',
        receiverCity: 'c',
        amount: '5',
      );
      final updated = original.copyWith(amount: '10');
      expect(updated.amount, '10');
      expect(updated.key, 'k');
    });
  });

  group('PixEntry', () {
    test('create generates a non-empty id and sets createdAt', () {
      final entry = PixEntry.create(
        key: 'k',
        receiverName: 'n',
        receiverCity: 'c',
        amount: '',
        description: '',
        txid: '',
        payload: 'payload',
      );
      expect(entry.id, isNotEmpty);
      expect(entry.createdAt, isA<DateTime>());
    });

    test('fromJson/toJson round-trips correctly', () {
      final entry = PixEntry.create(
        key: 'key@test.com',
        receiverName: 'Test',
        receiverCity: 'City',
        amount: '1.00',
        description: 'desc',
        txid: 'TXN01',
        payload: 'somePayload',
      );
      final json = entry.toJson();
      final restored = PixEntry.fromJson(json);

      expect(restored.id, entry.id);
      expect(restored.key, entry.key);
      expect(restored.receiverName, entry.receiverName);
      expect(restored.amount, entry.amount);
      expect(restored.payload, entry.payload);
      expect(restored.createdAt, entry.createdAt);
    });
  });

  group('PixController', () {
    test('starts clean, becomes editing, then consolidated on save', () async {
      final repository = _FakeHistoryRepository();
      final controller = PixController(repository: repository);
      await controller.init();

      expect(controller.formState, PixFormState.clean);
      expect(controller.history, isEmpty);

      controller.updateForm(
        const PixFormData(
          key: 'k@pix.com',
          receiverName: 'Nome',
          receiverCity: 'Cidade',
        ),
      );

      expect(controller.formState, PixFormState.editing);

      final saved = await controller.saveToHistory();
      expect(saved, isTrue);
      expect(controller.formState, PixFormState.consolidated);
      expect(controller.history.length, 1);
      expect(controller.editingEntryId, isNotNull);
    });

    test(
      'editing loaded entry updates same id when essentials unchanged',
      () async {
        final repository = _FakeHistoryRepository();
        final base = PixEntry.create(
          key: 'k@pix.com',
          receiverName: 'Nome',
          receiverCity: 'Cidade',
          amount: '10.00',
          description: 'desc',
          txid: 'TX1',
          payload: 'payload',
        );
        await repository.save(base);

        final controller = PixController(repository: repository);
        await controller.init();
        controller.loadFromEntry(base);

        controller.updateForm(
          const PixFormData(
            key: 'k@pix.com',
            receiverName: 'Nome alterado',
            receiverCity: 'Cidade',
            amount: '10.00',
            description: 'desc alterado',
            txid: 'TX1',
          ),
        );

        expect(controller.formState, PixFormState.editing);

        final saved = await controller.saveToHistory();
        expect(saved, isTrue);
        expect(controller.formState, PixFormState.consolidated);
        expect(controller.history.length, 1);
        expect(controller.history.first.id, base.id);
        expect(controller.history.first.receiverName, 'Nome alterado');
        expect(
          controller.history.first.updatedAt.isAfter(base.updatedAt),
          isTrue,
        );
      },
    );

    test('editing loaded entry creates new when essentials changed', () async {
      final repository = _FakeHistoryRepository();
      final base = PixEntry.create(
        key: 'k@pix.com',
        receiverName: 'Nome',
        receiverCity: 'Cidade',
        amount: '10.00',
        description: 'desc',
        txid: 'TX1',
        payload: 'payload',
      );
      await repository.save(base);

      final controller = PixController(repository: repository);
      await controller.init();
      controller.loadFromEntry(base);

      controller.updateForm(
        const PixFormData(
          key: 'nova@pix.com',
          receiverName: 'Nome',
          receiverCity: 'Cidade',
          amount: '10.00',
          description: 'desc',
          txid: 'TX1',
        ),
      );

      final saved = await controller.saveToHistory();
      expect(saved, isTrue);
      expect(controller.formState, PixFormState.consolidated);
      expect(controller.history.length, 2);
      expect(controller.history.any((e) => e.id == base.id), isTrue);
      expect(controller.editingEntryId, isNot(base.id));
    });
  });
}

class _FakeHistoryRepository implements HistoryRepository {
  final List<PixEntry> _entries = [];

  @override
  Future<List<PixEntry>> getAll() async => List<PixEntry>.from(_entries);

  @override
  Future<void> save(PixEntry entry) async {
    _entries.insert(0, entry);
  }

  @override
  Future<void> update(PixEntry entry) async {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) throw StateError('Entry not found');
    _entries[index] = entry;
  }

  @override
  Future<void> delete(String id) async {
    _entries.removeWhere((e) => e.id == id);
  }
}
