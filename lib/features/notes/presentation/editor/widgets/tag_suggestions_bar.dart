part of '../editor_view.dart';

class _TagSuggestionsBar extends StatelessWidget {
  final Function(String) onTagTap;
  _TagSuggestionsBar({required this.onTagTap});

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return Container(
      height: 48,
      decoration: BoxDecoration(color: style.secondarySurface),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tags.length,
        separatorBuilder: (context, index) => Container(
          width: 0.5,
          margin: const EdgeInsets.symmetric(vertical: 12),
          color: style.border,
        ),
        itemBuilder: (context, index) => CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          onPressed: () => onTagTap(_tags[index]),
          child: Text(
            _tags[index],
            style: TextStyle(
              color: style.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w500,
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
