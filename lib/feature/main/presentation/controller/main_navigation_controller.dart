import 'package:get/get.dart';

class MainNavigationController
    extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void changeTab(int index) {
    if (index < 0 || index > 3) {
      return;
    }

    selectedIndex.value = index;
  }

  bool isSelected(int index) {
    return selectedIndex.value == index;
  }
}