import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:Note/core/constants/app_constants.dart';
import 'package:Note/core/error/failures.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:Note/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:Note/features/auth/data/services/auth_device_service.dart';
import 'package:Note/features/auth/data/services/google_sign_in_service.dart';
import 'package:Note/features/auth/presentation/controllers/google_password_verification_controller.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/features/auth/domain/entities/security_question.dart';
import 'package:Note/features/auth/presentation/views/forgot_password_view.dart';
import 'package:Note/features/auth/presentation/widgets/password_otp_step.dart';
import 'package:Note/routes/app_pages.dart';

class _Session extends SessionStorage {
  bool cleared = false;
  @override
  Future<void> loadSession() async {}
  @override
  Future<void> clearSession() async {
    cleared = true;
    token.value = null;
    user.value = null;
  }
}

class _UnusedDeviceService implements AuthDeviceService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Recovery must not read device information');
}

class _GoogleIdentity extends GoogleSignInService {
  Future<String?> Function() respond = () async => null;
  int calls = 0;
  @override
  Future<String?> signInIdToken() {
    calls++;
    return respond();
  }
}

class _Adapter implements dio.HttpClientAdapter {
  final requests = <dio.RequestOptions>[];
  FutureOr<dio.ResponseBody> Function(dio.RequestOptions) respond = (_) =>
      _json({'success': true, 'data': null});

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

dio.ResponseBody _json(Object? body, [int status = 200]) =>
    dio.ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        dio.Headers.contentTypeHeader: ['application/json'],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Session session;
  late _Adapter adapter;
  late AuthRepositoryImpl repository;
  late _GoogleIdentity googleIdentity;
  late GooglePasswordVerificationController googleVerification;

  setUp(() {
    Get.testMode = true;
    session = Get.put<SessionStorage>(_Session()) as _Session;
    session.token.value = 'existing-session';
    final api = Get.put(ApiClient());
    adapter = _Adapter();
    api.dio.httpClientAdapter = adapter;
    repository = AuthRepositoryImpl(
      AuthRemoteDataSource(api: api, deviceService: _UnusedDeviceService()),
      session,
    );
    Get.put(ForgotPassword(repository));
    Get.put(VerifyPasswordOtp(repository));
    Get.put(VerifyPasswordGoogle(repository));
    googleIdentity = _GoogleIdentity();
    googleVerification = Get.put(
      GooglePasswordVerificationController(
        verify: Get.find<VerifyPasswordGoogle>(),
        googleSignIn: googleIdentity,
      ),
    );
    Get.put(GetSecurityQuestions(repository));
    Get.put(VerifySecurityAnswers(repository));
    Get.put(ResetPassword(repository));
  });

  tearDown(() => Get.reset());

  const questionData = [
    {
      'id': '1b6e2beb-0985-46b6-b8ec-038d45bdf235',
      'question': 'What city were you born in?',
    },
    {
      'id': '0f3f550d-6e25-48a7-8fbc-1301634035d5',
      'question': 'What was the name of your first teacher?',
    },
    {
      'id': '3c1f880a-9d32-45e6-a812-123456789abc',
      'question': 'What was your childhood nickname?',
    },
  ];

  test(
    'Security questions are fetched from the public GET endpoint and parsed from data',
    () async {
      adapter.respond = (_) => _json({'success': true, 'data': questionData});
      final result = await Get.find<GetSecurityQuestions>()(const NoParams());
      expect(
        result.valueOrNull?.map((q) => q.id),
        questionData.map((q) => q['id']),
      );
      expect(
        result.valueOrNull?.first.question,
        questionData.first['question'],
      );
      final request = adapter.requests.single;
      expect(
        request.uri.toString(),
        '${AppConstants.authBaseUrl}/password/security-questions',
      );
      expect(request.method, 'GET');
      expect(request.data, isNull);
      expect(request.headers.containsKey('Authorization'), isFalse);
    },
  );

