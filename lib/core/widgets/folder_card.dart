import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import '../../data/models/folder_model.dart';
import 'liquid_glass_container.dart';

class FolderCard extends StatefulWidget {
  final FolderModel folder;
  final VoidCallback onTap;
  final bool isGrid;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onTap,
    this.isGrid = true,
    this.onEdit,
    this.onDelete,
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
  State<FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<FolderCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = FolderCard.getFolderColor(widget.folder.colorValue);
    final icon = FolderCard.getFolderIcon(widget.folder.iconName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _isPressed ? 0.96 : 1.0,
        child: widget.isGrid ? _buildGridCard(color, icon, isDark) : _buildListCard(color, icon, isDark),
      ),
    );
  }

  Widget _buildListCard(Color color, IconData icon, bool isDark) {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
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
                  widget.folder.name, 
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${widget.folder.noteCount ?? 0} notes', 
                  style: TextStyle(color: isDark ? Colors.white38 : AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, fontWeight: FontWeight.bold, color: isDark ? Colors.white24 : AppColors.textPlaceholder),
          if (widget.onEdit != null || widget.onDelete != null)
            _buildPopupMenu(isDark),
        ],
      ),
    );
  }

  Widget _buildGridCard(Color color, IconData icon, bool isDark) {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          if (widget.onEdit != null || widget.onDelete != null)
            Positioned(
              top: -8,
              right: -8,
              child: _buildPopupMenu(isDark),
            ),
          Center(
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
                Text(
                  widget.folder.name, 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ), 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.folder.noteCount ?? 0} Notes', 
                  style: TextStyle(
                    fontSize: 13, 
                    color: isDark ? Colors.white38 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(bool isDark) {
    return GestureDetector(
      onTapDown: (details) {
        _showGlassMenu(context, details.globalPosition, isDark);
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          Icons.more_vert_rounded,
          size: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white38 : AppColors.textPlaceholder,
        ),
      ),
    );
  }
  void _showGlassMenu(BuildContext context, Offset position, bool isDark) {
    final RenderBox _ = Overlay.of(context).context.findRenderObject() as RenderBox;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              left: position.dx - 120, // Adjust based on menu width
              top: position.dy,
              child: FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: animation,
                  alignment: Alignment.topRight,
                  child: Material(
                    color: Colors.transparent,
                    child: LiquidGlassContainer(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      borderRadius: BorderRadius.circular(16),
                      opacity: 0.8,
                      blur: 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMenuItem(
                            icon: Icons.edit_rounded,
                            label: 'Edit',
                            onTap: () {
                              Navigator.pop(context);
                              widget.onEdit?.call();
                            },
                            isDark: isDark,
                          ),
                          _buildMenuItem(
                            icon: Icons.delete_rounded,
                            label: 'Delete',
                            isDelete: true,
                            onTap: () {
                              Navigator.pop(context);
                              widget.onDelete?.call();
                            },
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isDelete = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDelete ? Colors.redAccent : (isDark ? Colors.white70 : AppColors.textPrimary),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDelete ? Colors.redAccent : (isDark ? Colors.white70 : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
