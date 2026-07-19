import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:note_app/feature/main/presentation/widgets/app_liquid_background_widget.dart';
import '../controller/create_folder_controller.dart';

class CreateFolderView
    extends GetView<CreateFolderController> {
  const CreateFolderView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusManager.instance.primaryFocus
              ?.unfocus();
        },
        child: Stack(
          children: <Widget>[
            const Positioned.fill(
              child: AppLiquidBackgroundWidget(),
            ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  _CreateFolderTopBar(
                    onBack: Get.back,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior
                          .onDrag,
                      padding:
                      const EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                          const BoxConstraints(
                            maxWidth: 520,
                          ),
                          child:
                          const _CreateFolderCard(),
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

class _CreateFolderTopBar
    extends StatelessWidget {
  final VoidCallback onBack;

  const _CreateFolderTopBar({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        8,
        16,
        8,
      ),
      child: Row(
        children: <Widget>[
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onBack,
            child: const Icon(
              CupertinoIcons.back,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Create Folder',
              style: theme
                  .textTheme.headlineSmall
                  ?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateFolderCard
    extends GetView<CreateFolderController> {
  const _CreateFolderCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1B1D22)
            : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant
              .withValues(
            alpha: isDark ? 0.18 : 0.35,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: <Widget>[
          Obx(
                () => Center(
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: controller
                      .colorFromHex(
                    controller
                        .selectedColor.value,
                  )
                      .withValues(alpha: 0.14),
                  borderRadius:
                  BorderRadius.circular(27),
                ),
                child: Icon(
                  controller.iconData(
                    controller
                        .selectedIcon.value,
                  ),
                  size: 40,
                  color: controller.colorFromHex(
                    controller
                        .selectedColor.value,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            'Folder name',
            style:
            theme.textTheme.labelLarge
                ?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller:
            controller.nameController,
            autofocus: true,
            textInputAction:
            TextInputAction.done,
            onSubmitted: (_) {
              controller.saveFolder();
            },
            decoration: const InputDecoration(
              hintText:
              'Enter folder name',
              prefixIcon: Icon(
                Icons.folder_outlined,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Choose icon',
            style:
            theme.textTheme.titleMedium
                ?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
                () => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: controller
                  .availableIcons
                  .map(
                    (String iconName) {
                  final bool selected =
                      controller.selectedIcon
                          .value ==
                          iconName;

                  return _IconOption(
                    icon: controller
                        .iconData(iconName),
                    selected: selected,
                    onTap: () {
                      controller.selectIcon(
                        iconName,
                      );
                    },
                  );
                },
              ).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Choose color',
            style:
            theme.textTheme.titleMedium
                ?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
                () => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: controller
                  .availableColors
                  .map(
                    (String colorValue) {
                  final bool selected =
                      controller.selectedColor
                          .value ==
                          colorValue;

                  return _ColorOption(
                    color: controller
                        .colorFromHex(
                      colorValue,
                    ),
                    selected: selected,
                    onTap: () {
                      controller.selectColor(
                        colorValue,
                      );
                    },
                  );
                },
              ).toList(),
            ),
          ),
          Obx(() {
            final String error =
                controller.errorMessage.value;

            if (error.isEmpty) {
              return const SizedBox(
                height: 22,
              );
            }

            return Padding(
              padding:
              const EdgeInsets.only(
                top: 18,
              ),
              child: Text(
                error,
                style: TextStyle(
                  color: colorScheme.error,
                ),
              ),
            );
          }),
          const SizedBox(height: 22),
          Obx(
                () => FilledButton.icon(
              onPressed:
              controller.isSaving.value
                  ? null
                  : controller.saveFolder,
              icon: controller.isSaving.value
                  ? const SizedBox(
                width: 20,
                height: 20,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(
                Icons.add_rounded,
              ),
              label: Text(
                controller.isSaving.value
                    ? 'Creating...'
                    : 'Create Folder',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _IconOption({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colorScheme.primary.withValues(
        alpha: 0.14,
      )
          : colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(17),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(17),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Icon(
            icon,
            color: selected
                ? colorScheme.primary
                : colorScheme
                .onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
        const Duration(milliseconds: 180),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected
                ? Theme.of(context)
                .colorScheme
                .onSurface
                : Colors.transparent,
            width: 3,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(
                alpha: 0.30,
              ),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: selected
            ? const Icon(
          Icons.check_rounded,
          color: Colors.white,
        )
            : null,
      ),
    );
  }
}