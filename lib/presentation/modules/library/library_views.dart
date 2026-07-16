import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:notes/app/routes/app_routes.dart';
import 'package:notes/app/theme/colors.dart';
import 'package:notes/core/utils/image_helper.dart';
import 'package:notes/domain/entities/note.dart';
import 'package:notes/presentation/modules/home/home_controller.dart';

class MediaGalleryView extends GetView<HomeController> {
  const MediaGalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    return _LibraryScaffold(
      title: 'Attachments',
      child: Obx(() {
        final media = <({String path, Note note})>[
          for (final note in controller.notes)
            for (final path in note.imagePaths) (path: path, note: note),
        ];
        return RefreshIndicator(
          onRefresh: controller.loadNotes,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _FeatureIntro(
                  title: 'Media Gallery',
                  subtitle: '${media.length} attachments across your notes',
                  icon: CupertinoIcons.photo_on_rectangle,
                ),
              ),
              if (media.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _FeatureEmpty(
                    message: 'Photos, scans, and drawings will appear here.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: .78,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = media[index];
                      return Material(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          onTap: () => controller.openNote(item.note),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            decoration: _libraryCardDecoration(context),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ImageHelper.buildSafeImage(
                                    item.path,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.note.title.isEmpty
                                            ? 'Untitled'
                                            : item.note.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat.MMMd().format(
                                          item.note.updatedAt,
                                        ),
                                        style: const TextStyle(
                                          color: AppColors.subtitle,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: media.length),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class TagsManagerView extends GetView<HomeController> {
  const TagsManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    return _LibraryScaffold(
      title: 'Tags',
      action: TextButton(
        onPressed: controller.openCreateNote,
        child: const Text('New Note'),
      ),
      child: Obx(() {
        final tags = _tagCounts(controller.notes);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
          children: [
            const _FeatureIntro(
              title: 'Tags Manager',
              subtitle: 'Browse tags extracted from your saved notes',
              icon: CupertinoIcons.tag,
              compact: true,
            ),
            const SizedBox(height: 18),
            if (tags.isEmpty)
              const _FeatureEmpty(
                message: 'Type #work or another tag in a note to add it here.',
              )
            else
              _LibrarySurface(
                child: Column(
                  children: tags.entries.toList().asMap().entries.map((entry) {
                    final tag = entry.value;
                    return Column(
                      children: [
                        ListTile(
                          onTap: () {
                            Get.back<void>();
                            controller.selectTab(2);
                            controller.search(tag.key);
                          },
                          leading: const Icon(
                            CupertinoIcons.tag,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            tag.key,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${tag.value}',
                                style: const TextStyle(
                                  color: AppColors.subtitle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                CupertinoIcons.chevron_right,
                                size: 15,
                              ),
                            ],
                          ),
                        ),
                        if (entry.key != tags.length - 1)
                          const Divider(height: 1, indent: 56),
                      ],
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 22),
            Text(
              '${tags.length} tags · ${controller.notes.length} notes total',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.subtitle),
            ),
          ],
        );
      }),
    );
  }
}

class NoteCalendarView extends GetView<HomeController> {
  const NoteCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leadingDays = monthStart.weekday % 7;
    return _LibraryScaffold(
      title: 'Calendar',
      child: Obx(() {
        final selectedDay = controller.selectedCalendarDay.value.clamp(
          1,
          daysInMonth,
        );
        final selectedDate = DateTime(now.year, now.month, selectedDay);
        final selectedNotes = controller.notes
            .where((note) => DateUtils.isSameDay(note.updatedAt, selectedDate))
            .toList();
        final activeDays = controller.notes
            .where(
              (note) =>
                  note.updatedAt.year == now.year &&
                  note.updatedAt.month == now.month,
            )
            .map((note) => note.updatedAt.day)
            .toSet();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
          children: [
            Text(
              DateFormat.yMMMM().format(now),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _libraryCardDecoration(context),
              child: Column(
                children: [
                  const Row(
                    children: [
                      _WeekLabel('S'),
                      _WeekLabel('M'),
                      _WeekLabel('T'),
                      _WeekLabel('W'),
                      _WeekLabel('T'),
                      _WeekLabel('F'),
                      _WeekLabel('S'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 5,
                          crossAxisSpacing: 3,
                        ),
                    itemCount: leadingDays + daysInMonth,
                    itemBuilder: (context, index) {
                      if (index < leadingDays) return const SizedBox.shrink();
                      final day = index - leadingDays + 1;
                      final selected = day == selectedDay;
                      final active = activeDays.contains(day);
                      return InkWell(
                        onTap: () => controller.selectedCalendarDay.value = day,
                        borderRadius: BorderRadius.circular(30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  color: selected ? Colors.white : null,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.primary
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Text(
                  DateUtils.isSameDay(selectedDate, now)
                      ? "Today's Notes"
                      : DateFormat.MMMEd().format(selectedDate),
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '${selectedNotes.length}',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (selectedNotes.isEmpty)
              const _FeatureEmpty(message: 'No notes were edited on this date.')
            else
              _LibrarySurface(
                child: Column(
                  children: selectedNotes.asMap().entries.map((entry) {
                    final note = entry.value;
                    return Column(
                      children: [
                        ListTile(
                          onTap: () => controller.openNote(note),
                          leading: const Icon(
                            CupertinoIcons.doc_text,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            note.title.isEmpty ? 'Untitled' : note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            note.content.isEmpty
                                ? 'No additional text'
                                : note.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (entry.key != selectedNotes.length - 1)
                          const Divider(height: 1, indent: 56),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class SmartCategoriesView extends GetView<HomeController> {
  const SmartCategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    const categories = [
      _CategoryDefinition('Receipts', CupertinoIcons.doc_text_search, [
        'receipt',
        'invoice',
        'total',
        'purchase',
      ]),
      _CategoryDefinition('Travel', CupertinoIcons.airplane, [
        'travel',
        'trip',
        'flight',
        'hotel',
      ]),
      _CategoryDefinition('Work', CupertinoIcons.briefcase, [
        'work',
        'project',
        'meeting',
        'client',
      ]),
      _CategoryDefinition('Personal', CupertinoIcons.person, [
        'personal',
        'home',
        'family',
        'journal',
      ]),
    ];
    return _LibraryScaffold(
      title: 'Smart Categories',
      child: Obx(() {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
          children: [
            const _FeatureIntro(
              title: 'Smart Categories',
              subtitle: 'Automatically grouped from your note text',
              icon: CupertinoIcons.sparkles,
              compact: true,
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                final count = controller.notes.where((note) {
                  final value = '${note.title} ${note.content}'.toLowerCase();
                  return category.patterns.any(value.contains);
                }).length;
                return Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () {
                      Get.back<void>();
                      controller.searchCategory(category.title);
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: _libraryCardDecoration(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FeatureIcon(category.icon),
                          const Spacer(),
                          Text(
                            category.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '$count notes',
                            style: const TextStyle(color: AppColors.subtitle),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      }),
    );
  }
}

class StorageManagementView extends GetView<HomeController> {
  const StorageManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return _LibraryScaffold(
      title: 'Storage',
      child: Obx(() {
        final notes = controller.notes.toList(growable: false);
        final attachmentCount = notes.fold<int>(
          0,
          (sum, note) => sum + note.imagePaths.length,
        );
        return FutureBuilder<int>(
          future: _attachmentBytes(notes),
          builder: (context, snapshot) {
            final bytes = snapshot.data ?? 0;
            final megabytes = bytes / 1048576;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: _libraryCardDecoration(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('STORAGE USAGE', style: _featureEyebrow),
                      const SizedBox(height: 10),
                      Text(
                        '${megabytes.toStringAsFixed(1)} MB',
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Local note attachments',
                        style: TextStyle(color: AppColors.subtitle),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (megabytes / 1024).clamp(0, 1),
                          minHeight: 12,
                          color: AppColors.primary,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _LibrarySurface(
                  child: Column(
                    children: [
                      _StorageRow(
                        icon: CupertinoIcons.doc_text,
                        title: 'Notes',
                        value: '${notes.length} items',
                        onTap: () {
                          Get.back<void>();
                          controller.selectTab(0);
                        },
                      ),
                      _StorageRow(
                        icon: CupertinoIcons.photo,
                        title: 'Attachments',
                        value: '$attachmentCount files',
                        onTap: () => Get.toNamed(AppRoutes.media),
                      ),
                      _StorageRow(
                        icon: CupertinoIcons.trash,
                        title: 'Recently Deleted',
                        value: '${controller.trashNotes.length} items',
                        onTap: () {
                          Get.back<void>();
                          controller.showTrash();
                        },
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text('RECOMMENDATION', style: _featureEyebrow),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _libraryCardDecoration(context),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FeatureIcon(CupertinoIcons.cloud_download),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Keep important files backed up',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Notes currently stay on this device and are scoped to your authenticated account.',
                              style: TextStyle(
                                color: AppColors.subtitle,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}

class NoteHistoryView extends GetView<HomeController> {
  const NoteHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return _LibraryScaffold(
      title: 'Recent Activity',
      child: Obx(() {
        final notes = [...controller.notes]
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
          children: [
            const _FeatureIntro(
              title: 'Note History',
              subtitle: 'Recent saved updates from your note repository',
              icon: CupertinoIcons.time,
              compact: true,
            ),
            const SizedBox(height: 20),
            if (notes.isEmpty)
              const _FeatureEmpty(
                message: 'Your recent note activity will appear here.',
              )
            else
              ..._groupByDay(notes).entries.map((group) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 16, 4, 9),
                      child: Text(
                        group.key.toUpperCase(),
                        style: _featureEyebrow,
                      ),
                    ),
                    _LibrarySurface(
                      child: Column(
                        children: group.value.asMap().entries.map((entry) {
                          final note = entry.value;
                          return Column(
                            children: [
                              ListTile(
                                onTap: () => controller.openNote(note),
                                leading: const _FeatureIcon(
                                  CupertinoIcons.doc_text,
                                ),
                                title: Text(
                                  note.title.isEmpty ? 'Untitled' : note.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  'Updated at ${DateFormat.jm().format(note.updatedAt)}',
                                ),
                                trailing: const Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 15,
                                ),
                              ),
                              if (entry.key != group.value.length - 1)
                                const Divider(height: 1, indent: 70),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              }),
            const SizedBox(height: 24),
            const Text(
              'Full version snapshots require a server or database history contract. This timeline shows actual saved note updates.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.subtitle, height: 1.4),
            ),
          ],
        );
      }),
    );
  }
}

class _LibraryScaffold extends StatelessWidget {
  const _LibraryScaffold({
    required this.title,
    required this.child,
    this.action,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(
            CupertinoIcons.chevron_left,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: [?action],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: child,
    );
  }
}

class _LibrarySurface extends StatelessWidget {
  const _LibrarySurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: child,
      ),
    );
  }
}

class _FeatureIntro extends StatelessWidget {
  const _FeatureIntro({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          _FeatureIcon(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.subtitle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  const _FeatureIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFF3EACB),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primary, size: 23),
    );
  }
}

class _FeatureEmpty extends StatelessWidget {
  const _FeatureEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.subtitle,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _WeekLabel extends StatelessWidget {
  const _WeekLabel(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.subtitle),
      ),
    );
  }
}

class _StorageRow extends StatelessWidget {
  const _StorageRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: _FeatureIcon(icon),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(value),
          trailing: const Icon(CupertinoIcons.chevron_right, size: 15),
        ),
        if (!isLast) const Divider(height: 1, indent: 72),
      ],
    );
  }
}

class _CategoryDefinition {
  const _CategoryDefinition(this.title, this.icon, this.patterns);

  final String title;
  final IconData icon;
  final List<String> patterns;
}

Map<String, int> _tagCounts(List<Note> notes) {
  final counts = <String, int>{};
  final expression = RegExp(r'#[a-zA-Z0-9_-]+');
  for (final note in notes) {
    for (final match in expression.allMatches(note.content)) {
      final tag = match.group(0)!.toLowerCase();
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(sorted);
}

Future<int> _attachmentBytes(List<Note> notes) async {
  var total = 0;
  for (final path in notes.expand((note) => note.imagePaths)) {
    try {
      total += await File(path).length();
    } catch (_) {
      // Missing local files do not count toward current storage usage.
    }
  }
  return total;
}

Map<String, List<Note>> _groupByDay(List<Note> notes) {
  final groups = <String, List<Note>>{};
  final now = DateTime.now();
  for (final note in notes) {
    final key = DateUtils.isSameDay(note.updatedAt, now)
        ? 'Today'
        : DateUtils.isSameDay(
            note.updatedAt,
            now.subtract(const Duration(days: 1)),
          )
        ? 'Yesterday'
        : DateFormat.yMMMd().format(note.updatedAt);
    groups.putIfAbsent(key, () => []).add(note);
  }
  return groups;
}

BoxDecoration _libraryCardDecoration(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: colors.outlineVariant),
    boxShadow: [
      BoxShadow(
        color: colors.shadow.withValues(alpha: .07),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

const _featureEyebrow = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 12,
  letterSpacing: 1.2,
  fontWeight: FontWeight.w700,
);
