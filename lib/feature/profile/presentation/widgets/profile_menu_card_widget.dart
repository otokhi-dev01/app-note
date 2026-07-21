import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/app_surface_card.dart';

class ProfileMenuCardWidget extends StatelessWidget {
  const ProfileMenuCardWidget({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: children),
      ),
    );
  }
}
