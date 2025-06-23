import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/data_file.dart';
import '../models/model_country.dart';

class IntroController extends GetxController {
  // ignore: prefer_typing_uninitialized_variables
  var pageController;
  ValueNotifier selectedPage = ValueNotifier(0);
  RxInt select = 0.obs;

  change(RxInt index) {
    select.value = index.value;
    update();
  }

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    pageController = PageController();
  }

  @override
  void onClose() {
    // TODO: implement onClose
    super.onClose();
    pageController.disclose;
  }
}

class LoginController extends GetxController {
  RxBool show = true.obs;

  isShow() {
    show.value = show.value ? false : true;
    update();
  }
}

class ResetController extends GetxController {
  RxBool isOld = true.obs;
  RxBool isNew = true.obs;
  RxBool isConf = true.obs;

  isChangeOld() {
    isOld.value = isOld.value ? false : true;
    update();
  }

  isChangeNew() {
    isNew.value = isNew.value ? false : true;
    update();
  }

  isChangeConf() {
    isConf.value = isConf.value ? false : true;
    update();
  }
}

class SignupController extends GetxController {
  RxBool show = true.obs;
  RxBool agreeTerm = false.obs;

  isShow() {
    show.value = show.value ? false : true;
    update();
  }

  isAgree() {
    agreeTerm.value = agreeTerm.value ? false : true;
    update();
  }
}

class ForgotController extends GetxController {
  var searchController;
  RxString image = "flag.png".obs;
  RxString code = "+1".obs;
  RxBool check = false.obs;
  List<ModelCountry> newCountryLists = DataFile.countryList;

  onItemChanged(String value) {
    newCountryLists = DataFile.countryList
        .where((string) =>
            string.name!.toLowerCase().contains(value.toLowerCase()))
        .toList();
    update();
  }

  getImage(String value, String value1) {
    image.value = value;
    code.value = value1;
    update();
  }

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    searchController = TextEditingController();
  }

  @override
  void onClose() {
    // TODO: implement onClose
    super.onClose();
    searchController.disclose;
  }
}

class BottomItemSelectionController extends GetxController {
  var bottomBarSelectedItem = 0.obs;

  changePos(int pos) {
    bottomBarSelectedItem.value = pos;
  }
}
