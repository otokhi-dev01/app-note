import 'dart:async';

import 'package:Note/core/error/failures.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/storage/session_storage.dart';

/// Serializes cache mutations and binds every awaited operation to its account.
class AccountOperationQueue {
  AccountOperationQueue(this.session);

  final SessionStorage session;
  Future<void> _tail = Future.value();

  void check() {
    final scope = Zone.current[this] as ({String owner, int revision})?;
    if (scope != null &&
        (session.user.value?.id != scope.owner ||
            session.accountRevision != scope.revision ||
            !session.isLoggedIn)) {
      throw const _AccountChanged();
    }
  }

  Future<Result<T>> run<T>(Future<Result<T>> Function() action) async {
    try {
      if (Zone.current[this] != null) {
        check();
        return await action();
      }
      final owner = session.user.value?.id;
      if (owner == null || owner.isEmpty || !session.isLoggedIn) {
        return const Err(UnauthorizedFailure());
      }
      final scope = (owner: owner, revision: session.accountRevision);
      final previous = _tail;
      final finished = Completer<void>();
      _tail = finished.future;
      await previous;
      try {
        return await runZoned(() async {
          check();
          final result = await action();
          check();
          return result;
        }, zoneValues: {this: scope});
      } finally {
        finished.complete();
      }
    } on _AccountChanged {
      return const Err(
        UnauthorizedFailure('The account changed. Please retry.'),
      );
    }
  }
}

class _AccountChanged implements Exception {
  const _AccountChanged();
}
