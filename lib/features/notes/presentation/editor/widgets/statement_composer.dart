part of '../editor_view.dart';

class _StatementComposer extends StatefulWidget {
  const _StatementComposer({
    required this.controller,
    required this.onImageOptions,
  });

  final EditorController controller;
  final ValueChanged<int> onImageOptions;

  @override
  State<_StatementComposer> createState() => _StatementComposerState();
}

class _StatementComposerState extends State<_StatementComposer> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _replaceStatements(widget.controller.contentController.text.split('\n'));
    widget.controller.contentController.addListener(_syncFromNote);
    widget.controller.focusStatementComposer = () {
      if (_focusNodes.isNotEmpty) _focusNodes.last.requestFocus();
    };
    widget.controller.focusFirstStatementComposer = () {
      if (_focusNodes.isNotEmpty) _focusNodes.first.requestFocus();
    };
    widget.controller.bindActiveStatementEditor(
      text: () => _activeController.text,
      selection: () => _activeController.selection,
      apply: (text, selection) {
        _activeController.value = TextEditingValue(
          text: text,
          selection: selection,
        );
        _activeFocusNode.requestFocus();
      },
    );
  }

  int get _activeIndex => widget.controller.activeStatementIndex.value.clamp(
    0,
    _controllers.length - 1,
  );

  TextEditingController get _activeController => _controllers[_activeIndex];

  FocusNode get _activeFocusNode => _focusNodes[_activeIndex];

  FocusNode _createFocusNode() {
    final node = FocusNode();
    node.addListener(() {
      if (!mounted) return;
      if (node.hasFocus) {
        final index = _focusNodes.indexOf(node);
        if (index >= 0) widget.controller.setActiveStatement(index);
      }
      setState(() {});
    });
    return node;
  }

  void _replaceStatements(List<String> values) {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _controllers
      ..clear()
      ..addAll(
        (values.isEmpty ? const [''] : values).map(
          (value) => TextEditingController(text: value)..addListener(_publish),
        ),
      );
    _focusNodes
      ..clear()
      ..addAll(List.generate(_controllers.length, (_) => _createFocusNode()));
  }

  void _syncFromNote() {
    if (_publishing) return;
    final values = widget.controller.contentController.text.split('\n');
    if (values.length != _controllers.length) {
      setState(() => _replaceStatements(values));
      return;
    }
    _publishing = true;
    for (var index = 0; index < values.length; index++) {
      if (_controllers[index].text != values[index]) {
        _controllers[index].text = values[index];
      }
    }
    _publishing = false;
  }

  void _publish() {
    if (_publishing) return;
    _publishing = true;
    widget.controller.setStatements(
      _controllers.map((controller) => controller.text).toList(),
    );
    _publishing = false;
  }

  void _addStatement(int afterIndex) {
    widget.controller.statementInsertedAfter(afterIndex);
    setState(() {
      final controller = TextEditingController()..addListener(_publish);
      _controllers.insert(afterIndex + 1, controller);
      _focusNodes.insert(afterIndex + 1, _createFocusNode());
      _publish();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[afterIndex + 1].requestFocus();
    });
  }

  void _removeStatement(int index) {
    if (_controllers.length == 1) return;
    widget.controller.statementRemoved(index);
    setState(() {
      _controllers.removeAt(index).dispose();
      _focusNodes.removeAt(index).dispose();
      _publish();
    });
  }

  @override
  void dispose() {
    widget.controller.contentController.removeListener(_syncFromNote);
    widget.controller.focusStatementComposer = null;
    widget.controller.focusFirstStatementComposer = null;
    widget.controller.unbindActiveStatementEditor();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Column(
      children: List.generate(_controllers.length, (statementIndex) {
        final isFocused = _focusNodes[statementIndex].hasFocus;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedContainer(
              duration: reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isFocused
                        ? style.theme.colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      key: ValueKey(_controllers[statementIndex]),
                      controller: _controllers[statementIndex],
                      focusNode: _focusNodes[statementIndex],
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'[\r\n]')),
                      ],
                      minLines: 1,
                      maxLines: null,
                      onTap: () =>
                          widget.controller.setActiveStatement(statementIndex),
                      onSubmitted: (_) => _addStatement(statementIndex),
                      style: TextStyle(
                        color: style.primaryText,
                        fontSize: 18,
                        height: 1.55,
                        letterSpacing: -.15,
                      ),
                      decoration: InputDecoration(
                        hintText: statementIndex == 0
                            ? 'Start writing…'
                            : 'Continue writing…',
                        hintStyle: TextStyle(
                          color: style.secondaryText.withValues(alpha: .72),
                        ),
                      ),
                    ),
                  ),
                  if (isFocused && _controllers.length > 1)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size.square(44),
                      onPressed: () => _removeStatement(statementIndex),
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 17,
                        color: style.secondaryText.withValues(alpha: .58),
                      ),
                    ),
                ],
              ),
            ),
            Obx(() {
              final imageIndexes = widget.controller.imagesAfterStatement(
                statementIndex,
              );
              return Column(
                children: imageIndexes
                    .map(
                      (imageIndex) => Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 0, 14),
                        child: _IntegratedImage(
                          path: widget.controller.imagePaths[imageIndex],
                          onRemove: () =>
                              widget.controller.removeImage(imageIndex),
                          onEdit: () => widget.controller.editImage(imageIndex),
                          onTap: () => widget.onImageOptions(imageIndex),
                        ),
                      ),
                    )
                    .toList(),
              );
            }),
            if (statementIndex < _controllers.length - 1)
              const SizedBox(height: 2),
          ],
        );
      }),
    );
  }
}
