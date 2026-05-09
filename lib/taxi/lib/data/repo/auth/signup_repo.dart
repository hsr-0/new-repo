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
    // 🔥 1. فلترة وتنظيف رقم الهاتف الذكية
    String phone = model.mobile?.trim() ?? '';

    // مسح أي مسافات، علامة الزائد، أو شرطات
    phone = phone.replaceAll(RegExp(r'[\s\-\+]'), '');

    // إذا كتب الزبون 964 في البداية، نحذفها ونضع بدلها 0
    if (phone.startsWith('964')) {
      phone = '0${phone.substring(3)}';
    }
    // إذا كتب الزبون الرقم بدون صفر (مثل 7854076931)، نضيف له الصفر
    else if (phone.startsWith('7') && phone.length == 10) {
      phone = '0$phone';
    }

    // 🇮🇶 2. فحص الرقم العراقي الشامل
    RegExp iraqiPhoneRegex = RegExp(r'^0(75|77|78|79)[0-9]{8}$');

    if (!iraqiPhoneRegex.hasMatch(phone)) {
      print("❌ رقم الهاتف المرفوض هو: '$phone'");
      return RegistrationResponseModel(
        status: 'error',
        message: ['الرجاء إدخال رقم عراقي صحيح (مثال: 078XXXXXXX)'],
        data: null,
      );
    }

    // ✅ 3. بدلاً من محاولة تغيير الموديل (الذي يسبب الخطأ)، نمرر الرقم المنظف مباشرة للدالة
    final map = modelToMap(model, phone);

    String url = '${UrlContainer.baseUrl}${UrlContainer.registrationEndPoint}';

    print("🔥 Sending Registration Map: $map");

    final res = await apiClient.request(
      url,
      Method.postMethod,
      map,
      passHeader: true,
      isOnlyAcceptType: true,
    );

    // 🛑 4. المعالجة الآمنة للرد
    dynamic responseData = res.responseJson;

    if (responseData == null || (responseData is String && responseData.isEmpty)) {
      print("⚠️ Server returned empty response");
      return RegistrationResponseModel(
        status: 'error',
        message: ['لم يتم استلام رد من السيرفر (Empty Response)'],
      );
    }

    if (responseData is String) {
      try {
        responseData = jsonDecode(responseData);
      } catch (e) {
        print("⚠️ Error decoding JSON: $e");
        return RegistrationResponseModel(
          status: 'error',
          message: ['حدث خطأ في معالجة البيانات من السيرفر'],
        );
      }
    }

    if (responseData is! Map<String, dynamic>) {
      print("⚠️ Invalid Data Type: ${responseData.runtimeType}");
      return RegistrationResponseModel(
        status: 'error',
        message: ['صيغة البيانات غير صحيحة'],
      );
    }

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

  // 🔥 تعديل: جعل الدالة تستقبل الرقم المنظف (cleanedPhone) وتستخدمه بدل model.mobile
  Map<String, dynamic> modelToMap(SignUpModel model, String cleanedPhone) {
    Map<String, dynamic> bodyFields = {
      'firstname': model.fName,
      'lastname': model.lName,
      'email': model.email,
      'agree': model.agree.toString() == 'true' ? 'true' : '',
      'password': model.password,
      'password_confirmation': model.password,
      'mobile': cleanedPhone, // 👈 هنا نستخدم الرقم المفلتر والمجهز للإرسال
      'country_code': '964',
      'mobile_code': '964',
      'country': 'Iraq',
    };

    if (model.referName != null && model.referName!.isNotEmpty) {
      bodyFields['refer_name'] = model.referName;
    }

    return bodyFields;
  }

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
      ) ?? '';
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
    } else if (provider == 'apple') {
      map = {'token': accessToken, 'provider': "apple"};
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
