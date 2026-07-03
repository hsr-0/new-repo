import 'dart:async';
import 'dart:convert'; // ✅ تمت الإضافة للتعامل مع JSON
import 'package:http/http.dart' as http; // ✅ تمت الإضافة للاتصال بالسيرفر
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/taxi/lib/core/helper/date_converter.dart';
import 'package:cosmetic_store/taxi/lib/core/helper/string_format_helper.dart';
import 'package:cosmetic_store/taxi/lib/core/route/route.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_strings.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/location/app_location_controller.dart';
import 'package:cosmetic_store/taxi/lib/data/model/dashboard/dashboard_response_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/global/app/app_payment_method.dart';
import 'package:cosmetic_store/taxi/lib/data/model/global/app/app_service_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/global/app/ride_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/global/response_model/response_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/ride/create_ride_request_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/global/user/global_user_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/ride/create_ride_response_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/ride/ride_fare_response_model.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/util.dart';
import 'package:cosmetic_store/taxi/lib/data/model/general_setting/general_setting_response_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/location/selected_location_info.dart';
import 'package:cosmetic_store/taxi/lib/data/repo/home/home_repo.dart';
import 'package:cosmetic_store/taxi/lib/data/services/running_ride_service.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/bottom-sheet/custom_bottom_sheet.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/dialog/app_dialog.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:cosmetic_store/taxi/lib/presentation/screens/home/widgets/bottomsheet/ride_distance_warning_bottom_sheet.dart';

class HomeController extends GetxController {
  HomeRepo homeRepo;
  AppLocationController appLocationController;
  HomeController({required this.homeRepo, required this.appLocationController});

  TextEditingController amountController = TextEditingController();
  TextEditingController noteController = TextEditingController();

  // ==========================================
  // 🔥 متغيرات نظام الخصومات (Promo Code)
  // ==========================================
  TextEditingController promoCodeController = TextEditingController();
  bool isCouponApplied = false;
  String appliedCouponCode = '';
  String appliedCouponId = '';
  double discountAmount = 0.0;
  double originalAmount = 0.0; // حفظ السعر الأصلي قبل الخصم
  List<dynamic> availableCoupons = [];
  // ==========================================

  double mainAmount = 0;
  String email = "";
  bool isLoading = true;
  String username = "";

  String serviceImagePath = "";
  String gatewayImagePath = "";
  String userImagePath = "";

  String defaultCurrency = "";
  String defaultCurrencySymbol = "";
  String currentAddress = "${MyStrings.loading.tr}...";
  int passenger = 1;
  Position? currentPosition;
  GlobalUser user = GlobalUser(id: '-1');
  List<AppService> appServicesList = [];
  List<AppPaymentMethod> paymentMethodList = [];
  RideModel runningRide = RideModel(id: "-1");
  bool isKycVerified = true;
  bool isKycPending = false;

  // قائمة لحفظ السائقين القريبين
  List<dynamic> nearbyDrivers = [];

  @override
  void onClose() {
    promoCodeController.dispose();
    super.onClose();
  }

  void updatePassenger(bool isIncrement) {
    if (isIncrement) {
      passenger = passenger + 1;
    } else {
      passenger > 1 ? passenger-- : passenger = 1;
    }
    update();
  }

  GeneralSettingResponseModel generalSettingResponseModel = GeneralSettingResponseModel();

  Future<void> initialData({bool shouldLoad = true}) async {
    isLoading = shouldLoad;
    defaultCurrency = homeRepo.apiClient.getCurrency();
    defaultCurrencySymbol = homeRepo.apiClient.getCurrency(isSymbol: true);
    username = homeRepo.apiClient.getUserName();
    email = homeRepo.apiClient.getUserEmail();
    generalSettingResponseModel = homeRepo.apiClient.getGeneralSettings();
    minimumDistance = double.tryParse(homeRepo.apiClient.getMinimumRideDistance()) ?? 0.0;

    fetchLocation();
    await loadData(shouldLoad: shouldLoad);

    if (selectedLocations.length > 1) {
      await getRideFare();
    }
    isLoading = false;
    update();
  }

