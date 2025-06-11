import 'package:flutter/material.dart';
import 'flutter_flow/request_manager.dart';
import '/backend/api_requests/api_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'dart:convert';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _isIntro = prefs.getBool('ff_isIntro') ?? _isIntro;
    });
    _safeInit(() {
      _isLogin = prefs.getBool('ff_isLogin') ?? _isLogin;
    });
    _safeInit(() {
      if (prefs.containsKey('ff_userDetail')) {
        try {
          _userDetail = jsonDecode(prefs.getString('ff_userDetail') ?? '');
        } catch (e) {
          print("Can't decode persisted json. Error: $e.");
        }
      }
    });
    _safeInit(() {
      _token = prefs.getString('ff_token') ?? _token;
    });
    _safeInit(() {
      _currency = prefs.getString('ff_currency') ?? _currency;
    });
    _safeInit(() {
      _currencyCode = prefs.getString('ff_currencyCode') ?? _currencyCode;
    });
    _safeInit(() {
      _currencyPosition =
          prefs.getString('ff_currencyPosition') ?? _currencyPosition;
    });
    _safeInit(() {
      _thousandSeparator =
          prefs.getString('ff_thousandSeparator') ?? _thousandSeparator;
    });
    _safeInit(() {
      _decimalSeparator =
          prefs.getString('ff_decimalSeparator') ?? _decimalSeparator;
    });
    _safeInit(() {
      _decimalPlaces = prefs.getInt('ff_decimalPlaces') ?? _decimalPlaces;
    });
    _safeInit(() {
      _countryName = prefs.getString('ff_countryName') ?? _countryName;
    });
    _safeInit(() {
      _searchList = LoggableList(
        prefs.getStringList('ff_searchList') ?? _searchList,
      );
    });
    _safeInit(() {
      _allCountrysList = LoggableList(
        prefs.getStringList('ff_allCountrysList')?.map((x) {
              try {
                return jsonDecode(x);
              } catch (e) {
                print("Can't decode persisted json. Error: $e.");
                return {};
              }
            }).toList() ??
            _allCountrysList,
      );
    });
    _safeInit(() {
      _wishList = LoggableList(
        prefs.getStringList('ff_wishList') ?? _wishList,
      );
    });
    _safeInit(() {
      _paymentGatewaysList = LoggableList(
        prefs.getStringList('ff_paymentGatewaysList')?.map((x) {
              try {
                return jsonDecode(x);
              } catch (e) {
                print("Can't decode persisted json. Error: $e.");
                return {};
              }
            }).toList() ??
            _paymentGatewaysList,
      );
    });
    _safeInit(() {
      _cartCount = prefs.getString('ff_cartCount') ?? _cartCount;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  bool _connected = true;
  bool get connected => _connected;
  set connected(bool value) {
    _connected = value;

    debugLogAppState(this);
  }

  bool _isIntro = false;
  bool get isIntro => _isIntro;
  set isIntro(bool value) {
    _isIntro = value;
    prefs.setBool('ff_isIntro', value);
    debugLogAppState(this);
  }

  bool _isLogin = false;
  bool get isLogin => _isLogin;
  set isLogin(bool value) {
    _isLogin = value;
    prefs.setBool('ff_isLogin', value);
    debugLogAppState(this);
  }

  dynamic _userDetail;
  dynamic get userDetail => _userDetail;
  set userDetail(dynamic value) {
    _userDetail = value;
    prefs.setString('ff_userDetail', jsonEncode(value));
    debugLogAppState(this);
  }

  String _token = '';
  String get token => _token;
  set token(String value) {
    _token = value;
    prefs.setString('ff_token', value);
    debugLogAppState(this);
  }

  String _currency = '';
  String get currency => _currency;
  set currency(String value) {
    _currency = value;
    prefs.setString('ff_currency', value);
    debugLogAppState(this);
  }

  String _currencyCode = '';
  String get currencyCode => _currencyCode;
  set currencyCode(String value) {
    _currencyCode = value;
    prefs.setString('ff_currencyCode', value);
    debugLogAppState(this);
  }

  String _currencyPosition = '';
  String get currencyPosition => _currencyPosition;
  set currencyPosition(String value) {
    _currencyPosition = value;
    prefs.setString('ff_currencyPosition', value);
    debugLogAppState(this);
  }

  String _thousandSeparator = '';
  String get thousandSeparator => _thousandSeparator;
  set thousandSeparator(String value) {
    _thousandSeparator = value;
    prefs.setString('ff_thousandSeparator', value);
    debugLogAppState(this);
  }

  String _decimalSeparator = '';
  String get decimalSeparator => _decimalSeparator;
  set decimalSeparator(String value) {
    _decimalSeparator = value;
    prefs.setString('ff_decimalSeparator', value);
    debugLogAppState(this);
  }

  int _decimalPlaces = 0;
  int get decimalPlaces => _decimalPlaces;
  set decimalPlaces(int value) {
    _decimalPlaces = value;
    prefs.setInt('ff_decimalPlaces', value);
    debugLogAppState(this);
  }

  String _countryName = '';
  String get countryName => _countryName;
  set countryName(String value) {
    _countryName = value;
    prefs.setString('ff_countryName', value);
    debugLogAppState(this);
  }

  int _pageIndex = 0;
  int get pageIndex => _pageIndex;
  set pageIndex(int value) {
    _pageIndex = value;

    debugLogAppState(this);
  }

  late LoggableList<String> _searchList = LoggableList([]);
  List<String> get searchList =>
      _searchList?..logger = () => debugLogAppState(this);
  set searchList(List<String> value) {
    if (value != null) {
      _searchList = LoggableList(value);
    }

    prefs.setStringList('ff_searchList', value);
    debugLogAppState(this);
  }

  void addToSearchList(String value) {
    searchList.add(value);
    prefs.setStringList('ff_searchList', _searchList);
  }

  void removeFromSearchList(String value) {
    searchList.remove(value);
    prefs.setStringList('ff_searchList', _searchList);
  }

  void removeAtIndexFromSearchList(int index) {
    searchList.removeAt(index);
    prefs.setStringList('ff_searchList', _searchList);
  }

  void updateSearchListAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    searchList[index] = updateFn(_searchList[index]);
    prefs.setStringList('ff_searchList', _searchList);
  }

  void insertAtIndexInSearchList(int index, String value) {
    searchList.insert(index, value);
    prefs.setStringList('ff_searchList', _searchList);
  }

  bool _showCategorySection = true;
  bool get showCategorySection => _showCategorySection;
  set showCategorySection(bool value) {
    _showCategorySection = value;

    debugLogAppState(this);
  }

  late LoggableList<String> _categorySectionIdsList =
      LoggableList(['15', '19']);
  List<String> get categorySectionIdsList =>
      _categorySectionIdsList?..logger = () => debugLogAppState(this);
  set categorySectionIdsList(List<String> value) {
    if (value != null) {
      _categorySectionIdsList = LoggableList(value);
    }

    debugLogAppState(this);
  }

  void addToCategorySectionIdsList(String value) {
    categorySectionIdsList.add(value);
  }

  void removeFromCategorySectionIdsList(String value) {
    categorySectionIdsList.remove(value);
  }

  void removeAtIndexFromCategorySectionIdsList(int index) {
    categorySectionIdsList.removeAt(index);
  }

  void updateCategorySectionIdsListAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    categorySectionIdsList[index] = updateFn(_categorySectionIdsList[index]);
  }

  void insertAtIndexInCategorySectionIdsList(int index, String value) {
    categorySectionIdsList.insert(index, value);
  }

  late LoggableList<dynamic> _allCountrysList = LoggableList([]);
  List<dynamic> get allCountrysList =>
      _allCountrysList?..logger = () => debugLogAppState(this);
  set allCountrysList(List<dynamic> value) {
    if (value != null) {
      _allCountrysList = LoggableList(value);
    }

    prefs.setStringList(
        'ff_allCountrysList', value.map((x) => jsonEncode(x)).toList());
    debugLogAppState(this);
  }

  void addToAllCountrysList(dynamic value) {
    allCountrysList.add(value);
    prefs.setStringList('ff_allCountrysList',
        _allCountrysList.map((x) => jsonEncode(x)).toList());
  }

  void removeFromAllCountrysList(dynamic value) {
    allCountrysList.remove(value);
    prefs.setStringList('ff_allCountrysList',
        _allCountrysList.map((x) => jsonEncode(x)).toList());
  }

  void removeAtIndexFromAllCountrysList(int index) {
    allCountrysList.removeAt(index);
    prefs.setStringList('ff_allCountrysList',
        _allCountrysList.map((x) => jsonEncode(x)).toList());
  }

  void updateAllCountrysListAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    allCountrysList[index] = updateFn(_allCountrysList[index]);
    prefs.setStringList('ff_allCountrysList',
        _allCountrysList.map((x) => jsonEncode(x)).toList());
  }

  void insertAtIndexInAllCountrysList(int index, dynamic value) {
    allCountrysList.insert(index, value);
    prefs.setStringList('ff_allCountrysList',
        _allCountrysList.map((x) => jsonEncode(x)).toList());
  }

  late LoggableList<String> _wishList = LoggableList([]);
  List<String> get wishList =>
      _wishList?..logger = () => debugLogAppState(this);
  set wishList(List<String> value) {
    if (value != null) {
      _wishList = LoggableList(value);
    }

    prefs.setStringList('ff_wishList', value);
    debugLogAppState(this);
  }

  void addToWishList(String value) {
    wishList.add(value);
    prefs.setStringList('ff_wishList', _wishList);
  }

  void removeFromWishList(String value) {
    wishList.remove(value);
    prefs.setStringList('ff_wishList', _wishList);
  }

  void removeAtIndexFromWishList(int index) {
    wishList.removeAt(index);
    prefs.setStringList('ff_wishList', _wishList);
  }

  void updateWishListAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    wishList[index] = updateFn(_wishList[index]);
    prefs.setStringList('ff_wishList', _wishList);
  }

  void insertAtIndexInWishList(int index, String value) {
    wishList.insert(index, value);
    prefs.setStringList('ff_wishList', _wishList);
  }

  bool _response = true;
  bool get response => _response;
  set response(bool value) {
    _response = value;

    debugLogAppState(this);
  }

  late LoggableList<dynamic> _paymentGatewaysList = LoggableList([]);
  List<dynamic> get paymentGatewaysList =>
      _paymentGatewaysList?..logger = () => debugLogAppState(this);
  set paymentGatewaysList(List<dynamic> value) {
    if (value != null) {
      _paymentGatewaysList = LoggableList(value);
    }

    prefs.setStringList(
        'ff_paymentGatewaysList', value.map((x) => jsonEncode(x)).toList());
    debugLogAppState(this);
  }

  void addToPaymentGatewaysList(dynamic value) {
    paymentGatewaysList.add(value);
    prefs.setStringList('ff_paymentGatewaysList',
        _paymentGatewaysList.map((x) => jsonEncode(x)).toList());
  }

  void removeFromPaymentGatewaysList(dynamic value) {
    paymentGatewaysList.remove(value);
    prefs.setStringList('ff_paymentGatewaysList',
        _paymentGatewaysList.map((x) => jsonEncode(x)).toList());
  }

  void removeAtIndexFromPaymentGatewaysList(int index) {
    paymentGatewaysList.removeAt(index);
    prefs.setStringList('ff_paymentGatewaysList',
        _paymentGatewaysList.map((x) => jsonEncode(x)).toList());
  }

  void updatePaymentGatewaysListAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    paymentGatewaysList[index] = updateFn(_paymentGatewaysList[index]);
    prefs.setStringList('ff_paymentGatewaysList',
        _paymentGatewaysList.map((x) => jsonEncode(x)).toList());
  }

  void insertAtIndexInPaymentGatewaysList(int index, dynamic value) {
    paymentGatewaysList.insert(index, value);
    prefs.setStringList('ff_paymentGatewaysList',
        _paymentGatewaysList.map((x) => jsonEncode(x)).toList());
  }

  String _cartCount = '';
  String get cartCount => _cartCount;
  set cartCount(String value) {
    _cartCount = value;
    prefs.setString('ff_cartCount', value);
    debugLogAppState(this);
  }

  final _categoriesManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> categories({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _categoriesManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearCategoriesCache() => _categoriesManager.clear();
  void clearCategoriesCacheKey(String? uniqueKey) =>
      _categoriesManager.clearRequest(uniqueKey);

  final _trendingProductsManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> trendingProducts({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _trendingProductsManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearTrendingProductsCache() => _trendingProductsManager.clear();
  void clearTrendingProductsCacheKey(String? uniqueKey) =>
      _trendingProductsManager.clearRequest(uniqueKey);

  final _sellProductsManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> sellProducts({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _sellProductsManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearSellProductsCache() => _sellProductsManager.clear();
  void clearSellProductsCacheKey(String? uniqueKey) =>
      _sellProductsManager.clearRequest(uniqueKey);

  final _popularProductsManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> popularProducts({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _popularProductsManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearPopularProductsCache() => _popularProductsManager.clear();
  void clearPopularProductsCacheKey(String? uniqueKey) =>
      _popularProductsManager.clearRequest(uniqueKey);

  final _latestProductsManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> latestProducts({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _latestProductsManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearLatestProductsCache() => _latestProductsManager.clear();
  void clearLatestProductsCacheKey(String? uniqueKey) =>
      _latestProductsManager.clearRequest(uniqueKey);

  final _blogManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> blog({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _blogManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearBlogCache() => _blogManager.clear();
  void clearBlogCacheKey(String? uniqueKey) =>
      _blogManager.clearRequest(uniqueKey);

  final _categoryOpenManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> categoryOpen({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _categoryOpenManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearCategoryOpenCache() => _categoryOpenManager.clear();
  void clearCategoryOpenCacheKey(String? uniqueKey) =>
      _categoryOpenManager.clearRequest(uniqueKey);

  final _categoryOpenSubManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> categoryOpenSub({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _categoryOpenSubManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearCategoryOpenSubCache() => _categoryOpenSubManager.clear();
  void clearCategoryOpenSubCacheKey(String? uniqueKey) =>
      _categoryOpenSubManager.clearRequest(uniqueKey);

  final _productDdetailManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> productDdetail({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _productDdetailManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearProductDdetailCache() => _productDdetailManager.clear();
  void clearProductDdetailCacheKey(String? uniqueKey) =>
      _productDdetailManager.clearRequest(uniqueKey);

  final _reviewsManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> reviews({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _reviewsManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearReviewsCache() => _reviewsManager.clear();
  void clearReviewsCacheKey(String? uniqueKey) =>
      _reviewsManager.clearRequest(uniqueKey);

  final _cartManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> cart({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _cartManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearCartCache() => _cartManager.clear();
  void clearCartCacheKey(String? uniqueKey) =>
      _cartManager.clearRequest(uniqueKey);

  final _orderDetailManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> orderDetail({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _orderDetailManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearOrderDetailCache() => _orderDetailManager.clear();
  void clearOrderDetailCacheKey(String? uniqueKey) =>
      _orderDetailManager.clearRequest(uniqueKey);

  final _primaryCategoryManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> primaryCategory({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _primaryCategoryManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearPrimaryCategoryCache() => _primaryCategoryManager.clear();
  void clearPrimaryCategoryCacheKey(String? uniqueKey) =>
      _primaryCategoryManager.clearRequest(uniqueKey);

  final _secondaryCategoryManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> secondaryCategory({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _secondaryCategoryManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearSecondaryCategoryCache() => _secondaryCategoryManager.clear();
  void clearSecondaryCategoryCacheKey(String? uniqueKey) =>
      _secondaryCategoryManager.clearRequest(uniqueKey);

  final _otherCategoryManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> otherCategory({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _otherCategoryManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearOtherCategoryCache() => _otherCategoryManager.clear();
  void clearOtherCategoryCacheKey(String? uniqueKey) =>
      _otherCategoryManager.clearRequest(uniqueKey);

  Map<String, DebugDataField> toDebugSerializableMap() => {
        'connected': debugSerializeParam(
          connected,
          ParamType.bool,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=ChsKFQoJY29ubmVjdGVkEgh0dTF3dDQwanICCAVaCWNvbm5lY3RlZA==',
          name: 'bool',
          nullable: false,
        ),
        'isIntro': debugSerializeParam(
          isIntro,
          ParamType.bool,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=ChkKEwoHaXNJbnRybxIIODdxOW41OXlyAggFWgdpc0ludHJv',
          name: 'bool',
          nullable: false,
        ),
        'isLogin': debugSerializeParam(
          isLogin,
          ParamType.bool,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=ChkKEwoHaXNMb2dpbhIINHJxM2YybDVyAggFWgdpc0xvZ2lu',
          name: 'bool',
          nullable: false,
        ),
        'userDetail': debugSerializeParam(
          userDetail,
          ParamType.JSON,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=Ch4KFgoKdXNlckRldGFpbBIIbjU4NXd6aGRyAggJegBaCnVzZXJEZXRhaWw=',
          name: 'dynamic',
          nullable: false,
        ),
        'token': debugSerializeParam(
          token,
          ParamType.String,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=ChkKEQoFdG9rZW4SCDFkam94Z212cgIIA3oAWgV0b2tlbg==',
          name: 'String',
          nullable: false,
        ),
        'currency': debugSerializeParam(
          currency,
          ParamType.String,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=ChwKFAoIY3VycmVuY3kSCG51bnFmdjAxcgIIA3oAWghjdXJyZW5jeQ==',
          name: 'String',
          nullable: false,
        ),
        'currencyCode': debugSerializeParam(
          currencyCode,
          ParamType.String,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=CiAKGAoMY3VycmVuY3lDb2RlEghoMm9iOXl1anICCAN6AFoMY3VycmVuY3lDb2Rl',
          name: 'String',
          nullable: false,
        ),
        'currencyPosition': debugSerializeParam(
          currencyPosition,
          ParamType.String,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=CiQKHAoQY3VycmVuY3lQb3NpdGlvbhIIeDQxdTF4ZHNyAggDegBaEGN1cnJlbmN5UG9zaXRpb24=',
          name: 'String',
          nullable: false,
        ),
        'thousandSeparator': debugSerializeParam(
          thousandSeparator,
          ParamType.String,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=CiUKHQoRdGhvdXNhbmRTZXBhcmF0b3ISCGJ4aXVlcHlqcgIIA3oAWhF0aG91c2FuZFNlcGFyYXRvcg==',
          name: 'String',
          nullable: false,
        ),
        'decimalSeparator': debugSerializeParam(
          decimalSeparator,
          ParamType.String,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=CiQKHAoQZGVjaW1hbFNlcGFyYXRvchIIN2Fkdnhnd3RyAggDegBaEGRlY2ltYWxTZXBhcmF0b3I=',
          name: 'String',
          nullable: false,
        ),
        'decimalPlaces': debugSerializeParam(
          decimalPlaces,
          ParamType.int,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=CiEKGQoNZGVjaW1hbFBsYWNlcxIIMWdqNDh2cmRyAggBegBaDWRlY2ltYWxQbGFjZXM=',
          name: 'int',
          nullable: false,
        ),
        'countryName': debugSerializeParam(
          countryName,
          ParamType.String,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=Ch0KFwoLY291bnRyeU5hbWUSCDVqcW10Nm02cgIIA1oLY291bnRyeU5hbWU=',
          name: 'String',
          nullable: false,
        ),
        'pageIndex': debugSerializeParam(
          pageIndex,
          ParamType.int,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=ChsKFQoJcGFnZUluZGV4EghnYnR5NHdobXICCAFaCXBhZ2VJbmRleA==',
          name: 'int',
          nullable: false,
        ),
        'searchList': debugSerializeParam(
          searchList,
          ParamType.String,
          isList: true,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=Ch4KFgoKc2VhcmNoTGlzdBIIcHFtbm96Y2RyBBICCANaCnNlYXJjaExpc3Q=',
          name: 'String',
          nullable: false,
        ),
        'showCategorySection': debugSerializeParam(
          showCategorySection,
          ParamType.bool,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=CicKHwoTc2hvd0NhdGVnb3J5U2VjdGlvbhIIcDVtYXNscHZyAggFegBaE3Nob3dDYXRlZ29yeVNlY3Rpb24=',
          name: 'bool',
          nullable: false,
        ),
        'categorySectionIdsList': debugSerializeParam(
          categorySectionIdsList,
          ParamType.String,
          isList: true,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=CiwKIgoWY2F0ZWdvcnlTZWN0aW9uSWRzTGlzdBIIem9jZmI2aWZyBBICCAN6AFoWY2F0ZWdvcnlTZWN0aW9uSWRzTGlzdA==',
          name: 'String',
          nullable: false,
        ),
        'allCountrysList': debugSerializeParam(
          allCountrysList,
          ParamType.JSON,
          isList: true,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=CiUKGwoPYWxsQ291bnRyeXNMaXN0EghzZmVoeHN6d3IEEgIICXoAWg9hbGxDb3VudHJ5c0xpc3Q=',
          name: 'dynamic',
          nullable: false,
        ),
        'wishList': debugSerializeParam(
          wishList,
          ParamType.String,
          isList: true,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=Ch4KFAoId2lzaExpc3QSCHk3aXM2Z3JrcgQSAggDegBaCHdpc2hMaXN0',
          name: 'String',
          nullable: false,
        ),
        'response': debugSerializeParam(
          response,
          ParamType.bool,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=ChwKFAoIcmVzcG9uc2USCDUwcmg2MTRmcgIIBXoAWghyZXNwb25zZQ==',
          name: 'bool',
          nullable: false,
        ),
        'paymentGatewaysList': debugSerializeParam(
          paymentGatewaysList,
          ParamType.JSON,
          isList: true,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=CikKHwoTcGF5bWVudEdhdGV3YXlzTGlzdBIINTB6ajZmdmpyBBICCAl6AFoTcGF5bWVudEdhdGV3YXlzTGlzdA==',
          name: 'dynamic',
          nullable: false,
        ),
        'cartCount': debugSerializeParam(
          cartCount,
          ParamType.String,
          link:
              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=appValues&appValuesTab=state',
          searchReference:
              'reference=Ch0KFQoJY2FydENvdW50EghjbmtxcnYyOXICCAN6AFoJY2FydENvdW50',
          name: 'String',
          nullable: false,
        )
      };
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}
