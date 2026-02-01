import 'package:cosmetic_store/taxi/lib/core/helper/shared_preference_helper.dart';
import 'package:cosmetic_store/taxi/lib/core/helper/string_format_helper.dart';
import 'dart:convert';
import 'package:cosmetic_store/taxi/lib/core/route/route.dart';
import 'package:cosmetic_store/taxi/lib/data/model/global/pusher/pusher_event_response_model.dart';
import 'package:cosmetic_store/taxi/lib/data/services/pusher_service.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/taxi/lib/data/services/api_client.dart';
// 1. استدعاء مكتبة الصوت
import 'package:audioplayers/audioplayers.dart';

class GlobalPusherController extends GetxController {
  ApiClient apiClient;
  GlobalPusherController({required this.apiClient});

  // تعريف مشغل الصوت
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void onInit() {
    super.onInit();
    PusherManager().addListener(onEvent);
  }

  List<String> activeEventList = [
    "ride_end",
    "pick_up",
    "cash_payment_received",
    "new_bid",
    "ride_accepted",
    "bid_accepted"
  ];

  void onEvent(PusherEvent event) async { // لاحظ إضافة async هنا
    try {
      printD("Global pusher event: ${event.eventName}");

      if (event.data == null || event.eventName == "" || event.data.toString() == "{}") return;

      final eventName = event.eventName.toLowerCase();
      final data = jsonDecode(event.data);
      final model = PusherResponseModel.fromJson(data);

      // ============================================================
      // 🔥 تشغيل الصوت والانتقال عند القبول الفوري 🔥
      // ============================================================
      if (eventName == 'ride_accepted' || eventName == 'bid_accepted') {

        print("✅ Event Received: Driver Accepted - Playing Sound...");

        // 1. إغلاق نوافذ الانتظار
        if (Get.isDialogOpen ?? false) Get.back();
        if (Get.isBottomSheetOpen ?? false) Get.back();

        // 2. تشغيل النغمة 🔊
        try {
          // تأكد أن ملف الصوت موجود في: assets/sounds/notification.mp3
          await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
          // إذا أردت صوتاً قوياً واهتزازاً، يمكنك استخدام Vibrate أيضاً إذا أضفت مكتبتها
        } catch (e) {
          print("Error playing sound: $e");
        }

        // 3. الانتقال للخريطة
        final rideId = model.data?.ride?.id ?? model.data?.bid?.rideId;
        if (rideId != null) {
          Get.offNamed(RouteHelper.rideDetailsScreen, arguments: rideId);
        }
        return;
      }

      // باقي الأحداث (القديمة)
      if (activeEventList.contains(eventName) && !isRideDetailsPage()) {
        // يمكnew_bid إذا أردت
        /*
        if (eventName == "new_bid") {
             _audioPlayer.play(AssetSource('sounds/notification.mp3'));
        }
        */

        final rideId = eventName == "new_bid" ? model.data?.bid?.rideId : model.data?.ride?.id;
        if (rideId != null) {
          Get.toNamed(RouteHelper.rideDetailsScreen, arguments: rideId);
        }
      }

    } catch (e) {
      printE("Error handling event ${event.eventName}: $e");
    }
  }

  bool isRideDetailsPage() {
    return Get.currentRoute == RouteHelper.rideDetailsScreen;
  }

  @override
  void onClose() {
    PusherManager().removeListener(onEvent);
    _audioPlayer.dispose(); // تنظيف الذاكرة
    super.onClose();
  }

  Future<void> ensureConnection({String? channelName}) async {
    try {
      var userId = apiClient.sharedPreferences.getString(SharedPreferenceHelper.userIdKey) ?? '';
      await PusherManager().checkAndInitIfNeeded(channelName ?? "private-rider-user-$userId");
    } catch (e) {
      printX("Error ensuring connection: $e");
    }
  }
}
