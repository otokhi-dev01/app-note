import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notes/core/constants/app_strings.dart';
import '../home_style.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.style});

  final HomeStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 130),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _EmptyStateIcon(style: style),
            const SizedBox(height: 24),
            Text(
              AppStrings.noNotes,
              textAlign: TextAlign.center,
              style: style.theme.textTheme.headlineSmall?.copyWith(
                color: style.primaryText,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'Create your first note to save ideas,\n'
              'reminders and important information.',
              textAlign: TextAlign.center,
              style: style.theme.textTheme.bodyMedium?.copyWith(
                color: style.secondaryText,
                height: 1.45,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateIcon extends StatelessWidget {
  const _EmptyStateIcon({required this.style});

  final HomeStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: HomeStyle.yellow.withValues(alpha: style.isDark ? 0.18 : 0.14),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        CupertinoIcons.doc_text_fill,
        size: 42,
        color: HomeStyle.orange,
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.style,
    required this.error,
    required this.onRetry,
  });

  final HomeStyle style;
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 130),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: style.errorBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HomeStyle.red.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ErrorIcon(),
                const SizedBox(width: 13),
                Expanded(
                  child: _ErrorMessage(style: style, error: error),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: HomeStyle.red,
                borderRadius: BorderRadius.circular(13),
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: onRetry,
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorIcon extends StatelessWidget {
  const _ErrorIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: HomeStyle.red.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(
        CupertinoIcons.exclamationmark_triangle_fill,
        color: HomeStyle.red,
        size: 21,
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.style, required this.error});

  final HomeStyle style;
  final String error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unable to load notes',
          style: style.theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          error,
          style: style.theme.textTheme.bodyMedium?.copyWith(
            color: style.secondaryText,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class LoadingNotes extends StatefulWidget {
  const LoadingNotes({super.key, required this.style});

  final HomeStyle style;

  @override
  State<LoadingNotes> createState() => _LoadingNotesState();
}

class _LoadingNotesState extends State<LoadingNotes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.45, end: 0.85).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index == 2 ? 0 : 14),
            child: _LoadingNoteCard(style: widget.style, opacity: _opacity),
          );
        }, childCount: 3),
      ),
    );
  }
}

class _LoadingNoteCard extends StatelessWidget {
  const _LoadingNoteCard({required this.style, required this.opacity});

  final HomeStyle style;
  final Animation<double> opacity;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: Container(
        height: 116,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: style.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: style.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: style.placeholder,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonLine(
                    color: style.placeholder,
                    widthFactor: 0.58,
                    height: 14,
                  ),
                  const SizedBox(height: 12),
                  _SkeletonLine(color: style.placeholder, widthFactor: 0.88),
                  const SizedBox(height: 8),
                  _SkeletonLine(color: style.placeholder, widthFactor: 0.66),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.color,
    required this.widthFactor,
    this.height = 11,
  });

  final Color color;
  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
