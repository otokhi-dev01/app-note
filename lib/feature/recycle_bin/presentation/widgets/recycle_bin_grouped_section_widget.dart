import 'package:flutter/material.dart';

import 'recycle_bin_surface_widget.dart';

class RecycleBinGroupedSectionWidget extends StatelessWidget {
  const RecycleBinGroupedSectionWidget({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return RecycleBinSurfaceWidget(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
