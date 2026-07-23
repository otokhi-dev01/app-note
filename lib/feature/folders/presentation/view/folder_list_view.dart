import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/presentation/widgets/app_ambient_orb.dart';
import '../../../main/presentation/controller/main_navigation_controller.dart';
import '../../../notes/presentation/controllers/home_controller.dart';
import '../../domain/entities/folder_entity.dart';

part 'folder_action_sheet_label.dart';
part 'folder_ambient_background.dart';
part 'folder_count_badge.dart';
part 'folder_footer.dart';
part 'folder_glass_card.dart';
part 'folder_glass_navigation_button.dart';
part 'folder_glass_search_field.dart';
part 'folder_glass_surface.dart';
part 'folder_library_action_tile.dart';
part 'folder_library_overview.dart';
part 'folder_list_content.dart';
part 'folder_loading_state.dart';
part 'folder_navigation_actions.dart';
part 'folder_section_header.dart';
part 'folder_sort_action.dart';
part 'folder_status_view.dart';
part 'folder_system_section.dart';
part 'folder_tags_section.dart';

enum _FolderSort { newest, oldest, name, noteCount }

class FolderListView extends GetView<HomeController> {
  const FolderListView({super.key});

  @override
  Widget build(BuildContext context) {
    return _FolderListContent(controller: controller);
  }
}
