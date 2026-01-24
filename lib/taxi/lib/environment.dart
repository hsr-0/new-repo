class Environment {
  /* ATTENTION Please update your desired data. */
  static const String appName = 'OvoRide USER';
  static const String version = '1.0.0';

  //Language
  // Default display name for the app's language (used in UI language selectors)
  static String defaultLanguageName = "English";

  // Default language code (ISO 639-1) used by the app at startup
  static String defaultLanguageCode = "en";

  // Default country code
  static const String defaultCountryCode = 'د.ع';


  static const String baseUrl = 'https://taxi.beytei.com/api/';



  //MAP CONFIG
  // -----------------------------------------------------------------------------
  // [تعديل هام] جعلناها false لكي نعتمد على سيرفرنا الخاص بدلاً من جوجل
  static const bool addressPickerFromGoogleMapApi = false;

  // [مكان المفتاح] ضع مفتاح Mapbox الخاص بك هنا داخل علامات التنصيص
  // يبدأ عادة بـ pk.eyJ
  static const String mapKey = "pk.eyJ1IjoicmUtYmV5dGVpMzIxIiwiYSI6ImNtaTljbzM4eDBheHAyeHM0Y2Z0NmhzMWMifQ.ugV8uRN8pe9MmqPDcD5XcQ";
  // 👆 (هذا مفتاح عام للتجربة، يفضل استبداله بمفتاحك الخاص من حسابك في Mapbox)
  // -----------------------------------------------------------------------------

  static const double mapDefaultZoom = 16;
  static const String devToken = "\$2y\$12\$mEVBW3QASB5HMBv8igls3ejh6zw2A0Xb480HWAmYq6BY9xEifyBjG";
}
