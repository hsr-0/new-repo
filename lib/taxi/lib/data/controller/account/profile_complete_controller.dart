import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/taxi/lib/core/helper/shared_preference_helper.dart';
import 'package:cosmetic_store/taxi/lib/core/helper/string_format_helper.dart';
import 'package:cosmetic_store/taxi/lib/core/route/route_middleware.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_strings.dart';
import 'package:cosmetic_store/taxi/lib/data/model/authorization/authorization_response_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/country_model/country_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/profile/profile_response_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/user_post_model/user_post_model.dart';
import 'package:cosmetic_store/taxi/lib/data/repo/account/profile_repo.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/snack_bar/show_custom_snackbar.dart';

class ProfileCompleteController extends GetxController {
  ProfileRepo profileRepo;
  ProfileCompleteController({required this.profileRepo});

  ProfileResponseModel model = ProfileResponseModel();

  TextEditingController userNameController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileNoController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController zipCodeController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  TextEditingController referController = TextEditingController();

  FocusNode userNameFocusNode = FocusNode();
  FocusNode firstNameFocusNode = FocusNode();
  FocusNode lastNameFocusNode = FocusNode();
  FocusNode emailFocusNode = FocusNode();
  FocusNode mobileNoFocusNode = FocusNode();
  FocusNode addressFocusNode = FocusNode();
  FocusNode stateFocusNode = FocusNode();
  FocusNode zipCodeFocusNode = FocusNode();
  FocusNode cityFocusNode = FocusNode();
  FocusNode countryFocusNode = FocusNode();

  bool isLoading = false;

  Future<void> initialData() async {
    //    await loadProfileInfo();
    countryList = profileRepo.apiClient.getOperatingCountries();
    update();
    if (countryList.isNotEmpty) {
      selectCountryData(countryList.first);
    }
  }

  ProfileResponseModel profileResponseModel = ProfileResponseModel();

  String imageUrl = '';

  File? imageFile;
  String emailData = '';
  String countryData = '';
  String countryCodeData = '';
  String phoneCodeData = '';
  String phoneData = '';

  String loginType = '';

  Future<void> loadProfileInfo() async {
    isLoading = true;
    update();
    try {
      profileResponseModel = await profileRepo.loadProfileInfo();
      if (profileResponseModel.data != null && profileResponseModel.status?.toLowerCase() == MyStrings.success.toLowerCase()) {
        emailData = profileResponseModel.data?.user?.email ?? '';
        countryData = profileResponseModel.data?.user?.country ?? '';
        countryCodeData = profileResponseModel.data?.user?.countryCode ?? '';
        phoneData = profileResponseModel.data?.user?.mobile ?? '';
        loginType = profileResponseModel.data?.user?.loginBy ?? '';
      } else {
        isLoading = false;
        update();
      }
    } catch (e) {
      isLoading = false;
      update();
    }
    isLoading = false;
    update();
  }

  TextEditingController searchCountryController = TextEditingController();
  bool countryLoading = true;
  List<Countries> countryList = [];
  List<Countries> filteredCountries = [];

  Countries selectedCountryData = Countries();
  void selectCountryData(Countries value) {
    selectedCountryData = value;
    update();
  }

  bool submitLoading = false;
  Future<void> updateProfile() async {
    String firstName = firstNameController.text;
    String lastName = lastNameController.text.toString();
    String address = addressController.text.toString();
    String city = cityController.text.toString();
    String zip = zipCodeController.text.toString();
    String state = stateController.text.toString();

    // 🔥 1. معالجة رقم الهاتف (حذف الصفر من البداية إذا كتبه الزبون)
    String cleanMobile = mobileNoController.text.trim();
    if (cleanMobile.startsWith('0')) {
      cleanMobile = cleanMobile.substring(1);
    }

    // 🔥 2. فلتر اسم المستخدم الذكي (لإرضاء سيرفر Laravel بالقوة!)
    String currentUsername = userNameController.text.trim().toLowerCase();

    // شروط السيرفر: أحرف إنجليزية صغيرة وأرقام فقط، لا مسافات، لا رموز، طوله 6 فما فوق
    bool isValidUsername = RegExp(r'^[a-z0-9]{6,}$').hasMatch(currentUsername);

    if (!isValidUsername) {
      // استخراج الأحرف الإنجليزية فقط من اسم الزبون
      String safeBaseName = firstName.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (safeBaseName.isEmpty) {
        safeBaseName = 'user'; // إذا كان اسمه بالعربي، نضع كلمة user
      }

      // إضافة 5 أرقام تعتمد على الوقت بالملي ثانية لضمان عدم التكرار
      String timeDigits = (DateTime.now().millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');

      // دمج الاسم مع الأرقام (بدون شرطة سفلية _ لأن السيرفر يرفضها أحياناً)
      currentUsername = '$safeBaseName$timeDigits';

      // تحديث الحقل مخفياً
      userNameController.text = currentUsername;
    }

    submitLoading = true;
    update();

    UserPostModel model = UserPostModel(
      image: null,
      firstname: firstName,
      lastName: lastName,

      // ✅ نرسل الرقم والاسم بعد التنظيف والفلترة
      mobile: cleanMobile,
      username: currentUsername,
      email: '', // يمكن تركه فارغاً إذا لم يكن مطلوباً

      // ✅ التعديل: تثبيت بيانات العراق هنا أيضاً لمنع الأخطاء
      countryCode: 'IQ',
      country: 'Iraq',
      mobileCode: '964',

      address: address,
      state: state,
      zip: zip,
      city: city,
      refer: referController.text,
    );

    AuthorizationResponseModel responseModel = await profileRepo.updateProfile(model, false);

    if (responseModel.status == "success") {
      await profileRepo.apiClient.sharedPreferences.setString(
        SharedPreferenceHelper.userFullNameKey,
        '$firstName $lastName',
      );
      CustomSnackBar.success(successList: responseModel.message ?? [MyStrings.requestSuccess]);
      RouteMiddleware.checkNGotoNext(user: responseModel.data?.user);
    } else {
      CustomSnackBar.error(errorList: responseModel.message ?? [MyStrings.somethingWentWrong]);
    }

    submitLoading = false;
    update();
  }
}