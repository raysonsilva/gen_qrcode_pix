import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'pix_logic.dart';
import 'pix_parser.dart';
import 'qr_scanner_screen.dart';

void main() {
  runApp(const PixApp());
}

class PixApp extends StatelessWidget {
  const PixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerador de PIX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF32BCAD),
        useMaterial3: true,
      ),
      home: const PixGeneratorScreen(),
    );
  }
}

class PixGeneratorScreen extends StatefulWidget {
  const PixGeneratorScreen({super.key});

  @override
  State<PixGeneratorScreen> createState() => _PixGeneratorScreenState();
}

class _PixGeneratorScreenState extends State<PixGeneratorScreen> {
  final _scrollController = ScrollController();
  final _qrKey = GlobalKey();
  final _keyController = TextEditingController();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _txidController = TextEditingController();

  String _payload = '';
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    for (final c in [
      _keyController,
      _nameController,
      _cityController,
      _amountController,
      _descController,
      _txidController,
    ]) {
      c.addListener(_updatePayload);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final c in [
      _keyController,
      _nameController,
      _cityController,
      _amountController,
      _descController,
      _txidController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _updatePayload() {
    if (_keyController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _cityController.text.isEmpty) {
      setState(() => _payload = '');
      return;
    }

    final data = PixData(
      key: _keyController.text,
      receiverName: _nameController.text,
      receiverCity: _cityController.text,
      amount: _amountController.text,
      description: _descController.text,
      txid: _txidController.text,
    );

    setState(() {
      _payload = PixUtils.generatePayload(data);
    });
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('pix_history');
    if (historyJson != null) {
      try {
        setState(() {
          _history = List<Map<String, dynamic>>.from(json.decode(historyJson));
        });
      } catch (_) {}
    }
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pix_history', json.encode(_history));
  }

  Future<void> _saveToHistory() async {
    if (_payload.isEmpty) return;

    final key = _keyController.text;
    final amount = _amountController.text;
    final txid = _txidController.text;

    final alreadyExists = _history.any(
      (item) =>
          item['key'] == key &&
          item['amount'] == amount &&
          item['txid'] == txid,
    );

    if (alreadyExists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Já existe no histórico com os mesmos dados.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newItem = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'key': key,
      'name': _nameController.text,
      'city': _cityController.text,
      'amount': amount,
      'description': _descController.text,
      'txid': txid,
      'payload': _payload,
      'date': DateTime.now().toIso8601String(),
    };

    setState(() {
      _history.insert(0, newItem);
      if (_history.length > 50) _history.removeLast();
    });

    await _persistHistory();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Salvo no histórico!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _loadFromHistory(Map<String, dynamic> item) {
    _keyController.text = item['key'] ?? '';
    _nameController.text = item['name'] ?? '';
    _cityController.text = item['city'] ?? '';
    _amountController.text = item['amount'] ?? '';
    _descController.text = item['description'] ?? '';
    _txidController.text = item['txid'] ?? '';
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  Future<void> _deleteFromHistory(String id) async {
    setState(() {
      _history.removeWhere((item) => item['id'] == id);
    });
    await _persistHistory();
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _openScanner() async {
    final result = await Navigator.of(context).push<PixParsedData>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result == null) return;

    _keyController.text = result.key;
    _nameController.text = result.receiverName;
    _cityController.text = result.receiverCity;
    _amountController.text = result.amount;
    _descController.text = result.description;
    _txidController.text = result.txid;

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dados PIX preenchidos com sucesso!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareQrCode() async {
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/qrcode_pix.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'QR Code PIX'),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao compartilhar o QR Code.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerador de PIX'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.scanLine),
            tooltip: 'Ler QR Code PIX',
            onPressed: _openScanner,
          ),
          IconButton(
            icon: const Icon(LucideIcons.history),
            tooltip: 'Histórico',
            onPressed: () => _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFormSection(),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _payload.isNotEmpty
                  ? _buildQrSection()
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            _buildHistorySection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dados do recebedor',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Chave PIX',
              hint: 'CPF, CNPJ, e-mail, telefone ou aleatória',
              controller: _keyController,
              icon: LucideIcons.key,
              required: true,
            ),
            const SizedBox(height: 12),
            _buildField(
              label: 'Nome do recebedor',
              hint: 'Ex: João Silva',
              controller: _nameController,
              icon: LucideIcons.user,
              required: true,
            ),
            const SizedBox(height: 12),
            _buildField(
              label: 'Cidade',
              hint: 'Ex: São Paulo',
              controller: _cityController,
              icon: LucideIcons.mapPin,
              required: true,
            ),
            const Divider(height: 28),
            Text(
              'Dados opcionais',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Valor (R\$)',
              hint: '0,00',
              controller: _amountController,
              icon: LucideIcons.banknote,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            _buildField(
              label: 'Descrição',
              hint: 'Ex: Pagamento do almoço',
              controller: _descController,
              icon: LucideIcons.fileText,
              maxLength: 50,
            ),
            const SizedBox(height: 12),
            _buildField(
              label: 'ID da transação',
              hint: 'Ex: PEDIDO123',
              controller: _txidController,
              icon: LucideIcons.hash,
              maxLength: 25,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        counterText: '',
      ),
    );
  }

  Widget _buildQrSection() {
    return Card(
      key: const ValueKey('qr-card'),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'QR Code gerado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: RepaintBoundary(
                key: _qrKey,
                child: QrImageView(
                  data: _payload,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aponte a câmera do app do banco para escanear',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer.withAlpha(180),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        _copyToClipboard(_payload, 'Código PIX copiado!'),
                    icon: const Icon(LucideIcons.copy, size: 18),
                    label: const Text(
                      'Copia e Cola',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _shareQrCode,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.share2, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'QR Code',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: _saveToHistory,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.bookmark, size: 18),
                    SizedBox(width: 8),
                    Text('Salvar no histórico'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Histórico', style: Theme.of(context).textTheme.titleLarge),
            if (_history.isNotEmpty) ...[
              const SizedBox(width: 8),
              Badge(label: Text('${_history.length}')),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (_history.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.inbox,
                      size: 40,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhum QR Code salvo ainda',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) => _buildHistoryCard(_history[index]),
          ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final amount = item['amount'] as String? ?? '';
    final key = item['key'] as String? ?? '';
    final txid = item['txid'] as String? ?? '';
    final dateStr = item['date'] as String?;

    String dateLine = '';
    if (dateStr != null) {
      try {
        final date = DateTime.parse(dateStr);
        dateLine = DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
      } catch (_) {}
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(
            LucideIcons.user,
            size: 20,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(item['name'] ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (key.isNotEmpty)
              Text(
                key,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            if (txid.isNotEmpty)
              Text(
                txid,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            Text(
              amount.isEmpty ? 'Valor aberto' : 'R\$ $amount',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (dateLine.isNotEmpty)
              Text(
                dateLine,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          icon: const Icon(LucideIcons.moreVertical),
          onSelected: (value) {
            switch (value) {
              case 'copy':
                _copyToClipboard(item['payload'] ?? '', 'Código PIX copiado!');
              case 'edit':
                _loadFromHistory(item);
              case 'delete':
                _deleteFromHistory(item['id'] ?? '');
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'copy',
              child: ListTile(
                leading: Icon(LucideIcons.copy),
                title: Text('Copiar código'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(LucideIcons.pencil),
                title: Text('Editar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(LucideIcons.trash2),
                title: Text('Excluir'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
