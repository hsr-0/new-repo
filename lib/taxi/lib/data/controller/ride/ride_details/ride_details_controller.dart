import 'dart:async'; // ✅ تمت إضافة هذه المكتبة لدعم المؤقت (Timer)
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:cosmetic_store/taxi/lib/core/helper/string_format_helper.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_strings.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/url_container.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/util.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/map/ride_map_controller.dart';
import 'package:cosmetic_store/taxi/lib/data/model/authorization/authorization_response_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/bid/bid_list_response_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/global/app/review_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/global/app/ride_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/global/bid/bid_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/global/response_model/response_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/ride/ride_details_response_model.dart';
import 'package:cosmetic_store/taxi/lib/data/repo/ride/ride_repo.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/snack_bar/show_custom_snackbar.dart';

class RideDetailsController extends GetxController {
  RideRepo repo;
  RideMapController mapController;
  RideDetailsController({required this.repo, required this.mapController});

  RideModel ride = RideModel(id: '-1');
  String currency = '';
  String currencySym = '';
  bool isLoading = true;
  bool isPaymentRequested = false;
  LatLng pickupLatLng = const LatLng(0, 0);
  LatLng destinationLatLng = const LatLng(0, 0);
  String rideId = '-1';
  String serviceImagePath = '';
  String brandImagePath = '';
  String driverImagePath = '';
  String driverTotalCompletedRide = '';
  List<String> tipsList = [];

  TextEditingController tipsController = TextEditingController();

  // ==========================================
  // 🔥 بداية إضافة المؤقت الذكي (Polling Fallback)
  // ==========================================
  Timer? _fallbackTimer;

  @override
  void onClose() {
    stopPollingFallback(); // إيقاف المؤقت عند إغلاق الشاشة لمنع استهلاك البطارية
    super.onClose();
  }

