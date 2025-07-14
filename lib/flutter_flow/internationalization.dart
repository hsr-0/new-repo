import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleStorageKey = '__locale_key__';

class FFLocalizations {
  FFLocalizations(this.locale);

  final Locale locale;

  static FFLocalizations of(BuildContext context) =>
      Localizations.of<FFLocalizations>(context, FFLocalizations)!;

  static List<String> languages() => ['en', 'ar'];

  static late SharedPreferences _prefs;
  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();
  static Future storeLocale(String locale) =>
      _prefs.setString(_kLocaleStorageKey, locale);
  static Locale? getStoredLocale() {
    final locale = _prefs.getString(_kLocaleStorageKey);
    return locale != null && locale.isNotEmpty ? createLocale(locale) : null;
  }

  String get languageCode => locale.toString();
  String? get languageShortCode =>
      _languagesWithShortCode.contains(locale.toString())
          ? '${locale.toString()}_short'
          : null;
  int get languageIndex => languages().contains(languageCode)
      ? languages().indexOf(languageCode)
      : 0;

  String getText(String key) =>
      (kTranslationsMap[key] ?? {})[locale.toString()] ?? '';

  String getVariableText({
    String? enText = '',
    String? arText = '',
  }) =>
      [enText, arText][languageIndex] ?? '';

  static const Set<String> _languagesWithShortCode = {
    'ar',
    'az',
    'ca',
    'cs',
    'da',
    'de',
    'dv',
    'en',
    'es',
    'et',
    'fi',
    'fr',
    'gr',
    'he',
    'hi',
    'hu',
    'it',
    'km',
    'ku',
    'mn',
    'ms',
    'no',
    'pt',
    'ro',
    'ru',
    'rw',
    'sv',
    'th',
    'uk',
    'vi',
  };
}

/// Used if the locale is not supported by GlobalMaterialLocalizations.
class FallbackMaterialLocalizationDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      SynchronousFuture<MaterialLocalizations>(
        const DefaultMaterialLocalizations(),
      );

  @override
  bool shouldReload(FallbackMaterialLocalizationDelegate old) => false;
}

/// Used if the locale is not supported by GlobalCupertinoLocalizations.
class FallbackCupertinoLocalizationDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        const DefaultCupertinoLocalizations(),
      );

  @override
  bool shouldReload(FallbackCupertinoLocalizationDelegate old) => false;
}

class FFLocalizationsDelegate extends LocalizationsDelegate<FFLocalizations> {
  const FFLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<FFLocalizations> load(Locale locale) =>
      SynchronousFuture<FFLocalizations>(FFLocalizations(locale));

  @override
  bool shouldReload(FFLocalizationsDelegate old) => false;
}

Locale createLocale(String language) => language.contains('_')
    ? Locale.fromSubtags(
        languageCode: language.split('_').first,
        scriptCode: language.split('_').last,
      )
    : Locale(language);

bool _isSupportedLocale(Locale locale) {
  final language = locale.toString();
  return FFLocalizations.languages().contains(
    language.endsWith('_')
        ? language.substring(0, language.length - 1)
        : language,
  );
}