  Future<void> fetchLocation() async {
    bool hasPermission = await MyUtils.checkAppLocationPermission(onsuccess: () {
      initialData();
    });

    if (hasPermission) {
      currentPosition = await appLocationController.getCurrentPosition();
      currentAddress = appLocationController.currentAddress;

      if (selectedLocations.length != 2) {
        SelectedLocationInfo location = SelectedLocationInfo(
          address: currentAddress,
          fullAddress: currentAddress,
          latitude: appLocationController.currentPosition.latitude,
          longitude: appLocationController.currentPosition.longitude,
        );
        addLocationAtIndex(location, 0);
      }

      if (currentPosition != null) {
        fetchNearbyDrivers(currentPosition!.latitude, currentPosition!.longitude);
      }

      update();
    }
  }

  Future<void> loadData({bool shouldLoad = true}) async {
    isLoading = shouldLoad;
    update();
    try {
      ResponseModel responseModel = await homeRepo.getData();
      if (responseModel.statusCode == 200) {
        DashBoardResponseModel model = DashBoardResponseModel.fromJson((responseModel.responseJson));
        if (model.status == MyStrings.success && model.data != null) {
          appServicesList = model.data?.services ?? [];
          paymentMethodList = model.data?.paymentMethod ?? [];
          paymentMethodList.insertAll(0, MyUtils.getDefaultPaymentMethod());
          user = model.data?.userInfo ?? GlobalUser(id: '-1');
          serviceImagePath = model.data?.serviceImagePath ?? '';
          gatewayImagePath = model.data?.gatewayImagePath ?? '';
          userImagePath = model.data?.userImagePath ?? '';

          if (model.data?.runningRide != null && RunningRideService.instance.isRunningShow == false) {
            RunningRideService.instance.setIsRunning(true);
            runningRide = model.data!.runningRide!;
            AppDialog().showRideDetailsDialog(
              Get.context!,
              title: MyStrings.runningRideAlertTitle.tr,
              description: MyStrings.runningRideAlertSubTitle,
              barrierDismissible: true,
              onTap: () {
                Get.toNamed(
                  RouteHelper.rideDetailsScreen,
                  arguments: runningRide.id,
                );
              },
              onClose: () {
                Get.closeAllSnackbars();
                Get.back();
              },
            );
          }
          update();
        } else {
          CustomSnackBar.error(errorList: model.message ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e.toString());
    } finally {
      isLoading = false;
      update();
    }
  }

  bool isSubmitLoading = false;
  Future<void> createRide() async {
    isSubmitLoading = true;
    update();
    try {
      // إرسال تنبيه في الملاحظات للسيرفر بوجود خصم كإجراء احتياطي
      String finalNote = noteController.text;
      if (isCouponApplied) {
        finalNote = "$finalNote [تم تطبيق كود خصم: $appliedCouponCode]";
      }

      ResponseModel responseModel = await homeRepo.createRide(
        data: CreateRideRequestModel(
          serviceId: selectedService.id!,
          pickUpLocation: selectedLocations[0].fullAddress ?? "",
          pickUpLatitude: selectedLocations[0].latitude.toString(),
          pickUpLongitude: selectedLocations[0].longitude.toString(),
          destinationLocation: selectedLocations[1].fullAddress ?? "",
          destinationLatitude: selectedLocations[1].latitude.toString(),
          destinationLongitude: selectedLocations[1].longitude.toString(),
          isIntercity: rideFare.rideType?.toString() ?? '',
          pickUpDateTime: DateConverter.estimatedDate(DateTime.now()),
          numberOfPassenger: passenger.toString(),
          note: finalNote,
          offerAmount: mainAmount.toString(), // يتم إرسال السعر المخفض
          paymentType: selectedPaymentMethod.id == "-9" ? "2" : '1',
          gatewayCurrencyId: selectedPaymentMethod.id!,
        ),
      );
      if (responseModel.statusCode == 200) {
        CreateRideResponseModel model = CreateRideResponseModel.fromJson((responseModel.responseJson));
        if (model.status == MyStrings.success) {
          clearData();
          if (Get.currentRoute != RouteHelper.rideDetailsScreen) {
            Get.toNamed(
              RouteHelper.rideDetailsScreen,
              arguments: model.data?.ride?.id,
            );
          }
        } else {
          CustomSnackBar.error(errorList: model.message ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
    } finally {
      isSubmitLoading = false;
      update();
    }
  }

  RideFareModel rideFare = RideFareModel();
  Future<void> getRideFare() async {
    try {
      isPriceLocked = true;
      update();
      ResponseModel responseModel = await homeRepo.getRideFare(
        data: CreateRideRequestModel(
          serviceId: selectedService.id.toString(),
          pickUpLocation: selectedLocations[0].city.toString(),
          pickUpLatitude: selectedLocations[0].latitude.toString(),
          pickUpLongitude: selectedLocations[0].longitude.toString(),
          destinationLocation: selectedLocations[1].city.toString(),
          destinationLatitude: selectedLocations[1].latitude.toString(),
          destinationLongitude: selectedLocations[1].longitude.toString(),
          isIntercity: '1',
          pickUpDateTime: '',
          numberOfPassenger: '',
          note: '',
          offerAmount: '',
          paymentType: '',
          gatewayCurrencyId: '',
        ),
      );
      if (responseModel.statusCode == 200) {
        RideFareResponseModel model = RideFareResponseModel.fromJson((responseModel.responseJson));
        if (model.status == MyStrings.success) {
          rideFare = model.data ?? RideFareModel();
          appServicesList = model.data?.services ?? [];
          isPriceLocked = false;
          if (selectedService.id != "-99") {
            try {
              selectService(appServicesList.firstWhere((v) => v.id == selectedService.id));
            } catch (e) {
              printE(e);
            }
          }
          distance = double.tryParse(rideFare.distance.toString()) ?? 0.0;
          if (distance < minimumDistance) {
            distanceAlert();
          } else {
            isLocationShake = true;
          }
        } else {
          rideFare = RideFareModel();
          CustomSnackBar.error(errorList: model.message ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        isPriceLocked = true;
        rideFare = RideFareModel();
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
    }
    update();
  }

  //Handle Ride Functionality Start From here
  TextEditingController pickUpLocation = TextEditingController();
  SelectedLocationInfo? pickUpLocationInfo;
  TextEditingController pickUpDestination = TextEditingController();
  SelectedLocationInfo? pickUpDestinationInfo;

  List<SelectedLocationInfo> selectedLocations = [];
  bool isServiceShake = false;
  bool isLocationShake = false;
  void updateIsServiceShake(bool value) {
    isServiceShake = value;
    update();
  }

  Future<void> addLocationAtIndex(
      SelectedLocationInfo selectedLocationInfo,
      int index, {
        bool getFareData = false,
      }) async {
    SelectedLocationInfo newLocation = selectedLocationInfo;
    if (selectedLocations.length > index && index >= 0) {
      selectedLocations[index] = newLocation;
    } else {
      selectedLocations.add(newLocation);
    }
    update();

    if (index == 0 && newLocation.latitude != null && newLocation.longitude != null) {
      fetchNearbyDrivers(newLocation.latitude!, newLocation.longitude!);
    }

    if (selectedLocations.length >= 2 && selectedService.id != "-99" && getFareData == true) {
      getRideFare();
      removePromoCode(); // إلغاء الخصم في حال تغيير المسار لتجنب الأخطاء
    }
  }

  Future<void> fetchNearbyDrivers(double lat, double lng) async {
    try {
      final String url = 'https://taxi.beytei.com/api/nearby-drivers?lat=$lat&lng=$lng';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          nearbyDrivers = data['data'];
          update();
        }
      }
    } catch (e) {
      print("❌ خطأ في جلب السائقين القريبين: $e");
    }
  }

  SelectedLocationInfo? getSelectedLocationInfoAtIndex(int index) {
    if (index >= 0 && index < selectedLocations.length) {
      return selectedLocations[index];
    } else {
      return null;
    }
  }

  double distance = -1;
  double minimumDistance = -1;

  void updateMainAmount(double amount) {
    mainAmount = amount;
    amountController.text = StringConverter.formatNumber(mainAmount.toString());
    update();
  }

  AppPaymentMethod selectedPaymentMethod = MyUtils.getDefaultPaymentMethod()[0];
  void selectPaymentMethod(AppPaymentMethod method) {
    selectedPaymentMethod = method;
    update();
    Get.back();
  }

  AppService selectedService = AppService(id: '-99');

  bool isPriceLocked = false;
  Future<void> selectService(AppService service, {bool shouldLoadFare = false}) async {
    try {
      update();
      if (selectedLocations.length > 1) {
        selectedService = service;
        update();
        if (shouldLoadFare) {
          await getRideFare();
        }

        // حفظ السعر الأصلي قبل أي خصم
        originalAmount = StringConverter.formatDouble(service.recommendAmount.toString());
        mainAmount = originalAmount;
        amountController.text = mainAmount.toString();

        // إلغاء كود الخصم إذا كان مطبقاً لكي لا يختل الحساب عند تغيير نوع السيارة
        removePromoCode();

      } else {
        CustomSnackBar.error(errorList: [MyStrings.pleaseSelectPickupAndDestination]);
      }
    } catch (e) {
      printE(e);
    }
  }

  // ===========================================================================
  // 🔥 دوال إدارة نظام كود الخصم
  // ===========================================================================

  // 1. جلب الخصومات المتاحة للزبون
  Future<void> getAvailableCoupons() async {
    try {
      final url = 'https://taxi.beytei.com/api/coupons';
      // يتم استخدام التوكن إذا كانت الدالة محمية
      String? token = homeRepo.apiClient.sharedPreferences.getString('token'); // تأكد من مفتاح التوكن في نظامك

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          availableCoupons = data['data'] ?? [];
          update();
        }
      }
    } catch (e) {
      printX("❌ خطأ في جلب الخصومات: $e");
    }
  }

  // 2. التحقق من كود الخصم المكتوب وتطبيقه
  Future<void> verifyPromoCode() async {
    String code = promoCodeController.text.trim();
    if (code.isEmpty) {
      CustomSnackBar.error(errorList: ['الرجاء إدخال كود الخصم']);
      return;
    }

    // التأكد من أن الزبون اختار المسار والسيارة وظهر له السعر
    if (originalAmount <= 0) {
      CustomSnackBar.error(errorList: ['الرجاء اختيار نقطة الانطلاق والوصول والسيارة لمعرفة السعر أولاً']);
      return;
    }

    try {
      isSubmitLoading = true;
      update();

      String? token = homeRepo.apiClient.sharedPreferences.getString('token');

      final url = 'https://taxi.beytei.com/api/verify-coupon';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: {
          'coupon_code': code,
          'estimated_amount': originalAmount.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          isCouponApplied = true;
          appliedCouponCode = code;
          appliedCouponId = data['data']['coupon_id'].toString();
          discountAmount = double.tryParse(data['data']['discount_amount'].toString()) ?? 0.0;

          // تحديث السعر النهائي ليراه الزبون مخصوماً
          double newTotal = double.tryParse(data['data']['new_total'].toString()) ?? (originalAmount - discountAmount);
          updateMainAmount(newTotal);

          CustomSnackBar.success(successList: ['تم تطبيق كود الخصم بنجاح!']);
        } else {
          // استخراج رسالة الخطأ من السيرفر
          String errorMsg = 'الكود غير صالح';
          if (data['message'] != null && data['message']['error'] != null) {
            errorMsg = data['message']['error'][0];
          }
          CustomSnackBar.error(errorList: [errorMsg]);
        }
      } else {
        CustomSnackBar.error(errorList: ['تعذر التحقق من الخصم، حاول مرة أخرى']);
      }
    } catch (e) {
      printX("❌ خطأ أثناء التحقق من الخصم: $e");
    } finally {
      isSubmitLoading = false;
      update();
    }
  }

  // 3. إلغاء كود الخصم وإرجاع السعر الأصلي
  void removePromoCode() {
    if (isCouponApplied) {
      isCouponApplied = false;
      appliedCouponCode = '';
      appliedCouponId = '';
      discountAmount = 0.0;
      promoCodeController.clear();

      // استرجاع السعر الأصلي
      if (originalAmount > 0) {
        updateMainAmount(originalAmount);
      }

      update();
    }
  }
  // ===========================================================================


  void distanceAlert() {
    CustomBottomSheet(
      child: RideDistanceWarningBottomSheetBody(
        distance: minimumDistance.toString(),
        yes: () {
          Get.back();
        },
      ),
    ).customBottomSheet(Get.context!);
  }

  bool isValidForNewRide() {
    if (selectedLocations.isEmpty || selectedLocations.length < 2) {
      CustomSnackBar.error(errorList: [MyStrings.selectDestination]);
      return false;
    } else if (selectedService.id == "-99") {
      CustomSnackBar.error(errorList: [MyStrings.pleaseSelectAService]);
      return false;
    }
    return true;
  }

  void clearData() {
    mainAmount = 0;
    originalAmount = 0;
    rideFare = RideFareModel();
    selectedService = AppService(id: '-99');
    amountController.text = '';
    noteController.text = '';
    passenger = 1;
    isServiceShake = false;
    isLocationShake = false;
    removePromoCode(); // تصفير كود الخصم عند تنظيف البيانات
    update();
  }
}