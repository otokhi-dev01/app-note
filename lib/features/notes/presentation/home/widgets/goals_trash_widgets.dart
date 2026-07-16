part of '../home_view.dart';

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _WeeklyProgress extends StatelessWidget {
  const _WeeklyProgress({required this.activeDates});

  final Set<DateTime> activeDates;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateUtils.dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return _SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final daySize = (constraints.maxWidth / 7 - 4)
              .clamp(30.0, 38.0)
              .toDouble();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final date = monday.add(Duration(days: index));
              final complete = activeDates.contains(date);
              return Column(
                children: [
                  Text(DateFormat.E().format(date).substring(0, 1)),
                  const SizedBox(height: 9),
                  Container(
                    width: daySize,
                    height: daySize,
                    decoration: BoxDecoration(
                      color: complete
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: date == today
                            ? scheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: complete
                        ? Icon(
                            CupertinoIcons.check_mark,
                            size: 17,
                            color: scheme.onPrimary,
                          )
                        : Text(
                            '${date.day}',
                            style: const TextStyle(fontSize: 12),
                          ),
                  ),
                ],
              );
            }),
          );
        },
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.title,
    required this.subtitle,
    required this.complete,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final bool complete;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: complete
                  ? AppColors.yellow.withValues(alpha: .25)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              complete ? CupertinoIcons.rosette : CupertinoIcons.circle,
              color: complete ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(subtitle),
          trailing: Text(
            complete ? 'Done' : 'In progress',
            style: TextStyle(
              color: complete ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 72),
      ],
    );
  }
}

class _DeletedRow extends StatelessWidget {
  const _DeletedRow({
    required this.note,
    required this.isLast,
    required this.onTap,
  });

  final Note note;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(note.deletedAt ?? note.updatedAt);
    final remaining = (30 - elapsed.inDays).clamp(0, 30);
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          title: Text(
            note.title.isEmpty ? 'Untitled' : note.title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '${_shortDate(note.deletedAt ?? note.updatedAt)} · $remaining days remaining',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
        ),
        if (!isLast) const Divider(height: 1, indent: 16),
      ],
    );
  }
}
