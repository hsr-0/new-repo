import 'package:latlong2/latlong.dart';
import 'package:cosmetic_store/taxi/lib/core/helper/shared_preference_helper.dart';
import 'package:cosmetic_store/taxi/lib/core/helper/string_format_helper.dart';
import 'dart:convert';
import 'package:cosmetic_store/taxi/lib/core/route/route.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/app_status.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/audio_utils.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/util.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/ride/ride_details/ride_details_controller.dart';
import 'package:cosmetic_store/taxi/lib/data/model/general_setting/general_setting_response_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/global/pusher/pusher_event_response_model.dart';
import 'package:cosmetic_store/taxi/lib/data/services/pusher_service.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/dialog/show_custom_bid_dialog.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/ride/ride_meassage/ride_meassage_controller.dart';
import 'package:cosmetic_store/taxi/lib/data/services/api_client.dart';

class PusherRideController extends GetxController {
  ApiClient apiClient;
  RideMessageController rideMessageController;
  RideDetailsController rideDetailsController;
  String rideID;
  PusherRideController({
    required this.apiClient,
    required this.rideMessageController,
    required this.rideDetailsController,
    required this.rideID,
  });

  @override
  void onInit() {
    super.onInit();
    PusherManager().addListener(onEvent);
  }

  PusherConfig pusherConfig = PusherConfig();

