import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:notes/features/library/application/library_coordinator.dart';

import '../library_helpers.dart';
import '../widgets/library_components.dart';

class NoteCalendarView extends GetView<LibraryCoordinator> {
  const NoteCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leadingDays = monthStart.weekday % 7;
    return LibraryScaffold(
      title: 'Calendar',
      child: Obx(() {
        final selectedDay = controller.selectedCalendarDayValue.clamp(
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
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
          children: [
            LibraryFeatureIntro(
              title: DateFormat.yMMMM().format(now),
              subtitle: 'Browse notes by the day they were last updated',
              icon: CupertinoIcons.calendar,
              compact: true,
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 15),
              decoration: libraryCardDecoration(context),
              child: Column(
                children: [
                  const Row(
                    children: [
                      LibraryWeekLabel('S'),
                      LibraryWeekLabel('M'),
                      LibraryWeekLabel('T'),
                      LibraryWeekLabel('W'),
                      LibraryWeekLabel('T'),
                      LibraryWeekLabel('F'),
                      LibraryWeekLabel('S'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 2,
                          childAspectRatio: .84,
                        ),
                    itemCount: leadingDays + daysInMonth,
                    itemBuilder: (context, index) {
                      if (index < leadingDays) return const SizedBox.shrink();
                      final day = index - leadingDays + 1;
                      final selected = day == selectedDay;
                      final active = activeDays.contains(day);
                      final isToday = day == now.day;
                      return InkWell(
                        onTap: () => controller.setSelectedCalendarDay(day),
                        borderRadius: BorderRadius.circular(30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 33,
                              height: 33,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? colors.primary
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: isToday && !selected
                                    ? Border.all(
                                        color: colors.primary.withValues(
                                          alpha: .55,
                                        ),
                                      )
                                    : null,
                              ),
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  color: selected
                                      ? colors.onPrimary
                                      : colors.onSurface,
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: active
                                    ? colors.primary
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
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateUtils.isSameDay(selectedDate, now)
                        ? "Today's Notes"
                        : DateFormat.MMMEd().format(selectedDate),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.3,
                    ),
                  ),
                ),
                LibraryCountBadge('${selectedNotes.length}'),
              ],
            ),
            const SizedBox(height: 12),
            if (selectedNotes.isEmpty)
              const LibraryFeatureEmpty(
                message: 'No notes were edited on this date.',
                icon: CupertinoIcons.calendar_badge_minus,
              )
            else
              LibrarySurface(
                child: Column(
                  children: selectedNotes.asMap().entries.map((entry) {
                    final note = entry.value;
                    return Column(
                      children: [
                        ListTile(
                          onTap: () => controller.openNote(note),
                          minTileHeight: 70,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          leading: const LibraryFeatureIcon(
                            CupertinoIcons.doc_text,
                            size: 40,
                            iconSize: 19,
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
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (entry.key != selectedNotes.length - 1)
                          Divider(
                            height: 1,
                            indent: 72,
                            color: colors.outlineVariant.withValues(alpha: .55),
                          ),
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
