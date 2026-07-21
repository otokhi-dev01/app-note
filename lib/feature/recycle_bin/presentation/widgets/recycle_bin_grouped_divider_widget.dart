import 'package:flutter/material.dart';

class RecycleBinGroupedDividerWidget extends StatelessWidget {
  const RecycleBinGroupedDividerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 69,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
