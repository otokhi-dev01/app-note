import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/colors.dart';
import '../../data/models/note_model.dart';
import '../../data/models/content_block_model.dart';
import 'liquid_glass_container.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final bool isPinned;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.isPinned = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPinned) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
          width: 240,
          height: 170,
          child: LiquidGlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        note.folderName ?? 'General',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Icon(Icons.push_pin, size: 18, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  note.content?.firstWhere((b) => b.type == 'text', orElse: () => ContentBlockModel(id: '', type: 'text', text: '')).text ?? 'No content',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textPlaceholder),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('MMM dd, yyyy').format(note.createdAt ?? DateTime.now()),
                      style: const TextStyle(fontSize: 11, color: AppColors.textPlaceholder),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: LiquidGlassContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      note.content?.firstWhere((b) => b.type == 'text', orElse: () => ContentBlockModel(id: '', type: 'text', text: '')).text ?? 'No description available', 
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('h a').format(note.updatedAt ?? DateTime.now()),
                style: const TextStyle(fontSize: 12, color: AppColors.textPlaceholder, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
