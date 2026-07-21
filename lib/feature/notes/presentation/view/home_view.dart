import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../widgets/home/home_bottom_bar_widget.dart';
import '../widgets/home/home_content_widget.dart';
import '../widgets/home/home_folder_strip_widget.dart';
import '../widgets/home/home_header_widget.dart';
import '../widgets/home/home_overlays.dart';
import '../widgets/home/liquid_background_widget.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(child: LiquidBackground()),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: HomeHeader(
                    onOpenFolders: () {
                      HomeOverlays.showFolderSheet(
                        context: context,
                        controller: controller,
                      );
                    },
                    onOpenMenu: () {
                      HomeOverlays.showAccountSheet(
                        context: context,
                        controller: controller,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                HomeFolderStrip(
                  onCreateFolder: () {
                    HomeOverlays.showCreateFolder(
                      context: context,
                      controller: controller,
                    );
                  },
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: HomeContent(
                    onCreateFolder: () {
                      HomeOverlays.showCreateFolder(
                        context: context,
                        controller: controller,
                      );
                    },
                    onCreateNote: () {
                      HomeOverlays.showCreateNote(
                        context: context,
                        controller: controller,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: HomeBottomBar(
                onCreateNote: () {
                  HomeOverlays.showCreateNote(
                    context: context,
                    controller: controller,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