  test('Unavailable and malformed question lists remain failures', () async {
    for (final data in [
      null,
      [],
      {},
      [
        {'question': 'Missing id'},
      ],
      [questionData.first, questionData.first],
    ]) {
      adapter.respond = (_) => _json({'success': true, 'data': data});
      expect((await repository.getSecurityQuestions()).isErr, isTrue);
    }
    adapter.respond = (_) =>
        _json({'Success': false, 'Message': 'Questions unavailable'}, 503);
    expect(
      (await repository.getSecurityQuestions()).failureOrNull?.message,
      'Questions unavailable',
    );
  });

  test(
    'Security verification validates rows and uses account with questionId/answer pairs',
    () async {
      final verify = Get.find<VerifySecurityAnswers>();
      final answers = [
        SecurityAnswer(
          questionId: questionData[0]['id']!,
          answer: ' Phnom Penh ',
        ),
        SecurityAnswer(questionId: questionData[1]['id']!, answer: ' Teacher '),
        SecurityAnswer(
          questionId: questionData[2]['id']!,
          answer: ' Nickname ',
        ),
      ];
      for (final params in [
        VerifySecurityAnswersParams(account: '', answers: answers),
        const VerifySecurityAnswersParams(account: 'someone', answers: []),
        VerifySecurityAnswersParams(account: 'someone', answers: [answers[0]]),
        VerifySecurityAnswersParams(
          account: 'someone',
          answers: [answers[0], answers[1]],
        ),
        VerifySecurityAnswersParams(
          account: 'someone',
          answers: [
            answers[0],
            answers[1],
            const SecurityAnswer(questionId: '', answer: 'Answer'),
          ],
        ),
        VerifySecurityAnswersParams(
          account: 'someone',
          answers: [
            answers[0],
            answers[1],
            const SecurityAnswer(questionId: 'id', answer: ' '),
          ],
        ),
        VerifySecurityAnswersParams(
          account: 'someone',
          answers: [answers[0], answers[0], answers[1]],
        ),
      ]) {
        expect((await verify(params)).failureOrNull, isA<ValidationFailure>());
      }
      expect(adapter.requests, isEmpty);
      adapter.respond = (_) => _json({
        'Success': true,
        'Data': {'ResetToken': 'security-proof'},
      });
      expect(
        (await verify(
          VerifySecurityAnswersParams(account: ' someone ', answers: answers),
        )).valueOrNull,
        'security-proof',
      );
      final request = adapter.requests.single;
      expect(request.uri.path, '/api/auth/password/verify-security');
      expect(request.method, 'POST');
      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(request.data, {
        'account': 'someone',
        'answers': [
          {'questionId': answers[0].questionId, 'answer': ' Phnom Penh '},
          {'questionId': answers[1].questionId, 'answer': ' Teacher '},
          {'questionId': answers[2].questionId, 'answer': ' Nickname '},
        ],
      });
      expect(session.cleared, isFalse);
    },
  );

  test(
    'Rejected security answers and missing reset tokens cannot unlock reset',
    () async {
      final answers = [
        SecurityAnswer(questionId: questionData.first['id']!, answer: 'Wrong'),
      ];
      adapter.respond = (_) => _json({
        'Success': false,
        'Message': 'Security verification failed',
        'Data': null,
      }, 500);
      expect(
        (await repository.verifySecurityAnswers(
          'someone',
          answers,
        )).failureOrNull?.message,
        'Security verification failed',
      );
      adapter.respond = (_) => _json({'success': true, 'data': null});
      expect(
        (await repository.verifySecurityAnswers('someone', answers)).isErr,
        isTrue,
      );
      expect(adapter.requests, hasLength(2));
      expect(session.token.value, 'existing-session');
    },
  );

  test(
    'Recovery sends a trimmed account, supports email/username/phone, and is public',
    () async {
      for (final account in [
        'someone@example.com',
        'someone',
        '+85512345678',
      ]) {
        expect((await Get.find<ForgotPassword>()('  $account  ')).isOk, isTrue);
        final request = adapter.requests.last;
        expect(
          request.uri.toString(),
          '${AppConstants.authBaseUrl}/password/forgot',
        );
        expect(request.method, 'POST');
        expect(request.data, {'account': account});
        expect(request.headers.containsKey('Authorization'), isFalse);
        expect(request.extra['requiresAuth'], isFalse);
      }
      expect(
        (await Get.find<ForgotPassword>()(' ')).failureOrNull,
        isA<ValidationFailure>(),
      );
      expect(adapter.requests, hasLength(3));
    },
  );

