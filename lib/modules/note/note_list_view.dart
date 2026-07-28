import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'note_list_controller.dart';
import '../../app/theme/colors.dart';
import '../../app/routes/app_routes.dart';
import '../../core/widgets/note_card.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../../core/widgets/custom_app_bar.dart';

class NoteListView extends StatefulWidget {
  const NoteListView({super.key});

  @override
  State<NoteListView> createState() => _NoteListViewState();
}

class _NoteListViewState extends State<NoteListView> with AutomaticKeepAliveClientMixin {
  final controller = Get.isRegistered<NoteListController>() 
      ? Get.find<NoteListController>() 
      : Get.put(NoteListController());

  @override
  void initState() {
    super.initState();
    controller.fetchAllNotes();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: const CustomGlassAppBar(
        titleText: 'All Notes',
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: LiquidGlassContainer(
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              opacity: 0.6,
              child: TextField(
                onChanged: controller.searchNotes,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Search all notes...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : AppColors.textPlaceholder,
                    fontWeight: FontWeight.bold,
                  ),
                  prefixIcon: Icon(
                    Icons.search, 
                    size: 22, 
                    color: isDark ? Colors.white38 : AppColors.textPlaceholder,
                    weight: 800,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => controller.fetchAllNotes(),
              child: Obx(() {
                if (controller.isLoading.value && controller.notes.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (controller.notes.isEmpty) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note_alt_outlined, size: 64, color: AppColors.textPlaceholder.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            const Text('No Notes Found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  itemCount: controller.notes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final note = controller.notes[index];
                    return NoteCard(
                      note: note,
                      isFullWidth: true,
                      onTap: () => Get.toNamed(AppRoutes.noteEditor, arguments: note.id),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.noteEditor),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
