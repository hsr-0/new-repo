import 'package:flutter/material.dart';
import 'package:cosmetic_store/lab/lib/app/screen/home/home_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/chat/chat_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/home_visit/home_visit_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/labDetail/about_lab_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/labDetail/lab_detail_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/labDetail/lab_location_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/mycard/add_new_card_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/mycard/edit_card_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/nearby_lab_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/profile/my_profile_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/search_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/settings/notification_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/specialist_detail_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/test_report/test_report_Screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/tests/payment_method_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/tests/review_test_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/tests/tests_lists_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/tests_panel_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/lists/top_specialist_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/login/forgot_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/login/login_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/login/reset_password_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/sign_up/sign_up_screen.dart';
import 'package:cosmetic_store/lab/lib/app/screen/sign_up/verification_screen.dart';
import 'package:cosmetic_store/lab/lib/app/splash_screen.dart';
import '../screen/intro/intro_screen.dart';
import '../screen/lists/home_visit/my_home_visit_screen.dart';
import '../screen/lists/labDetail/lab_reviews_screen.dart';
import '../screen/lists/mycard/my_card_screen.dart';
import '../screen/lists/profile/edit_profile_screen.dart';
import '../screen/lists/settings/reminder_screen.dart';
import '../screen/lists/settings/settings_screen.dart';
import '../screen/lists/tests/payment_gateway_screen.dart';
import '../screen/lists/tests/payment_screen.dart';
import '../screen/lists/tests/test_detail_screen.dart';
import '../screen/sign_up/select_country_screen.dart';
import 'app_routes.dart';

class AppPages {
  static const initialRoute = Routes.homeRoute;
  static Map<String, WidgetBuilder> routes = {
    Routes.homeRoute: (context) => const SplashScreen(),
    Routes.introRoute: (context) => const IntroScreen(),
    Routes.loginRoute: (context) => const LoginScreen(),
    Routes.forgotRoute: (context) => const ForgotScreen(),
    Routes.resetPasswordRoute: (context) => const ResetPasswordScreen(),
    Routes.signUpRoute: (context) => const SignUpScreen(),
    Routes.selectCountryRoute: (context) => const SelectCountryScreen(),
    Routes.verificationRoute: (context) => const VerificationScreen(),
    Routes.homeScreenRoute: (context) => const HomeScreen(),
    Routes.searchScreenRoute: (context) => const SearchScreen(),
    Routes.nearbyLabScreenRoute: (context) => const NearbyLabScreen(),
    Routes.topSpecialistScreenRoute: (context) => const TopSpecialistScreen(),
    Routes.specialistDetailScreenRoute: (context) =>
        const SpecialistDetailScreen(),
    Routes.testsListsScreenRoute: (context) => const TestsListsScreen(),
    Routes.labDetailScreenRoute: (context) => const LabDetailScreen(),
    Routes.aboutLabScreenRoute: (context) => const AboutLabScreen(),
    Routes.labLocationScreenRoute: (context) => const LabLocationScreen(),
    Routes.labReviewsScreenRoute: (context) => const LabReviewsScreen(),
    Routes.testReportScreenRoute: (context) => const TestReportScreen(),
    Routes.homeVisitScreenRoute: (context) => const HomeVisitScreen(),
    Routes.chatScreenRoute: (context) => const ChatScreen(),
    Routes.myProfileScreenRoute: (context) => const MyProfileScreen(),
    Routes.editProfileScreenRoute: (context) => const EditProfileScreen(),
    Routes.testDetailScreenRoute: (context) => const TestDetailScreen(),
    Routes.reviewTestScreenRoute: (context) => const ReviewTestScreen(),
    Routes.paymentMethodScreenRoute: (context) => const PaymentMethodScreen(),
    Routes.paymentScreenRoute: (context) => const PaymentScreen(),
    Routes.paymentGatewayScreenRoute: (context) => const PaymentGatewayScreen(),
    Routes.myCardScreenRoute: (context) => const MyCardScreen(),
    Routes.addNewCardScreenRoute: (context) => const AddNewCardScreen(),
    Routes.editCardScreenRoute: (context) => const EditCardScreen(),
    Routes.myHomeVisitScreenRoute: (context) => const MyHomeVisitScreen(),
    Routes.settingsScreenRoute: (context) => const SettingsScreen(),
    Routes.notificationScreenRoute: (context) => const NotificationScreen(),
    Routes.reminderScreenRoute: (context) => const ReminderScreen(),
    Routes.testsPanelScreenRoute: (context) => const TestsPanelScreen(),
  };
}
