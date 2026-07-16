part of '../editor_view.dart';

class _TagSuggestionsBar extends StatelessWidget {
  final Function(String) onTagTap;
  _TagSuggestionsBar({required this.onTagTap});

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: style.surface,
        border: Border(top: BorderSide(color: style.border, width: .5)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tags.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) => CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          onPressed: () => onTagTap(_tags[index]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: style.secondarySurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _tags[index],
              style: TextStyle(
                color: style.primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  final List<String> _tags = [
    '#dinner',
    '#dessert',
    '#drink',
    '#pie',
    '#cooking',
    '#ideas',
    '#work',
    '#personal',
  ];
}
