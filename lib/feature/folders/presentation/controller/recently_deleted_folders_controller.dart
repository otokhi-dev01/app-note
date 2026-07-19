import 'package:get/get.dart';

import '../../../notes/presentation/controllers/home_controller.dart';
import '../../domain/entities/folder_entity.dart';

class RecentlyDeletedFoldersController
    extends GetxController {
  final HomeController homeController;

  RecentlyDeletedFoldersController({
    required this.homeController,
  });

  final RxBool isRefreshing = false.obs;

  final RxnInt restoringFolderId =
  RxnInt();

  final RxString errorMessage = ''.obs;

  List<FolderEntity> get deletedFolders {
    final List<FolderEntity> snapshot =
    homeController.deletedFolders.toList(
      growable: false,
    );

    snapshot.sort(
          (
          FolderEntity first,
          FolderEntity second,
          ) {
        final DateTime? firstDeletedAt =
            first.deletedAt;

        final DateTime? secondDeletedAt =
            second.deletedAt;

        if (firstDeletedAt == null &&
            secondDeletedAt == null) {
          return second.id.compareTo(first.id);
        }

        if (firstDeletedAt == null) {
          return 1;
        }

        if (secondDeletedAt == null) {
          return -1;
        }

        return secondDeletedAt.compareTo(
          firstDeletedAt,
        );
      },
    );

    return snapshot;
  }

  int get deletedFolderCount {
    return homeController.deletedFolders.length;
  }

  bool get isEmpty {
    return deletedFolderCount == 0;
  }

  bool isRestoring(int folderId) {
    return restoringFolderId.value ==
        folderId;
  }

  @override
  void onReady() {
    super.onReady();

    refreshFolders();
  }

  Future<void> refreshFolders() async {
    if (isRefreshing.value) {
      return;
    }

    try {
      isRefreshing.value = true;
      errorMessage.value = '';

      await homeController.loadFolders();
    } catch (error) {
      errorMessage.value =
          _cleanError(error);
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<bool> restoreFolder(
      FolderEntity folder,
      ) async {
    if (restoringFolderId.value != null) {
      return false;
    }

    try {
      restoringFolderId.value =
          folder.id;

      errorMessage.value = '';

      return await homeController
          .deleteOrRestoreFolder(
        folderId: folder.id,
        isDelete: false,
      );
    } catch (error) {
      errorMessage.value =
          _cleanError(error);

      return false;
    } finally {
      restoringFolderId.value = null;
    }
  }

  String deletedDateText(
      FolderEntity folder,
      ) {
    final DateTime? deletedAt =
        folder.deletedAt;

    if (deletedAt == null) {
      return 'Recently deleted';
    }

    final DateTime now =
    DateTime.now();

    final Duration difference =
    now.difference(deletedAt);

    if (difference.isNegative) {
      return _formatDate(deletedAt);
    }

    if (difference.inMinutes < 1) {
      return 'Deleted just now';
    }

    if (difference.inHours < 1) {
      final int minutes =
          difference.inMinutes;

      return 'Deleted $minutes '
          '${minutes == 1 ? 'minute' : 'minutes'} ago';
    }

    if (difference.inDays < 1) {
      final int hours =
          difference.inHours;

      return 'Deleted $hours '
          '${hours == 1 ? 'hour' : 'hours'} ago';
    }

    if (difference.inDays < 7) {
      final int days =
          difference.inDays;

      return 'Deleted $days '
          '${days == 1 ? 'day' : 'days'} ago';
    }

    return 'Deleted ${_formatDate(deletedAt)}';
  }

  String _formatDate(
      DateTime date,
      ) {
    final String day =
    date.day.toString().padLeft(
      2,
      '0',
    );

    final String month =
    date.month.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/${date.year}';
  }

  String _cleanError(
      Object error,
      ) {
    return error
        .toString()
        .replaceFirst(
      'ApiException: ',
      '',
    )
        .replaceFirst(
      'Exception: ',
      '',
    )
        .trim();
  }
}