  /// Handle incoming Pusher events
  void onEvent(PusherEvent event) {
    try {
      printD('Pusher Channel: ${event.channelName}');
      printD('Pusher Event: ${event.eventName}');
      if (event.data == null) return;

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(event.data);
      } catch (e) {
        printX('Invalid JSON: $e');
        return;
      }

      final model = PusherResponseModel.fromJson(data);
      final modifiedEvent = PusherResponseModel(
        eventName: event.eventName,
        channelName: event.channelName,
        data: model.data,
      );

      updateEvent(modifiedEvent);
    } catch (e) {
      printX('onEvent error: $e');
    }
  }

  /// Update UI or state based on event name
  void updateEvent(PusherResponseModel event) {
    // تنظيف اسم الحدث لضمان المطابقة
    final eventName = event.eventName?.toLowerCase().trim();
    printX('Handling event: $eventName');

    switch (eventName) {
      case 'online_payment_received':
        _handleOnlinePayment(event);
        break;

      case 'message_received':
        _handleMessageReceived(event);
        break;

      case 'live_location':
        _handleLiveLocation(event);
        break;

      case 'new_bid':
        _handleNewBid(event);
        break;

      case 'bid_reject':
        rideDetailsController.updateBidCount(true);
        break;

      case 'cash_payment_received':
        _handleCashPayment(event);
        break;

    // ✅ تم تحديث حالات القبول لتشمل كل ما يرسله السيرفر في Pusher
      case 'ride_accepted':
      case 'ride_accept':
      case 'ride.accepted':
      case 'bid_accepted':
      case 'bid_accept':
      case 'accepted':
        _handleInstantAccept(event);
        break;

      case 'pick_up':
      case 'ride_end':
        _updateRideIfAvailable(event);
        break;

      default:
        _updateRideIfAvailable(event);
        break;
    }
  }

  // 🔥 الدالة المُحدثة للتعامل مع القبول الفوري
  void _handleInstantAccept(PusherResponseModel event) {
    printX('🔥 RIDE ACCEPTED TRIGGERED! Forcing UI Refresh...');

    // 1. إغلاق أي ديالوج مفتوح
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    // 2. تحديث حالة الرحلة داخلياً
    rideDetailsController.ride.status = AppStatus.RIDE_ACTIVE.toString();

    // 3. تحديث البيانات فوراً من السيرفر (لسحب معلومات السائق)
    rideDetailsController.getRideDetails(rideID);

    // 4. التنبيهات
    AudioUtils.playAudio(apiClient.getNotificationAudio());
    if (rideDetailsController.repo.apiClient.isNotificationAudioEnable()) {
      MyUtils.vibrate();
    }

    // 5. التأكد من الانتقال لشاشة تفاصيل الرحلة الحية
    if (Get.currentRoute != RouteHelper.rideDetailsScreen) {
      String targetRideId = event.data?.ride?.id ?? rideID;
      Get.offNamed(
          RouteHelper.rideDetailsScreen,
          arguments: targetRideId
      );
    }
  }

  void _handleOnlinePayment(PusherResponseModel event) {
    Get.offAndToNamed(
      RouteHelper.rideReviewScreen,
      arguments: event.data?.rideId ?? '',
    );
  }

  void _handleMessageReceived(PusherResponseModel eventResponse) {
    if (eventResponse.data?.message != null) {
      if (eventResponse.data!.ride != null && eventResponse.data!.ride!.id != rideID) return;
      if (isRideDetailsPage()) {
        if (rideDetailsController.repo.apiClient.isNotificationAudioEnable()) {
          MyUtils.vibrate();
        }
      }
      rideMessageController.addEventMessage(eventResponse.data!.message!);
    }
  }

  void _handleLiveLocation(PusherResponseModel eventResponse) {
    if (eventResponse.data!.ride != null && eventResponse.data!.ride!.id != rideID) return;
    if (rideDetailsController.ride.status == AppStatus.RIDE_ACTIVE.toString() || rideDetailsController.ride.status == AppStatus.RIDE_RUNNING.toString()) {
      final lat = StringConverter.formatDouble(eventResponse.data?.driverLatitude ?? '0', precision: 10);
      final lng = StringConverter.formatDouble(eventResponse.data?.driverLongitude ?? '0', precision: 10);

      rideDetailsController.mapController.updateDriverLocation(
        latLng: LatLng(lat, lng),
        isRunning: false,
      );
    }
  }

  void _handleNewBid(PusherResponseModel eventResponse) {
    if (rideDetailsController.ride.status == AppStatus.RIDE_ACTIVE.toString()) return;

    if (eventResponse.data!.bid != null && eventResponse.data!.bid!.rideId != rideID) return;
    final bid = eventResponse.data?.bid;
    if (bid != null) {
      AudioUtils.playAudio(apiClient.getNotificationAudio());
      if (rideDetailsController.repo.apiClient.isNotificationAudioEnable()) {
        MyUtils.vibrate();
      }

      CustomBidDialog.newBid(
        bid: bid,
        currency: rideDetailsController.currencySym,
        driverImagePath: '${rideDetailsController.driverImagePath}/${bid.driver?.avatar}',
        serviceImagePath: '${rideDetailsController.serviceImagePath}/${eventResponse.data?.service?.image}',
        totalRideCompleted: eventResponse.data?.driverTotalRide ?? '0',
      );
    }
    rideDetailsController.updateBidCount(false);
  }

  void _handleCashPayment(PusherResponseModel event) {
    rideDetailsController.updatePaymentRequested(isRequested: false);
    _updateRideIfAvailable(event);
  }

  void _updateRideIfAvailable(PusherResponseModel eventResponse) {
    if (eventResponse.data!.ride != null && eventResponse.data!.ride!.id != rideID) return;
    final ride = eventResponse.data?.ride;
    if (ride != null) {
      rideDetailsController.updateRide(ride);
    }
  }

  bool isRideDetailsPage() => Get.currentRoute == RouteHelper.rideDetailsScreen;

  @override
  void onClose() {
    PusherManager().removeListener(onEvent);
    super.onClose();
  }

  // ✅ تعديل هام: تغيير "user" إلى "rider" لتطابق قناة الإرسال في السيرفر
  Future<void> ensureConnection({String? channelName}) async {
    try {
      var userId = apiClient.sharedPreferences.getString(SharedPreferenceHelper.userIdKey) ?? '';
      // التغيير هنا ليتطابق مع: private-rider-rider-ID
      await PusherManager().checkAndInitIfNeeded(channelName ?? "private-rider-rider-$userId");
    } catch (e) {
      printX("Error ensuring connection: $e");
    }
  }
}