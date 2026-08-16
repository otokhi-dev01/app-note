import 'package:Note/app/widgets/glass_widgets.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons, CupertinoTextField;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

void main() {
  testWidgets('CustomGlassContainer uses the package GlassContainer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomGlassContainer(
            width: 160,
            height: 80,
            child: Text('Glass content'),
          ),
        ),
      ),
    );

    expect(find.text('Glass content'), findsOneWidget);
    expect(find.byType(lg.GlassContainer), findsOneWidget);

    final packageContainer = tester.widget<lg.GlassContainer>(
      find.byType(lg.GlassContainer),
    );
    expect(packageContainer.useOwnLayer, isTrue);
    expect(packageContainer.width, 160);
    expect(packageContainer.height, 80);
  });

  testWidgets('CustomGlassContainer safely clamps invalid opacity', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomGlassContainer(opacity: 2, child: Text('Clamped glass')),
        ),
      ),
    );

    final packageContainer = tester.widget<lg.GlassContainer>(
      find.byType(lg.GlassContainer),
    );
    expect(packageContainer.settings?.glassColor.a, 1);
  });

  testWidgets('CustomGlassButton forwards taps to onPressed', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomGlassButton(
            onPressed: () => tapCount++,
            child: const Text('Save'),
          ),
        ),
      ),
    );

    expect(find.byType(lg.GlassButton), findsOneWidget);
    await tester.tap(find.byType(CustomGlassButton));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('CustomGlassButton is disabled when onPressed is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomGlassButton(onPressed: null, child: Text('Disabled')),
        ),
      ),
    );

    final packageButton = tester.widget<lg.GlassButton>(
      find.byType(lg.GlassButton),
    );
    expect(packageButton.enabled, isFalse);
  });

  testWidgets('MoreButton has an accessible label and ellipsis icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MoreButton(onPressed: () {})),
      ),
    );

    expect(find.byIcon(Icons.more_horiz), findsOneWidget);

    final packageButton = tester.widget<lg.GlassButton>(
      find.byType(lg.GlassButton),
    );
    expect(packageButton.label, 'More options');
  });

  group('package-backed input facades', () {
    testWidgets('CustomGlassTextField forwards input and glass defaults', (
      tester,
    ) async {
      final controller = TextEditingController();
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomGlassTextField(
              controller: controller,
              placeholder: 'Title',
              borderRadius: 24,
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      final packageField = tester.widget<lg.GlassTextField>(
        find.byType(lg.GlassTextField),
      );
      expect(packageField.controller, same(controller));
      expect(packageField.useOwnLayer, isTrue);
      expect(packageField.quality, lg.GlassQuality.standard);
      expect(
        (packageField.shape as lg.LiquidRoundedSuperellipse).borderRadius,
        24,
      );

      await tester.enterText(find.byType(CupertinoTextField), 'Meeting notes');
      expect(controller.text, 'Meeting notes');
      expect(changedValue, 'Meeting notes');

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });

    testWidgets(
      'CustomGlassSearchBar clear and cancel callbacks stay distinct',
      (tester) async {
        final controller = TextEditingController();
        final events = <String>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomGlassSearchBar(
                controller: controller,
                showsCancelButton: true,
                onChanged: (value) => events.add('changed:$value'),
                onCancel: () => events.add('cancel'),
              ),
            ),
          ),
        );

        final packageSearchBar = tester.widget<lg.GlassSearchBar>(
          find.byType(lg.GlassSearchBar),
        );
        expect(packageSearchBar.controller, same(controller));
        expect(packageSearchBar.useOwnLayer, isTrue);
        expect(packageSearchBar.quality, lg.GlassQuality.standard);

        await tester.enterText(find.byType(CupertinoTextField), 'glass');
        await tester.pumpAndSettle();
        expect(find.byIcon(CupertinoIcons.clear_circled_solid), findsOneWidget);
        expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);

        await tester.tap(find.byIcon(CupertinoIcons.clear_circled_solid));
        await tester.pump();
        expect(controller.text, isEmpty);
        expect(events.last, 'changed:');
        expect(events, isNot(contains('cancel')));

        await tester.enterText(find.byType(CupertinoTextField), 'again');
        await tester.pump();
        await tester.tap(find.byIcon(CupertinoIcons.xmark));
        await tester.pumpAndSettle();

        expect(controller.text, isEmpty);
        expect(events.sublist(events.length - 2), ['cancel', 'changed:']);

        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      },
    );

    testWidgets('standalone list tile forces the missing package own layer', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomGlassListTile(
              standalone: true,
              title: const Text('Standalone row'),
              trailing: CustomGlassListTile.chevron,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(lg.GlassListTile), findsOneWidget);
      final packageContainer = tester.widget<lg.GlassContainer>(
        find.byType(lg.GlassContainer),
      );
      expect(packageContainer.useOwnLayer, isTrue);
      expect(packageContainer.quality, lg.GlassQuality.standard);

      await tester.tap(find.text('Standalone row'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('grouped list tile does not add a second glass surface', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CustomGlassListTile(title: Text('Grouped row'))),
        ),
      );

      expect(find.byType(lg.GlassListTile), findsOneWidget);
      expect(find.byType(lg.GlassContainer), findsNothing);
    });
  });

  group('package-backed surface facades', () {
    testWidgets('CustomGlassAppBar preserves package API and preferred size', (
      tester,
    ) async {
      final appBar = CustomGlassAppBar(
        title: const Text('Notes'),
        actions: const [Icon(Icons.add)],
        toolbarHeight: 48,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(20),
          child: SizedBox(height: 20),
        ),
      );

      expect(appBar.preferredSize.height, 68);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(appBar: appBar, body: const SizedBox()),
        ),
      );

      final packageAppBar = tester.widget<lg.GlassAppBar>(
        find.byType(lg.GlassAppBar),
      );
      expect(packageAppBar.toolbarHeight, 48);
      expect(packageAppBar.actions, hasLength(1));
      expect(packageAppBar.bottom?.preferredSize.height, 20);
    });

    testWidgets('bottom and inline tab bars keep 0.29.5 preferred heights', (
      tester,
    ) async {
      var selected = -1;
      final tabs = [
        const CustomGlassTab(
          icon: Icon(Icons.note),
          label: 'Notes',
          semanticLabel: 'Notes tab',
        ),
        const CustomGlassTab(icon: Icon(Icons.folder), label: 'Folders'),
      ];
      final bottomBar = CustomGlassTabBar.bottom(
        tabs: tabs,
        selectedIndex: 0,
        onTabSelected: (index) => selected = index,
        extraButton: CustomGlassTabBarExtraButton(
          icon: const Icon(Icons.add),
          label: 'New note',
          onTap: () {},
        ),
      );

      expect(bottomBar.preferredSize.height, 104);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(bottomNavigationBar: bottomBar)),
      );

      var packageBar = tester.widget<lg.GlassTabBar>(
        find.byType(lg.GlassTabBar),
      );
      expect(packageBar.tabs.first.semanticLabel, 'Notes tab');
      expect(packageBar.extraButton?.label, 'New note');
      packageBar.onTabSelected(1);
      expect(selected, 1);

      final inlineBar = CustomGlassTabBar.inline(
        tabs: tabs,
        selectedIndex: 1,
        onTabSelected: (_) {},
      );
      expect(inlineBar.preferredSize.height, 40);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: inlineBar)),
        ),
      );
      packageBar = tester.widget<lg.GlassTabBar>(find.byType(lg.GlassTabBar));
      expect(packageBar.selectedIndex, 1);
      expect(packageBar.barHeight, 40);
    });

    testWidgets('searchable tab bar is explicitly controlled by facade state', (
      tester,
    ) async {
      bool? requestedSearchState;
      final tabs = [
        const CustomGlassTab(icon: Icon(Icons.note), label: 'Notes'),
      ];
      final inactiveBar = CustomGlassTabBar.searchable(
        tabs: tabs,
        selectedIndex: 0,
        onTabSelected: (_) {},
        searchConfig: CustomGlassSearchConfig(
          hintText: 'Search notes',
          onSearchToggle: (value) => requestedSearchState = value,
        ),
        isSearchActive: false,
      );
      final activeBar = CustomGlassTabBar.searchable(
        tabs: tabs,
        selectedIndex: 0,
        onTabSelected: (_) {},
        searchConfig: CustomGlassSearchConfig(
          hintText: 'Search notes',
          onSearchToggle: (value) => requestedSearchState = value,
        ),
        isSearchActive: true,
      );

      expect(inactiveBar.preferredSize.height, 104);
      expect(activeBar.preferredSize.height, 90);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(bottomNavigationBar: activeBar)),
      );

      final packageBar = tester.widget<lg.GlassTabBar>(
        find.byType(lg.GlassTabBar),
      );
      expect(packageBar.isSearchActive, isTrue);
      expect(packageBar.searchConfig?.hintText, 'Search notes');

      packageBar.searchConfig?.onSearchToggle(false);
      expect(requestedSearchState, isFalse);
    });

    testWidgets('dialog facade forwards barrier color and owns auto-dismiss', (
      tester,
    ) async {
      late BuildContext hostContext;
      var actionCalled = false;
      const barrierColor = Color(0x66123456);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              hostContext = context;
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      );

      final dialogResult = CustomGlassDialog.show<void>(
        context: hostContext,
        title: 'Delete note?',
        barrierColor: barrierColor,
        actions: [
          CustomGlassDialogAction(
            label: 'Delete',
            isDestructive: true,
            onPressed: () => actionCalled = true,
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomGlassDialog), findsOneWidget);
      expect(find.byType(lg.GlassDialog), findsOneWidget);
      final barrier = tester.widget<AnimatedModalBarrier>(
        find.byType(AnimatedModalBarrier),
      );
      expect(barrier.color.value, barrierColor);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await dialogResult;

      expect(actionCalled, isTrue);
      expect(find.byType(CustomGlassDialog), findsNothing);
    });

    testWidgets('sheet facade pins standard quality for the animated route', (
      tester,
    ) async {
      late BuildContext hostContext;
      const barrierColor = Color(0x55223344);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              hostContext = context;
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      );

      final sheetResult = CustomGlassSheet.show<void>(
        context: hostContext,
        builder: (_) => const Text('Sheet content'),
        showDragIndicator: false,
        isScrollable: false,
        enableDrag: false,
        barrierColor: barrierColor,
      );
      await tester.pumpAndSettle();

      final packageSheet = tester.widget<lg.GlassSheet>(
        find.byType(lg.GlassSheet),
      );
      expect(packageSheet.quality, lg.GlassQuality.standard);
      expect(packageSheet.showDragIndicator, isFalse);
      expect(packageSheet.isScrollable, isFalse);
      final barrier = tester.widget<AnimatedModalBarrier>(
        find.byType(AnimatedModalBarrier),
      );
      expect(barrier.color.value, barrierColor);

      Navigator.of(hostContext).pop();
      await tester.pumpAndSettle();
      await sheetResult;
      expect(find.byType(lg.GlassSheet), findsNothing);
    });
  });
}
