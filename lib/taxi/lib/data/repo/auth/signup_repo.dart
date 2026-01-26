import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cosmetic_store/taxi/lib/core/helper/shared_preference_helper.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/method.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/url_container.dart';
import 'package:cosmetic_store/taxi/lib/data/model/auth/sign_up_model/registration_response_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/auth/sign_up_model/sign_up_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/global/response_model/response_model.dart';
import 'package:cosmetic_store/taxi/lib/data/services/api_client.dart';

class RegistrationRepo {
  ApiClient apiClient;

  RegistrationRepo({required this.apiClient});

  Future<RegistrationResponseModel> registerUser(SignUpModel model) async {
    // 1. التحقق من صحة رقم الهاتف محلياً
    String phone = model.mobile?.trim() ?? '';
    RegExp iraqiPhoneRegex = RegExp(r'^(077|078)\d{8}$');

    if (!iraqiPhoneRegex.hasMatch(phone)) {
      print("❌ رقم الهاتف غير صحيح");
      return RegistrationResponseModel(
        status: 'error',
        message: ['رقم الهاتف يجب أن يتكون من 11 رقم ويبدأ بـ 077 أو 078'],
        data: null,
      );
    }

    // 2. تجهيز البيانات
    final map = modelToMap(model);
    String url = '${UrlContainer.baseUrl}${UrlContainer.registrationEndPoint}';

    print("🔥 Sending Registration Map: $map");

    final res = await apiClient.request(
      url,
      Method.postMethod,
      map,
      passHeader: true,
      isOnlyAcceptType: true,
    );

    // 🛑 3. المعالجة الآمنة للرد (لمنع الانهيار)
    dynamic responseData = res.responseJson;

    // إذا كان الرد فارغاً أو null
    if (responseData == null || (responseData is String && responseData.isEmpty)) {
      print("⚠️ Server returned empty response");
      return RegistrationResponseModel(
        status: 'error',
        message: ['لم يتم استلام رد من السيرفر (Empty Response)'],
      );
    }

    // محاولة تحويل النص إلى JSON إذا لزم الأمر
    if (responseData is String) {
      try {
        responseData = jsonDecode(responseData);
      } catch (e) {
        print("⚠️ Error decoding JSON: $e");
        // في حال فشل التحويل، نعيد رسالة خطأ بدلاً من الانهيار
        return RegistrationResponseModel(
          status: 'error',
          message: ['حدث خطأ في معالجة البيانات من السيرفر'],
        );
      }
    }

    // التأكد النهائي أن البيانات هي Map قبل تمريرها
    if (responseData is! Map<String, dynamic>) {
      print("⚠️ Invalid Data Type: ${responseData.runtimeType}");
      return RegistrationResponseModel(
        status: 'error',
        message: ['صيغة البيانات غير صحيحة'],
      );
    }

    // الآن أصبح آمناً التحويل للموديل
    try {
      return RegistrationResponseModel.fromJson(responseData);
    } catch (e) {
      print("⚠️ Error parsing Model: $e");
      return RegistrationResponseModel(
        status: 'error',
        message: ['خطأ في قراءة البيانات'],
      );
    }
  }

  // ... (بقية الدوال modelToMap وغيرها تبقى كما هي في الكود السابق)

  Map<String, dynamic> modelToMap(SignUpModel model) {
    Map<String, dynamic> bodyFields = {
      'firstname': model.fName,
      'lastname': model.lName,
      'email': model.email,
      'agree': model.agree.toString() == 'true' ? 'true' : '',
      'password': model.password,
      'password_confirmation': model.password,
      'mobile': model.mobile,
      'country_code': '964',
      'mobile_code': '964',
      'country': 'Iraq',
    };

    if (model.referName != null && model.referName!.isNotEmpty) {
      bodyFields['refer_name'] = model.referName;
    }

    return bodyFields;
  }

  // يرجى نسخ باقي الدوال (getCountryList, sendUserToken, ...) من الكود السابق إذا لم تكن موجودة هنا
  // ...

  Future<dynamic> getCountryList() async {
    String url = '${UrlContainer.baseUrl}${UrlContainer.countryEndPoint}';
    ResponseModel model = await apiClient.request(url, Method.getMethod, null);
    return model;
  }

  Future<bool> sendUserToken() async {
    String deviceToken;
    if (apiClient.sharedPreferences.containsKey(
      SharedPreferenceHelper.fcmDeviceKey,
    )) {
      deviceToken = apiClient.sharedPreferences.getString(
        SharedPreferenceHelper.fcmDeviceKey,
      ) ??
          '';
    } else {
      deviceToken = '';
    }

    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    bool success = false;
    if (deviceToken.isEmpty) {
      firebaseMessaging.getToken().then((fcmDeviceToken) async {
        success = await sendUpdatedToken(fcmDeviceToken ?? '');
      });
    } else {
      firebaseMessaging.onTokenRefresh.listen((fcmDeviceToken) async {
        if (deviceToken == fcmDeviceToken) {
          success = true;
        } else {
          apiClient.sharedPreferences.setString(
            SharedPreferenceHelper.fcmDeviceKey,
            fcmDeviceToken,
          );
          success = await sendUpdatedToken(fcmDeviceToken);
        }
      });
    }
    return success;
  }

  Future<bool> sendUpdatedToken(String deviceToken) async {
    String url = '${UrlContainer.baseUrl}${UrlContainer.deviceTokenEndPoint}';
    Map<String, String> map = deviceTokenMap(deviceToken);

    await apiClient.request(url, Method.postMethod, map, passHeader: true);
    return true;
  }

  Map<String, String> deviceTokenMap(String deviceToken) {
    Map<String, String> map = {'token': deviceToken.toString()};
    return map;
  }

  Future<ResponseModel> socialLoginUser({
    String accessToken = '',
    String? provider,
  }) async {
    Map<String, String>? map;

    if (provider == 'google') {
      map = {'token': accessToken, 'provider': "google"};
    }

    String url = '${UrlContainer.baseUrl}${UrlContainer.socialLoginEndPoint}';

    ResponseModel model = await apiClient.request(
      url,
      Method.postMethod,
      map,
      passHeader: false,
    );

    return model;
  }
}