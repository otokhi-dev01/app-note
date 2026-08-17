import 'package:Note/core/error/result.dart';

/// A single application operation.
///
/// Use cases are the only thing controllers call. Each one is a class with a
/// `call()`, so a controller reads as a list of intents:
///
/// ```dart
/// final result = await _getNotes(GetNotesParams(folderId: 3));
/// ```
abstract class UseCase<Type, Params> {
  const UseCase();

  Future<Result<Type>> call(Params params);
}

/// A use case that is pure and synchronous — no I/O, just a domain rule.
/// [BuildFolderHierarchy] is the example: a list in, a tree out.
abstract class SyncUseCase<Type, Params> {
  const SyncUseCase();

  Result<Type> call(Params params);
}

/// Parameter object for use cases that take no input.
class NoParams {
  const NoParams();
}
