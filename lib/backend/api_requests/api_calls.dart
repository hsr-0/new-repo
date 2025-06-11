import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

/// Start PlantShop Group Code

class PlantShopGroup {
  static String getBaseUrl({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    return '${url}';
  }

  static Map<String, String> headers = {};
  static EditShippingAddressCall editShippingAddressCall =
      EditShippingAddressCall();
  static LogInCall logInCall = LogInCall();
  static GetCustomerCall getCustomerCall = GetCustomerCall();
  static DeleteAccountCall deleteAccountCall = DeleteAccountCall();
  static SignUpCall signUpCall = SignUpCall();
  static SearchApiCall searchApiCall = SearchApiCall();
  static CouponCodeCall couponCodeCall = CouponCodeCall();
  static BlogCall blogCall = BlogCall();
  static AuthorizationCall authorizationCall = AuthorizationCall();
  static CurrentCurrencyCall currentCurrencyCall = CurrentCurrencyCall();
  static CurrencyPositionCall currencyPositionCall = CurrencyPositionCall();
  static ThousandSeparatorCall thousandSeparatorCall = ThousandSeparatorCall();
  static DecimalSeparatorCall decimalSeparatorCall = DecimalSeparatorCall();
  static NumberOfDecimalsCall numberOfDecimalsCall = NumberOfDecimalsCall();
  static ListAllCountriesCall listAllCountriesCall = ListAllCountriesCall();
  static ProductDetailCall productDetailCall = ProductDetailCall();
  static ProductVariationsCall productVariationsCall = ProductVariationsCall();
  static ProductReviewCall productReviewCall = ProductReviewCall();
  static AddReviewCall addReviewCall = AddReviewCall();
  static ShippingZoneCall shippingZoneCall = ShippingZoneCall();
  static ShippingZoneLocationCall shippingZoneLocationCall =
      ShippingZoneLocationCall();
  static ShippingZoneMethodsCall shippingZoneMethodsCall =
      ShippingZoneMethodsCall();
  static GetCartCall getCartCall = GetCartCall();
  static AddToCartCall addToCartCall = AddToCartCall();
  static UpdateCartCall updateCartCall = UpdateCartCall();
  static DeleteCartCall deleteCartCall = DeleteCartCall();
  static ApplyCouponCodeCall applyCouponCodeCall = ApplyCouponCodeCall();
  static RemoveCouponCodeCall removeCouponCodeCall = RemoveCouponCodeCall();
  static UpdateShippingCall updateShippingCall = UpdateShippingCall();
  static PaymentGatewaysCall paymentGatewaysCall = PaymentGatewaysCall();
  static CreateOrderCall createOrderCall = CreateOrderCall();
  static GetOrdersCall getOrdersCall = GetOrdersCall();
  static CancelOrderCall cancelOrderCall = CancelOrderCall();
  static OrderDetailCall orderDetailCall = OrderDetailCall();
  static CategoriesCall categoriesCall = CategoriesCall();
  static CategoryOpenCall categoryOpenCall = CategoryOpenCall();
  static CategoryOpenSubCall categoryOpenSubCall = CategoryOpenSubCall();
  static TrendingProductsCall trendingProductsCall = TrendingProductsCall();
  static LatestProductsCall latestProductsCall = LatestProductsCall();
  static SellProductsCall sellProductsCall = SellProductsCall();
  static PopularProductsCall popularProductsCall = PopularProductsCall();
  static EditUserCall editUserCall = EditUserCall();
  static EditBillingAddressCall editBillingAddressCall =
      EditBillingAddressCall();
  static LogOutCall logOutCall = LogOutCall();
  static AllIntroCall allIntroCall = AllIntroCall();
  static AllBannerCall allBannerCall = AllBannerCall();
  static PrimaryCategoryCall primaryCategoryCall = PrimaryCategoryCall();
  static SecondaryCategoryCall secondaryCategoryCall = SecondaryCategoryCall();
  static OtherCategoryCall otherCategoryCall = OtherCategoryCall();

  static var socialLoginCall;
}

class EditShippingAddressCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? firstName = '',
    String? lastName = '',
    String? address1 = '',
    String? address2 = '',
    String? city = '',
    String? state = '',
    String? postcode = '',
    String? country = '',
    String? phone = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    final ffApiRequestBody = '''
{
  "shipping": {
    "first_name": "${escapeStringForJson(firstName)}",
    "last_name": "${escapeStringForJson(lastName)}",
    "company": "",
    "address_1": "${escapeStringForJson(address1)}",
    "address_2": "${escapeStringForJson(address2)}",
    "city": "${escapeStringForJson(city)}",
    "state": "${escapeStringForJson(state)}",
    "postcode": "${escapeStringForJson(postcode)}",
    "country": "${escapeStringForJson(country)}",
    "phone": "${escapeStringForJson(phone)}"
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Edit shipping address',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/customers/${userId}?force=true&consumer_key=${consumerKey}&consumer_secret=${consumerSecret}',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class LogInCall {
  Future<ApiCallResponse> call({
    String? username = '',
    String? password = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    final ffApiRequestBody = '''
{
  "username": "${escapeStringForJson(username)}",
  "password": "${escapeStringForJson(password)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'log in',
      apiUrl:
          '${baseUrl}/wp-json/jwt-auth/v1/token?consumer_key=${consumerKey}&consumer_secret=${consumerSecret}',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? token(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.token''',
      ));
  String? userEmail(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.user_email''',
      ));
  String? userNicename(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.user_nicename''',
      ));
  String? userDisplayName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.user_display_name''',
      ));
  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class GetCustomerCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Get customer',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/customers/${userId}?consumer_key=${consumerKey}&consumer_secret=${consumerSecret}',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  dynamic? userDetail(dynamic response) => getJsonField(
        response,
        r'''$''',
      );
  int? userId(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.id''',
      ));
  String? email(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.email''',
      ));
  dynamic? billingAddress(dynamic response) => getJsonField(
        response,
        r'''$.billing''',
      );
  dynamic? shippingAddress(dynamic response) => getJsonField(
        response,
        r'''$.shipping''',
      );
  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class DeleteAccountCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Delete account',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/customers/${userId}?force=true&consumer_key=${consumerKey}&consumer_secret=${consumerSecret}',
      callType: ApiCallType.DELETE,
      headers: {
        'content-type': 'application/json',
        'cache-control': 'no-cache',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class SignUpCall {
  Future<ApiCallResponse> call({
    String? email = '',
    String? userName = '',
    String? password = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    final ffApiRequestBody = '''
{
  "email": "${escapeStringForJson(email)}",
  "username": "${escapeStringForJson(userName)}",
  "password": "${escapeStringForJson(password)}",
  "billing": {
    "email": "${escapeStringForJson(email)}"
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'sign up',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/customers?consumer_key=${consumerKey}&consumer_secret=${consumerSecret}',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class SearchApiCall {
  Future<ApiCallResponse> call({
    String? search = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'SearchApi',
      apiUrl: '${baseUrl}/wp-json/wc/v3/products?search=${search}',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'search': search,
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  List? searchList(dynamic response) => getJsonField(
        response,
        r'''$''',
        true,
      ) as List?;
}

class CouponCodeCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Coupon code',
      apiUrl: '${baseUrl}/wp-json/wc/v3/coupons?status=publish',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  List? couponsList(dynamic response) => getJsonField(
        response,
        r'''$''',
        true,
      ) as List?;
  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class BlogCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Blog',
      apiUrl: '${baseUrl}/wp-json/wp/v2/posts?_embed',
      callType: ApiCallType.GET,
      headers: {},
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  dynamic status(dynamic response) => getJsonField(
        response,
        r'''$.data.status''',
      );
  dynamic message(dynamic response) => getJsonField(
        response,
        r'''$.message''',
      );
  List? blogList(dynamic response) => getJsonField(
        response,
        r'''$''',
        true,
      ) as List?;
}

class AuthorizationCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Authorization',
      apiUrl: '${baseUrl}/wp-json/lumo/v1/authorization',
      callType: ApiCallType.POST,
      headers: {},
      params: {
        'base_url': url,
      },
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? success(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.success''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
  int? error(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.error''',
      ));
}

class CurrentCurrencyCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Current currency',
      apiUrl: '${baseUrl}/wp-json/wc/v3/data/currencies/current',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? code(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.code''',
      ));
  String? symbol(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.symbol''',
      ));
  String? name(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.name''',
      ));
  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class CurrencyPositionCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Currency position',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/settings/general/woocommerce_currency_pos',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? label(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.label''',
      ));
  String? defaultValue(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.default''',
      ));
  String? value(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.value''',
      ));
  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class ThousandSeparatorCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Thousand separator',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/settings/general/woocommerce_price_thousand_sep',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  String? label(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.label''',
      ));
  String? defaultValue(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.default''',
      ));
  String? value(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.value''',
      ));
}

class DecimalSeparatorCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Decimal separator',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/settings/general/woocommerce_price_decimal_sep',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  String? label(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.label''',
      ));
  String? defaultValue(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.default''',
      ));
  String? value(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.value''',
      ));
}

class NumberOfDecimalsCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Number of Decimals',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/settings/general/woocommerce_price_num_decimals',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  String? label(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.label''',
      ));
  String? defaultValue(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.default''',
      ));
  String? value(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.value''',
      ));
}

class ListAllCountriesCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'ListAllCountries',
      apiUrl: '${baseUrl}/wp-json/wc/v3/data/countries/',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  List? countriesList(dynamic response) => getJsonField(
        response,
        r'''$''',
        true,
      ) as List?;
}

class ProductDetailCall {
  Future<ApiCallResponse> call({
    String? productId = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Product detail',
      apiUrl: '${baseUrl}/wp-json/wc/v3/products/${productId}',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  dynamic? productDetail(dynamic response) => getJsonField(
        response,
        r'''$''',
      );
  String? price(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.price''',
      ));
  String? regularPrice(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.regular_price''',
      ));
  bool? onSale(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.on_sale''',
      ));
  List<int>? upsellIdsList(dynamic response) => (getJsonField(
        response,
        r'''$.upsell_ids''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  List? imagesList(dynamic response) => getJsonField(
        response,
        r'''$.images''',
        true,
      ) as List?;
  List? attributes(dynamic response) => getJsonField(
        response,
        r'''$.attributes''',
        true,
      ) as List?;
  List? variationsIdsList(dynamic response) => getJsonField(
        response,
        r'''$.variations''',
        true,
      ) as List?;
  List<int>? relatedIdsList(dynamic response) => (getJsonField(
        response,
        r'''$.related_ids''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  String? priceHtml(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.price_html''',
      ));
  int? ratingCount(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.rating_count''',
      ));
}

