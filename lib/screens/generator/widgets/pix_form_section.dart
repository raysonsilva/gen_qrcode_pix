import 'package:flutter/material.dart';
import '../../../models/pix_entry.dart';
import '../../../theme/app_theme.dart';

class PixFormSection extends StatefulWidget {
  final PixFormData initialData;
  final PixFormState formState;
  final ValueChanged<PixFormData> onChanged;

  const PixFormSection({
    super.key,
    required this.initialData,
    required this.formState,
    required this.onChanged,
  });

  @override
  State<PixFormSection> createState() => _PixFormSectionState();
}

class _PixFormSectionState extends State<PixFormSection> {
  late final TextEditingController _keyCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _txidCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _keyCtrl = TextEditingController(text: d.key);
    _nameCtrl = TextEditingController(text: d.receiverName);
    _cityCtrl = TextEditingController(text: d.receiverCity);
    _amountCtrl = TextEditingController(text: d.amount);
    _descCtrl = TextEditingController(text: d.description);
    _txidCtrl = TextEditingController(text: d.txid);

    for (final c in _all) c.addListener(_notify);
  }

  @override
  void didUpdateWidget(covariant PixFormSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final d = widget.initialData;
    for (final c in _all) c.removeListener(_notify);
    if (d.key != _keyCtrl.text) _keyCtrl.text = d.key;
    if (d.receiverName != _nameCtrl.text) _nameCtrl.text = d.receiverName;
    if (d.receiverCity != _cityCtrl.text) _cityCtrl.text = d.receiverCity;
    if (d.amount != _amountCtrl.text) _amountCtrl.text = d.amount;
    if (d.description != _descCtrl.text) _descCtrl.text = d.description;
    if (d.txid != _txidCtrl.text) _txidCtrl.text = d.txid;
    for (final c in _all) c.addListener(_notify);
  }

  List<TextEditingController> get _all => [
    _keyCtrl,
    _nameCtrl,
    _cityCtrl,
    _amountCtrl,
    _descCtrl,
    _txidCtrl,
  ];

  @override
  void dispose() {
    for (final c in _all) c.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(
      PixFormData(
        key: _keyCtrl.text,
        receiverName: _nameCtrl.text,
        receiverCity: _cityCtrl.text,
        amount: _amountCtrl.text,
        description: _descCtrl.text,
        txid: _txidCtrl.text,
      ),
    );
  }

  String? get _txidError {
    final txid = _txidCtrl.text;
    if (txid.isEmpty) return null;
    if (!RegExp(r'^[a-zA-Z0-9]{1,25}$').hasMatch(txid)) {
      return 'Use apenas letras e números, sem espaços (máx. 25 caracteres)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: widget.formState == PixFormState.editing
              ? AppColors.primary.withAlpha(140)
              : cs.outline,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.formState == PixFormState.editing) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.primary.withAlpha(80)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Em edição',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          _SectionLabel(
            icon: Icons.person_outline_rounded,
            text: 'Dados do recebedor',
          ),
          const SizedBox(height: 16),
          _Field(
            label: 'Chave PIX *',
            hint: 'CPF, CNPJ, e-mail, telefone ou aleatória',
            controller: _keyCtrl,
            icon: Icons.key_rounded,
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'Nome do recebedor *',
            hint: 'Ex: João Silva',
            controller: _nameCtrl,
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'Cidade *',
            hint: 'Ex: São Paulo',
            controller: _cityCtrl,
            icon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 20),
          _SectionLabel(icon: Icons.tune_rounded, text: 'Dados opcionais'),
          const SizedBox(height: 16),
          _Field(
            label: 'Valor (R\$)',
            hint: '0,00',
            controller: _amountCtrl,
            icon: Icons.attach_money_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'Descrição',
            hint: 'Ex: Pagamento do almoço',
            controller: _descCtrl,
            icon: Icons.description_rounded,
            maxLength: 50,
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'ID da transação',
            hint: 'Ex: PEDIDO123',
            controller: _txidCtrl,
            icon: Icons.tag_rounded,
            maxLength: 25,
            errorText: _txidError,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final int? maxLength;
  final String? errorText;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.maxLength,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: TextStyle(color: cs.onSurface, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        counterText: '',
        errorText: errorText,
      ),
    );
  }
}