  test(
    'HTTP 200 failure and malformed responses never report success',
    () async {
      for (final body in [
        {'success': false, 'message': 'Please try again later.'},
        {'message': 'Missing success marker'},
        '<html>Proxy page</html>',
        null,
      ]) {
        adapter.respond = (_) => _json(body);
        expect((await repository.forgotPassword('someone')).isErr, isTrue);
      }
      expect(session.cleared, isFalse);
    },
  );

  test(
    'Recovery errors do not refresh or clear the signed-in session',
    () async {
      for (final status in [400, 401, 404, 429, 500]) {
        adapter.requests.clear();
        adapter.respond = (_) =>
            _json({'success': false, 'message': 'Recovery rejected'}, status);
        final result = await repository.forgotPassword('someone');
        expect(result.failureOrNull?.message, 'Recovery rejected');
        expect(adapter.requests, hasLength(1));
        expect(session.token.value, 'existing-session');
      }
      adapter.respond = (request) => throw dio.DioException(
        requestOptions: request,
        type: dio.DioExceptionType.receiveTimeout,
      );
      expect(
        (await repository.forgotPassword('someone')).failureOrNull,
        isA<NetworkFailure>(),
      );
    },
  );

  test(
    'OTP verification needs an explicit reset token and sends the documented body',
    () async {
      adapter.respond = (_) => _json({
        'success': true,
        'data': {'resetToken': 'reset-proof'},
      });
      final result = await Get.find<VerifyPasswordOtp>()(
        const VerifyPasswordOtpParams(account: ' someone ', otp: ' 012345 '),
      );
      expect(result.valueOrNull, 'reset-proof');
      expect(adapter.requests.single.uri.path, '/api/auth/password/verify-otp');
      expect(adapter.requests.single.data, {
        'account': 'someone',
        'otp': '012345',
      });
      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
      for (final data in [
        null,
        {'resetToken': ''},
        {'token': 'session-token'},
      ]) {
        adapter.respond = (_) => _json({'success': true, 'data': data});
        expect(
          (await repository.verifyPasswordOtp('someone', '123456')).isErr,
          isTrue,
        );
      }
      final count = adapter.requests.length;
      expect(
        (await Get.find<VerifyPasswordOtp>()(
          const VerifyPasswordOtpParams(account: 'someone', otp: ' '),
        )).isErr,
        isTrue,
      );
      expect(adapter.requests, hasLength(count));
    },
  );

  test(
    'Google verification sends only the Google ID token and returns reset proof',
    () async {
      adapter.respond = (_) => _json({
        'success': true,
        'data': {'resetToken': 'google-reset-token'},
      });
      final result = await Get.find<VerifyPasswordGoogle>()(
        const VerifyPasswordGoogleParams(idToken: ' google-id-token '),
      );
      expect(result.valueOrNull, 'google-reset-token');
      expect(
        adapter.requests.single.uri.path,
        '/api/auth/password/google/verify',
      );
      expect(adapter.requests.single.data, {'idToken': 'google-id-token'});
    },
  );