  void startPollingFallback(String id) {
    stopPollingFallback(); // التأكد من عدم تشغيل أكثر من مؤقت

    // تشغيل المؤقت كل 10 ثواني (يمكنك تقليلها إلى 5 ثواني إذا أردت استجابة أسرع)
    _fallbackTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      // إذا اكتملت الرحلة أو تم إلغاؤها، نوقف المؤقت لكي لا نضغط على السيرفر
      if (ride.status == "3" || ride.status == "4" || ride.status == "9") {
        stopPollingFallback();
        return;
      }

      // تحديث بيانات الرحلة وقائمة السائقين بصمت (بدون إظهار دائرة التحميل)
      await getRideBidList(id);
      await getRideDetails(id, shouldLoading: false);
    });
  }

  void stopPollingFallback() {
    _fallbackTimer?.cancel();
  }
  // ==========================================
  // نهاية قسم المؤقت الذكي
  // ==========================================

  void updateTips(String amount) {
    tipsController.text = amount;
    update();
  }

  void updatePaymentRequested({bool isRequested = true}) {
    isPaymentRequested = isRequested;
    update();
  }

  void updateRide(RideModel updatedRide) {
    ride = updatedRide;
    update();
    printD('Updated ride: $ride');
  }

  void initialData(String id) async {
    currency = repo.apiClient.getCurrency();
    currencySym = repo.apiClient.getCurrency(isSymbol: true);
    rideId = id;
    totalBids = 0;
    bids = [];
    cancelReasonController.text = '';
    isLoading = true;
    isPaymentRequested = false;
    tipsList = repo.apiClient.getTipsList();
    update();

    await Future.wait([
      getRideBidList(id),
      getRideDetails(id),
    ]);
    isLoading = false;
    update();

    // ✅ تشغيل المؤقت الذكي بمجرد فتح الشاشة وانتهاء التحميل الأولي
    startPollingFallback(id);
  }

  //ride
  Future<void> getRideDetails(String id, {bool shouldLoading = true}) async {
    currency = repo.apiClient.getCurrency();
    currencySym = repo.apiClient.getCurrency(isSymbol: true);
    rideId = id;

    if (shouldLoading) bids = [];
    isLoading = shouldLoading;
    update();

    ResponseModel responseModel = await repo.getRideDetails(id);
    if (responseModel.statusCode == 200) {
      RideDetailsResponseModel model = RideDetailsResponseModel.fromJson((responseModel.responseJson));
      if (model.status == MyStrings.success) {
        RideModel? tempRide = model.data?.ride;
        if (tempRide != null) {
          ride = tempRide;
          driverTotalCompletedRide = model.data?.driverTotalRide ?? '';

          pickupLatLng = LatLng(
            StringConverter.formatDouble(
              tempRide.pickupLatitude.toString(),
              precision: 16,
            ),
            StringConverter.formatDouble(
              tempRide.pickupLongitude.toString(),
              precision: 16,
            ),
          );
          destinationLatLng = LatLng(
            StringConverter.formatDouble(
              tempRide.destinationLatitude.toString(),
              precision: 16,
            ),
            StringConverter.formatDouble(
              tempRide.destinationLongitude.toString(),
              precision: 14,
            ),
          );
        }
        serviceImagePath = '${UrlContainer.domainUrl}/${model.data?.serviceImagePath ?? ''}';
        brandImagePath = '${UrlContainer.domainUrl}/${model.data?.brandImagePath ?? ''}';
        driverImagePath = '${UrlContainer.domainUrl}/${model.data?.driverImagePath}';

        update();
        mapController.loadMap(
          pickup: pickupLatLng,
          destination: destinationLatLng,
          isRunning: ride.status == "3",
        );
      } else {
        if (shouldLoading) Get.back();
      }
    } else {
      if (shouldLoading) CustomSnackBar.error(errorList: [responseModel.message]);
    }
    isLoading = false;
    update();
  }

  //bid
  List<BidModel> bids = [];
  List<BidModel> tempBids = [];
  int totalBids = 0;

  Future<void> getRideBidList(String id) async {
    try {
      ResponseModel responseModel = await repo.getRideBidList(id: id);
      if (responseModel.statusCode == 200) {
        BidListResponseModel model = BidListResponseModel.fromJson((responseModel.responseJson));
        if (model.status == "success") {
          bids = model.data?.bids ?? [];
          totalBids = bids.length;
          update(); // هذا التحديث سيجعل قائمة السائقين تظهر للزبون حتى لو تعطل Pusher
        }
      }
    } catch (e) {
      printX(e);
    }
  }

  void updateTempBid({required BidModel bid, bool isRemoved = false}) {
    if (isRemoved) {
      tempBids.remove(bid);
    } else {
      tempBids.add(bid);
    }
    update();
  }

  void updateBidCount(bool remove) {
    if (totalBids > 0 && remove) {
      totalBids--;
    } else {
      totalBids++;
    }
    update();
  }

  bool isAcceptLoading = false;
  String selectedId = '-1';
  Future<void> acceptBid(String id, {VoidCallback? onSuccess}) async {
    isAcceptLoading = true;
    selectedId = id;
    update();
    try {
      ResponseModel responseModel = await repo.acceptBid(bidId: id);
      if (responseModel.statusCode == 200) {
        RideDetailsResponseModel model = RideDetailsResponseModel.fromJson((responseModel.responseJson));
        if (model.status == "success") {
          await getRideDetails(ride.id ?? "", shouldLoading: false);
          onSuccess?.call();
        } else {
          CustomSnackBar.error(
            errorList: model.message ?? [MyStrings.somethingWentWrong],
            dismissAll: false,
          );
        }
      } else {
        CustomSnackBar.error(
          errorList: [responseModel.message],
          dismissAll: false,
        );
      }
    } catch (e) {
      printX(e);
    }
    selectedId = '-1';
    isAcceptLoading = false;
    update();
  }

  bool isRejectLoading = false;

  Future<void> rejectBid(String id, {VoidCallback? onSuccess}) async {
    isRejectLoading = true;
    selectedId = id;
    update();
    try {
      ResponseModel responseModel = await repo.rejectBid(id: id);
      if (responseModel.statusCode == 200) {
        RideDetailsResponseModel model = RideDetailsResponseModel.fromJson((responseModel.responseJson));
        if (model.status == "success") {
          await getRideDetails(ride.id ?? "", shouldLoading: false);
          onSuccess?.call();
        } else {
          CustomSnackBar.error(
            errorList: model.message ?? [MyStrings.somethingWentWrong],
            dismissAll: false,
          );
        }
      } else {
        CustomSnackBar.error(
          errorList: [responseModel.message],
          dismissAll: false,
        );
      }
    } catch (e) {
      printX(e);
    }
    isRejectLoading = false;
    selectedId = '-1';
    update();
  }

  //sos
  TextEditingController sosMsgController = TextEditingController();
  bool isSosLoading = false;
  Future<void> sos(String id) async {
    isSosLoading = true;
    update();
    Position position = await MyUtils.getCurrentPosition();
    try {
      ResponseModel responseModel = await repo.sos(
        id: ride.id ?? "-1",
        msg: sosMsgController.text,
        latLng: LatLng(position.latitude, position.longitude),
      );
      if (responseModel.statusCode == 200) {
        AuthorizationResponseModel model = AuthorizationResponseModel.fromJson((responseModel.responseJson));
        if (model.status == "success") {
          sosMsgController.text = '';
          update();
          CustomSnackBar.success(successList: model.message ?? ["Success"]);
        } else {
          CustomSnackBar.error(errorList: model.message ?? ["Error"]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
    }

    isSosLoading = false;
    update();
  }

  //cancel
  bool isCancelLoading = false;
  TextEditingController cancelReasonController = TextEditingController();
  Future<void> cancelRide() async {
    isCancelLoading = true;
    update();
    try {
      ResponseModel responseModel = await repo.cancelRide(
        id: ride.id ?? "-1",
        reason: cancelReasonController.text,
      );
      if (responseModel.statusCode == 200) {
        AuthorizationResponseModel model = AuthorizationResponseModel.fromJson((responseModel.responseJson));
        if (model.status == "success") {
          await getRideDetails(rideId, shouldLoading: false);
          Get.back();
          CustomSnackBar.success(successList: model.message ?? ["Success"]);
        } else {
          CustomSnackBar.error(errorList: model.message ?? ["Error"]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
    }
    isCancelLoading = false;
    update();
  }

  //review
  double rating = 0.0;
  TextEditingController reviewMsgController = TextEditingController();
  bool isReviewLoading = false;
  Future<void> reviewRide(String rideId) async {
    isReviewLoading = true;
    update();

    try {
      ResponseModel responseModel = await repo.reviewRide(
        rideId: rideId,
        rating: rating.toString(),
        review: reviewMsgController.text,
      );
      if (responseModel.statusCode == 200) {
        AuthorizationResponseModel model = AuthorizationResponseModel.fromJson((responseModel.responseJson));

        if (model.status == MyStrings.success) {
          ride.driverReview = UserReview(
            rating: rating.toString(),
            review: reviewMsgController.text,
          );
          reviewMsgController.text = '';
          rating = 0.0;
          update();

          Get.back();
          CustomSnackBar.success(successList: model.message ?? []);
        } else {
          CustomSnackBar.error(
            errorList: model.message ?? [MyStrings.somethingWentWrong],
          );
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
    }
    isReviewLoading = false;
    update();
  }

  void updateRating(double rate) {
    rating = rate;
    update();
  }
}