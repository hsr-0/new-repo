import 'package:cosmetic_store/taxi/lib/core/utils/method.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_strings.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/url_container.dart';
import 'package:cosmetic_store/taxi/lib/data/model/global/response_model/response_model.dart';
import 'package:cosmetic_store/taxi/lib/data/services/api_client.dart';

class GeneralSettingRepo {
  ApiClient apiClient;
  GeneralSettingRepo({required this.apiClient});

  Future<dynamic> getGeneralSetting() async {
    String url = '${UrlContainer.baseUrl}${UrlContainer.generalSettingEndPoint}';
    ResponseModel response = await apiClient.request(
      url,
      Method.getMethod,
      null,
      passHeader: false,
    );
    return response;
  }

  Future<dynamic> getLanguage(String languageCode) async {
    try {
      String url = '${UrlContainer.baseUrl}${UrlContainer.languageUrl}$languageCode';
      ResponseModel response = await apiClient.request(
        url,
        Method.getMethod,
        null,
        passHeader: false,
      );
      return response;
    } catch (e) {
      return ResponseModel(false, MyStrings.somethingWentWrong, 300, '');
    }
  }
}
