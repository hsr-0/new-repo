import 'package:cosmetic_store/taxi/lib/core/helper/shared_preference_helper.dart';
import 'package:cosmetic_store/taxi/lib/core/helper/string_format_helper.dart';
import 'dart:convert';
import 'package:cosmetic_store/taxi/lib/core/route/route.dart';
import 'package:cosmetic_store/taxi/lib/data/model/global/pusher/pusher_event_response_model.dart';
import 'package:cosmetic_store/taxi/lib/data/services/pusher_service.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/taxi/lib/data/services/api_client.dart';
import 'package:audioplayers/audioplayers.dart';

class GlobalPusherController extends GetxController {
  ApiClient apiClient;
  GlobalPusherController({required this.apiClient});

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void onInit() {
    super.onInit();
    PusherManager().addListener(onEvent);
  }

  // قائمة الأحداث التي نهتم بها
  List<String> activeEventList = [
    "ride_end",
    "pick_up",
    "cash_payment_received",
    "new_bid",
    "ride_accepted",
    "bid_accepted",
    "app\\events\\ride", // إضافة صيغة لارافل الافتراضية
    ".ride_accepted"     // إضافة صيغة النقطة
  ];

  void onEvent(PusherEvent event) async {
    try {
      // 1. تنظيف اسم الحدث وتحويله لحروف صغيرة لضمان المطابقة
      final rawEventName = event.eventName;
      final eventName = rawEventName.toLowerCase();

      printD("🔥 SOCKET RECEIVED: $rawEventName | Data: ${event.data}");

      if (event.data == null || rawEventName == "" || event.data.toString() == "{}") return;

      final data = jsonDecode(event.data);
      final model = PusherResponseModel.fromJson(data);

      // ============================================================
      // 🚀 الحل الجذري: شرط ذكي يقبل كل الاحتمالات 🚀
      // ============================================================
      bool isRideAccepted = false;

      // فحص شامل لكل الصيغ المحتملة لقبول الرحلة
      if (eventName.contains('ride_accepted') ||
          eventName.contains('bid_accepted') ||
          eventName.contains('app\\events\\ride') || // الصيغة التي ظهرت في الفيديو
          (eventName.contains('ride') && eventName.contains('accepted'))) {
        isRideAccepted = true;
      }

      if (isRideAccepted) {
        print("✅ SUCCESS: Driver Accepted Ride. Navigating to Map...");

        // 1. إغلاق أي نوافذ مفتوحة (مثل نافذة البحث)
        if (Get.isDialogOpen ?? false) Get.back();
        if (Get.isBottomSheetOpen ?? false) Get.back();

        // 2. تشغيل الصوت
        try {
          await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
        } catch (e) {
          print("Error playing sound: $e");
        }

        // 3. استخراج رقم الرحلة والانتقال
        // نحاول استخراج الـ ID من عدة أماكن محتملة في الـ JSON
        final rideId = model.data?.ride?.id ??
            model.data?.bid?.rideId ??
            data['ride_id']?.toString() ?? // أحياناً يكون مباشر
            data['ride']?['id']?.toString();

        if (rideId != null) {
          print("🚀 Navigating to RideDetailsScreen with ID: $rideId");
          Get.offNamed(RouteHelper.rideDetailsScreen, arguments: rideId);
        } else {
          print("❌ Error: Ride ID is NULL in the socket response!");
        }
        return;
      }

      // ============================================================
      // التعامل مع باقي الأحداث (نهاية الرحلة، بدء الرحلة، إلخ)
      // ============================================================

      // التحقق من وجود اسم الحدث في القائمة (بشكل مرن)
      bool isActiveEvent = activeEventList.any((e) => eventName.contains(e));

      if (isActiveEvent && !isRideDetailsPage()) {
        final rideId = eventName.contains("new_bid") ? model.data?.bid?.rideId : model.data?.ride?.id;

        if (rideId != null) {
          Get.toNamed(RouteHelper.rideDetailsScreen, arguments: rideId);
        }
      }

    } catch (e) {
      printE("❌ Error handling event ${event.eventName}: $e");
    }
  }

  bool isRideDetailsPage() {
    return Get.currentRoute == RouteHelper.rideDetailsScreen;
  }

  @override
  void onClose() {
    PusherManager().removeListener(onEvent);
    _audioPlayer.dispose();
    super.onClose();
  }

  Future<void> ensureConnection({String? channelName}) async {
    try {
      var userId = apiClient.sharedPreferences.getString(SharedPreferenceHelper.userIdKey) ?? '';
      // التأكد من استخدام القناة الخاصة كما ظهر في اللوج
      await PusherManager().checkAndInitIfNeeded(channelName ?? "private-rider-user-$userId");
    } catch (e) {
      printX("Error ensuring connection: $e");
    }
  }
}