import 'package:flutter/foundation.dart';

import 'package:Note/core/error/exceptions.dart';
import 'package:Note/core/error/failures.dart';
import 'package:Note/core/error/result.dart';

/// Runs a datasource call and converts anything it throws into a [Result].
///
/// This is the single place where data-layer exceptions become domain
/// failures, so repository implementations read as one line per operation:
///
/// ```dart
/// @override
/// Future<Result<Note>> getNoteDetail(int id) =>
///     guard(() => _remote.getNoteDetail(id));
/// ```
Future<Result<T>> guard<T>(Future<T> Function() body) async {
  try {
    return Ok(await body());
  } on UnsupportedFeatureException catch (e) {
    return Err(UnsupportedFeatureFailure(e.message));
  } on UnauthorizedException catch (e) {
    return Err(UnauthorizedFailure(e.message));
  } on NetworkException catch (e) {
    return Err(NetworkFailure(e.message));
  } on ServerException catch (e) {
    return Err(ServerFailure(e.message, statusCode: e.statusCode));
  } catch (e, s) {
    if (kDebugMode) {
      debugPrint('[GUARD] unclassified error: $e');
      debugPrintStack(stackTrace: s);
    }
    return const Err(UnknownFailure());
  }
}
