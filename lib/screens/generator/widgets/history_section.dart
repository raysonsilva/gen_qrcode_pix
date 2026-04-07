import 'package:flutter/material.dart';
import '../../../models/pix_entry.dart';
import '../../../theme/app_theme.dart';
import 'history_card.dart';

class HistorySection extends StatelessWidget {
  final List<PixEntry> entries;
  final String? editingEntryId;
  final bool isFormEditing;
  final ValueChanged<PixEntry> onSelect;
  final ValueChanged<String> onDelete;

  const HistorySection({
    super.key,
    required this.entries,
    required this.editingEntryId,
    required this.isFormEditing,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Histórico',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withAlpha(70)),
                ),
                child: Text(
                  '${entries.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Lista
        Column(
          children: [
            for (int i = 0; i < entries.length; i++) ...[
              HistoryCard(
                entry: entries[i],
                isBeingEdited: isFormEditing && editingEntryId == entries[i].id,
                onTap: () => onSelect(entries[i]),
                onDelete: () => onDelete(entries[i].id),
              ),
              if (i < entries.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ],
    );
  }
}
