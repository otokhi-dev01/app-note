import 'package:Note/core/error/guard.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/features/search/data/datasources/user_search_remote_data_source.dart';
import 'package:Note/features/search/domain/entities/search_user.dart';
import 'package:Note/features/search/domain/repositories/user_search_repository.dart';

class UserSearchRepositoryImpl implements UserSearchRepository {
  final UserSearchRemoteDataSource _remote;

  const UserSearchRepositoryImpl(this._remote);

  @override
  Future<Result<List<SearchUser>>> search(String keyword) =>
      guard(() => _remote.search(keyword));
}
