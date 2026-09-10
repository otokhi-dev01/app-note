import 'package:Note/core/error/result.dart';
import 'package:Note/features/search/domain/entities/search_user.dart';

abstract class UserSearchRepository {
  Future<Result<List<SearchUser>>> search(String keyword);
}
