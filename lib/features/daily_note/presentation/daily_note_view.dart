import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/daily_note/data/daily_note_store.dart';
import 'package:Note/features/daily_note/presentation/daily_note_editor.dart';

class DailyNoteView extends StatefulWidget {
  final DailyNoteStore? store;
  final DateTime? initialDate;

  const DailyNoteView({super.key, this.store, this.initialDate});

  @override
  State<DailyNoteView> createState() => _DailyNoteViewState();
}

class _DailyNoteViewState extends State<DailyNoteView> {
  static const _hourHeight = 44.0;
  late final DailyNoteStore _store;
  late DateTime _date;
  late List<DailyNote> _entries;
  final _scroll = ScrollController(initialScrollOffset: 6 * _hourHeight);
  final _search = TextEditingController();
  bool _searching = false;
  bool _agenda = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _date = DateTime(initial.year, initial.month, initial.day);
    _store = widget.store ?? _createStore();
    _entries = _store.read();
  }

  DailyNoteStore _createStore() {
    final guest = Get.find<GuestModeService>().isGuestMode.value;
    final userId = Get.find<SessionStorage>().user.value?.id;
    return DailyNoteStore(
      storage: GetStorage(),
      owner: guest || userId == null ? 'guest' : 'account_$userId',
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  List<DailyNote> get _visible {
    final query = _search.text.trim().toLowerCase();
    return _entries.where((entry) {
      return DateUtils.isSameDay(entry.date, _date) &&
          (query.isEmpty ||
              '${entry.title} ${entry.body}'.toLowerCase().contains(query));
    }).toList()..sort((a, b) => a.startMinute.compareTo(b.startMinute));
  }

  void _selectDate(DateTime date) => setState(() => _date = date);

  /// Swiping the day content (as opposed to the week strip, which jumps a
  /// whole week) moves one day at a time — the same velocity-threshold
  /// gesture the week strip already uses, just a smaller step.
  void _moveDay(int days) =>
      _selectDate(DateTime(_date.year, _date.month, _date.day + days));

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
    );
    if (date != null && mounted) _selectDate(date);
  }

  Future<void> _edit({DailyNote? note, int? minute}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DailyNoteEditor(
        store: _store,
        date: _date,
        note: note,
        initialMinute: minute ?? 9 * 60,
      ),
    );
    if (mounted) setState(() => _entries = _store.read());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final visible = _visible;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: TextButton(
          onPressed: _pickDate,
          child: Text(
            localizations.formatMonthYear(_date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),
        ),
        actions: [
          IconButton(
            tooltip: (_agenda ? 'daily_timeline' : 'daily_agenda').tr,
            onPressed: () => setState(() => _agenda = !_agenda),
            icon: Icon(
              _agenda ? CupertinoIcons.calendar : CupertinoIcons.list_bullet,
            ),
          ),
          IconButton(
            tooltip: 'daily_search'.tr,
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _search.clear();
            }),
            icon: Icon(
              _searching ? CupertinoIcons.xmark : CupertinoIcons.search,
            ),
          ),
          IconButton(
            tooltip: 'daily_add'.tr,
            onPressed: () => _edit(),
            icon: const Icon(CupertinoIcons.add),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_searching)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _search,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'daily_search'.tr,
                    prefixIcon: const Icon(CupertinoIcons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            _weekStrip(context),
            const Divider(height: 1),
            // Swiping anywhere in the date header or the day's content moves
            // one day at a time — a lighter-weight gesture than a PageView,
            // matching the velocity-threshold swipe the week strip above
            // already uses for whole weeks.
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity.abs() > 100) _moveDay(velocity < 0 ? 1 : -1);
                },
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              localizations.formatFullDate(_date),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _todayPill(theme),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _agenda ? _agendaList(visible) : _timeline(visible),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'daily_local'.tr,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _todayPill(ThemeData theme) => Material(
    color: theme.colorScheme.primary.withValues(alpha: 0.14),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _selectDate(DateUtils.dateOnly(DateTime.now())),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Text(
          'daily_today'.tr,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );

  Widget _weekStrip(BuildContext context) {
    final theme = Theme.of(context);
    final weekStart = DateTime(
      _date.year,
      _date.month,
      _date.day - (_date.weekday - 1),
    );
    final localizations = MaterialLocalizations.of(context);
    void moveWeek(int days) =>
        _selectDate(DateTime(_date.year, _date.month, _date.day + days));
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() > 100) moveWeek(velocity < 0 ? 7 : -7);
      },
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'daily_previous_week'.tr,
              onPressed: () => moveWeek(-7),
              icon: const Icon(CupertinoIcons.chevron_left, size: 15),
            ),
          ),
          for (var index = 0; index < 7; index++)
            Expanded(
              child: Builder(
                builder: (context) {
                  final day = DateTime(
                    weekStart.year,
                    weekStart.month,
                    weekStart.day + index,
                  );
                  final selected = DateUtils.isSameDay(day, _date);
                  final hasEntries = _entries.any(
                    (entry) => DateUtils.isSameDay(entry.date, day),
                  );
                  return Semantics(
                    selected: selected,
                    label: localizations.formatFullDate(day),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _selectDate(day),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Text(
                              localizations.narrowWeekdays[day.weekday % 7],
                              style: theme.textTheme.labelSmall,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                              ),
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: selected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasEntries
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          SizedBox(
            width: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'daily_next_week'.tr,
              onPressed: () => moveWeek(7),
              icon: const Icon(CupertinoIcons.chevron_right, size: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(CupertinoIcons.calendar, size: 28),
        const SizedBox(height: 10),
        Text(
          (_search.text.isEmpty ? 'daily_empty' : 'daily_no_results').tr,
          textAlign: TextAlign.center,
        ),
        if (_search.text.isEmpty)
          TextButton.icon(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
            label: Text('daily_add'.tr),
          ),
      ],
    ),
  );

  Widget _agendaList(List<DailyNote> entries) {
    if (entries.isEmpty) return Center(child: _empty());
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) =>
          SizedBox(height: 90, child: _entryCard(entries[index])),
    );
  }

  Widget _timeline(List<DailyNote> entries) {
    final theme = Theme.of(context);
    final placements = layoutDailyNotes(entries);
    return SingleChildScrollView(
      key: const ValueKey('daily-timeline'),
      controller: _scroll,
      child: SizedBox(
        height: 24 * _hourHeight + 20,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth - 60;
            return Stack(
              children: [
                for (var hour = 0; hour <= 24; hour++) ...[
                  Positioned(
                    top: hour * _hourHeight,
                    left: 8,
                    width: 42,
                    child: Text(
                      dailyTime(hour * 60),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (hour < 24)
                    Positioned(
                      top: hour * _hourHeight,
                      left: 56,
                      right: 0,
                      height: _hourHeight,
                      child: InkWell(
                        onTap: () => _edit(minute: hour * 60),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.center,
                            child: Divider(
                              height: 1,
                              color: theme.dividerColor.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
                if (entries.isEmpty)
                  Positioned(
                    top: 7 * _hourHeight,
                    left: 56,
                    right: 8,
                    child: _empty(),
                  ),
                for (final placement in placements)
                  Positioned(
                    top: placement.note.startMinute / 60 * _hourHeight + 1,
                    left:
                        56 +
                        placement.column * availableWidth / placement.columns,
                    width: availableWidth / placement.columns - 3,
                    height: math.max(
                      14,
                      (placement.note.endMinute - placement.note.startMinute) /
                              60 *
                              _hourHeight -
                          2,
                    ),
                    child: _entryCard(placement.note),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _entryCard(DailyNote note) {
    final theme = Theme.of(context);
    final color = Color(note.color);
    return Semantics(
      button: true,
      label:
          '${note.title}, ${dailyTime(note.startMinute)} – ${dailyTime(note.endMinute)}',
      child: Material(
        color: Color.alphaBlend(
          color.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.32 : 0.16,
          ),
          theme.scaffoldBackgroundColor,
        ),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _edit(note: note),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: 4)),
            ),
            padding: const EdgeInsets.fromLTRB(8, 2, 6, 2),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = MediaQuery.textScalerOf(context).scale(1);
                final showTitle = constraints.maxHeight >= 15 * scale;
                final showBadge = showTitle && constraints.maxWidth >= 84;
                return ClipRect(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showTitle)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                note.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            if (showBadge) ...[
                              const SizedBox(width: 4),
                              Container(
                                width: 14,
                                height: 14,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.withValues(alpha: 0.85),
                                ),
                                child: const Icon(
                                  Icons.event_note,
                                  size: 8,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      if (constraints.maxHeight >= 34 * scale)
                        Text(
                          '${dailyTime(note.startMinute)} – ${dailyTime(note.endMinute)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (constraints.maxHeight >= 58 * scale &&
                          note.body.isNotEmpty)
                        Text(
                          note.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

String dailyTime(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
