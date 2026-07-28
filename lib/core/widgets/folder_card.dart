import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import '../../data/models/folder_model.dart';
import 'liquid_glass_container.dart';

class FolderCard extends StatelessWidget {
  final FolderModel folder;
  final VoidCallback onTap;
  final bool isGrid;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onTap,
    this.isGrid = true,
  });

  static IconData getFolderIcon(String? name) {
    if (name == null) return Icons.folder;
    switch (name.toLowerCase()) {
      case '0':
      case 'folder': return Icons.folder;
      case '1':
      case 'work': return Icons.work_outline;
      case '2':
      case 'home': return Icons.home_outlined;
      case '3':
      case 'lightbulb': return Icons.lightbulb_outline;
      case '4':
      case 'favorite': return Icons.favorite_border;
      case '5':
      case 'school': return Icons.school_outlined;
      default: return Icons.folder_outlined;
    }
  }

  static Color getFolderColor(String? value) {
    if (value == null) return AppColors.primary;
    if (value.startsWith('#')) {
      return Color(int.parse(value.replaceFirst('#', '0xFF')));
    }
    // Handle index-based strings or raw ARGB values
    final int? colorInt = int.tryParse(value);
    if (colorInt != null) {
      if (colorInt < AppColors.folderColors.length) {
        return AppColors.folderColors[colorInt];
      }
      return Color(colorInt);
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = getFolderColor(folder.colorValue);
    final icon = getFolderIcon(folder.iconName);

    if (!isGrid) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: LiquidGlassContainer(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.name, 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('${folder.noteCount ?? 0} notes', style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textPlaceholder),
              ],
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(folder.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('${folder.noteCount ?? 0} Notes', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
