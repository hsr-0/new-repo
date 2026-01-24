import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/taxi/lib/core/helper/string_format_helper.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_strings.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/util.dart';
import 'package:cosmetic_store/taxi/lib/data/repo/location/location_search_repo.dart';
import 'package:cosmetic_store/taxi/lib/environment.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/snack_bar/show_custom_snackbar.dart';

class AppLocationController extends GetxController {
  LocationSearchRepo locationSearchRepo = LocationSearchRepo(apiClient: Get.find());
  Position currentPosition = MyUtils.getDefaultPosition();
  String currentAddress = "${MyStrings.loading.tr}...";
  Position? position;

  Future<Position?> getCurrentPosition() async {
    try {
      final geolocator = GeolocatorPlatform.instance;

      // 1. جلب إحداثيات GPS الخام من الحساس الخاص بالجهاز
      final position = await geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      this.position = position;

      // 2. جلب العنوان حصراً من Mapbox لضمان الدقة واللغة العربية في العراق
      // قمت بإلغاء فحص الشرط (Environment.addressPickerFromGoogleMapApi)
      // لنجعله يعتمد على Mapbox دائماً كما طلبت.

      String? address = await locationSearchRepo.getActualAddress(position.latitude, position.longitude);

      if (address != null && address.isNotEmpty) {
        currentAddress = address;
      } else {
        currentAddress = 'موقع محدد - العراق'; // نص احتياطي بدلاً من Unknown
      }

      currentPosition = position;
      update();

      printX('appLocations position: $currentAddress');
      return position;
    } catch (e) {
      printX('Error in getCurrentPosition: $e');
      CustomSnackBar.error(errorList: [MyStrings.locationPermissionNeedMSG.tr]);
    }

    return null;
  }
}