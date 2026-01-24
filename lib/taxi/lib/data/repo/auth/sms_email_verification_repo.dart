import 'package:cosmetic_store/taxi/lib/core/utils/method.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_strings.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/url_container.dart';
import 'package:cosmetic_store/taxi/lib/data/model/authorization/authorization_response_model.dart';
import 'package:cosmetic_store/taxi/lib/data/model/global/response_model/response_model.dart';
import 'package:cosmetic_store/taxi/lib/data/services/api_client.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/snack_bar/show_custom_snackbar.dart';

class SmsEmailVerificationRepo {
  ApiClient apiClient;

  SmsEmailVerificationRepo({required this.apiClient});

  Future<ResponseModel> verify(
    String code, {
    bool isEmail = true,
    bool isTFA = false,
  }) async {
    final map = {'code': code};
    String url = '${UrlContainer.baseUrl}${isEmail ? UrlContainer.verifyEmailEndPoint : UrlContainer.verifySmsEndPoint}';

    ResponseModel responseModel = await apiClient.request(
      url,
      Method.postMethod,
      map,
      passHeader: true,
    );
    return responseModel;
  }

  Future<bool> sendAuthorizationRequest() async {
    String url = '${UrlContainer.baseUrl}${UrlContainer.authorizationCodeEndPoint}';
    ResponseModel response = await apiClient.request(
      url,
      Method.getMethod,
      null,
      passHeader: true,
    );

    if (response.statusCode == 200) {
      AuthorizationResponseModel model = AuthorizationResponseModel.fromJson((response.responseJson));
      if (model.status == 'error') {
        CustomSnackBar.error(
          errorList: model.message ?? [MyStrings.somethingWentWrong],
        );
        return false;
      }

      return true;
    } else {
      CustomSnackBar.error(errorList: [response.message]);
      return false;
    }
  }

  Future<bool> resendVerifyCode({required bool isEmail}) async {
    final url = '${UrlContainer.baseUrl}${UrlContainer.resendVerifyCodeEndPoint}${isEmail ? 'email' : 'mobile'}';
    ResponseModel response = await apiClient.request(
      url,
      Method.getMethod,
      null,
      passHeader: true,
    );

    if (response.statusCode == 200) {
      AuthorizationResponseModel model = AuthorizationResponseModel.fromJson((response.responseJson));

      if (model.status == 'error') {
        CustomSnackBar.error(
          errorList: model.message ?? [MyStrings.resendCodeFail],
        );
        return false;
      } else {
        CustomSnackBar.success(
          successList: model.message ?? [MyStrings.successfullyCodeResend],
        );
        return true;
      }
    } else {
      return false;
    }
  }
}
