import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '../../beytei_ms/ms.dart';
import '../../beytei_re/re.dart'as re;
import '../../chat/chat.dart' hide HomeScreen;
import '../../doctoe_beyte/do.dart';
import '../../lab/lab.dart';
import '../../ph/ph.dart' hide LocationCheckWrapper;
import '../../taxi/tx.dart';
import '../home_flow/splashbeytei.dart';
import '/home_flow/splash_home_page_widget.dart'; // ✅ استيراد صفحة splash الجديدة

import '/main.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/lat_lng.dart';
import '/flutter_flow/place.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'serialization_util.dart';

import '/index.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

const debugRouteLinkMap = {
  '/splashPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SplashPage',
  '/onboardingPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=OnboardingPage',
  '/demoImages':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=DemoImages',
  '/signInPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignInPage',
  '/signUpPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignUpPage',
  '/homeMainPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeMainPage',
  '/settingPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SettingPage',
  '/contactUsPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ContactUsPage',
  '/feedbackage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=Feedbackage',
  '/wishlistPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=WishlistPage',
  '/myAddressPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MyAddressPage',
  '/addAddressPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=AddAddressPage',
  '/productDetailPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPage',
  '/myProfilePage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MyProfilePage',
  '/editProfilePage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=EditProfilePage',
  '/sucessfullyPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SucessfullyPage',
  '/reviewPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ReviewPage',
  '/myOrdersPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MyOrdersPage',
  '/orderDetailsPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=OrderDetailsPage',
  '/categoryOpenPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryOpenPage',
  '/cartPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartPage',
  '/checkoutPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
  '/couponPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CouponPage',
  '/trendingProductsPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=TrendingProductsPage',
  '/relatedProductsPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=RelatedProductsPage',
  '/searchPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SearchPage',
  '/writeReviewPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=WriteReviewPage',
  '/writeReviewSubmitPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=WriteReviewSubmitPage',
  '/demoPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=DemoPage',
  '/blogPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=BlogPage',
  '/saleProductsPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SaleProductsPage',
  '/popularProductsPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=PopularProductsPage',
  '/latestProductsPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=LatestProductsPage',
  '/blogDetailPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=BlogDetailPage',
  '/upSellProductsPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=UpSellProductsPage',
  '/moreProductPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MoreProductPage',
  '/payForOderPage':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=PayForOderPage',
  '/productDetailPageCopy':
      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy'
};

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  bool showSplashImage = true;

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
  initialLocation: '/splash-home', // ✅ نبدأ من splash الجديدة
  debugLogDiagnostics: true,
  refreshListenable: appStateNotifier,
  navigatorKey: appNavigatorKey,
  errorBuilder: (context, state) => const SplashHomePageWidget(), // لتجنب ظهور شاشة خطأ
  routes: [

    // ✅ splash الجديدة
    FFRoute(
      name: 'SplashHomePage',
      path: '/splash-home',
      builder: (context, _) => const SplashHomePageWidget(),
    ),

    // ✅ splash القديمة الخاصة بالكوزمتك
    FFRoute(
      name: 'CosmeticSplashPage',
      path: '/splash', // مهم جدًا لأن بطاقة الكوزمتك تستخدم هذا المسار
      builder: (context, _) => const SplashPageWidget(), // استخدم نفس الصفحة القديمة
    ),

    // ✅ صفحة الأقسام
    FFRoute(
      name: 'SectionsPage',
      path: '/sections',
      builder: (context, _) => const SectionsPageWidget(),
    ),

    // ✅ صفحة الـ Onboarding (كما كانت)
    FFRoute(
      name: OnboardingPageWidget.routeName,
      path: OnboardingPageWidget.routePath,
      builder: (context, params) => OnboardingPageWidget(
        introList: params.getParam<dynamic>(
          'introList',
          ParamType.JSON,
          isList: true,
),
),
),
FFRoute(
name: DemoImagesWidget.routeName,
path: DemoImagesWidget.routePath,
builder: (context, params) => DemoImagesWidget(),
),
FFRoute(
name: SignInPageWidget.routeName,
path: SignInPageWidget.routePath,
builder: (context, params) => SignInPageWidget(
isInner: params.getParam('isInner', ParamType.bool),
),
),
FFRoute(
name: SignUpPageWidget.routeName,
path: SignUpPageWidget.routePath,
builder: (context, params) => SignUpPageWidget(
isInner: params.getParam('isInner', ParamType.bool),
),
),
FFRoute(
name: HomeMainPageWidget.routeName,
path: HomeMainPageWidget.routePath,
builder: (context, params) => HomeMainPageWidget(),
),
    FFRoute(
      name: 'MiswakStorePage',
      path: '/miswak-store',
      // ✅ التعديل هنا: نستدعي نقطة الدخول الجديدة (MiswakAppEntryPoint)
      // بدلاً من (LocationCheckWrapper) مباشرة
      builder: (context, params) => const MiswakModule(),
    ),
    FFRoute(
      name: 'medicalstorepage',
      path: '/medical-store',
      builder: (context, params) => AuthDispatcher(),
    ),







    FFRoute(
      name: 'labstorepage',
      path: '/lab-store',
      builder: (context, params) => const LabStoreScreen(),
    ),

    FFRoute(
      name: 'dostorepage',
      path: '/do-store',
      builder: (context, params) => HomeScreen(),
    ),




    FFRoute(
      name: 'trbstorepage',
      path: '/trb-store',
      builder: (context, params) => const  AuthGate(),
    ),






    FFRoute(
      name: 'phstorepage',
      path: '/pharmacy-store',
      builder: (context, params) => const PharmacyApp(),
    ),












    FFRoute(
      name: 'restaurantstorepage', // اسم مميز للمسار
      path: '/restaurants-store',  // الرابط الذي سيتم استخدامه للانتقال
      // تأكد من استبدال RestaurantHomeScreen باسم شاشة المطاعم الفعلية لديك
      builder: (context, params) => const re.RestaurantModule(),
    ),








FFRoute(
name: SettingPageWidget.routeName,
path: SettingPageWidget.routePath,
builder: (context, params) => SettingPageWidget(),
),
FFRoute(
name: ContactUsPageWidget.routeName,
path: ContactUsPageWidget.routePath,
builder: (context, params) => ContactUsPageWidget(),
),
FFRoute(
name: FeedbackageWidget.routeName,
path: FeedbackageWidget.routePath,
builder: (context, params) => FeedbackageWidget(),
),
FFRoute(
name: WishlistPageWidget.routeName,
path: WishlistPageWidget.routePath,
builder: (context, params) => WishlistPageWidget(),
),
FFRoute(
name: MyAddressPageWidget.routeName,
path: MyAddressPageWidget.routePath,
builder: (context, params) => MyAddressPageWidget(),
),
        FFRoute(
          name: AddAddressPageWidget.routeName,
          path: AddAddressPageWidget.routePath,
          builder: (context, params) => AddAddressPageWidget(
            isEdit: params.getParam(
              'isEdit',
              ParamType.bool,
            ),
            isShipping: params.getParam(
              'isShipping',
              ParamType.bool,
            ),
            address: params.getParam(
              'address',
              ParamType.JSON,
            ),
          ),
        ),
        FFRoute(
          name: ProductDetailPageWidget.routeName,
          path: ProductDetailPageWidget.routePath,
          builder: (context, params) => ProductDetailPageWidget(
            productDetail: params.getParam(
              'productDetail',
              ParamType.JSON,
            ),
            upsellIdsList: params.getParam<String>(
              'upsellIdsList',
              ParamType.String,
              isList: true,
            ),
            relatedIdsList: params.getParam<String>(
              'relatedIdsList',
              ParamType.String,
              isList: true,
            ),
            imagesList: params.getParam<dynamic>(
              'imagesList',
              ParamType.JSON,
              isList: true,
            ),
          ),
        ),
        FFRoute(
          name: MyProfilePageWidget.routeName,
          path: MyProfilePageWidget.routePath,
          builder: (context, params) => MyProfilePageWidget(),
        ),
        FFRoute(
          name: EditProfilePageWidget.routeName,
          path: EditProfilePageWidget.routePath,
          builder: (context, params) => EditProfilePageWidget(),
        ),
        FFRoute(
          name: SucessfullyPageWidget.routeName,
          path: SucessfullyPageWidget.routePath,
          builder: (context, params) => SucessfullyPageWidget(
            orderDetail: params.getParam(
              'orderDetail',
              ParamType.JSON,
            ),
          ),
        ),
        FFRoute(
          name: ReviewPageWidget.routeName,
          path: ReviewPageWidget.routePath,
          builder: (context, params) => ReviewPageWidget(
            reviewsList: params.getParam<dynamic>(
              'reviewsList',
              ParamType.JSON,
              isList: true,
            ),
            averageRating: params.getParam(
              'averageRating',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: MyOrdersPageWidget.routeName,
          path: MyOrdersPageWidget.routePath,
          builder: (context, params) => MyOrdersPageWidget(),
        ),
        FFRoute(
          name: OrderDetailsPageWidget.routeName,
          path: OrderDetailsPageWidget.routePath,
          builder: (context, params) => OrderDetailsPageWidget(
            orderId: params.getParam(
              'orderId',
              ParamType.int,
            ),
          ),
        ),
        FFRoute(
          name: CategoryOpenPageWidget.routeName,
          path: CategoryOpenPageWidget.routePath,
          builder: (context, params) => CategoryOpenPageWidget(
            title: params.getParam(
              'title',
              ParamType.String,
            ),
            catId: params.getParam(
              'catId',
              ParamType.String,
            ),
            cateImage: params.getParam(
              'cateImage',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: CartPageWidget.routeName,
          path: CartPageWidget.routePath,
          builder: (context, params) => CartPageWidget(),
        ),
        FFRoute(
          name: CheckoutPageWidget.routeName,
          path: CheckoutPageWidget.routePath,
          builder: (context, params) => CheckoutPageWidget(),
        ),
        FFRoute(
          name: CouponPageWidget.routeName,
          path: CouponPageWidget.routePath,
          builder: (context, params) => CouponPageWidget(
            nonce: params.getParam(
              'nonce',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: TrendingProductsPageWidget.routeName,
          path: TrendingProductsPageWidget.routePath,
          builder: (context, params) => TrendingProductsPageWidget(),
        ),
        FFRoute(
          name: RelatedProductsPageWidget.routeName,
          path: RelatedProductsPageWidget.routePath,
          builder: (context, params) => RelatedProductsPageWidget(
            relatedProductList: params.getParam<String>(
              'relatedProductList',
              ParamType.String,
              isList: true,
            ),
          ),
        ),
        FFRoute(
          name: SearchPageWidget.routeName,
          path: SearchPageWidget.routePath,
          builder: (context, params) => SearchPageWidget(),
        ),
        FFRoute(
          name: WriteReviewPageWidget.routeName,
          path: WriteReviewPageWidget.routePath,
          builder: (context, params) => WriteReviewPageWidget(
            productDetail: params.getParam(
              'productDetail',
              ParamType.JSON,
            ),
          ),
        ),
        FFRoute(
          name: WriteReviewSubmitPageWidget.routeName,
          path: WriteReviewSubmitPageWidget.routePath,
          builder: (context, params) => WriteReviewSubmitPageWidget(
            productDetail: params.getParam(
              'productDetail',
              ParamType.JSON,
            ),
            rating: params.getParam(
              'rating',
              ParamType.double,
            ),
          ),
        ),
        FFRoute(
          name: DemoPageWidget.routeName,
          path: DemoPageWidget.routePath,
          builder: (context, params) => DemoPageWidget(),
        ),
        FFRoute(
          name: BlogPageWidget.routeName,
          path: BlogPageWidget.routePath,
          builder: (context, params) => BlogPageWidget(),
        ),
        FFRoute(
          name: SaleProductsPageWidget.routeName,
          path: SaleProductsPageWidget.routePath,
          builder: (context, params) => SaleProductsPageWidget(),
        ),
        FFRoute(
          name: PopularProductsPageWidget.routeName,
          path: PopularProductsPageWidget.routePath,
          builder: (context, params) => PopularProductsPageWidget(),
        ),
        FFRoute(
          name: LatestProductsPageWidget.routeName,
          path: LatestProductsPageWidget.routePath,
          builder: (context, params) => LatestProductsPageWidget(),
        ),
        FFRoute(
          name: BlogDetailPageWidget.routeName,
          path: BlogDetailPageWidget.routePath,
          builder: (context, params) => BlogDetailPageWidget(
            title: params.getParam(
              'title',
              ParamType.String,
            ),
            date: params.getParam(
              'date',
              ParamType.String,
            ),
            detail: params.getParam(
              'detail',
              ParamType.String,
            ),
            shareUrl: params.getParam(
              'shareUrl',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: UpSellProductsPageWidget.routeName,
          path: UpSellProductsPageWidget.routePath,
          builder: (context, params) => UpSellProductsPageWidget(
            upSellProductList: params.getParam<String>(
              'upSellProductList',
              ParamType.String,
              isList: true,
            ),
          ),
        ),
        FFRoute(
          name: MoreProductPageWidget.routeName,
          path: MoreProductPageWidget.routePath,
          builder: (context, params) => MoreProductPageWidget(
            moreProductList: params.getParam<int>(
              'moreProductList',
              ParamType.int,
              isList: true,
            ),
          ),
        ),
        FFRoute(
          name: PayForOderPageWidget.routeName,
          path: PayForOderPageWidget.routePath,
          builder: (context, params) => PayForOderPageWidget(
            orderDetail: params.getParam(
              'orderDetail',
              ParamType.JSON,
            ),
          ),
        ),
        FFRoute(
          name: ProductDetailPageCopyWidget.routeName,
          path: ProductDetailPageCopyWidget.routePath,
          builder: (context, params) => ProductDetailPageCopyWidget(
            productDetail: params.getParam(
              'productDetail',
              ParamType.JSON,
            ),
            upsellIdsList: params.getParam<String>(
              'upsellIdsList',
              ParamType.String,
              isList: true,
            ),
            relatedIdsList: params.getParam<String>(
              'relatedIdsList',
              ParamType.String,
              isList: true,
            ),
            imagesList: params.getParam<dynamic>(
              'imagesList',
              ParamType.JSON,
              isList: true,
            ),
          ),
        )
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
      observers: [routeObserver],
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(key: state.pageKey, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
