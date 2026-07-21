part of 'create_folder_view.dart';

class _CreateFolderCard extends GetView<CreateFolderController> {
  const _CreateFolderCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? <Color>[
                      const Color(0xFF22242A).withValues(alpha: 0.85),
                      const Color(0xFF16181D).withValues(alpha: 0.90),
                    ]
                  : <Color>[
                      Colors.white.withValues(alpha: 0.85),
                      const Color(0xFFECECEF).withValues(alpha: 0.70),
                    ],
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.90),
              width: 1.2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.08),
                blurRadius: 30,
                spreadRadius: -6,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: colorScheme.primary.withValues(
                  alpha: isDark ? 0.08 : 0.03,
                ),
                blurRadius: 20,
                spreadRadius: -8,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Obx(() {
                  final Color folderColor = controller.colorFromHex(
                    controller.selectedColor.value,
                  );
                  return Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            folderColor.withValues(alpha: 0.22),
                            folderColor.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: folderColor.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: folderColor.withValues(alpha: 0.25),
                            blurRadius: 18,
                            spreadRadius: -4,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        controller.iconData(controller.selectedIcon.value),
                        size: 42,
                        color: folderColor,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 28),
                Text(
                  'Folder name',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller.nameController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    controller.saveFolder();
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter folder name',
                    prefixIcon: const Icon(Icons.folder_outlined),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Choose icon',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Obx(
                  () => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: controller.availableIcons.map((String iconName) {
                      final bool selected =
                          controller.selectedIcon.value == iconName;

                      return _IconOption(
                        icon: controller.iconData(iconName),
                        selected: selected,
                        onTap: () {
                          controller.selectIcon(iconName);
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Choose color',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Obx(
                  () => Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: controller.availableColors.map((
                      String colorValue,
                    ) {
                      final bool selected =
                          controller.selectedColor.value == colorValue;

                      return _ColorOption(
                        color: controller.colorFromHex(colorValue),
                        selected: selected,
                        onTap: () {
                          controller.selectColor(colorValue);
                        },
                      );
                    }).toList(),
                  ),
                ),
                Obx(() {
                  final String error = controller.errorMessage.value;

                  if (error.isEmpty) {
                    return const SizedBox(height: 24);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      error,
                      style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                Obx(
                  () => SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                        shadowColor: colorScheme.primary.withValues(alpha: 0.4),
                      ),
                      onPressed: controller.isSaving.value
                          ? null
                          : controller.saveFolder,
                      icon: controller.isSaving.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_rounded, size: 24),
                      label: Text(
                        controller.isSaving.value
                            ? 'Creating...'
                            : 'Create Folder',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
