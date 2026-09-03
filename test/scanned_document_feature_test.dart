// import 'dart:io';
//
// import 'package:flutter/services.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter/widgets.dart';
// import 'package:get/get.dart';
// import 'package:image/image.dart' as image;
//
// import 'package:Note/core/localization/app_translations.dart';
// import 'package:Note/features/note/data/services/scan_page_processor.dart';
// import 'package:Note/features/note/domain/entities/scanned_document_draft.dart';
// import 'package:Note/features/note/presentation/widgets/scanned_document_review_page.dart';
//
// void main() {
//   TestWidgetsFlutterBinding.ensureInitialized();
//
//   setUpAll(() {
//     TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//         .setMockMethodCallHandler(
//           const MethodChannel('plugins.flutter.io/path_provider'),
//           (_) async => Directory.systemTemp.path,
//         );
//   });
//
//   test(
//     'scan page processing rotates, filters, and cleans derived files',
//     () async {
//       final token = DateTime.now().microsecondsSinceEpoch;
//       final source = File(
//         '${Directory.systemTemp.path}/scan_source_$token.png',
//       );
//       final sourceImage = image.Image(width: 6, height: 3);
//       sourceImage.setPixelRgb(0, 0, 240, 30, 10);
//       source.writeAsBytesSync(image.encodePng(sourceImage));
//
//       final prepared = await prepareScannedPages([
//         ScannedPageDraft(
//           path: source.path,
//           quarterTurns: 1,
//           filter: ScanPageFilter.grayscale,
//         ),
//       ]);
//
//       expect(prepared.paths, hasLength(1));
//       expect(prepared.generatedPaths, prepared.paths);
//       final rendered = image.decodeImage(
//         File(prepared.paths.single).readAsBytesSync(),
//       );
//       expect(rendered, isNotNull);
//       expect(rendered!.width, 3);
//       expect(rendered.height, 6);
//       final pixel = rendered.getPixel(2, 0);
//       expect(pixel.r, closeTo(pixel.g, 2));
//       expect(pixel.g, closeTo(pixel.b, 2));
//
//       await prepared.cleanUp();
//       expect(File(prepared.paths.single).existsSync(), isFalse);
//       source.deleteSync();
//     },
//   );
//
//   test('untouched scan pages are not re-encoded', () async {
//     final path = '${Directory.systemTemp.path}/untouched-scan.jpg';
//     final prepared = await prepareScannedPages([ScannedPageDraft(path: path)]);
//
//     expect(prepared.paths, [path]);
//     expect(prepared.generatedPaths, isEmpty);
//   });
//
//   testWidgets('review saves the name, rotation, filter, and page order', (
//     tester,
//   ) async {
//     final source =
//         '${Directory.current.path}/assets/icons/piisiit_logo_app.png';
//     ScannedDocumentDraft? savedDraft;
//
//     await tester.pumpWidget(
//       GetMaterialApp(
//         translations: AppTranslations(),
//         locale: const Locale('en', 'US'),
//         home: ScannedDocumentReviewPage(
//           initialPagePaths: [source, source],
//           initialTitle: 'Scanned Document',
//           onSave: (draft) async {
//             savedDraft = draft;
//             return false;
//           },
//         ),
//       ),
//     );
//     await tester.pump();
//
//     expect(find.byKey(const ValueKey('scan-review-page')), findsOneWidget);
//     expect(find.text('1 / 2'), findsOneWidget);
//
//     await tester.tap(find.byKey(const ValueKey('scan-review-rotate')));
//     await tester.tap(find.byKey(const ValueKey('scan-review-filter')));
//     await tester.enterText(
//       find.byKey(const ValueKey('scan-review-title')),
//       'Receipt September',
//     );
//     await tester.tap(find.byKey(const ValueKey('scan-review-save')));
//     await tester.pump();
//
//     expect(savedDraft, isNotNull);
//     expect(savedDraft!.title, 'Receipt September');
//     expect(savedDraft!.pages, hasLength(2));
//     expect(savedDraft!.pages.first.quarterTurns, 1);
//     expect(savedDraft!.pages.first.filter, ScanPageFilter.grayscale);
//     expect(savedDraft!.pages.last.quarterTurns, 0);
//     expect(savedDraft!.pages.last.filter, ScanPageFilter.color);
//   });
// }
