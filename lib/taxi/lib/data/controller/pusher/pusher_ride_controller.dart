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
    final eventName = event.eventName?.toLowerCase();
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

    // ✅ التعديل الجوهري هنا: أضفنا ride_accepted
      case 'ride_accepted':
      case 'ride_active':
        _handleInstantAccept(event);
        break;

      case 'pick_up':
      case 'ride_end':
      case 'bid_accept': // أبقينا عليه للدعم القديم
        _updateRideIfAvailable(event);
        break;

      default:
        _updateRideIfAvailable(event);
        break;
    }
  }

  /// Handlers for each event type

  // 🔥 الدالة الجديدة للتعامل مع القبول الفوري
  void _handleInstantAccept(PusherResponseModel event) {
    // 1. تحديث بيانات الرحلة (ستتحول الحالة إلى ACTIVE)
    _updateRideIfAvailable(event);

    // 2. تشغيل التنبيهات (صوت + هزاز)
    AudioUtils.playAudio(apiClient.getNotificationAudio());
    if (rideDetailsController.repo.apiClient.isNotificationAudioEnable()) {
      MyUtils.vibrate();
    }

    // 3. الخدعة: إغلاق أي ديالوج (مثل ديالوج البحث أو العروض) إذا كان مفتوحاً
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    // 4. الانتقال الإجباري لصفحة التفاصيل إذا لم يكن المستخدم فيها
    // هذا يضمن خروج المستخدم من شاشة "جاري البحث" فوراً
    if (Get.currentRoute != RouteHelper.rideDetailsScreen) {
      // نستخدم ID القادم من الحدث أو الـ ID المحفوظ
      String targetRideId = event.data?.ride?.id ?? rideID;
      printX('🚀 Force navigating to Ride Details for ride: $targetRideId');

      Get.offNamed(
          RouteHelper.rideDetailsScreen,
          arguments: targetRideId
      );
    }
  }

  void _handleOnlinePayment(PusherResponseModel event) {
    printX('Online payment received for ride: ${event.data?.rideId}');
    Get.offAndToNamed(
      RouteHelper.rideReviewScreen,
      arguments: event.data?.rideId ?? '',
    );
  }

  void _handleMessageReceived(PusherResponseModel eventResponse) {
    if (eventResponse.data?.message != null) {
      if (eventResponse.data!.ride != null && eventResponse.data!.ride!.id != rideID) {
        printX('Message for different ride: ${eventResponse.data!.ride!.id}, current ride: $rideID');
        return;
      }
      if (isRideDetailsPage()) {
        if (rideDetailsController.repo.apiClient.isNotificationAudioEnable()) {
          MyUtils.vibrate();
        }
      }

      rideMessageController.addEventMessage(eventResponse.data!.message!);
    }
  }

  void _handleLiveLocation(PusherResponseModel eventResponse) {
    if (eventResponse.data!.ride != null && eventResponse.data!.ride!.id != rideID) {
      printX('Message for different ride: ${eventResponse.data!.ride!.id}, current ride: $rideID');
      return;
    }
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
    // 🛑 حماية إضافية: إذا كانت الرحلة قد قبلت بالفعل، تجاهل أي عروض متأخرة
    if (rideDetailsController.ride.status == AppStatus.RIDE_ACTIVE.toString()) {
      return;
    }

    if (eventResponse.data!.bid != null && eventResponse.data!.bid!.rideId != rideID) {
      printX('Message for different ride: ${eventResponse.data!.bid!.rideId}, current ride: $rideID');
      return;
    }
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
    if (eventResponse.data!.ride != null && eventResponse.data!.ride!.id != rideID) {
      printX('Message for different ride: ${eventResponse.data!.ride!.id}, current ride: $rideID');
      return;
    }
    final ride = eventResponse.data?.ride;
    if (ride != null) {
      rideDetailsController.updateRide(ride);
    }
  }

  /// Utility
  bool isRideDetailsPage() => Get.currentRoute == RouteHelper.rideDetailsScreen;

  @override
  void onClose() {
    PusherManager().removeListener(onEvent);
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