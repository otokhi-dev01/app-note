import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'note_list_controller.dart';
import '../../app/theme/colors.dart';
import '../../app/routes/app_routes.dart';
import '../../core/widgets/note_card.dart';
import '../../core/widgets/custom_app_bar.dart';

class PinnedNotesView extends StatefulWidget {
  const PinnedNotesView({super.key});

  @override
  State<PinnedNotesView> createState() => _PinnedNotesViewState();
}

class _PinnedNotesViewState extends State<PinnedNotesView> with AutomaticKeepAliveClientMixin {
  final controller = Get.find<NoteListController>();

  @override
  void initState() {
    super.initState();
    controller.fetchPinnedNotes();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    return Scaffold(
      appBar: CustomGlassAppBar(
        titleText: 'Pinned Notes',
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded, weight: 800)),
          const SizedBox(width: 16),
        ],  bottom: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: SizedBox(),)
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.fetchPinnedNotes(),
        child: Obx(() {
          if (controller.isLoading.value && controller.notes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.notes.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.push_pin_outlined, size: 64, color: AppColors.textPlaceholder.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text('No Pinned Notes', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            key: const ValueKey('pinned_notes_list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            itemCount: controller.notes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final note = controller.notes[index];
              return NoteCard(
                note: note,
                isPinned: true,
                isFullWidth: true,
                onTap: () => Get.toNamed(AppRoutes.noteEditor, arguments: note.id),
              );
            },
          );
        }),
      ),
    );
  }
}
