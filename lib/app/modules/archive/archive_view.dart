import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../data/models/note_model.dart';
import '../../routes/app_pages.dart';
import '../../widgets/glass_widgets.dart';
import '../note/note_controller.dart';
import '../../theme/app_theme.dart';

class ArchiveView extends GetView<NoteController> {
  const ArchiveView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark 
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent) 
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: false,
        body: RefreshIndicator(
          onRefresh: () => controller.fetchNotes(),
          color: theme.primaryColor,
          backgroundColor: theme.scaffoldBackgroundColor,
          edgeOffset: 140,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                pinned: true,
                expandedHeight: 140.0,
                elevation: 0,
                automaticallyImplyLeading: false,
                centerTitle: true,
                title: LayoutBuilder(
                  builder: (context, constraints) {
                    final double percentage = (constraints.maxHeight - kToolbarHeight) / (140.0 - kToolbarHeight);
                    final opacity = (1.0 - percentage).clamp(0.0, 1.0);
                    
                    return Opacity(
                      opacity: opacity > 0.8 ? 1.0 : 0.0,
                      child: Text(
                        "Archive",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                      ),
                    );
                  },
                ),
                leading: Center(
                  child: LiquidGlassContainer(
                    width: 44,
                    height: 44,
                    borderRadius: 22,
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(CupertinoIcons.chevron_left, color: AppTheme.textSecondary, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
                leadingWidth: 70,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
                  title: LayoutBuilder(
                    builder: (context, constraints) {
                      final double percentage = (constraints.maxHeight - kToolbarHeight) / (140.0 - kToolbarHeight);
                      return Opacity(
                        opacity: percentage.clamp(0.0, 1.0),
                        child: Text(
                          "Archive",
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 34,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              Obx(() {
                if (controller.isLoading.value) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppTheme.folderYellow)),
                  );
                }
                
                if (controller.hasError.value) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off_rounded, size: 64, color: AppTheme.textSecondary),
                          const SizedBox(height: 16),
                          Text(controller.errorMessage.value, style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => controller.fetchNotes(),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.folderYellow),
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (controller.archivedNotes.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text("No Archived Notes")),
                  );
                }

                final groupedNotes = _groupNotesByDate(controller.archivedNotes);

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final section = groupedNotes.keys.elementAt(index);
                    final sectionNotes = groupedNotes[section]!;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 8),
                            child: Text(section, style: theme.textTheme.titleLarge),
                          ),
                          GlassCard(
                            borderRadius: 20,
                            padding: EdgeInsets.zero,
                            children: [
                              for (int i = 0; i < sectionNotes.length; i++) ...[
                                _buildNoteTile(context, sectionNotes[i]),
                                if (i < sectionNotes.length - 1)
                                  const Divider(indent: 56, height: 1),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  }, childCount: groupedNotes.length),
                );
              }),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteTile(BuildContext context, NoteModel note) {
    final theme = Theme.of(context);
    final attachment = note.content.firstWhereOrNull((b) => b is AttachmentBlock) as AttachmentBlock?;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () {
        Get.toNamed(Routes.NOTE_DETAIL, arguments: {
          "noteId": note.id,
          "folderId": note.folderId,
        })?.then((value) {
          if (value == true) controller.fetchNotes();
        });
      },
      leading: note.isPinned 
          ? const Icon(Icons.push_pin, color: AppTheme.folderYellow, size: 16) 
          : null,
      title: Text(
        note.displayTitle,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          "${_formatTime(note.updatedAt)}  ${_getContentSnippet(note)}",
          style: theme.textTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: attachment != null
          ? Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: attachment.url != null 
                    ? NetworkImage(attachment.url!) 
                    : const AssetImage('assets/images/placeholder.png') as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            )
          : Icon(Icons.chevron_right, color: theme.colorScheme.outline, size: 20),
    );
  }

  Map<String, List<NoteModel>> _groupNotesByDate(List<NoteModel> notes) {
    Map<String, List<NoteModel>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sevenDaysAgo = today.subtract(const Duration(days: 7));

    for (var note in notes) {
      final date = note.updatedAt ?? now;
      final noteDate = DateTime(date.year, date.month, date.day);
      
      String key;
      if (noteDate == today) {
        key = "Today";
      } else if (noteDate == yesterday) {
        key = "Yesterday";
      } else if (noteDate.isAfter(sevenDaysAgo)) {
        key = "Previous 7 Days";
      } else {
        key = DateFormat('MMMM').format(date);
      }

      if (!groups.containsKey(key)) groups[key] = [];
      groups[key]!.add(note);
    }
    return groups;
  }

  String _formatTime(DateTime? date) {
    if (date == null) return "";
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('EEEE').format(date); 
  }

  String _getContentSnippet(NoteModel note) {
    if (note.content.isEmpty) {
      if (note.attachmentCount > 0) {
        return "${note.attachmentCount} attachment${note.attachmentCount > 1 ? 's' : ''}";
      }
      return "No additional text";
    }
    final firstBlock = note.content.firstWhereOrNull((b) => b is TextBlock) as TextBlock?;
    if (firstBlock != null) return firstBlock.text;
    return "Attachment/Checklist";
  }
}
