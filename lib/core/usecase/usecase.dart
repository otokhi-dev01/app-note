import 'package:Note/core/error/result.dart';

/// A single application operation.
///
/// Use cases are the only thing controllers call. Each one is a class with a
/// `call()`, so a controller reads as a list of intents:
///
/// ```dart
/// final result = await _getNotes(GetNotesParams(folderId: 3));
/// ```
abstract class UseCase<T, Params> {
  const UseCase();

  Future<Result<T>> call(Params params);
}

/// A use case that is pure and synchronous — no I/O, just a domain rule.
/// [BuildFolderHierarchy] is the example: a list in, a tree out.
abstract class SyncUseCase<T, Params> {
  const SyncUseCase();

  Result<T> call(Params params);
}

/// Parameter object for use cases that take no input.
class NoParams {
  const NoParams();
}
