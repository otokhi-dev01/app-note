import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_app/feature/main/presentation/widgets/app_liquid_background_widget.dart';
import '../controller/create_folder_controller.dart';

part 'create_folder_card.dart';
part 'create_folder_color_option.dart';
part 'create_folder_icon_option.dart';
part 'create_folder_top_bar.dart';

class CreateFolderView extends GetView<CreateFolderController> {
  const CreateFolderView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: AppLiquidBackgroundWidget()),
            SafeArea(
              child: Column(
                children: <Widget>[
                  _CreateFolderTopBar(onBack: Get.back),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: const _CreateFolderCard(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
