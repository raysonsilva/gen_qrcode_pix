import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'pix_logic.dart';

void main() {
  runApp(const PixApp());
}

class PixApp extends StatelessWidget {
  const PixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerador de PIX',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF32BCAD),
          primary: const Color(0xFF32BCAD),
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
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
    _keyController.addListener(_updatePayload);
    _nameController.addListener(_updatePayload);
    _cityController.addListener(_updatePayload);
    _amountController.addListener(_updatePayload);
    _descController.addListener(_updatePayload);
    _txidController.addListener(_updatePayload);
  }

  void _updatePayload() {
    if (_keyController.text.isEmpty || _nameController.text.isEmpty || _cityController.text.isEmpty) {
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
      setState(() {
        _history = List<Map<String, dynamic>>.from(json.decode(historyJson));
      });
    }
  }

  Future<void> _saveToHistory() async {
    if (_payload.isEmpty) return;

    final newItem = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _nameController.text,
      'city': _cityController.text,
      'key': _keyController.text,
      'amount': _amountController.text,
      'payload': _payload,
      'date': DateTime.now().toIso8601String(),
    };

    setState(() {
      _history.insert(0, newItem);
      if (_history.length > 50) _history.removeLast();
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pix_history', json.encode(_history));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Salvo no histórico!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerador de PIX', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFormCard(),
            const SizedBox(height: 20),
            if (_payload.isNotEmpty) _buildQrCard(),
            const SizedBox(height: 20),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildField('Chave PIX *', _keyController, LucideIcons.key),
            _buildField('Nome do Recebedor *', _nameController, LucideIcons.user),
            _buildField('Cidade *', _cityController, LucideIcons.mapPin),
            _buildField('Valor (Opcional)', _amountController, LucideIcons.dollarSign, keyboardType: TextInputType.number),
            _buildField('Descrição (Opcional)', _descController, LucideIcons.fileText),
            _buildField('ID Transação (Opcional)', _txidController, LucideIcons.hash),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildQrCard() {
    return Card(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            QrImageView(
              data: _payload,
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _payload));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copiado!')),
                      );
                    },
                    icon: const Icon(LucideIcons.copy),
                    label: const Text('Copiar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF32BCAD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveToHistory,
                    icon: const Icon(LucideIcons.save),
                    label: const Text('Salvar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Histórico', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (_history.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('Nenhum item no histórico'),
          ))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final item = _history[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(item['name']),
                  subtitle: Text(item['amount'].isEmpty ? 'Valor em aberto' : 'R$ ${item['amount']}'),
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.copy, size: 20),
                    onPressed: () => Clipboard.setData(ClipboardData(text: item['payload'])),
                  ),
                  onTap: () {
                    setState(() {
                      _keyController.text = item['key'];
                      _nameController.text = item['name'];
                      _cityController.text = item['city'];
                      _amountController.text = item['amount'];
                    });
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}
