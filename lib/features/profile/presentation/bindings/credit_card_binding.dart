import 'package:get/get.dart';
import 'package:Note/features/profile/presentation/controllers/credit_card_controller.dart';

class CreditCardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CreditCardController());
  }
}
