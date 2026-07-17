part of '../home_view.dart';

class _GoalsPage extends StatelessWidget {
  const _GoalsPage({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      bottom: false,
      child: Obx(() {
        final todayWords = controller.notes
            .where(
              (note) => DateUtils.isSameDay(note.updatedAt, DateTime.now()),
            )
            .fold<int>(0, (sum, note) => sum + _wordCount(note.content));
        const dailyGoal = 2000;
        final progress = (todayWords / dailyGoal).clamp(0.0, 1.0);
        final activeDates = controller.notes
            .map((note) => DateUtils.dateOnly(note.updatedAt))
            .toSet();
        final totalWords = controller.notes.fold<int>(
          0,
          (sum, note) => sum + _wordCount(note.content),
        );
        return RefreshIndicator(
          onRefresh: controller.loadNotes,
          color: scheme.primary,
          child: ListView(
            key: const PageStorageKey('goals_page'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _SurfaceCard(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 174,
                        height: 174,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 14,
                              color: scheme.primary,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              strokeCap: StrokeCap.round,
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(progress * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'of Daily Goal',
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        '${NumberFormat.decimalPattern().format(todayWords)} / ${NumberFormat.decimalPattern().format(dailyGoal)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Words written today',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: CupertinoIcons.flame_fill,
                        value: '${activeDates.length}',
                        label: 'Active days',
                        accent: scheme.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        icon: CupertinoIcons.text_cursor,
                        value: NumberFormat.compact().format(totalWords),
                        label: 'Total words',
                        accent: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const _SectionHeading(title: 'Weekly Progress'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _WeeklyProgress(activeDates: activeDates),
              ),
              const _SectionHeading(title: 'Milestones'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SurfaceCard(
                  child: Column(
                    children: [
                      _MilestoneRow(
                        title: 'First 1,000 Words',
                        subtitle: 'Build momentum with your first draft',
                        complete: totalWords >= 1000,
                      ),
                      _MilestoneRow(
                        title: 'Organized Writer',
                        subtitle: 'Create five focused folders',
                        complete: controller.folders.length >= 5,
                      ),
                      _MilestoneRow(
                        title: 'Visual Thinker',
                        subtitle: 'Add five photos or drawings',
                        complete:
                            controller.notes.fold<int>(
                              0,
                              (sum, note) => sum + note.imagePaths.length,
                            ) >=
                            5,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
