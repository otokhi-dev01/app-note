import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes/data/models/note_model.dart';
import 'package:notes/presentation/modules/home/widgets/home_sheets.dart';
import 'package:notes/shared/components/note_card.dart';

void main() {
  final note = NoteModel(
    id: 1,
    title: 'Runtime test',
    content: 'Content',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  testWidgets('note card can be removed during its swipe animation', (
    tester,
  ) async {
    late StateSetter updateHost;
    var showCard = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return showCard
                  ? NoteCard(
                      key: const ValueKey('note-1'),
                      note: note,
                      onTap: () {},
                      onDelete: () {},
                    )
                  : const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    await tester.drag(find.byType(NoteCard), const Offset(-180, 0));
    updateHost(() => showCard = false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
  });

  testWidgets('share sheet gives list tiles their own material layer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(bottomSheet: ShareBottomSheet(note: note)),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
