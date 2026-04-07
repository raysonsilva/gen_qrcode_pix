import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/pix_entry.dart';
import '../../../theme/app_theme.dart';

class HistoryCard extends StatelessWidget {
  final PixEntry entry;
  final bool isBeingEdited;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const HistoryCard({
    super.key,
    required this.entry,
    this.isBeingEdited = false,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(entry.createdAt);
    final hasAmount =
        entry.amount.isNotEmpty &&
        entry.amount != '0' &&
        entry.amount != '0.00';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: isBeingEdited ? AppColors.primary : cs.outline,
            width: isBeingEdited ? 1.6 : 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(60)),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.receiverName,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.key,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isBeingEdited) ...[
                        const _Chip(
                          label: 'Em edição',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (hasAmount) ...[
                        _Chip(
                          label: 'R\$ ${entry.amount}',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: cs.onSurfaceVariant.withAlpha(160),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant.withAlpha(160),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Botão deletar
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: cs.error.withAlpha(180),
              ),
              tooltip: 'Remover',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_outline_rounded, color: cs.error),
        title: const Text('Remover entrada'),
        content: Text('Deseja remover "${entry.receiverName}" do histórico?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) onDelete();
    });
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
