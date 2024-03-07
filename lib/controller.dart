import 'package:get/get.dart';
class Controller extends GetxController {
  static Controller get to => Get.find();

  RxBool isLogin = true.obs;
  RxString hubName = "".obs;

}