  test(
    'Reset validates locally and clears the session only after server success',
    () async {
      final reset = Get.find<ResetPassword>();
      for (final params in [
        const ResetPasswordParams(
          resetToken: '',
          newPassword: 'new-password',
          confirmPassword: 'new-password',
        ),
        const ResetPasswordParams(
          resetToken: 'proof',
          newPassword: 'short',
          confirmPassword: 'short',
        ),
        const ResetPasswordParams(
          resetToken: 'proof',
          newPassword: 'new-password',
          confirmPassword: 'different',
        ),
      ]) {
        expect((await reset(params)).failureOrNull, isA<ValidationFailure>());
      }
      expect(adapter.requests, isEmpty);
      const params = ResetPasswordParams(
        resetToken: 'proof',
        newPassword: ' new-password ',
        confirmPassword: ' new-password ',
      );
      adapter.respond = (_) =>
          _json({'success': false, 'message': 'Reset token expired'}, 400);
      expect((await reset(params)).isErr, isTrue);
      expect(session.cleared, isFalse);
      adapter.respond = (_) => _json({'success': true});
      expect((await reset(params)).isOk, isTrue);
      expect(session.cleared, isTrue);
      final request = adapter.requests.last;
      expect(request.uri.path, '/api/auth/password/reset');
      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(request.data, {
        'resetToken': 'proof',
        'newPassword': ' new-password ',
        'confirmPassword': ' new-password ',
      });
    },
  );

  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        initialRoute: Routes.FORGOT_PASSWORD,
        getPages: [
          GetPage(
            name: Routes.FORGOT_PASSWORD,
            page: () => const ForgotPasswordView(),
          ),
          GetPage(
            name: Routes.LOGIN,
            page: () => const Scaffold(body: Text('Login destination')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, String label) async {
    await tester.pump();
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('Google verification opens password reset without signing in', (
    tester,
  ) async {
    googleIdentity.respond = () async => 'google-id-token';
    adapter.respond = (request) => request.uri.path.endsWith('/google/verify')
        ? _json({
            'success': true,
            'data': {'resetToken': 'google-proof'},
          })
        : _json({'success': true});
    await mount(tester);
    await press(tester, 'Verify with Google');
    expect(find.text('New Password'), findsOneWidget);
    expect(adapter.requests, hasLength(1));
    expect(
      adapter.requests.single.uri.path,
      '/api/auth/password/google/verify',
    );
    expect(adapter.requests.single.data, {'idToken': 'google-id-token'});
    expect(
      adapter.requests.single.headers.containsKey('Authorization'),
      isFalse,
    );
    expect(session.token.value, 'existing-session');
    expect(session.cleared, isFalse);
    expect(Get.currentRoute, Routes.FORGOT_PASSWORD);
    await tester.enterText(find.byType(EditableText).at(0), 'new-password');
    await tester.enterText(find.byType(EditableText).at(1), 'new-password');
    await press(tester, 'Reset Password');
    expect(adapter.requests.last.uri.path, '/api/auth/password/reset');
    expect(adapter.requests.last.data['resetToken'], 'google-proof');
    expect(session.cleared, isTrue);
    expect(find.text('Password changed successfully'), findsOneWidget);
    expect(find.byType(EditableText), findsNothing);
    expect(find.text('Login destination'), findsNothing);
    await press(tester, 'Done');
    expect(find.text('Login destination'), findsOneWidget);
    expect(Get.key.currentState!.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Google cancellation and missing configuration keep recovery usable',
    (tester) async {
      await mount(tester);
      await press(tester, 'Verify with Google');
      expect(adapter.requests, isEmpty);
      expect(find.text('Send Request'), findsOneWidget);
      googleIdentity.respond = () async =>
          throw PlatformException(code: 'google_not_configured');
      await press(tester, 'Verify with Google');
      expect(
        find.text(
          'Google verification is not configured in this version. Please use email verification.',
        ),
        findsOneWidget,
      );
      expect(adapter.requests, isEmpty);
      expect(googleVerification.isLoading.value, isFalse);
      expect(session.token.value, 'existing-session');
    },
  );

  testWidgets(
    'Google verification requires server reset proof and allows retry',
    (tester) async {
      googleIdentity.respond = () async => 'google-id-token';
      adapter.respond = (_) => _json({'success': true});
      await mount(tester);
      await press(tester, 'Verify with Google');
      expect(find.text('New Password'), findsNothing);
      expect(find.text('Verify with Google'), findsOneWidget);
      expect(session.cleared, isFalse);
      adapter.respond = (_) => _json({
        'success': false,
        'message': 'Google verification rejected',
      }, 400);
      await press(tester, 'Verify with Google');
      expect(find.text('Google verification rejected'), findsOneWidget);
      expect(find.text('New Password'), findsNothing);
      adapter.respond = (_) => _json({
        'success': true,
        'data': {'resetToken': 'retry-proof'},
      });
      await press(tester, 'Verify with Google');
      expect(find.text('New Password'), findsOneWidget);
      expect(session.token.value, 'existing-session');
    },
  );

  test(
    'Google verification blocks duplicates and ignores identity after disposal',
    () async {
      final pending = Completer<String?>();
      googleIdentity.respond = () => pending.future;
      final first = googleVerification.verify();
      expect(await googleVerification.verify(), isNull);
      expect(googleIdentity.calls, 1);
      googleVerification.onDelete();
      pending.complete('late-google-id-token');
      expect(await first, isNull);
      expect(adapter.requests, isEmpty);
    },
  );

  test('Google verification ignores server proof after disposal', () async {
    googleIdentity.respond = () async => 'google-id-token';
    final received = Completer<void>();
    final pending = Completer<dio.ResponseBody>();
    adapter.respond = (_) {
      received.complete();
      return pending.future;
    };
    final first = googleVerification.verify();
    await received.future;
    googleVerification.onDelete();
    pending.complete(
      _json({
        'success': true,
        'data': {'resetToken': 'late-proof'},
      }),
    );
    expect(await first, isNull);
    expect(session.token.value, 'existing-session');
  });

  testWidgets('Recovery sends the selected phone country code', (tester) async {
    await mount(tester);
    await tester.enterText(find.byType(EditableText).first, '12345678');
    await tester.pump();
    expect(find.text('+855'), findsOneWidget);
    await press(tester, 'Send Request');
    expect(adapter.requests.single.data, {'account': '+85512345678'});
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Security question loading retries and verified answers continue to password reset',
    (tester) async {
      var loadFails = true;
      var answersFail = true;
      adapter.respond = (request) {
        if (request.method == 'GET') {
          return loadFails
              ? _json({
                  'success': false,
                  'message': 'Questions unavailable',
                }, 503)
              : _json({'success': true, 'data': questionData});
        }
        if (request.uri.path.endsWith('/verify-security')) {
          return answersFail
              ? _json({
                  'success': false,
                  'message': 'Answers do not match',
                }, 400)
              : _json({
                  'success': true,
                  'data': {'resetToken': 'security-proof'},
                });
        }
        return _json({'success': true});
      };
      await mount(tester);
      await press(tester, 'Use Security Questions');
      expect(find.text('Please enter your account.'), findsOneWidget);
      expect(adapter.requests, isEmpty);
      await tester.enterText(
        find.byType(EditableText).first,
        'someone@example.com',
      );
      await press(tester, 'Use Security Questions');
      expect(find.text('Questions unavailable'), findsOneWidget);
      loadFails = false;
      await press(tester, 'Use Security Questions');
      await tester.enterText(find.byType(TextField).at(0), 'Phnom Penh');
      await tester.enterText(find.byType(TextField).at(1), 'Teacher');
      await tester.enterText(find.byType(TextField).at(2), 'Nickname');
      await press(tester, 'Verify Answers');
      expect(find.text('Answers do not match'), findsOneWidget);
      expect(find.text('New Password'), findsNothing);
      expect(adapter.requests.last.data, {
        'account': 'someone@example.com',
        'answers': [
          {'questionId': questionData[0]['id'], 'answer': 'Phnom Penh'},
          {'questionId': questionData[1]['id'], 'answer': 'Teacher'},
          {'questionId': questionData[2]['id'], 'answer': 'Nickname'},
        ],
      });
      answersFail = false;
      await press(tester, 'Verify Answers');
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      await tester.enterText(find.byType(EditableText).at(0), 'new-password');
      await tester.enterText(find.byType(EditableText).at(1), 'new-password');
      await press(tester, 'Reset Password');
      expect(adapter.requests.last.data['resetToken'], 'security-proof');
      expect(session.cleared, isTrue);
      expect(
        adapter.requests.any((r) => r.uri.path.endsWith('/forgot')),
        isFalse,
      );
      expect(find.text('Password changed successfully'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Login destination'), findsOneWidget);
      expect(Get.key.currentState!.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Complete account, OTP, password and sign-in flow with failure retries',
    (tester) async {
      var invalidOtp = true;
      var expiredToken = true;
      adapter.respond = (request) {
        if (request.uri.path.endsWith('verify-otp')) {
          return invalidOtp
              ? _json({'success': false, 'message': 'Code is invalid'}, 400)
              : _json({
                  'success': true,
                  'data': {'resetToken': 'verified-proof'},
                });
        }
        if (request.uri.path.endsWith('/reset') && expiredToken) {
          return _json({
            'success': false,
            'message': 'Reset token expired',
          }, 400);
        }
        return _json({'success': true});
      };
      await mount(tester);
      await tester.enterText(
        find.byType(EditableText).first,
        'someone@example.com',
      );
      await press(tester, 'Send Request');
      expect(find.text('OTP Verification'), findsOneWidget);
      expect(find.text('someone@example.com'), findsOneWidget);
      await tester.enterText(find.byType(EditableText).first, '012345');
      await press(tester, 'Verify OTP');
      expect(find.text('Code is invalid'), findsOneWidget);
      expect(adapter.requests.last.data, {
        'account': 'someone@example.com',
        'otp': '012345',
      });
      expect(find.text('New Password'), findsNothing);
      invalidOtp = false;
      await tester.enterText(find.byType(EditableText).first, '654321');
      await tester.pump();
      expect(find.text('Code is invalid'), findsNothing);
      await press(tester, 'Verify OTP');
      await tester.enterText(find.byType(EditableText).at(0), 'new-password');
      await tester.enterText(find.byType(EditableText).at(1), 'different');
      final beforeReset = adapter.requests.length;
      await press(tester, 'Reset Password');
      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(adapter.requests, hasLength(beforeReset));
      await tester.enterText(find.byType(EditableText).at(1), 'new-password');
      await press(tester, 'Reset Password');
      expect(find.text('Reset token expired'), findsOneWidget);
      expect(find.text('Password changed successfully'), findsNothing);
      expect(session.cleared, isFalse);
      expiredToken = false;
      await press(tester, 'Reset Password');
      expect(session.cleared, isTrue);
      expect(find.byType(TextField), findsNothing);
      expect(adapter.requests.last.data['resetToken'], 'verified-proof');
      expect(find.text('Password changed successfully'), findsOneWidget);
      expect(
        find.text(
          'Your password has been reset. Sign in with your new password.',
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Login destination'), findsNothing);
      await press(tester, 'Done');
      expect(find.text('Login destination'), findsOneWidget);
      expect(Get.key.currentState!.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Request failure allows retry, duplicate submits are blocked and resend has a cooldown',
    (tester) async {
      await mount(tester);
      adapter.respond = (_) =>
          _json({'success': false, 'message': 'Try later'}, 429);
      await tester.enterText(find.byType(EditableText).first, 'someone');
      await press(tester, 'Send Request');
      expect(find.text('Try later'), findsOneWidget);
      final pending = Completer<dio.ResponseBody>();
      adapter.respond = (_) => pending.future;
      await tester.tap(find.text('Send Request'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      expect(adapter.requests, hasLength(2));
      pending.complete(_json({'success': true}));
      await tester.pumpAndSettle();
      expect(find.text('You may resend OTP in 01:00 min'), findsOneWidget);
      await tester.pump(const Duration(seconds: 60));
      await tester.pumpAndSettle();
      adapter.respond = (_) => _json({'success': true});
      await press(tester, 'Resend OTP');
      expect(adapter.requests, hasLength(3));
      expect(adapter.requests.last.data, {'account': 'someone'});
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Send Request'), findsOneWidget);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'someone',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('OTP paste and deletion retain one complete numeric code', (
    tester,
  ) async {
    await mount(tester);
    await tester.enterText(find.byType(EditableText).first, 'someone');
    await press(tester, 'Send Request');
    final input = find.byType(EditableText);
    await tester.enterText(input, '01 23a4567');
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(input).controller.text, '012345');
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );
    await tester.enterText(input, '01234');
    await tester.pumpAndSettle();
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(adapter.requests, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('OTP fits a small screen with large Khmer text and a keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final code = TextEditingController(text: '012345');
    addTearDown(code.dispose);
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          theme: ThemeData(
            brightness: brightness,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF69B4),
              primary: const Color(0xFFFF69B4),
              brightness: brightness,
            ),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              viewInsets: EdgeInsets.only(bottom: 240),
              textScaler: TextScaler.linear(1.8),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: PasswordOtpStep(
              account: 'someone.with.a.long.email@example.com',
              controller: code,
              resendSeconds: 60,
              isSubmitting: false,
              onVerify: () {},
              onResend: () {},
              onBack: () {},
              onCodeChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