class ProductVariationsCall {
  Future<ApiCallResponse> call({
    String? productId = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Product variations',
      apiUrl: '${baseUrl}/wp-json/wc/v3/products/${productId}/variations',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  List<int>? idsList(dynamic response) => (getJsonField(
        response,
        r'''$[:].id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  List<String>? priceList(dynamic response) => (getJsonField(
        response,
        r'''$[:].price''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List? variationsList(dynamic response) => getJsonField(
        response,
        r'''$''',
        true,
      ) as List?;
}

class ProductReviewCall {
  Future<ApiCallResponse> call({
    String? id = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Product review',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/products/reviews?product=${id}&order=desc',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  List? reviewsList(dynamic response) => getJsonField(
        response,
        r'''$''',
        true,
      ) as List?;
}

class AddReviewCall {
  Future<ApiCallResponse> call({
    int? productId,
    String? review = '',
    String? reviewer = '',
    String? reviewerEmail = '',
    double? rating,
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    final ffApiRequestBody = '''
{
  "product_id": ${productId},
  "review": "${escapeStringForJson(review)}",
  "reviewer": "${escapeStringForJson(reviewer)}",
  "reviewer_email": "${escapeStringForJson(reviewerEmail)}",
  "rating": ${rating}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Add review',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/products/reviews?consumer_key=${consumerKey}&consumer_secret=${consumerSecret}',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class ShippingZoneCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'shipping zone',
      apiUrl: '${baseUrl}/wp-json/wc/v3/shipping/zones',
      callType: ApiCallType.GET,
      headers: {},
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ShippingZoneLocationCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'shipping zone location',
      apiUrl: '${baseUrl}/wp-json/wc/v3/shipping/zones/3/locations',
      callType: ApiCallType.GET,
      headers: {},
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ShippingZoneMethodsCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'shipping zone methods',
      apiUrl: '${baseUrl}/wp-json/wc/v3/shipping/zones/3/methods',
      callType: ApiCallType.GET,
      headers: {},
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetCartCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Get cart',
      apiUrl: '${baseUrl}/wp-json/wc/store/cart',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  List? itemsList(dynamic response) => getJsonField(
        response,
        r'''$.items''',
        true,
      ) as List?;
  String? totalitems(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.totals.total_items''',
      ));
  String? totalItemsTax(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.totals.total_items_tax''',
      ));
  String? totalPrice(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.totals.total_price''',
      ));
  String? totalTax(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.totals.total_tax''',
      ));
  dynamic? shippingAddress(dynamic response) => getJsonField(
        response,
        r'''$.shipping_address''',
      );
  dynamic? billingAddress(dynamic response) => getJsonField(
        response,
        r'''$.billing_address''',
      );
  List? shippingRates(dynamic response) => getJsonField(
        response,
        r'''$.shipping_rates[:].shipping_rates''',
        true,
      ) as List?;
  List<int>? crossSellsIdList(dynamic response) => (getJsonField(
        response,
        r'''$.cross_sells[:].id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  String? totalShipping(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.totals.total_shipping''',
      ));
  String? totalShippingTax(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.totals.total_shipping_tax''',
      ));
  String? totalDiscount(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.totals.total_discount''',
      ));
  String? totalDiscountTax(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.totals.total_discount_tax''',
      ));
  List? couponsList(dynamic response) => getJsonField(
        response,
        r'''$.coupons''',
        true,
      ) as List?;
}

class AddToCartCall {
  Future<ApiCallResponse> call({
    String? nonce = '',
    int? id,
    String? quantity = '',
    dynamic? variationJson,
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    final variation = _serializeJson(variationJson, true);
    final ffApiRequestBody = '''
{
  "id": "${id}",
  "quantity": "${escapeStringForJson(quantity)}",
  "variation": ${variation}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'add to cart',
      apiUrl: '${baseUrl}/wp-json/wc/store/cart/items',
      callType: ApiCallType.POST,
      headers: {
        'x-wc-store-api-nonce': '${nonce}',
        'nonce': '${nonce}',
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class UpdateCartCall {
  Future<ApiCallResponse> call({
    String? nonce = '',
    String? keyId = '',
    String? id = '',
    String? qty = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    final ffApiRequestBody = '''
{
  "id": "${escapeStringForJson(id)}",
  "quantity": "${escapeStringForJson(qty)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Update cart',
      apiUrl: '${baseUrl}/wp-json/wc/store/cart/items/${keyId}',
      callType: ApiCallType.PUT,
      headers: {
        'x-wc-store-api-nonce': '${nonce}',
        'Authorization': 'Bearer ${token}',
        'nonce': '${nonce}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class DeleteCartCall {
  Future<ApiCallResponse> call({
    String? nonce = '',
    String? keyId = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Delete cart',
      apiUrl: '${baseUrl}/wp-json/wc/store/cart/items/${keyId}',
      callType: ApiCallType.DELETE,
      headers: {
        'x-wc-store-api-nonce': '${nonce}',
        'Authorization': 'Bearer ${token}',
        'nonce': '${nonce}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class ApplyCouponCodeCall {
  Future<ApiCallResponse> call({
    String? code = '',
    String? nonce = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    final ffApiRequestBody = '''
{
  "code": "${escapeStringForJson(code)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Apply coupon code',
      apiUrl: '${baseUrl}/wp-json/wc/store/cart/apply-coupon',
      callType: ApiCallType.POST,
      headers: {
        'x-wc-store-api-nonce': '${nonce}',
        'Content-Type': 'application/json',
        'nonce': '${nonce}',
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class RemoveCouponCodeCall {
  Future<ApiCallResponse> call({
    String? code = '',
    String? nonce = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    final ffApiRequestBody = '''
{
  "code": "${escapeStringForJson(code)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Remove coupon code',
      apiUrl: '${baseUrl}/wp-json/wc/store/cart/remove-coupon',
      callType: ApiCallType.POST,
      headers: {
        'x-wc-store-api-nonce': '${nonce}',
        'Content-Type': 'application/json',
        'nonce': '${nonce}',
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class UpdateShippingCall {
  Future<ApiCallResponse> call({
    String? shippingMethod = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    final ffApiRequestBody = '''
{
  "shipping_method": "${escapeStringForJson(shippingMethod)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Update shipping',
      apiUrl: '${baseUrl}/wp-json/custom/v1/update_shipping_method',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  bool? success(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.success''',
      ));
}

class PaymentGatewaysCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Payment gateways',
      apiUrl: '${baseUrl}/wp-json/wc/v3/payment_gateways',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  List? paymentGatewaysList(dynamic response) => getJsonField(
        response,
        r'''$''',
        true,
      ) as List?;
}

class CreateOrderCall {
  Future<ApiCallResponse> call({
    String? paymentMethod = '',
    String? paymentMethodTitle = '',
    bool? setPaid,
    int? customerId,
    dynamic? billingJson,
    dynamic? shippingJson,
    dynamic? lineItemsJson,
    dynamic? shippingLinesJson,
    dynamic? couponLinesJson,
    dynamic? taxLinesJson,
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    final billing = _serializeJson(billingJson);
    final shipping = _serializeJson(shippingJson);
    final lineItems = _serializeJson(lineItemsJson, true);
    final shippingLines = _serializeJson(shippingLinesJson, true);
    final couponLines = _serializeJson(couponLinesJson, true);
    final taxLines = _serializeJson(taxLinesJson, true);
    final ffApiRequestBody = '''
{
  "payment_method": "${escapeStringForJson(paymentMethod)}",
  "payment_method_title": "${escapeStringForJson(paymentMethodTitle)}",
  "set_paid": ${setPaid},
  "customer_id": ${customerId},
  "billing": ${billing},
  "shipping": ${shipping},
  "line_items": ${lineItems},
  "shipping_lines": ${shippingLines},
  "coupon_lines": ${couponLines},
  "tax_lines": ${taxLines}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Create order',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/orders?consumer_key=${consumerKey}&consumer_secret=${consumerSecret}',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  dynamic orderDetail(dynamic response) => getJsonField(
        response,
        r'''$''',
      );
}

class GetOrdersCall {
  Future<ApiCallResponse> call({
    String? customer = '',
    int? perPage,
    int? page,
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Get orders',
      apiUrl: '${baseUrl}/wp-json/wc/v3/orders',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'customer': customer,
        'per_page': perPage,
        'page': page,
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  List? orderList(dynamic response) => getJsonField(
        response,
        r'''$''',
        true,
      ) as List?;
}

class CancelOrderCall {
  Future<ApiCallResponse> call({
    int? orderId,
    String? status = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    final ffApiRequestBody = '''
{
  "status": "${escapeStringForJson(status)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Cancel order',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/orders/${orderId}?consumer_key=${consumerKey}&consumer_secret=${consumerSecret}',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  dynamic? detail(dynamic response) => getJsonField(
        response,
        r'''$''',
      );
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
}

class OrderDetailCall {
  Future<ApiCallResponse> call({
    int? orderId,
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'order detail',
      apiUrl: '${baseUrl}/wp-json/wc/v3/orders/${orderId}',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  dynamic? orderDetail(dynamic response) => getJsonField(
        response,
        r'''$''',
      );
  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class CategoriesCall {
  Future<ApiCallResponse> call({
    String? search = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'categories',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/products/categories?parent=0&per_page=100&search=${search}',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  List? categoriesList(dynamic response) => getJsonField(
        response,
        r'''$''',
        true,
      ) as List?;
}

class CategoryOpenCall {
  Future<ApiCallResponse> call({
    String? categoryId = '',
    int? page,
    String? filter = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Category open',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/products?category=${categoryId}&page=${page}&status=publish&${filter}',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  List? categoryOpenList(dynamic response) => getJsonField(
        response,
        r'''$''',
        true,
      ) as List?;
}

class CategoryOpenSubCall {
  Future<ApiCallResponse> call({
    String? categoryId = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Category open sub',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/products/categories?parent=${categoryId}',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  List? categoryOpenSubList(dynamic response) => getJsonField(
        response,
        r'''$''',
        true,
      ) as List?;
}

class TrendingProductsCall {
  Future<ApiCallResponse> call({
    String? filter = '',
    int? page,
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Trending products',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/products?orderby=popularity&status=publish&page=${page}&${filter}',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  List? trendingProductsList(dynamic response) => getJsonField(
        response,
        r'''$''',
        true,
      ) as List?;
}

class LatestProductsCall {
  Future<ApiCallResponse> call({
    int? page,
    String? filter = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Latest products',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/products?orderby=date&order=desc&status=publish&page=${page}&${filter}',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  List? latestProductsList(dynamic response) => getJsonField(
        response,
        r'''$''',
        true,
      ) as List?;
}

class SellProductsCall {
  Future<ApiCallResponse> call({
    int? page,
    String? filter = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Sell products',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/products?on_sale=true&status=publish&page=${page}&${filter}',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  List? sellProductsList(dynamic response) => getJsonField(
        response,
        r'''$''',
        true,
      ) as List?;
}

class PopularProductsCall {
  Future<ApiCallResponse> call({
    int? page,
    String? filter = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Popular products',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/products?featured=true&status=publish&page=${page}&${filter}',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  List? popularProductsList(dynamic response) => getJsonField(
        response,
        r'''$''',
        true,
      ) as List?;
}

class EditUserCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? firstName = '',
    String? lastName = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    final ffApiRequestBody = '''
{
  "first_name": "${escapeStringForJson(firstName)}",
  "last_name": "${escapeStringForJson(lastName)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Edit user',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/customers/${userId}?consumer_key=${consumerKey}&consumer_secret=${consumerSecret}',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class EditBillingAddressCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? firstName = '',
    String? lastName = '',
    String? address1 = '',
    String? address2 = '',
    String? city = '',
    String? state = '',
    String? postcode = '',
    String? country = '',
    String? email = '',
    String? phone = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    final ffApiRequestBody = '''
{
  "billing": {
    "first_name": "${escapeStringForJson(firstName)}",
    "last_name": "${escapeStringForJson(lastName)}",
    "company": "",
    "address_1": "${escapeStringForJson(address1)}",
    "address_2": "${escapeStringForJson(address2)}",
    "city": "${escapeStringForJson(city)}",
    "state": "${escapeStringForJson(state)}",
    "postcode": "${escapeStringForJson(postcode)}",
    "country": "${escapeStringForJson(country)}",
    "email": "${escapeStringForJson(email)}",
    "phone": "${escapeStringForJson(phone)}"
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Edit billing address',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/customers/${userId}?force=true&consumer_key=${consumerKey}&consumer_secret=${consumerSecret}',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class LogOutCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Log out',
      apiUrl:
          '${baseUrl}/wp-json/wc/v3/customers/${userId}?force=true&consumer_key=${consumerKey}&consumer_secret=${consumerSecret}',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? status(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class AllIntroCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'All Intro',
      apiUrl: '${baseUrl}/wp-json/lumo-intro/v1/items',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? status(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  List? dataList(dynamic response) => getJsonField(
        response,
        r'''$.data''',
        true,
      ) as List?;
}

class AllBannerCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'All Banner',
      apiUrl: '${baseUrl}/wp-json/lumo-banner/v1/banners',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? status(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  List? dataList(dynamic response) => getJsonField(
        response,
        r'''$.data''',
        true,
      ) as List?;
}

class PrimaryCategoryCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Primary Category',
      apiUrl: '${baseUrl}//wp-json/lumo-banner/v1/banners/primary',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? status(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  List? dataList(dynamic response) => getJsonField(
        response,
        r'''$.data''',
        true,
      ) as List?;
}

class SecondaryCategoryCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Secondary Category',
      apiUrl: '${baseUrl}/wp-json/lumo-banner/v1/banners/secondary',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? status(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  List? dataList(dynamic response) => getJsonField(
        response,
        r'''$.data''',
        true,
      ) as List?;
}

class OtherCategoryCall {
  Future<ApiCallResponse> call({
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Other Category',
      apiUrl: '${baseUrl}/wp-json/lumo-banner/v1/banners/other',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? status(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.status''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  List? dataList(dynamic response) => getJsonField(
        response,
        r'''$.data''',
        true,
      ) as List?;
}

/// End PlantShop Group Code

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
class SocialLoginCall {
  Future<ApiCallResponse> call({
    required String provider,
    required String accessToken,
    String? token = '',
    String? url,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    url ??= FFAppConstants.baseUrl;
    consumerKey ??= FFAppConstants.consumerKey;
    consumerSecret ??= FFAppConstants.consumerSecret;
    final baseUrl = PlantShopGroup.getBaseUrl(
      token: token,
      url: url,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );

    final ffApiRequestBody = '''
{
  "provider": "${escapeStringForJson(provider)}",
  "access_token": "${escapeStringForJson(accessToken)}"
}''';

    return ApiManager.instance.makeApiCall(
      callName: 'Social Login',
      apiUrl: '${baseUrl}/wp-json/jwt-auth/v1/token/social',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
    );
  }
}