final kTranslationsMap = <Map<String, Map<String, String>>>[
  // SplashPage
  {
    '4ybbqts6': {
      'en': 'بوتيك بيتي ',
      'ar': 'بوتيك بيتي ',
    },
    'd6o1wtnw': {
      'en': 'Home',
      'ar': 'الرئيسية ',
    },
  },
  // OnboardingPage
  {
    'j0ngg6c9': {
      'en': 'Skip',
      'ar': 'تخطي',
    },
    'czcldauw': {
      'en': 'Home',
      'ar': 'الرئيسية ',
    },
  },
  // DemoImages
  {
    '12r2kklu': {
      'en': 'Home',
      'ar': 'الرئيسية',
    },
  },
  // SignInPage
  {
    '6fc5xbzy': {
      'en': 'Skip',
      'ar': 'يتخطى',
    },
    'es61617d': {
      'en': 'Log In',
      'ar': 'تسجيل الدخول',
    },
    'ly8wf6m1': {
      'en': 'Hello, Welcome back to your account',
      'ar': 'مرحباً بك مرة أخرى في حسابك',
    },
    '4r5csmay': {
      'en': 'Username or email',
      'ar': 'اسم المستخدم أو البريد الإلكتروني',
    },
    '0fxv4yqv': {
      'en': 'Enter username or email',
      'ar': 'أدخل اسم المستخدم أو البريد الإلكتروني',
    },
    'pjqa4ebr': {
      'en': 'Password',
      'ar': 'كلمة المرور',
    },
    '28jl72m0': {
      'en': 'Enter password',
      'ar': 'أدخل كلمة المرور',
    },
    '4k8m5a3z': {
      'en': 'Forgot Password?',
      'ar': 'هل نسيت كلمة السر؟',
    },
    'mmryahke': {
      'en': 'Log In',
      'ar': 'تسجيل الدخول',
    },
    'u8loqg6n': {
      'en': 'Please enter username or email',
      'ar': 'الرجاء إدخال اسم المستخدم أو البريد الإلكتروني',
    },
    'yo5eo6kg': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    'pawk42w6': {
      'en': 'Please enter password',
      'ar': 'الرجاء إدخال كلمة المرور',
    },
    'hpv6i7uf': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    '5gpypk82': {
      'en': 'Don’t have an account ? ',
      'ar': 'ليس لديك حساب؟',
    },
    '6yooe4tr': {
      'en': 'Sign Up',
      'ar': 'انشاء حساب',
    },
    'rx7onf8w': {
      'en': 'Home',
      'ar': 'الرئيسية',
    },
  },
  // SignUpPage
  {
    '8ayctuid': {
      'en': 'Skip',
      'ar': 'تخطي',
    },
    'y0hhgxph': {
      'en': 'Sign Up',
      'ar': 'انشاء حساب',
    },
    'k94erxx1': {
      'en': 'Let’s Create your account',
      'ar': 'دعنا ننشئ حسابك',
    },
    'mfwlfn05': {
      'en': 'Username',
      'ar': 'اسم المستخدم',
    },
    '5lvh8bjh': {
      'en': 'Enter username',
      'ar': 'أدخل اسم المستخدم',
    },
    '3l2msneq': {
      'en': 'Email Address',
      'ar': 'عنوان البريد الإلكتروني',
    },
    '058kryv8': {
      'en': 'Enter email address',
      'ar': 'أدخل عنوان البريد الإلكتروني',
    },
    'w1v5qefh': {
      'en': 'Password',
      'ar': 'كلمة المرور',
    },
    'toej9jpu': {
      'en': 'Enter password',
      'ar': 'أدخل كلمة المرور',
    },
    'i1yz7hg3': {
      'en': 'Confirm Password',
      'ar': 'تأكيد كلمة المرور',
    },
    'xtaqdl4z': {
      'en': 'Enter confirm Password',
      'ar': 'أدخل تأكيد كلمة المرور',
    },
    'fn1msowf': {
      'en': 'I accepted ',
      'ar': 'لقد قبلت',
    },
    'qjwlvdrl': {
      'en': 'Terms & Privacy Policy',
      'ar': 'الشروط وسياسة الخصوصية',
    },
    'qvq7ui0l': {
      'en': 'Sign Up',
      'ar': 'انشاء حساب',
    },
    'cagfa4hb': {
      'en': 'Please enter username',
      'ar': 'الرجاء إدخال اسم المستخدم',
    },
    'fflaw0hd': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    'c12hy1cn': {
      'en': 'Please enter email address',
      'ar': 'الرجاء إدخال عنوان البريد الإلكتروني',
    },
    'a3bia36h': {
      'en': 'Please enter valid email address',
      'ar': 'الرجاء إدخال عنوان بريد إلكتروني صالح',
    },
    'jumy6tj0': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    'l61afd4j': {
      'en': 'Please enter password',
      'ar': 'الرجاء إدخال كلمة المرور',
    },
    'ttvlrbwn': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    'ys6g7k01': {
      'en': 'Please enter confirm password',
      'ar': 'الرجاء إدخال تأكيد كلمة المرور',
    },
    'wc0pj0fb': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    'p0oybniu': {
      'en': 'Already have a account? ',
      'ar': 'هل لديك حساب بالفعل؟',
    },
    '1p7n5ccl': {
      'en': 'Sign In',
      'ar': 'تسجيل الدخول',
    },
    '6j7u5k56': {
      'en': 'Home',
      'ar': 'الرئيسية',
    },
  },
  // HomeMainPage
  {
    'kxrg5v20': {
      'en': 'Home',
      'ar': 'الرئيسية',
    },
    '7eu077s9': {
      'en': 'Category',
      'ar': 'فئة',
    },
    'j4ybyq20': {
      'en': 'Cart',
      'ar': 'عربة التسوق',
    },
    'p1rixi5p': {
      'en': 'Profile',
      'ar': 'حساب تعريفي',
    },
    'dd70tglh': {
      'en': 'Home',
      'ar': 'الرئيسية',
    },
  },
  // SettingPage
  {
    'x3kd0g4j': {
      'en': 'Settings',
      'ar': 'إعدادات',
    },
    '91mao9bh': {
      'en': 'Privacy Policy',
      'ar': 'سياسة الخصوصية',
    },
    '4kc4c64i': {
      'en': 'Contact Us',
      'ar': 'اتصل بنا',
    },
    'jph32eit': {
      'en': 'Rate Us',
      'ar': 'قيمنا',
    },
    '42g3tt77': {
      'en': 'About Us',
      'ar': 'معلومات عنا',
    },
    'uvf1vj70': {
      'en': 'Feedback',
      'ar': 'تعليق',
    },
    'ybwkhe1p': {
      'en': 'Delete Account',
      'ar': 'حذف الحساب',
    },
    '4y5pqt6k': {
      'en': 'Log Out',
      'ar': 'تسجيل الخروج',
    },
    '19rssp92': {
      'en': 'Log In',
      'ar': 'تسجيل الدخول',
    },
    'ev6aggyu': {
      'en': 'Home',
      'ar': 'الصفحة الرئيسية',
    },
  },
  // ContactUsPage
  {
    '7qjqmf6z': {
      'en': 'Contact Us',
      'ar': 'اتصل بنا',
    },
    '567g3e1d': {
      'en': 'Email',
      'ar': 'بريد إلكتروني',
    },
    'lebdw9h2': {
      'en': 'darlenerobertson@gmail.com',
      'ar': 'darlenerobertson@gmail.com',
    },
    'u5hylub5': {
      'en': 'Phone Number',
      'ar': 'رقم التليفون',
    },
    't6erxu8x': {
      'en': '09715 526 267',
      'ar': '09715 526 267',
    },
    'u6oq9bf0': {
      'en': 'Home',
      'ar': 'الرئيسية',
    },
  },
  // Feedbackage
  {
    'c9n1xp30': {
      'en': 'Feedback',
      'ar': 'تعليق',
    },
    '8crpjwvp': {
      'en': 'Give Feedback',
      'ar': 'تقديم ملاحظات',
    },
    '4pn9vuhe': {
      'en': 'Give your feedback about our app',
      'ar': 'أعطنا رأيك حول تطبيقنا',
    },
    'lgjj64xr': {
      'en': 'Are you satisfied with this app?',
      'ar': 'هل أنت راضٍ عن هذا التطبيق؟',
    },
    '3g8jr69t': {
      'en': 'Tell us what can be improved!',
      'ar': 'أخبرنا ما الذي يمكن تحسينه!',
    },
    'su3sezl2': {
      'en': 'Type here...',
      'ar': 'اكتب هنا...',
    },
    'pxjxwmmh': {
      'en': 'Please enter sum thoughts',
      'ar': 'الرجاء إدخال مجموع الأفكار',
    },
    '495yyb57': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    '1p78scrr': {
      'en': 'Submit Feedback',
      'ar': 'إرسال التعليقات',
    },
    'pcb4nvqy': {
      'en': 'Home',
      'ar': 'الصفحة الرئيسية',
    },
  },
  // WishlistPage
  {
    'cq3pjudd': {
      'en': 'Home',
      'ar': 'الصفحة الرئيسية',
    },
  },
  // MyAddressPage
  {
    'qdz0wtt9': {
      'en': 'My Address',
      'ar': 'عنواني',
    },
    '89wgw45e': {
      'en': 'Billing address',
      'ar': 'عنوان الفاتورة',
    },
    'wu93zfc7': {
      'en': 'Default',
      'ar': 'تقصير',
    },
    'ty2d5a18': {
      'en': 'Shipping address',
      'ar': 'عنوان الشحن',
    },
    '3r8rvd96': {
      'en': 'Add shipping address',
      'ar': 'إضافة عنوان الشحن',
    },
    'vtu3b9q4': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // AddAddressPage
  {
    '0mjzh96n': {
      'en': 'First name',
      'ar': 'الاسم الأول',
    },
    'gfsim0le': {
      'en': 'Enter first name',
      'ar': 'أدخل الاسم الأول',
    },
    'wm1ho79n': {
      'en': 'Last name',
      'ar': 'اسم العائلة',
    },
    'twgofq5x': {
      'en': 'Enter last name',
      'ar': 'أدخل الاسم الأخير',
    },
    'raa65d3s': {
      'en': 'Email',
      'ar': 'بريد إلكتروني',
    },
    'knbvh0qk': {
      'en': 'Enter email',
      'ar': 'أدخل البريد الإلكتروني',
    },
    'p93gq2j9': {
      'en': 'Address line 1',
      'ar': 'المحافظة',
    },
    'maz889ao': {
      'en': 'Enter address line 1',
      'ar': 'مثل واسط  ',
    },
    'n46yv5wm': {
      'en': 'Address line 2',
      'ar': 'سطر العنوان 2',
    },
    'l99qyk44': {
      'en': 'Enter address line 2',
      'ar': 'مثل العزيزية ',
    },
    'idf0u7pp': {
      'en': 'Select  country',
      'ar': 'اختر البلد',
    },
    'ugv5b2h7': {
      'en': 'Search...',
      'ar': 'يبحث...',
    },
    '6kh21akw': {
      'en': 'Select state',
      'ar': 'اختر الولاية',
    },
    'thi2wl8q': {
      'en': 'Search...',
      'ar': 'يبحث...',
    },
    'fme2q2kk': {
      'en': 'City',
      'ar': 'المنطقة ',
    },
    '7ex062p0': {
      'en': 'Enter city',
      'ar': 'الشباب ',
    },
    'oq9dwncq': {
      'en': 'رقم حظج ياحلوة',
      'ar': 'رقم حظج ',
    },
    'djc1z3pw': {
      'en': 'اكتبي اي رقم لحظج ',
      'ar': 'اكتبي اي  رقم لحظج',
    },
    '0pg7scg9': {
      'en': 'Please enter first name',
      'ar': 'الرجاء إدخال الاسم الأول',
    },
    't5609iaz': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    'iff82xf7': {
      'en': 'Please enter last name',
      'ar': 'الرجاء إدخال الاسم الأخير',
    },
    'r8ldd4ut': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    'ufe728y0': {
      'en': 'Please enter email address',
      'ar': 'الرجاء إدخال عنوان البريد الإلكتروني',
    },
    'jhmbdo3f': {
      'en': 'Please enter valid email address',
      'ar': 'الرجاء إدخال عنوان بريد إلكتروني صالح',
    },
    '5upj4o7d': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    'dy0xuad4': {
      'en': 'Please enter address line 1',
      'ar': 'الرجاء إدخال عنوان السطر 1',
    },
    'p87xie95': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    'rf2tphet': {
      'en': 'Please enter address line 2',
      'ar': 'الرجاء إدخال سطر العنوان 2',
    },
    '0qpksdbs': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    'n6prf892': {
      'en': 'Please enter city',
      'ar': 'الرجاء إدخال المدينة',
    },
    '60ax1jj4': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    'k21cwl9i': {
      'en': 'يمعودة خلي رقم 5 ماذا متعرفين ',
      'ar': 'يمعودة خلي رقم 5 ماذا متعرفين',
    },
    'pbgqbzh7': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    'xgn2f38p': {
      'en': 'Home',
      'ar': 'الصفحة الرئيسية',
    },
  },
  // ProductDetailPage
  {
    'aqnmmqwq': {
      'en': 'Add to Cart',
      'ar': 'أضف إلى السلة',
    },
    '9o5zygl7': {
      'en': 'Home',
      'ar': 'الصفحة الرئيسية',
    },
  },
  // MyProfilePage
  {
    'f5qa4u4n': {
      'en': 'Name',
      'ar': 'اسم',
    },
    'e1zo0lnc': {
      'en': 'Email',
      'ar': 'بريد إلكتروني',
    },
    'ijvh7ylb': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // EditProfilePage
  {
    'b7f2um7d': {
      'en': 'First name',
      'ar': 'الاسم الأول',
    },
    'x7hastdc': {
      'en': 'Enter first name',
      'ar': 'أدخل الاسم الأول',
    },
    '4rnggw1e': {
      'en': 'Last name',
      'ar': 'اسم العائلة',
    },
    'eamiqpcj': {
      'en': 'Enter last name',
      'ar': 'أدخل الاسم الأخير',
    },
    'z025sda6': {
      'en': 'Enter first name',
      'ar': 'أدخل الاسم الأول',
    },
    'km640e5k': {
      'en': 'Please enter first name',
      'ar': 'الرجاء إدخال الاسم الأول',
    },
    '6lwog2mz': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    '0t1qrd0p': {
      'en': 'Please enter last name',
      'ar': 'الرجاء إدخال الاسم الأخير',
    },
    '9v7c06cq': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    '9pv7f4vw': {
      'en': 'email is required',
      'ar': 'البريد الإلكتروني مطلوب',
    },
    '9nfskfjy': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    '6flkhs9r': {
      'en': 'Save',
      'ar': 'يحفظ',
    },
    'uba5c9i1': {
      'en': 'Home',
      'ar': 'الرئيسية',
    },
  },
  // SucessfullyPage
  {
    '5xg0wce1': {
      'en': 'انتظري اتصال المندوب',
      'ar': 'انتظري اتصال المندوب ',
    },
    'mk0gyhl7': {
      'en': 'STATUS: ',
      'ar': 'حالة:',
    },
    'xa98cdf1': {
      'en': 'Order ID: ',
      'ar': 'معرف الطلب:',
    },
    'tcyr4n1x': {
      'en': 'Order ID: 369655',
      'ar': 'رقم الطلب: 369655',
    },
    'fmlou9iw': {
      'en': 'Thank you for shopping with us',
      'ar': 'شكرا لك على التسوق معنا',
    },
    'kmscxnuh': {
      'en': 'View My Order',
      'ar': 'عرض طلبي',
    },
    'vwh4d715': {
      'en': 'Home',
      'ar': ' الرئيسية',
    },
  },
  // ReviewPage
  {
    'ipw2it5d': {
      'en': 'Review',
      'ar': 'مراجعة',
    },
    'rz2pb5pt': {
      'en': ' / 5',
      'ar': '/ 5',
    },
    'k19ouw6k': {
      'en': ' Reviews',
      'ar': 'المراجعات',
    },
    'q6c7nx2j': {
      'en': '8 Reviews',
      'ar': '8 مراجعات',
    },
    'is9q5l6h': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // MyOrdersPage
  {
    'khyl2n96': {
      'en': 'My Orders',
      'ar': 'طلبياتي',
    },
    'jmqtoksd': {
      'en': 'Order ID : #',
      'ar': 'معرف الطلب : #',
    },
    'tam1iflp': {
      'en': 'Order at ',
      'ar': 'اطلب في',
    },
    's1lq35nd': {
      'en': 'Home',
      'ar': 'الرئسية',
    },
  },
  // OrderDetailsPage
  {
    '3583upp2': {
      'en': 'Order Details',
      'ar': 'تفاصيل الطلب',
    },
    '70i6tngn': {
      'en': 'Order ID : #',
      'ar': 'معرف الطلب : #',
    },
    'sokhjacz': {
      'en': 'Order at ',
      'ar': 'اطلب في',
    },
    'fwz5yfz0': {
      'en': 'Order at 6:35 PM | 4-March-2022',
      'ar': 'اطلب الساعة 6:35 مساءً | 4 مارس 2022',
    },
    'knp9t4zs': {
      'en': 'Payment Method: ',
      'ar': 'طريقة الدفع:',
    },
    'rripe6dj': {
      'en': 'Payment Method: cod',
      'ar': 'طريقة الدفع: كود',
    },
    'ssfg60su': {
      'en': 'Cancel Order?',
      'ar': 'إلغاء الطلب؟',
    },
    'ljska8ls': {
      'en': 'Pay for this order',
      'ar': 'ادفع ثمن هذا الطلب',
    },
    'l5n4uaum': {
      'en': ' : ',
      'ar': ':',
    },
    '2kv89zxg': {
      'en': 'Qty : ',
      'ar': 'الكمية :',
    },
    'rezv8r0s': {
      'en': 'Total : ',
      'ar': 'المجموع :',
    },
    'ikxgviv7': {
      'en': 'Rate this product now',
      'ar': 'قم بتقييم هذا المنتج الآن',
    },
    'cqtqt1eu': {
      'en': 'Billing Address',
      'ar': 'عنوان الفاتورة',
    },
    'oxdef9wj': {
      'en': 'Shipping Address',
      'ar': 'عنوان الشحن',
    },
    'vs0pl8z9': {
      'en': 'Payment Summary',
      'ar': 'ملخص الدفع',
    },
    'igghtok3': {
      'en': 'Sub Total',
      'ar': 'المجموع الفرعي',
    },
    'lb4m7i28': {
      'en': 'Discount : ',
      'ar': 'تخفيض :',
    },
    'd8us270o': {
      'en': 'Shipping',
      'ar': 'شحن',
    },
    '2zrytvyg': {
      'en': 'Via ',
      'ar': 'عبر',
    },
    'rnty6xud': {
      'en': 'Tax',
      'ar': 'ضريبة',
    },
    '4ru38dmu': {
      'en': 'Refund',
      'ar': 'استرداد',
    },
    'va24mxdw': {
      'en': 'Total Payment Amount',
      'ar': 'إجمالي مبلغ الدفع',
    },
    'bmlmi7vg': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // CategoryOpenPage
  {
    'zl3b3m8y': {
      'en': 'All',
      'ar': 'الجميع',
    },
    'rovmtzbo': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // CartPage
  {
    'tg6map0b': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // CheckoutPage
  {
    'qnae2am5': {
      'en': 'Checkout',
      'ar': 'الدفع',
    },
    '3z9g83vu': {
      'en': 'My Cart',
      'ar': 'سلة التسوق الخاصة بي',
    },
    'ds81gy5k': {
      'en': 'Payment',
      'ar': 'قسط',
    },
    '6428nib9': {
      'en': 'Add new address',
      'ar': 'إضافة عنوان جديد',
    },
    'qifs2i4m': {
      'en': 'Billing Address',
      'ar': 'عنوان الفاتورة',
    },
    '2spvicj3': {
      'en': 'Default',
      'ar': 'تقصير',
    },
    '9my8c7k5': {
      'en': 'Shipping Address',
      'ar': 'عنوان الشحن',
    },
    'ukiu0111': {
      'en': ' : ',
      'ar': ':',
    },
    'qz0lzb8i': {
      'en': 'Quantity : ',
      'ar': 'كمية :',
    },
    't0l7aq1r': {
      'en': 'Total : ',
      'ar': 'المجموع :',
    },
    'tmu1zwcy': {
      'en': 'Enter coupon code',
      'ar': 'أدخل رمز القسيمة',
    },
    'iihsc0wr': {
      'en': 'Apply',
      'ar': 'يتقدم',
    },
    'jknh9898': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
    'ytlg9ykw': {
      'en': 'Payment Summary',
      'ar': 'ملخص الدفع',
    },
    'z1z1z0cx': {
      'en': 'Sub Total',
      'ar': 'المجموع الفرعي',
    },
    'n3mf80hc': {
      'en': 'Discount : ',
      'ar': 'تخفيض :',
    },
    'sd6fm294': {
      'en': 'Discount',
      'ar': 'تخفيض',
    },
    'l1hd4xt8': {
      'en': 'Remove',
      'ar': 'يزيل',
    },
    'zyyjtu2a': {
      'en': 'Shipping',
      'ar': 'شحن',
    },
    'rvnboy3d': {
      'en': 'Tax',
      'ar': 'ضريبة',
    },
    'l74q8jia': {
      'en': 'Total Payment Amount',
      'ar': 'إجمالي مبلغ الدفع',
    },
    'kkjz9j7a': {
      'en': 'Choose your Payment Mode',
      'ar': ' اختر طريقة الدفع الخاصة بك',
    },
    'tmlmzccj': {
      'en': 'Confirm Payment',
      'ar': 'تأكيد الدفع',
    },
    '91mjem8b': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // CouponPage
  {
    'hrtaedlx': {
      'en': 'My Coupon',
      'ar': 'قسيمتي',
    },
    '51k041fu': {
      'en': 'Have a coupon Code',
      'ar': 'احصل على رمز قسيمة',
    },
    'yecfghwv': {
      'en': 'Enter coupon code',
      'ar': 'أدخل رمز القسيمة',
    },
    '63i60tuh': {
      'en': 'Apply',
      'ar': 'يتقدم',
    },
    'wh1nj53v': {
      'en': 'Promo Code',
      'ar': 'رمز ترويجي',
    },
    'pz2surpo': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // TrendingProductsPage
  {
    'hjgs5wsy': {
      'en': 'Trending products',
      'ar': 'المنتجات الرائجة',
    },
    'skum6qhd': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // RelatedProductsPage
  {
    'lof68zqo': {
      'en': 'Related products',
      'ar': 'المنتجات ذات الصلة',
    },
    '5s16qlfl': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // SearchPage
  {
    's1uo5zgg': {
      'en': 'Search',
      'ar': 'يبحث',
    },
    'rng28ddd': {
      'en': '% OFF',
      'ar': '٪ عن',
    },
    'i3ub5o3d': {
      'en': 'SALE',
      'ar': 'أُوكَازيُون',
    },
    'x3mrwuob': {
      'en': 'Search',
      'ar': 'يبحث',
    },
    '6j7qzcwi': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // WriteReviewPage
  {
    'gzvlrnk0': {
      'en': 'Review',
      'ar': 'مراجعة',
    },
    'becfhxdg': {
      'en': 'Are you satisfied with this Product?',
      'ar': 'هل أنت راضٍ عن هذا المنتج؟',
    },
    'lk1g9jh8': {
      'en': 'Next',
      'ar': 'التالي',
    },
    'hq432vjl': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // WriteReviewSubmitPage
  {
    '2fljz2r3': {
      'en': 'Review',
      'ar': 'مراجعة',
    },
    '1z1nz7b1': {
      'en': 'Write a Review',
      'ar': 'اكتب مراجعة',
    },
    'nwrejqx9': {
      'en': 'Type here...',
      'ar': 'اكتب هنا...',
    },
    'tway3uju': {
      'en': 'Please enter write a review',
      'ar': 'الرجاء إدخال كتابة مراجعة',
    },
    'kyjuc588': {
      'en': 'Please choose an option from the dropdown',
      'ar': 'الرجاء اختيار خيار من القائمة المنسدلة',
    },
    'gdin4eta': {
      'en': 'Submit',
      'ar': 'يُقدِّم',
    },
    'c7t8zruy': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // DemoPage
  {
    '2686ban5': {
      'en': 'Product added to wishlist',
      'ar': 'تمت إضافة المنتج إلى قائمة الرغبات',
    },
    'mhsqij7m': {
      'en': 'VIEW',
      'ar': 'منظر',
    },
    'qjo8qlka': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // BlogPage
  {
    'qibzwzaz': {
      'en': 'Blog',
      'ar': 'مدونة',
    },
    'p0qdt7ct': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // SaleProductsPage
  {
    '5ytdhpdc': {
      'en': 'Sale products',
      'ar': 'منتجات للبيع',
    },
    '8ygjd81a': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // PopularProductsPage
  {
    '05tb79m5': {
      'en': 'براندات ',
      'ar': 'البراندات',
    },
    'yht4f0e3': {
      'en': 'Home',
      'ar': 'الرئيسية',
    },
  },
  // LatestProductsPage
  {
    '2atinkbz': {
      'en': 'Trending products',
      'ar': 'المنتجات الرائجة',
    },
    'eox5jdag': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // BlogDetailPage
  {
    'd29cei61': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // UpSellProductsPage
  {
    '1whpdrn3': {
      'en': 'Up sell products',
      'ar': 'بيع المنتجات',
    },
    '35eqd7wo': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // MoreProductPage
  {
    'o8lk94qm': {
      'en': 'More Products ',
      'ar': 'المزيد من المنتجات',
    },
    'w6n49c2i': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // PayForOderPage
  {
    'v1gllvl6': {
      'en': 'Total',
      'ar': 'المجموع',
    },
    'embgk3cg': {
      'en': 'Back',
      'ar': 'خلف',
    },
    'pjf0n0dp': {
      'en': 'Pay For This Order',
      'ar': 'ادفع ثمن هذا الطلب',
    },
    '7p37pchg': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // ProductDetailPageCopy
  {
    'mw5f2pyt': {
      'en': ' / ',
      'ar': '/',
    },
    'q4xh0elw': {
      'en': 'Hello World',
      'ar': 'مرحبا بالعالم',
    },
    'vzwjr0kq': {
      'en': 'SALE',
      'ar': 'أُوكَازيُون',
    },
    'u4jwt0r7': {
      'en': '% OFF',
      'ar': '٪ عن',
    },
    'iw08eu89': {
      'en': '8 Reviews',
      'ar': '8 مراجعات',
    },
    '8x0wv4hs': {
      'en': 'Out of Stock',
      'ar': 'إنتهى من المخزن',
    },
    'j4wjuy2o': {
      'en': 'Available on backorder',
      'ar': 'متوفر للطلب المسبق',
    },
    '31is92sl': {
      'en': 'Availability : ',
      'ar': 'التوفر :',
    },
    'bd2pkygo': {
      'en': ' in stock',
      'ar': 'في الأوراق المالية',
    },
    'g84tatb0': {
      'en': 'Available on backorder',
      'ar': 'متوفر للطلب المسبق',
    },
    'jqrbxy6s': {
      'en': 'Description',
      'ar': 'وصف',
    },
    '1z77lbxm': {
      'en': 'Description',
      'ar': 'وصف',
    },
    'v2kv6rtz': {
      'en': 'Information',
      'ar': 'معلومة',
    },
    'egc1dmow': {
      'en': 'Information',
      'ar': 'معلومة',
    },
    'rls9ruwy': {
      'en': 'Reviews',
      'ar': 'المراجعات',
    },
    'mwb0vbdi': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
    'eflyxdfb': {
      'en': 'Up sell product',
      'ar': 'بيع المنتج',
    },
    'dcwiobsj': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
    'tgvyfo3c': {
      'en': 'Related product',
      'ar': 'منتج ذو صلة',
    },
    'itf618zm': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
    'hswqpgon': {
      'en': 'Add to Cart',
      'ar': 'أضف إلى السلة',
    },
    '5k6d0hu5': {
      'en': 'Home',
      'ar': 'بيت',
    },
  },
  // HomeComponent
  {
    'r8or6va3': {
      'en': 'Welcome back',
      'ar': 'مرحبًا بعودتك',
    },
    'o2qcaobb': {
      'en': 'Categories',
      'ar': 'فئات',
    },
    'bamwuzoa': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
    'jc4z0gdg': {
      'en': 'Trending products',
      'ar': 'المنتجات الرائجة',
    },
    'xooyca16': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
    'p4az8tcq': {
      'en': 'Sell products',
      'ar': 'بيع المنتجات',
    },
    '8rbkat8u': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
    'vlzt95wn': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
    'x3jbgg32': {
      'en': 'Popular \nproducts 🔥',
      'ar': 'المنتجات الشائعة 🔥',
    },
    '80202dlg': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
    '8g0rz082': {
      'en': 'Latest products',
      'ar': 'أحدث المنتجات',
    },
    'vomlpa1l': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
    'rb8azn36': {
      'en': 'Blog',
      'ar': 'مدونة',
    },
    '3hnspteu': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
  },
  // MainComponent
  {
    '2alg9xtu': {
      'en': '% OFF',
      'ar': '٪ عن',
    },
    '1dj04jko': {
      'en': 'SALE',
      'ar': 'أُوكَازيُون',
    },
    'votmzinj': {
      'en': '% OFF',
      'ar': '٪ عن',
    },
    'n9flzvjc': {
      'en': 'SALE',
      'ar': 'أُوكَازيُون',
    },
  },
  // ProfileComponent
  {
    'wfauemuk': {
      'en': 'Profile',
      'ar': 'حساب تعريفي',
    },
    'ut2vybvg': {
      'en': 'My Profile',
      'ar': 'ملفي الشخصي',
    },
    'cwfmfk8t': {
      'en': 'My Address',
      'ar': 'عنواني',
    },
    'rlva0ckp': {
      'en': 'My Orders',
      'ar': 'طلبياتي',
    },
    'eqw921m0': {
      'en': 'Wishlist',
      'ar': 'قائمة الرغبات',
    },
    '6vd7kaaa': {
      'en': 'Settings',
      'ar': 'إعدادات',
    },
  },
  // LogOutComponent
  {
    'hds1xqd1': {
      'en': 'Are you sure you want to logout?',
      'ar': 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
    },
    '2hzd4kyw': {
      'en': 'Cancel',
      'ar': 'يلغي',
    },
    'ry3x60mq': {
      'en': 'Log Out',
      'ar': 'تسجيل الخروج',
    },
  },
  // DeleteAccountComponent
  {
    'mir9opgi': {
      'en': 'Are you sure you want to delete account?',
      'ar': 'هل أنت متأكد أنك تريد حذف الحساب؟',
    },
    '40r34z3y': {
      'en': 'No',
      'ar': 'لا',
    },
    'uqo88o6n': {
      'en': 'Yes',
      'ar': 'نعم',
    },
  },
  // NoAddressComponent
  {
    '9k0mnffe': {
      'en': 'No Address Yet!',
      'ar': 'لا يوجد عنوان حتى الآن!',
    },
    'fw89qis0': {
      'en': 'Add your address for faster check out product deals',
      'ar': 'أضف عنوانك للتحقق من عروض المنتجات بشكل أسرع',
    },
    'qjlswrpe': {
      'en': 'Add Address',
      'ar': 'إضافة عنوان',
    },
  },
  // NoFavouriteComponent
  {
    'aok0znot': {
      'en': 'No Wishlist Yet!',
      'ar': 'لا توجد قائمة أمنيات حتى الآن!',
    },
    'v8konlgk': {
      'en': 'Please go to home & add some products to wishlist',
      'ar':
          'يرجى الذهاب إلى الصفحة الرئيسية وإضافة بعض المنتجات إلى قائمة الرغبات',
    },
    'miw8r1h0': {
      'en': 'Go to Home',
      'ar': 'اذهب إلى الصفحة الرئيسية',
    },
  },
  // NoOrderComponent
  {
    'q97i3k33': {
      'en': 'No Orders Yet!',
      'ar': 'لا توجد طلبات حتى الآن!',
    },
    'nhe1ox4c': {
      'en': 'When you place an order it will show up here',
      'ar': 'عند تقديم طلب، سيظهر هنا',
    },
    'qomy1xm7': {
      'en': 'Add',
      'ar': 'يضيف',
    },
  },
  // NoCartComponent
  {
    'l8fir6r8': {
      'en': 'Your cart is currently empty',
      'ar': 'سلة التسوق الخاصة بك فارغة حاليا',
    },
    '7cqznrn2': {
      'en': 'Must add items on the cart before you proceed to check out.',
      'ar': 'يجب إضافة العناصر إلى سلة التسوق قبل المتابعة إلى الخروج.',
    },
  },
  // NoSearchComponent
  {
    'hv0vhyux': {
      'en': 'What are you searching for?',
      'ar': 'ماذا تبحث عنه؟',
    },
    'hb1i25h2': {
      'en': 'Search for your favorite product or find similar in this app',
      'ar': 'ابحث عن منتجك المفضل أو ابحث عن منتج مشابه في هذا التطبيق',
    },
  },
  // NoProductsComponent
  {
    'gedj2jx5': {
      'en': 'No Products Yet',
      'ar': 'لا يوجد منتجات حتى الآن',
    },
    'ylqbsv5h': {
      'en':
          'Your products list is empty please wait for some time and go to home',
      'ar':
          'قائمة منتجاتك فارغة، يرجى الانتظار لبعض الوقت ثم الانتقال إلى الصفحة الرئيسية',
    },
    'ctwoqc4r': {
      'en': 'Go to Home',
      'ar': 'اذهب إلى الصفحة الرئيسية',
    },
  },
  // CartItemDeleteComponent
  {
    '0715827l': {
      'en': 'Are you sure you want to delete this product from cart?',
      'ar': 'هل أنت متأكد أنك تريد حذف هذا المنتج من سلة التسوق؟',
    },
    'kifgtznn': {
      'en': 'No',
      'ar': 'لا',
    },
    'uzppau8v': {
      'en': 'Yes',
      'ar': 'نعم',
    },
  },
  // CategoryComponent
  {
    'sxygd232': {
      'en': 'Categories',
      'ar': 'فئات',
    },
    'knst3phz': {
      'en': 'Search',
      'ar': 'يبحث',
    },
    'rggadksb': {
      'en': 'Search',
      'ar': 'يبحث',
    },
  },
  // SortByBottomSheet
  {
    'ji9fcwgx': {
      'en': 'Sort by',
      'ar': 'فرز حسب',
    },
    'gv1tywde': {
      'en': 'New Added',
      'ar': 'تمت الإضافة الجديدة',
    },
    '0kwu01eg': {
      'en': 'Popularity',
      'ar': 'شعبية',
    },
    'btvrud2m': {
      'en': 'Rating',
      'ar': 'تصنيف',
    },
    '5l06e62l': {
      'en': 'Lowest Price',
      'ar': 'أقل سعر',
    },
    'qiaod4lt': {
      'en': 'Highest Price',
      'ar': 'أعلى سعر',
    },
  },
  // VariationBottomSheet
  {
    's0c8m3r9': {
      'en': 'Variation',
      'ar': 'تفاوت',
    },
    'h8z831pa': {
      'en': '% OFF',
      'ar': '٪ عن',
    },
    '2rnvwadh': {
      'en': 'Hello World',
      'ar': 'مرحبا بالعالم',
    },
    'fq51bqn7': {
      'en': 'Add to Cart',
      'ar': 'أضف إلى السلة',
    },
  },
  // CartComponent
  {
    'vm44u9cc': {
      'en': 'Cart',
      'ar': 'عربة التسوق',
    },
    'l0100w0k': {
      'en': 'My Cart',
      'ar': 'سلة التسوق الخاصة بي',
    },
    'xlvvckcw': {
      'en': 'Payment',
      'ar': 'قسط',
    },
    'rb9w1nuh': {
      'en': ' : ',
      'ar': ':',
    },
    'bgw2bqbg': {
      'en': 'Total : ',
      'ar': 'المجموع :',
    },
    'jq6v4dgk': {
      'en': 'There’s  More Product To Try!',
      'ar': 'هناك المزيد من المنتجات لتجربتها!',
    },
    'ht9njueb': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
    'lf2y6nwh': {
      'en': 'Payment Summary',
      'ar': 'ملخص الدفع',
    },
    'hwsa58a3': {
      'en': 'Sub Total',
      'ar': 'المجموع الفرعي',
    },
    '8jcjmpzl': {
      'en': 'Discount : ',
      'ar': 'تخفيض :',
    },
    'ptnlnbrv': {
      'en': 'Discount',
      'ar': 'تخفيض',
    },
    's3q35ul4': {
      'en': 'Remove',
      'ar': 'يزيل',
    },
    'i5xw99ot': {
      'en': 'Shipping',
      'ar': 'شحن',
    },
    'm97hvo6a': {
      'en': 'Tax',
      'ar': 'ضريبة',
    },
    '7qe7psl2': {
      'en': 'Total Payment Amount',
      'ar': 'إجمالي مبلغ الدفع',
    },
    'tdybmzuw': {
      'en': 'Grand Total',
      'ar': 'المجموع الإجمالي',
    },
    'afgrh8co': {
      'en': 'Proceed to Payment',
      'ar': 'انتقل إلى الدفع',
    },
  },
  // CancleOrderComponent
  {
    'a66dnbjl': {
      'en': 'Are you sure you want to\ncancle this order?',
      'ar': 'هل أنت متأكد أنك تريد إلغاء هذا الطلب؟',
    },
    'jvg5ge3d': {
      'en': 'No',
      'ar': 'لا',
    },
    'yh0c1oog': {
      'en': 'Yes',
      'ar': 'نعم',
    },
  },
  // ReviewDoneComponent
  {
    'tabqofrv': {
      'en': 'Thank You',
      'ar': 'شكرًا لك',
    },
    '0obvqg8r': {
      'en': 'Success! Your review has been submitted',
      'ar': 'تم بنجاح! تم إرسال تقييمك.',
    },
    'mw9awo5t': {
      'en': 'Ok',
      'ar': 'نعم',
    },
  },
  // CategoryShimmer
  {
    '0chsqbx7': {
      'en': 'Categories',
      'ar': 'فئات',
    },
    '5cc51fc1': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
  },
  // ProductsHoreShimmer
  {
    'taf09wse': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
  },
  // SaleProductsShimmer
  {
    '65pggxtc': {
      'en': 'Sale products',
      'ar': 'منتجات للبيع',
    },
    '99rv79nx': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
  },
  // BigSavingShimmer
  {
    '49lffdzb': {
      'en': 'Popular \nproducts 🔥',
      'ar': 'المنتجات الشائعة 🔥',
    },
    '8vd5ihur': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
  },
  // BlogShimmer
  {
    'yt4otr15': {
      'en': 'Blog',
      'ar': 'مدونة',
    },
    '3atcur5h': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
  },
  // ReviewsShimmer
  {
    '7vmwxll3': {
      'en': 'Reviews',
      'ar': 'المراجعات',
    },
    '78l7x7xv': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
  },
  // CustomDropDown
  {
    'uwoqiec1': {
      'en': 'Search...',
      'ar': 'يبحث...',
    },
  },
  // NoCouponComponent
  {
    'g13ld9o0': {
      'en': 'No Coupon Available!',
      'ar': 'لا يوجد قسيمة متاحة!',
    },
    'l0s2ht3k': {
      'en':
          'But don’t worry, you still get to enjoy the best deals & offers with us',
      'ar': 'لكن لا تقلق، لا يزال بإمكانك الاستمتاع بأفضل الصفقات والعروض معنا',
    },
  },
  // NoPaymentMethodesComponent
  {
    'zl0yxktw': {
      'en': 'there are no payment methods available',
      'ar': 'لا توجد طرق دفع متاحة',
    },
  },
  // ImageComponent
  {
    '8awpnyp6': {
      'en': ' / ',
      'ar': '/',
    },
    'hdbhe3du': {
      'en': 'Hello World',
      'ar': 'مرحبا بالعالم',
    },
    'ffzdaose': {
      'en': 'SALE',
      'ar': 'أُوكَازيُون',
    },
  },
  // DetailComponent
  {
    'du61ojol': {
      'en': '% OFF',
      'ar': '٪ عن',
    },
    '1s2cc0bp': {
      'en': ' ',
      'ar': '',
    },
    'm32l9l3d': {
      'en': ' Reviews',
      'ar': 'المراجعات',
    },
    'qqu7ifny': {
      'en': '8 Reviews',
      'ar': '8 مراجعات',
    },
    'kre32zck': {
      'en': 'Out of Stock',
      'ar': 'إنتهى من المخزن',
    },
    'u84jmyyj': {
      'en': 'Available on backorder',
      'ar': 'متوفر للطلب المسبق',
    },
    'en4ywh8a': {
      'en': 'Availability : ',
      'ar': 'التوفر :',
    },
    '0itgqiwg': {
      'en': ' in stock',
      'ar': 'في الأوراق المالية',
    },
    'fcjy3zh6': {
      'en': 'Available on backorder',
      'ar': 'متوفر للطلب المسبق',
    },
    'p54q9w73': {
      'en': 'Description',
      'ar': 'وصف',
    },
    'mgfw5zy4': {
      'en': 'Description',
      'ar': 'وصف',
    },
    'ebn4bv0v': {
      'en': 'Information',
      'ar': 'معلومة',
    },
    'psf8b8pw': {
      'en': 'Information',
      'ar': 'معلومة',
    },
    '2a0dr9fb': {
      'en': 'Reviews',
      'ar': 'المراجعات',
    },
    'mz0w24di': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
    's878imht': {
      'en': 'Up sell product',
      'ar': 'بيع المنتج',
    },
    'c7wdl67m': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
    '7lgx0dud': {
      'en': 'Related product',
      'ar': 'منتج ذو صلة',
    },
    'po2o18d4': {
      'en': 'View all',
      'ar': 'عرض الكل',
    },
  },
  // Miscellaneous
  {
    'cbsr661h': {
      'en': 'Large title 34 Bold',
      'ar': 'عنوان كبير 34 غامق',
    },
    'xzzrz2ho': {
      'en': 'Title-1 28 Bold',
      'ar': 'العنوان-1 28 غامق',
    },
    '00ocltui': {
      'en': 'Title 2 22 Bold',
      'ar': 'العنوان 2 22 غامق',
    },
    'ds7v9e83': {
      'en': 'Title 3 20 Bold',
      'ar': 'العنوان 3 20 غامق',
    },
    'fl62rn2x': {
      'en': 'Headline 18 Semi Bold ',
      'ar': 'العنوان الرئيسي 18 بخط غامق جزئيًا',
    },
    'tx3kio81': {
      'en': 'Subheadline 15 Medium',
      'ar': 'العنوان الفرعي 15 متوسط',
    },
    '6cby00x4': {
      'en': 'Body 17 Medium',
      'ar': 'الجسم 17 متوسط',
    },
    'zopkcd21': {
      'en': 'Callout 16 Normal',
      'ar': 'نداء رقم 16 عادي',
    },
    'rhq6i2sj': {
      'en': 'Caption 1 16  SemiBold',
      'ar': 'التسمية التوضيحية 1 16 شبه غامق',
    },
    '0kebfksw': {
      'en': 'Caption 2 14 Medium',
      'ar': 'التسمية التوضيحية 2 14 متوسطة',
    },
    'afdbsu6v': {
      'en': 'Footnote 13 Regular',
      'ar': 'الحاشية رقم 13 العادية',
    },
    'qghph1j2': {
      'en': 'Button',
      'ar': 'زر',
    },
    'mmor1igi': {
      'en': 'Button',
      'ar': 'زر',
    },
    '78eytsp1': {
      'en': 'label',
      'ar': 'ملصق',
    },
    'q71ykuhf': {
      'en': 'TextField',
      'ar': 'حقل النص',
    },
    'za15g7mm': {
      'en': 'Button',
      'ar': 'زر',
    },
    '32p4mg3h': {
      'en': 'Button',
      'ar': 'زر',
    },
    'g927mar4': {
      'en':
          'This app uses notification to enhance your experience with haptic feedback. Please ensure notification is enabled on your device.',
      'ar':
          'يستخدم هذا التطبيق الإشعارات لتحسين تجربتك من خلال ردود الفعل اللمسية. يُرجى التأكد من تفعيل الإشعارات على جهازك.',
    },
    'to7cmi71': {
      'en':
          'This app uses vibration to enhance your experience with haptic feedback. Please ensure vibration is enabled on your device.',
      'ar':
          'يستخدم هذا التطبيق الاهتزاز لتحسين تجربتك من خلال ردود الفعل اللمسية. يُرجى التأكد من تفعيل الاهتزاز على جهازك.',
    },
    '1kpnfkoq': {
      'en': '',
      'ar': '',
    },
    '7j1nnaqp': {
      'en': '',
      'ar': '',
    },
    'ge7p8vvc': {
      'en': '',
      'ar': '',
    },
    'rfx1k2rp': {
      'en': '',
      'ar': '',
    },
    '0h6uyz45': {
      'en': '',
      'ar': '',
    },
    'dgxxcvky': {
      'en': '',
      'ar': '',
    },
    '686jbmqv': {
      'en': '',
      'ar': '',
    },
    'sopspszx': {
      'en': '',
      'ar': '',
    },
    '72mx9c1c': {
      'en': '',
      'ar': '',
    },
    '2he73kus': {
      'en': '',
      'ar': '',
    },
    'ihhx98ek': {
      'en': '',
      'ar': '',
    },
    '2et96coz': {
      'en': '',
      'ar': '',
    },
    '5hn0fyyr': {
      'en': '',
      'ar': '',
    },
    'hhoa5ty6': {
      'en': '',
      'ar': '',
    },
    'ulk1ghul': {
      'en': '',
      'ar': '',
    },
    'hpxzfyed': {
      'en': '',
      'ar': '',
    },
    '1xn2hx3c': {
      'en': '',
      'ar': '',
    },
    'qc0p53li': {
      'en': '',
      'ar': '',
    },
    'eoa95484': {
      'en': '',
      'ar': '',
    },
    'dvfq0tf6': {
      'en': '',
      'ar': '',
    },
    'j3qnspwk': {
      'en': '',
      'ar': '',
    },
    '5fndnslz': {
      'en': '',
      'ar': '',
    },
    'kdd6s43e': {
      'en': '',
      'ar': '',
    },
    'oadrk00x': {
      'en': '',
      'ar': '',
    },
    'voo9yvw9': {
      'en': '',
      'ar': '',
    },
    'k7vais61': {
      'en': '',
      'ar': '',
    },
    '8hw2u9xf': {
      'en': '',
      'ar': '',
    },
    'q5wzo7kx': {
      'en': '',
      'ar': '',
    },
  },
].reduce((a, b) => a..addAll(b));
