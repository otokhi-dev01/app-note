import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:notes/app/theme/app_colors.dart';
import 'package:notes/features/library/application/library_coordinator.dart';

import '../library_helpers.dart';
import '../widgets/library_components.dart';

class NoteCalendarView extends GetView<LibraryCoordinator> {
  const NoteCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
          children: [
            Text(
              DateFormat.yMMMM().format(now),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
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
                        onTap: () => controller.setSelectedCalendarDay(day),
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
              const LibraryFeatureEmpty(
                message: 'No notes were edited on this date.',
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
