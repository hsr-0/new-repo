import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/categories_single_home_component/categories_single_home_component_widget.dart';
import '/pages/components/logo_component/logo_component_widget.dart';
import '/pages/components/main_component/main_component_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/shimmer/banner_shimmer/banner_shimmer_widget.dart';
import '/pages/shimmer/big_saving_shimmer/big_saving_shimmer_widget.dart';
import '/pages/shimmer/blog_shimmer/blog_shimmer_widget.dart';
import '/pages/shimmer/category_shimmer/category_shimmer_widget.dart';
import '/pages/shimmer/products_hore_shimmer/products_hore_shimmer_widget.dart';
import '/pages/shimmer/sale_products_shimmer/sale_products_shimmer_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'home_component_model.dart';
export 'home_component_model.dart';

class HomeComponentWidget extends StatefulWidget {
  const HomeComponentWidget({super.key});

  @override
  State<HomeComponentWidget> createState() => _HomeComponentWidgetState();
}

class _HomeComponentWidgetState extends State<HomeComponentWidget>
    with TickerProviderStateMixin, RouteAware {
  late HomeComponentModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomeComponentModel());

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await action_blocks.responseAction(context);
      safeSetState(() {});
    });

    animationsMap.addAll({
      'mainComponentOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 120.0.ms,
            duration: 600.0.ms,
            begin: 0.15,
            end: 1.0,
          ),
        ],
      ),
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);

    _model.maybeDispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = DebugModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
    debugLogGlobalProperty(context);
  }

  @override
  void didPopNext() {
    if (mounted && DebugFlutterFlowModelContext.maybeOf(context) == null) {
      setState(() => _model.isRouteVisible = true);
      debugLogWidgetClass(_model);
    }
  }

  @override
  void didPush() {
    if (mounted && DebugFlutterFlowModelContext.maybeOf(context) == null) {
      setState(() => _model.isRouteVisible = true);
      debugLogWidgetClass(_model);
    }
  }

  @override
  void didPop() {
    _model.isRouteVisible = false;
  }

  @override
  void didPushNext() {
    _model.isRouteVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    DebugFlutterFlowModelContext.maybeOf(context)
        ?.parentModelCallback
        ?.call(_model);
    context.watch<FFAppState>();

    return Builder(
      builder: (context) {
        if (FFAppState().connected) {
          return Builder(
            builder: (context) {
              if (FFAppState().response) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).lightGray,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primaryBackground,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  12.0, 16.0, 12.0, 16.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  wrapWithModel(
                                    model: _model.logoComponentModel,
                                    updateCallback: () => safeSetState(() {}),
                                    child: Builder(builder: (_) {
                                      return DebugFlutterFlowModelContext(
                                        rootModel: _model.rootModel,
                                        child: LogoComponentWidget(
                                          height: 46.0,
                                          width: 46.0,
                                        ),
                                      );
                                    }),
                                  ),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          FFLocalizations.of(context).getText(
                                            'r8or6va3' /* Welcome back */,
                                          ),
                                          textAlign: TextAlign.start,
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'SF Pro Display',
                                                fontSize: 16.0,
                                                letterSpacing: 0.16,
                                                fontWeight: FontWeight.normal,
                                                useGoogleFonts: false,
                                                lineHeight: 1.5,
                                              ),
                                        ),
                                        if (FFAppState().isLogin)
                                          Text(
                                            ('' ==
                                                        getJsonField(
                                                          FFAppState()
                                                              .userDetail,
                                                          r'''$.first_name''',
                                                        ).toString()) &&
                                                    ('' ==
                                                        getJsonField(
                                                          FFAppState()
                                                              .userDetail,
                                                          r'''$.last_name''',
                                                        ).toString())
                                                ? getJsonField(
                                                    FFAppState().userDetail,
                                                    r'''$.username''',
                                                  ).toString()
                                                : '${getJsonField(
                                                    FFAppState().userDetail,
                                                    r'''$.first_name''',
                                                  ).toString()} ${getJsonField(
                                                    FFAppState().userDetail,
                                                    r'''$.last_name''',
                                                  ).toString()}',
                                            textAlign: TextAlign.start,
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'SF Pro Display',
                                                  fontSize: 18.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                  useGoogleFonts: false,
                                                  lineHeight: 1.5,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      context.pushNamed(
                                          SearchPageWidget.routeName);
                                    },
                                    child: Container(
                                      width: 40.0,
                                      height: 40.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .black10,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(0.0),
                                        child: SvgPicture.asset(
                                          'assets/images/search.svg',
                                          width: 24.0,
                                          height: 24.0,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      FFAppState().pageIndex = 2;
                                      FFAppState().update(() {});
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(),
                                      child: Stack(
                                        alignment:
                                            AlignmentDirectional(1.3, -2.2),
                                        children: [
                                          Container(
                                            width: 40.0,
                                            height: 40.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .black10,
                                              shape: BoxShape.circle,
                                            ),
                                            alignment:
                                                AlignmentDirectional(0.0, 0.0),
                                            child: Icon(
                                              Icons.shopping_cart_outlined,
                                              color: Colors.black,
                                              size: 24.0,
                                            ),
                                          ),
                                          if ((FFAppState().cartCount != '0') &&
                                              FFAppState().isLogin)
                                            Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: AlignmentDirectional(
                                                  0.0, 0.0),
                                              child: Padding(
                                                padding: EdgeInsets.all(5.0),
                                                child: Text(
                                                  FFAppState().cartCount,
                                                  textAlign: TextAlign.start,
                                                  maxLines: 1,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily:
                                                            'SF Pro Display',
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .primaryBackground,
                                                        fontSize: 13.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        useGoogleFonts: false,
                                                        lineHeight: 1.5,
                                                      ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ].divide(SizedBox(width: 12.0)),
                              ),
                            ),
                            Divider(
                              height: 1.0,
                              thickness: 1.0,
                              color: FlutterFlowTheme.of(context).black10,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          key: Key('RefreshIndicator_60rx6uzj'),
                          color: FlutterFlowTheme.of(context).primary,
                          onRefresh: () async {
                            await Future.wait([
                              Future(() async {
                                safeSetState(() {
                                  FFAppState().clearCategoriesCache();
                                  _model.apiRequestCompleted7 = false;
                                });
                                await _model.waitForApiRequestCompleted7();
                              }),
                              Future(() async {
                                safeSetState(() {
                                  FFAppState().clearTrendingProductsCache();
                                  _model.apiRequestCompleted1 = false;
                                });
                                await _model.waitForApiRequestCompleted1();
                              }),
                              Future(() async {
                                safeSetState(() {
                                  FFAppState().clearSellProductsCache();
                                  _model.apiRequestCompleted9 = false;
                                });
                                await _model.waitForApiRequestCompleted9();
                              }),
                              Future(() async {
                                safeSetState(() {
                                  FFAppState().clearCategoriesCache();
                                  _model.apiRequestCompleted5 = false;
                                });
                                await _model.waitForApiRequestCompleted5();
                                safeSetState(() {
                                  FFAppState().clearCategoryOpenCacheKey(
                                      _model.apiRequestLastUniqueKey3);
                                  _model.apiRequestCompleted3 = false;
                                });
                                await _model.waitForApiRequestCompleted3();
                              }),
                              Future(() async {
                                safeSetState(() {
                                  FFAppState().clearPopularProductsCache();
                                  _model.apiRequestCompleted6 = false;
                                });
                                await _model.waitForApiRequestCompleted6();
                              }),
                              Future(() async {
                                safeSetState(() {
                                  FFAppState().clearLatestProductsCache();
                                  _model.apiRequestCompleted4 = false;
                                });
                                await _model.waitForApiRequestCompleted4();
                              }),
                              Future(() async {
                                safeSetState(() {
                                  FFAppState().clearBlogCache();
                                  _model.apiRequestCompleted2 = false;
                                });
                                await _model.waitForApiRequestCompleted2();
                              }),
                              Future(() async {
                                FFAppState().clearReviewsCache();
                              }),
                              Future(() async {
                                FFAppState().clearProductDdetailCache();
                              }),
                              Future(() async {
                                safeSetState(() {
                                  FFAppState().clearPrimaryCategoryCache();
                                  _model.apiRequestCompleted10 = false;
                                });
                                await _model.waitForApiRequestCompleted10();
                                safeSetState(() {
                                  FFAppState().clearProductDdetailCacheKey(
                                      _model.apiRequestLastUniqueKey8);
                                  _model.apiRequestCompleted8 = false;
                                });
                                await _model.waitForApiRequestCompleted8(
                                    maxWait: 3000);
                              }),
                            ]);
                          },
                          child: SingleChildScrollView(
                            primary: false,
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                FutureBuilder<ApiCallResponse>(
                                  future: FFAppState()
                                      .primaryCategory(
                                    requestFn: () => PlantShopGroup
                                        .primaryCategoryCall
                                        .call(),
                                  )
                                      .then((result) {
                                    _model.apiRequestCompleted10 = true;
                                    return result;
                                  }),
                                  builder: (context, snapshot) {
                                    // Customize what your widget looks like when it's loading.
                                    if (!snapshot.hasData) {
                                      return BannerShimmerWidget(
                                        isBig: true,
                                        image: '',
                                      );
                                    }
                                    final primaryCategoryPrimaryCategoryResponse =
                                        snapshot.data!;
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.primaryCategoryCall_statusCode_Container_zkfkjhyz'] =
                                        debugSerializeParam(
                                      primaryCategoryPrimaryCategoryResponse
                                          .statusCode,
                                      ParamType.int,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                      name: 'int',
                                      nullable: false,
                                    );
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.primaryCategoryCall_responseBody_Container_zkfkjhyz'] =
                                        debugSerializeParam(
                                      primaryCategoryPrimaryCategoryResponse
                                          .bodyText,
                                      ParamType.String,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                      name: 'String',
                                      nullable: false,
                                    );
                                    debugLogWidgetClass(_model);

                                    return Container(
                                      decoration: BoxDecoration(),
                                      child: Visibility(
                                        visible: (PlantShopGroup
                                                    .primaryCategoryCall
                                                    .status(
                                                  primaryCategoryPrimaryCategoryResponse
                                                      .jsonBody,
                                                ) ==
                                                'success') &&
                                            (PlantShopGroup.primaryCategoryCall
                                                        .dataList(
                                                      primaryCategoryPrimaryCategoryResponse
                                                          .jsonBody,
                                                    ) !=
                                                    null &&
                                                (PlantShopGroup
                                                        .primaryCategoryCall
                                                        .dataList(
                                                  primaryCategoryPrimaryCategoryResponse
                                                      .jsonBody,
                                                ))!
                                                    .isNotEmpty),
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .primaryBackground,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Builder(
                                                builder: (context) {
                                                  final bannerList =
                                                      PlantShopGroup
                                                              .primaryCategoryCall
                                                              .dataList(
                                                                primaryCategoryPrimaryCategoryResponse
                                                                    .jsonBody,
                                                              )
                                                              ?.toList() ??
                                                          [];
                                                  _model.debugGeneratorVariables[
                                                          'bannerList${bannerList.length > 100 ? ' (first 100)' : ''}'] =
                                                      debugSerializeParam(
                                                    bannerList.take(100),
                                                    ParamType.JSON,
                                                    isList: true,
                                                    link:
                                                        'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                    name: 'dynamic',
                                                    nullable: false,
                                                  );
                                                  debugLogWidgetClass(_model);

                                                  return Container(
                                                    width: double.infinity,
                                                    height: () {
                                                      if (MediaQuery.sizeOf(
                                                                  context)
                                                              .width <
                                                          kBreakpointSmall) {
                                                        return 154.0;
                                                      } else if (MediaQuery
                                                                  .sizeOf(
                                                                      context)
                                                              .width <
                                                          kBreakpointMedium) {
                                                        return 184.0;
                                                      } else if (MediaQuery
                                                                  .sizeOf(
                                                                      context)
                                                              .width <
                                                          kBreakpointLarge) {
                                                        return 204.0;
                                                      } else {
                                                        return 234.0;
                                                      }
                                                    }(),
                                                    child:
                                                        CarouselSlider.builder(
                                                      itemCount:
                                                          bannerList.length,
                                                      itemBuilder: (context,
                                                          bannerListIndex, _) {
                                                        final bannerListItem =
                                                            bannerList[
                                                                bannerListIndex];
                                                        return FutureBuilder<
                                                            ApiCallResponse>(
                                                          future: FFAppState()
                                                              .productDdetail(
                                                            uniqueQueryKey:
                                                                getJsonField(
                                                              bannerListItem,
                                                              r'''$.redirect_id''',
                                                            ).toString(),
                                                            requestFn: () =>
                                                                PlantShopGroup
                                                                    .productDetailCall
                                                                    .call(
                                                              productId:
                                                                  getJsonField(
                                                                bannerListItem,
                                                                r'''$.redirect_id''',
                                                              ).toString(),
                                                            ),
                                                          )
                                                              .then((result) {
                                                            try {
                                                              _model.apiRequestCompleted8 =
                                                                  true;
                                                              _model.apiRequestLastUniqueKey8 =
                                                                  getJsonField(
                                                                bannerListItem,
                                                                r'''$.redirect_id''',
                                                              ).toString();
                                                            } finally {}
                                                            return result;
                                                          }),
                                                          builder: (context,
                                                              snapshot) {
                                                            // Customize what your widget looks like when it's loading.
                                                            if (!snapshot
                                                                .hasData) {
                                                              return BannerShimmerWidget(
                                                                isBig: false,
                                                                image:
                                                                    getJsonField(
                                                                  bannerListItem,
                                                                  r'''$.featured_image''',
                                                                ).toString(),
                                                              );
                                                            }
                                                            final bannerProductDetailResponse =
                                                                snapshot.data!;
                                                            _model.debugBackendQueries[
                                                                    'PlantShopGroup.productDetailCall_statusCode_Container_wh29f9e5'] =
                                                                debugSerializeParam(
                                                              bannerProductDetailResponse
                                                                  .statusCode,
                                                              ParamType.int,
                                                              link:
                                                                  'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                              name: 'int',
                                                              nullable: false,
                                                            );
                                                            _model.debugBackendQueries[
                                                                    'PlantShopGroup.productDetailCall_responseBody_Container_wh29f9e5'] =
                                                                debugSerializeParam(
                                                              bannerProductDetailResponse
                                                                  .bodyText,
                                                              ParamType.String,
                                                              link:
                                                                  'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                              name: 'String',
                                                              nullable: false,
                                                            );
                                                            debugLogWidgetClass(
                                                                _model);

                                                            return Container(
                                                              decoration:
                                                                  BoxDecoration(),
                                                              child: InkWell(
                                                                splashColor: Colors
                                                                    .transparent,
                                                                focusColor: Colors
                                                                    .transparent,
                                                                hoverColor: Colors
                                                                    .transparent,
                                                                highlightColor:
                                                                    Colors
                                                                        .transparent,
                                                                onTap:
                                                                    () async {
                                                                  if ('product' ==
                                                                      getJsonField(
                                                                        bannerListItem,
                                                                        r'''$.redirect_type''',
                                                                      ).toString()) {
                                                                    context
                                                                        .pushNamed(
                                                                      ProductDetailPageWidget
                                                                          .routeName,
                                                                      queryParameters:
                                                                          {
                                                                        'productDetail':
                                                                            serializeParam(
                                                                          PlantShopGroup
                                                                              .productDetailCall
                                                                              .productDetail(
                                                                            bannerProductDetailResponse.jsonBody,
                                                                          ),
                                                                          ParamType
                                                                              .JSON,
                                                                        ),
                                                                        'upsellIdsList':
                                                                            serializeParam(
                                                                          (getJsonField(
                                                                            PlantShopGroup.productDetailCall.productDetail(
                                                                              bannerProductDetailResponse.jsonBody,
                                                                            ),
                                                                            r'''$.upsell_ids''',
                                                                            true,
                                                                          ) as List)
                                                                              .map<String>((s) => s.toString())
                                                                              .toList(),
                                                                          ParamType
                                                                              .String,
                                                                          isList:
                                                                              true,
                                                                        ),
                                                                        'relatedIdsList':
                                                                            serializeParam(
                                                                          (getJsonField(
                                                                            PlantShopGroup.productDetailCall.productDetail(
                                                                              bannerProductDetailResponse.jsonBody,
                                                                            ),
                                                                            r'''$.related_ids''',
                                                                            true,
                                                                          ) as List)
                                                                              .map<String>((s) => s.toString())
                                                                              .toList(),
                                                                          ParamType
                                                                              .String,
                                                                          isList:
                                                                              true,
                                                                        ),
                                                                        'imagesList':
                                                                            serializeParam(
                                                                          PlantShopGroup
                                                                              .productDetailCall
                                                                              .imagesList(
                                                                            bannerProductDetailResponse.jsonBody,
                                                                          ),
                                                                          ParamType
                                                                              .JSON,
                                                                          isList:
                                                                              true,
                                                                        ),
                                                                      }.withoutNulls,
                                                                    );
                                                                  } else {
                                                                    context
                                                                        .pushNamed(
                                                                      CategoryOpenPageWidget
                                                                          .routeName,
                                                                      queryParameters:
                                                                          {
                                                                        'title':
                                                                            serializeParam(
                                                                          getJsonField(
                                                                            bannerListItem,
                                                                            r'''$.redirect_info''',
                                                                          ).toString(),
                                                                          ParamType
                                                                              .String,
                                                                        ),
                                                                        'catId':
                                                                            serializeParam(
                                                                          getJsonField(
                                                                            bannerListItem,
                                                                            r'''$.redirect_id''',
                                                                          ).toString(),
                                                                          ParamType
                                                                              .String,
                                                                        ),
                                                                        'cateImage':
                                                                            serializeParam(
                                                                          '',
                                                                          ParamType
                                                                              .String,
                                                                        ),
                                                                      }.withoutNulls,
                                                                    );
                                                                  }
                                                                },
                                                                child:
                                                                    ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              16.0),
                                                                  child:
                                                                      CachedNetworkImage(
                                                                    fadeInDuration:
                                                                        Duration(
                                                                            milliseconds:
                                                                                200),
                                                                    fadeOutDuration:
                                                                        Duration(
                                                                            milliseconds:
                                                                                200),
                                                                    imageUrl:
                                                                        getJsonField(
                                                                      bannerListItem,
                                                                      r'''$.featured_image''',
                                                                    ).toString(),
                                                                    width: double
                                                                        .infinity,
                                                                    height: double
                                                                        .infinity,
                                                                    fit: BoxFit
                                                                        .fill,
                                                                    errorWidget: (context,
                                                                            error,
                                                                            stackTrace) =>
                                                                        Image
                                                                            .asset(
                                                                      'assets/images/error_image.png',
                                                                      width: double
                                                                          .infinity,
                                                                      height: double
                                                                          .infinity,
                                                                      fit: BoxFit
                                                                          .fill,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        );
                                                      },
                                                      carouselController: _model
                                                              .carouselController1 ??=
                                                          CarouselSliderController(),
                                                      options: CarouselOptions(
                                                        initialPage: max(
                                                            0,
                                                            min(
                                                                1,
                                                                bannerList
                                                                        .length -
                                                                    1)),
                                                        viewportFraction: () {
                                                          if (MediaQuery.sizeOf(
                                                                      context)
                                                                  .width <
                                                              kBreakpointSmall) {
                                                            return 0.8;
                                                          } else if (MediaQuery
                                                                      .sizeOf(
                                                                          context)
                                                                  .width <
                                                              kBreakpointMedium) {
                                                            return 0.7;
                                                          } else if (MediaQuery
                                                                      .sizeOf(
                                                                          context)
                                                                  .width <
                                                              kBreakpointLarge) {
                                                            return 0.55;
                                                          } else {
                                                            return 0.45;
                                                          }
                                                        }(),
                                                        disableCenter: true,
                                                        enlargeCenterPage: true,
                                                        enlargeFactor: 0.25,
                                                        enableInfiniteScroll:
                                                            true,
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        autoPlay: false,
                                                        onPageChanged:
                                                            (index, _) async {
                                                          _model.carouselCurrentIndex1 =
                                                              index;

                                                          safeSetState(() {});
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 16.0, 0.0, 16.0),
                                                child: Builder(
                                                  builder: (context) {
                                                    final rowList = PlantShopGroup
                                                            .primaryCategoryCall
                                                            .dataList(
                                                              primaryCategoryPrimaryCategoryResponse
                                                                  .jsonBody,
                                                            )
                                                            ?.toList() ??
                                                        [];
                                                    _model.debugGeneratorVariables[
                                                            'rowList${rowList.length > 100 ? ' (first 100)' : ''}'] =
                                                        debugSerializeParam(
                                                      rowList.take(100),
                                                      ParamType.JSON,
                                                      isList: true,
                                                      link:
                                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                      name: 'dynamic',
                                                      nullable: false,
                                                    );
                                                    debugLogWidgetClass(_model);

                                                    return Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: List.generate(
                                                          rowList.length,
                                                          (rowListIndex) {
                                                        final rowListItem =
                                                            rowList[
                                                                rowListIndex];
                                                        return Container(
                                                          width: 10.0,
                                                          height: 10.0,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: rowListIndex ==
                                                                    _model
                                                                        .carouselCurrentIndex1
                                                                ? FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary
                                                                : FlutterFlowTheme.of(
                                                                        context)
                                                                    .black10,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                        );
                                                      }).divide(
                                                          SizedBox(width: 8.0)),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ].addToStart(
                                                SizedBox(height: 16.0)),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                FutureBuilder<ApiCallResponse>(
                                  future: FFAppState()
                                      .categories(
                                    requestFn: () =>
                                        PlantShopGroup.categoriesCall.call(),
                                  )
                                      .then((result) {
                                    _model.apiRequestCompleted7 = true;
                                    return result;
                                  }),
                                  builder: (context, snapshot) {
                                    // Customize what your widget looks like when it's loading.
                                    if (!snapshot.hasData) {
                                      return CategoryShimmerWidget();
                                    }
                                    final categoriesContainerCategoriesResponse =
                                        snapshot.data!;
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.categoriesCall_statusCode_Container_u0q7dlhe'] =
                                        debugSerializeParam(
                                      categoriesContainerCategoriesResponse
                                          .statusCode,
                                      ParamType.int,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                      name: 'int',
                                      nullable: false,
                                    );
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.categoriesCall_responseBody_Container_u0q7dlhe'] =
                                        debugSerializeParam(
                                      categoriesContainerCategoriesResponse
                                          .bodyText,
                                      ParamType.String,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                      name: 'String',
                                      nullable: false,
                                    );
                                    debugLogWidgetClass(_model);

                                    return Container(
                                      decoration: BoxDecoration(),
                                      child: Visibility(
                                        visible: (PlantShopGroup.categoriesCall
                                                    .status(
                                                  categoriesContainerCategoriesResponse
                                                      .jsonBody,
                                                ) ==
                                                null) &&
                                            (PlantShopGroup.categoriesCall
                                                        .categoriesList(
                                                      categoriesContainerCategoriesResponse
                                                          .jsonBody,
                                                    ) !=
                                                    null &&
                                                (PlantShopGroup.categoriesCall
                                                        .categoriesList(
                                                  categoriesContainerCategoriesResponse
                                                      .jsonBody,
                                                ))!
                                                    .isNotEmpty),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 12.0, 0.0, 0.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryBackground,
                                            ),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 20.0, 0.0, 20.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(12.0, 0.0,
                                                                12.0, 0.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          FFLocalizations.of(
                                                                  context)
                                                              .getText(
                                                            'o2qcaobb' /* Categories */,
                                                          ),
                                                          textAlign:
                                                              TextAlign.start,
                                                          maxLines: 1,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                fontSize: 20.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                useGoogleFonts:
                                                                    false,
                                                                lineHeight: 1.5,
                                                              ),
                                                        ),
                                                        InkWell(
                                                          splashColor: Colors
                                                              .transparent,
                                                          focusColor: Colors
                                                              .transparent,
                                                          hoverColor: Colors
                                                              .transparent,
                                                          highlightColor: Colors
                                                              .transparent,
                                                          onTap: () async {
                                                            FFAppState()
                                                                .pageIndex = 1;
                                                            FFAppState()
                                                                .update(() {});
                                                          },
                                                          child: Container(
                                                            height: 29.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .black10,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          30.0),
                                                            ),
                                                            alignment:
                                                                AlignmentDirectional(
                                                                    0.0, 0.0),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          10.0,
                                                                          0.0,
                                                                          10.0,
                                                                          0.0),
                                                              child: Text(
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  'bamwuzoa' /* View all */,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      fontSize:
                                                                          14.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal,
                                                                      useGoogleFonts:
                                                                          false,
                                                                      lineHeight:
                                                                          1.0,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 20.0,
                                                                0.0, 0.0),
                                                    child: Container(
                                                      width: double.infinity,
                                                      decoration:
                                                          BoxDecoration(),
                                                      child: Builder(
                                                        builder: (context) {
                                                          final categoriesList =
                                                              PlantShopGroup
                                                                      .categoriesCall
                                                                      .categoriesList(
                                                                        categoriesContainerCategoriesResponse
                                                                            .jsonBody,
                                                                      )
                                                                      ?.toList() ??
                                                                  [];
                                                          _model.debugGeneratorVariables[
                                                                  'categoriesList${categoriesList.length > 100 ? ' (first 100)' : ''}'] =
                                                              debugSerializeParam(
                                                            categoriesList
                                                                .take(100),
                                                            ParamType.JSON,
                                                            isList: true,
                                                            link:
                                                                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                            name: 'dynamic',
                                                            nullable: false,
                                                          );
                                                          debugLogWidgetClass(
                                                              _model);

                                                          return SingleChildScrollView(
                                                            scrollDirection:
                                                                Axis.horizontal,
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              children: List.generate(
                                                                      categoriesList
                                                                          .length,
                                                                      (categoriesListIndex) {
                                                                final categoriesListItem =
                                                                    categoriesList[
                                                                        categoriesListIndex];
                                                                return wrapWithModel(
                                                                  model: _model
                                                                      .categoriesSingleHomeComponentModels
                                                                      .getModel(
                                                                    getJsonField(
                                                                      categoriesListItem,
                                                                      r'''$.id''',
                                                                    ).toString(),
                                                                    categoriesListIndex,
                                                                  ),
                                                                  updateCallback: () =>
                                                                      safeSetState(
                                                                          () {}),
                                                                  child: Builder(
                                                                      builder:
                                                                          (_) {
                                                                    return DebugFlutterFlowModelContext(
                                                                      rootModel:
                                                                          _model
                                                                              .rootModel,
                                                                      child:
                                                                          CategoriesSingleHomeComponentWidget(
                                                                        key:
                                                                            Key(
                                                                          'Keyp92_${getJsonField(
                                                                            categoriesListItem,
                                                                            r'''$.id''',
                                                                          ).toString()}',
                                                                        ),
                                                                        image:
                                                                            getJsonField(
                                                                          categoriesListItem,
                                                                          r'''$.image.src''',
                                                                        ).toString(),
                                                                        name:
                                                                            getJsonField(
                                                                          categoriesListItem,
                                                                          r'''$.name''',
                                                                        ).toString(),
                                                                        width:
                                                                            83.0,
                                                                        showImage: ('' !=
                                                                                getJsonField(
                                                                                  categoriesListItem,
                                                                                  r'''$.image.src''',
                                                                                ).toString()) &&
                                                                            (getJsonField(
                                                                                  categoriesListItem,
                                                                                  r'''$.image.src''',
                                                                                ) !=
                                                                                null) &&
                                                                            (getJsonField(
                                                                                  categoriesListItem,
                                                                                  r'''$.image''',
                                                                                ) !=
                                                                                null),
                                                                        isMainTap:
                                                                            () async {
                                                                          context
                                                                              .pushNamed(
                                                                            CategoryOpenPageWidget.routeName,
                                                                            queryParameters:
                                                                                {
                                                                              'title': serializeParam(
                                                                                getJsonField(
                                                                                  categoriesListItem,
                                                                                  r'''$.name''',
                                                                                ).toString(),
                                                                                ParamType.String,
                                                                              ),
                                                                              'catId': serializeParam(
                                                                                getJsonField(
                                                                                  categoriesListItem,
                                                                                  r'''$.id''',
                                                                                ).toString(),
                                                                                ParamType.String,
                                                                              ),
                                                                              'cateImage': serializeParam(
                                                                                getJsonField(
                                                                                  categoriesListItem,
                                                                                  r'''$.image.src''',
                                                                                ).toString(),
                                                                                ParamType.String,
                                                                              ),
                                                                            }.withoutNulls,
                                                                          );
                                                                        },
                                                                      ),
                                                                    );
                                                                  }),
                                                                );
                                                              })
                                                                  .divide(SizedBox(
                                                                      width:
                                                                          12.0))
                                                                  .addToStart(
                                                                      SizedBox(
                                                                          width:
                                                                              12.0))
                                                                  .addToEnd(
                                                                      SizedBox(
                                                                          width:
                                                                              12.0)),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                FutureBuilder<ApiCallResponse>(
                                  future: FFAppState()
                                      .trendingProducts(
                                    requestFn: () => PlantShopGroup
                                        .trendingProductsCall
                                        .call(
                                      page: 1,
                                    ),
                                  )
                                      .then((result) {
                                    _model.apiRequestCompleted1 = true;
                                    return result;
                                  }),
                                  builder: (context, snapshot) {
                                    // Customize what your widget looks like when it's loading.
                                    if (!snapshot.hasData) {
                                      return ProductsHoreShimmerWidget(
                                        name: 'Trending products',
                                      );
                                    }
                                    final trendingProductsTrendingProductsResponse =
                                        snapshot.data!;
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.trendingProductsCall_statusCode_Container_91tcrd8e'] =
                                        debugSerializeParam(
                                      trendingProductsTrendingProductsResponse
                                          .statusCode,
                                      ParamType.int,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                      name: 'int',
                                      nullable: false,
                                    );
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.trendingProductsCall_responseBody_Container_91tcrd8e'] =
                                        debugSerializeParam(
                                      trendingProductsTrendingProductsResponse
                                          .bodyText,
                                      ParamType.String,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                      name: 'String',
                                      nullable: false,
                                    );
                                    debugLogWidgetClass(_model);

                                    return Container(
                                      decoration: BoxDecoration(),
                                      child: Visibility(
                                        visible: (PlantShopGroup
                                                    .trendingProductsCall
                                                    .status(
                                                  trendingProductsTrendingProductsResponse
                                                      .jsonBody,
                                                ) ==
                                                null) &&
                                            (PlantShopGroup.trendingProductsCall
                                                        .trendingProductsList(
                                                      trendingProductsTrendingProductsResponse
                                                          .jsonBody,
                                                    ) !=
                                                    null &&
                                                (PlantShopGroup
                                                        .trendingProductsCall
                                                        .trendingProductsList(
                                                  trendingProductsTrendingProductsResponse
                                                      .jsonBody,
                                                ))!
                                                    .isNotEmpty),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 12.0, 0.0, 0.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryBackground,
                                            ),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 20.0, 0.0, 20.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(12.0, 0.0,
                                                                12.0, 16.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          FFLocalizations.of(
                                                                  context)
                                                              .getText(
                                                            'jc4z0gdg' /* Trending products */,
                                                          ),
                                                          textAlign:
                                                              TextAlign.start,
                                                          maxLines: 1,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                                fontSize: 20.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                useGoogleFonts:
                                                                    false,
                                                                lineHeight: 1.5,
                                                              ),
                                                        ),
                                                        InkWell(
                                                          splashColor: Colors
                                                              .transparent,
                                                          focusColor: Colors
                                                              .transparent,
                                                          hoverColor: Colors
                                                              .transparent,
                                                          highlightColor: Colors
                                                              .transparent,
                                                          onTap: () async {
                                                            context.pushNamed(
                                                                TrendingProductsPageWidget
                                                                    .routeName);
                                                          },
                                                          child: Container(
                                                            height: 29.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .black10,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          30.0),
                                                            ),
                                                            alignment:
                                                                AlignmentDirectional(
                                                                    0.0, 0.0),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          10.0,
                                                                          0.0,
                                                                          10.0,
                                                                          0.0),
                                                              child: Text(
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  'xooyca16' /* View all */,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      fontSize:
                                                                          14.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal,
                                                                      useGoogleFonts:
                                                                          false,
                                                                      lineHeight:
                                                                          1.0,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(),
                                                    child: Builder(
                                                      builder: (context) {
                                                        final trendingProductsList =
                                                            (PlantShopGroup
                                                                        .trendingProductsCall
                                                                        .trendingProductsList(
                                                                          trendingProductsTrendingProductsResponse
                                                                              .jsonBody,
                                                                        )
                                                                        ?.toList() ??
                                                                    [])
                                                                .take(6)
                                                                .toList();
                                                        _model.debugGeneratorVariables[
                                                                'trendingProductsList${trendingProductsList.length > 100 ? ' (first 100)' : ''}'] =
                                                            debugSerializeParam(
                                                          trendingProductsList
                                                              .take(100),
                                                          ParamType.JSON,
                                                          isList: true,
                                                          link:
                                                              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                          name: 'dynamic',
                                                          nullable: false,
                                                        );
                                                        debugLogWidgetClass(
                                                            _model);

                                                        return SingleChildScrollView(
                                                          scrollDirection:
                                                              Axis.horizontal,
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            children: List.generate(
                                                                    trendingProductsList
                                                                        .length,
                                                                    (trendingProductsListIndex) {
                                                              final trendingProductsListItem =
                                                                  trendingProductsList[
                                                                      trendingProductsListIndex];
                                                              return wrapWithModel(
                                                                model: _model
                                                                    .mainComponentModels1
                                                                    .getModel(
                                                                  getJsonField(
                                                                    trendingProductsListItem,
                                                                    r'''$.id''',
                                                                  ).toString(),
                                                                  trendingProductsListIndex,
                                                                ),
                                                                updateCallback: () =>
                                                                    safeSetState(
                                                                        () {}),
                                                                child: Builder(
                                                                    builder:
                                                                        (_) {
                                                                  return DebugFlutterFlowModelContext(
                                                                    rootModel:
                                                                        _model
                                                                            .rootModel,
                                                                    child:
                                                                        MainComponentWidget(
                                                                      key: Key(
                                                                        'Keyipb_${getJsonField(
                                                                          trendingProductsListItem,
                                                                          r'''$.id''',
                                                                        ).toString()}',
                                                                      ),
                                                                      image:
                                                                          getJsonField(
                                                                        trendingProductsListItem,
                                                                        r'''$.images[0].src''',
                                                                      ).toString(),
                                                                      name:
                                                                          getJsonField(
                                                                        trendingProductsListItem,
                                                                        r'''$.name''',
                                                                      ).toString(),
                                                                      isLike: FFAppState()
                                                                          .wishList
                                                                          .contains(
                                                                              getJsonField(
                                                                            trendingProductsListItem,
                                                                            r'''$.id''',
                                                                          ).toString()),
                                                                      regularPrice:
                                                                          getJsonField(
                                                                        trendingProductsListItem,
                                                                        r'''$.regular_price''',
                                                                      ).toString(),
                                                                      price:
                                                                          getJsonField(
                                                                        trendingProductsListItem,
                                                                        r'''$.price''',
                                                                      ).toString(),
                                                                      review:
                                                                          getJsonField(
                                                                        trendingProductsListItem,
                                                                        r'''$.rating_count''',
                                                                      ).toString(),
                                                                      isBigContainer:
                                                                          true,
                                                                      height: ('' !=
                                                                                  getJsonField(
                                                                                    trendingProductsListItem,
                                                                                    r'''$.images[0].src''',
                                                                                  ).toString()) &&
                                                                              (getJsonField(
                                                                                    trendingProductsListItem,
                                                                                    r'''$.images[0].src''',
                                                                                  ) !=
                                                                                  null) &&
                                                                              (getJsonField(
                                                                                    trendingProductsListItem,
                                                                                    r'''$.images''',
                                                                                  ) !=
                                                                                  null)
                                                                          ? 298.0
                                                                          : 180.0,
                                                                      width:
                                                                          189.0,
                                                                      onSale:
                                                                          getJsonField(
                                                                        trendingProductsListItem,
                                                                        r'''$.on_sale''',
                                                                      ),
                                                                      showImage: ('' !=
                                                                              getJsonField(
                                                                                trendingProductsListItem,
                                                                                r'''$.images[0].src''',
                                                                              ).toString()) &&
                                                                          (getJsonField(
                                                                                trendingProductsListItem,
                                                                                r'''$.images[0].src''',
                                                                              ) !=
                                                                              null) &&
                                                                          (getJsonField(
                                                                                trendingProductsListItem,
                                                                                r'''$.images''',
                                                                              ) !=
                                                                              null),
                                                                      isLikeTap:
                                                                          () async {
                                                                        if (FFAppState()
                                                                            .isLogin) {
                                                                          await action_blocks
                                                                              .addorRemoveFavourite(
                                                                            context,
                                                                            id: getJsonField(
                                                                              trendingProductsListItem,
                                                                              r'''$.id''',
                                                                            ).toString(),
                                                                          );
                                                                          safeSetState(
                                                                              () {});
                                                                        } else {
                                                                          ScaffoldMessenger.of(context)
                                                                              .hideCurrentSnackBar();
                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(
                                                                            SnackBar(
                                                                              content: Text(
                                                                                FFLocalizations.of(context).getVariableText(
                                                                                  enText: 'Please log in first',
                                                                                  arText: 'الرجاء تسجيل الدخول أولاً',
                                                                                ),
                                                                                style: TextStyle(
                                                                                  fontFamily: 'SF Pro Display',
                                                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                                                ),
                                                                              ),
                                                                              duration: Duration(milliseconds: 2000),
                                                                              backgroundColor: FlutterFlowTheme.of(context).secondary,
                                                                              action: SnackBarAction(
                                                                                label: FFLocalizations.of(context).getVariableText(
                                                                                  enText: 'Login',
                                                                                  arText: 'تسجيل الدخول',
                                                                                ),
                                                                                textColor: FlutterFlowTheme.of(context).primary,
                                                                                onPressed: () async {
                                                                                  context.pushNamed(SignInPageWidget.routeName);
                                                                                },
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }
                                                                      },
                                                                      isMainTap:
                                                                          () async {
                                                                        context
                                                                            .pushNamed(
                                                                          ProductDetailPageWidget
                                                                              .routeName,
                                                                          queryParameters:
                                                                              {
                                                                            'productDetail':
                                                                                serializeParam(
                                                                              trendingProductsListItem,
                                                                              ParamType.JSON,
                                                                            ),
                                                                            'upsellIdsList':
                                                                                serializeParam(
                                                                              (getJsonField(
                                                                                trendingProductsListItem,
                                                                                r'''$.upsell_ids''',
                                                                                true,
                                                                              ) as List)
                                                                                  .map<String>((s) => s.toString())
                                                                                  .toList(),
                                                                              ParamType.String,
                                                                              isList: true,
                                                                            ),
                                                                            'relatedIdsList':
                                                                                serializeParam(
                                                                              (getJsonField(
                                                                                trendingProductsListItem,
                                                                                r'''$.related_ids''',
                                                                                true,
                                                                              ) as List)
                                                                                  .map<String>((s) => s.toString())
                                                                                  .toList(),
                                                                              ParamType.String,
                                                                              isList: true,
                                                                            ),
                                                                            'imagesList':
                                                                                serializeParam(
                                                                              getJsonField(
                                                                                trendingProductsListItem,
                                                                                r'''$.images''',
                                                                                true,
                                                                              ),
                                                                              ParamType.JSON,
                                                                              isList: true,
                                                                            ),
                                                                          }.withoutNulls,
                                                                        );
                                                                      },
                                                                    ),
                                                                  );
                                                                }),
                                                              );
                                                            })
                                                                .divide(SizedBox(
                                                                    width:
                                                                        12.0))
                                                                .addToStart(
                                                                    SizedBox(
                                                                        width:
                                                                            12.0))
                                                                .addToEnd(SizedBox(
                                                                    width:
                                                                        12.0)),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                FutureBuilder<ApiCallResponse>(
                                  future: FFAppState()
                                      .sellProducts(
                                    requestFn: () =>
                                        PlantShopGroup.sellProductsCall.call(
                                      page: 1,
                                    ),
                                  )
                                      .then((result) {
                                    _model.apiRequestCompleted9 = true;
                                    return result;
                                  }),
                                  builder: (context, snapshot) {
                                    // Customize what your widget looks like when it's loading.
                                    if (!snapshot.hasData) {
                                      return SaleProductsShimmerWidget();
                                    }
                                    final sellProductsSellProductsResponse =
                                        snapshot.data!;
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.sellProductsCall_statusCode_Container_y0oun9yl'] =
                                        debugSerializeParam(
                                      sellProductsSellProductsResponse
                                          .statusCode,
                                      ParamType.int,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                      name: 'int',
                                      nullable: false,
                                    );
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.sellProductsCall_responseBody_Container_y0oun9yl'] =
                                        debugSerializeParam(
                                      sellProductsSellProductsResponse.bodyText,
                                      ParamType.String,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                      name: 'String',
                                      nullable: false,
                                    );
                                    debugLogWidgetClass(_model);

                                    return Container(
                                      decoration: BoxDecoration(),
                                      child: Visibility(
                                        visible: (PlantShopGroup
                                                        .sellProductsCall
                                                        .sellProductsList(
                                                      sellProductsSellProductsResponse
                                                          .jsonBody,
                                                    ) !=
                                                    null &&
                                                (PlantShopGroup.sellProductsCall
                                                        .sellProductsList(
                                                  sellProductsSellProductsResponse
                                                      .jsonBody,
                                                ))!
                                                    .isNotEmpty) &&
                                            (PlantShopGroup.sellProductsCall
                                                    .status(
                                                  sellProductsSellProductsResponse
                                                      .jsonBody,
                                                ) ==
                                                null),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 12.0, 0.0, 0.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondary,
                                            ),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 20.0, 0.0, 20.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(12.0, 0.0,
                                                                12.0, 16.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .getText(
                                                                'p4az8tcq' /* Sell products */,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                              maxLines: 1,
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText,
                                                                    fontSize:
                                                                        20.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    useGoogleFonts:
                                                                        false,
                                                                    lineHeight:
                                                                        1.5,
                                                                  ),
                                                            ),
                                                            Image.asset(
                                                              'assets/images/smile.png',
                                                              width: 27.0,
                                                              height: 27.0,
                                                              fit: BoxFit.cover,
                                                            ),
                                                          ].divide(SizedBox(
                                                              width: 6.0)),
                                                        ),
                                                        InkWell(
                                                          splashColor: Colors
                                                              .transparent,
                                                          focusColor: Colors
                                                              .transparent,
                                                          hoverColor: Colors
                                                              .transparent,
                                                          highlightColor: Colors
                                                              .transparent,
                                                          onTap: () async {
                                                            context.pushNamed(
                                                                SaleProductsPageWidget
                                                                    .routeName);
                                                          },
                                                          child: Container(
                                                            height: 29.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .secondary,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          30.0),
                                                            ),
                                                            alignment:
                                                                AlignmentDirectional(
                                                                    0.0, 0.0),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          10.0,
                                                                          0.0,
                                                                          10.0,
                                                                          0.0),
                                                              child: Text(
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  '8rbkat8u' /* View all */,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      fontSize:
                                                                          14.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal,
                                                                      useGoogleFonts:
                                                                          false,
                                                                      lineHeight:
                                                                          1.0,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  12.0,
                                                                  0.0,
                                                                  12.0,
                                                                  0.0),
                                                      child: Builder(
                                                        builder: (context) {
                                                          final sellProductList =
                                                              (PlantShopGroup
                                                                          .sellProductsCall
                                                                          .sellProductsList(
                                                                            sellProductsSellProductsResponse.jsonBody,
                                                                          )
                                                                          ?.toList() ??
                                                                      [])
                                                                  .take(4)
                                                                  .toList();
                                                          _model.debugGeneratorVariables[
                                                                  'sellProductList${sellProductList.length > 100 ? ' (first 100)' : ''}'] =
                                                              debugSerializeParam(
                                                            sellProductList
                                                                .take(100),
                                                            ParamType.JSON,
                                                            isList: true,
                                                            link:
                                                                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                            name: 'dynamic',
                                                            nullable: false,
                                                          );
                                                          debugLogWidgetClass(
                                                              _model);

                                                          return Wrap(
                                                            spacing: 12.0,
                                                            runSpacing: 12.0,
                                                            alignment:
                                                                WrapAlignment
                                                                    .start,
                                                            crossAxisAlignment:
                                                                WrapCrossAlignment
                                                                    .start,
                                                            direction:
                                                                Axis.horizontal,
                                                            runAlignment:
                                                                WrapAlignment
                                                                    .start,
                                                            verticalDirection:
                                                                VerticalDirection
                                                                    .down,
                                                            clipBehavior:
                                                                Clip.none,
                                                            children: List.generate(
                                                                sellProductList
                                                                    .length,
                                                                (sellProductListIndex) {
                                                              final sellProductListItem =
                                                                  sellProductList[
                                                                      sellProductListIndex];
                                                              return wrapWithModel(
                                                                model: _model
                                                                    .mainComponentModels2
                                                                    .getModel(
                                                                  getJsonField(
                                                                    sellProductListItem,
                                                                    r'''$.id''',
                                                                  ).toString(),
                                                                  sellProductListIndex,
                                                                ),
                                                                updateCallback: () =>
                                                                    safeSetState(
                                                                        () {}),
                                                                child: Builder(
                                                                    builder:
                                                                        (_) {
                                                                  return DebugFlutterFlowModelContext(
                                                                    rootModel:
                                                                        _model
                                                                            .rootModel,
                                                                    child:
                                                                        MainComponentWidget(
                                                                      key: Key(
                                                                        'Keybxt_${getJsonField(
                                                                          sellProductListItem,
                                                                          r'''$.id''',
                                                                        ).toString()}',
                                                                      ),
                                                                      image:
                                                                          getJsonField(
                                                                        sellProductListItem,
                                                                        r'''$.images[0].src''',
                                                                      ).toString(),
                                                                      name:
                                                                          getJsonField(
                                                                        sellProductListItem,
                                                                        r'''$.name''',
                                                                      ).toString(),
                                                                      isLike: FFAppState()
                                                                          .wishList
                                                                          .contains(
                                                                              getJsonField(
                                                                            sellProductListItem,
                                                                            r'''$.id''',
                                                                          ).toString()),
                                                                      regularPrice:
                                                                          getJsonField(
                                                                        sellProductListItem,
                                                                        r'''$.regular_price''',
                                                                      ).toString(),
                                                                      price:
                                                                          getJsonField(
                                                                        sellProductListItem,
                                                                        r'''$.price''',
                                                                      ).toString(),
                                                                      review:
                                                                          getJsonField(
                                                                        sellProductListItem,
                                                                        r'''$.rating_count''',
                                                                      ).toString(),
                                                                      isBigContainer:
                                                                          true,
                                                                      height: ('' !=
                                                                                  getJsonField(
                                                                                    sellProductListItem,
                                                                                    r'''$.images[0].src''',
                                                                                  ).toString()) &&
                                                                              (getJsonField(
                                                                                    sellProductListItem,
                                                                                    r'''$.images[0].src''',
                                                                                  ) !=
                                                                                  null) &&
                                                                              (getJsonField(
                                                                                    sellProductListItem,
                                                                                    r'''$.images''',
                                                                                  ) !=
                                                                                  null)
                                                                          ? 298.0
                                                                          : 180.0,
                                                                      width:
                                                                          () {
                                                                        if (MediaQuery.sizeOf(context).width <
                                                                            810.0) {
                                                                          return ((MediaQuery.sizeOf(context).width - 36) *
                                                                              1 /
                                                                              2);
                                                                        } else if ((MediaQuery.sizeOf(context).width >=
                                                                                810.0) &&
                                                                            (MediaQuery.sizeOf(context).width <
                                                                                1280.0)) {
                                                                          return ((MediaQuery.sizeOf(context).width - 72) *
                                                                              1 /
                                                                              5);
                                                                        } else if (MediaQuery.sizeOf(context).width >=
                                                                            1280.0) {
                                                                          return ((MediaQuery.sizeOf(context).width - 96) *
                                                                              1 /
                                                                              7);
                                                                        } else {
                                                                          return ((MediaQuery.sizeOf(context).width - 120) *
                                                                              1 /
                                                                              9);
                                                                        }
                                                                      }(),
                                                                      onSale:
                                                                          getJsonField(
                                                                        sellProductListItem,
                                                                        r'''$.on_sale''',
                                                                      ),
                                                                      showImage: ('' !=
                                                                              getJsonField(
                                                                                sellProductListItem,
                                                                                r'''$.images[0].src''',
                                                                              ).toString()) &&
                                                                          (getJsonField(
                                                                                sellProductListItem,
                                                                                r'''$.images[0].src''',
                                                                              ) !=
                                                                              null) &&
                                                                          (getJsonField(
                                                                                sellProductListItem,
                                                                                r'''$.images''',
                                                                              ) !=
                                                                              null),
                                                                      isNotBorder:
                                                                          true,
                                                                      isLikeTap:
                                                                          () async {
                                                                        if (FFAppState()
                                                                            .isLogin) {
                                                                          await action_blocks
                                                                              .addorRemoveFavourite(
                                                                            context,
                                                                            id: getJsonField(
                                                                              sellProductListItem,
                                                                              r'''$.id''',
                                                                            ).toString(),
                                                                          );
                                                                          safeSetState(
                                                                              () {});
                                                                        } else {
                                                                          ScaffoldMessenger.of(context)
                                                                              .hideCurrentSnackBar();
                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(
                                                                            SnackBar(
                                                                              content: Text(
                                                                                FFLocalizations.of(context).getVariableText(
                                                                                  enText: 'Please log in first',
                                                                                  arText: 'الرجاء تسجيل الدخول أولاً',
                                                                                ),
                                                                                style: TextStyle(
                                                                                  fontFamily: 'SF Pro Display',
                                                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                                                ),
                                                                              ),
                                                                              duration: Duration(milliseconds: 2000),
                                                                              backgroundColor: FlutterFlowTheme.of(context).secondary,
                                                                              action: SnackBarAction(
                                                                                label: FFLocalizations.of(context).getVariableText(
                                                                                  enText: 'Login',
                                                                                  arText: 'تسجيل الدخول',
                                                                                ),
                                                                                textColor: FlutterFlowTheme.of(context).primary,
                                                                                onPressed: () async {
                                                                                  context.pushNamed(SignInPageWidget.routeName);
                                                                                },
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }
                                                                      },
                                                                      isMainTap:
                                                                          () async {
                                                                        context
                                                                            .pushNamed(
                                                                          ProductDetailPageWidget
                                                                              .routeName,
                                                                          queryParameters:
                                                                              {
                                                                            'productDetail':
                                                                                serializeParam(
                                                                              sellProductListItem,
                                                                              ParamType.JSON,
                                                                            ),
                                                                            'upsellIdsList':
                                                                                serializeParam(
                                                                              (getJsonField(
                                                                                sellProductListItem,
                                                                                r'''$.upsell_ids''',
                                                                                true,
                                                                              ) as List)
                                                                                  .map<String>((s) => s.toString())
                                                                                  .toList(),
                                                                              ParamType.String,
                                                                              isList: true,
                                                                            ),
                                                                            'relatedIdsList':
                                                                                serializeParam(
                                                                              (getJsonField(
                                                                                sellProductListItem,
                                                                                r'''$.related_ids''',
                                                                                true,
                                                                              ) as List)
                                                                                  .map<String>((s) => s.toString())
                                                                                  .toList(),
                                                                              ParamType.String,
                                                                              isList: true,
                                                                            ),
                                                                            'imagesList':
                                                                                serializeParam(
                                                                              getJsonField(
                                                                                sellProductListItem,
                                                                                r'''$.images''',
                                                                                true,
                                                                              ),
                                                                              ParamType.JSON,
                                                                              isList: true,
                                                                            ),
                                                                          }.withoutNulls,
                                                                        );
                                                                      },
                                                                    ),
                                                                  );
                                                                }),
                                                              ).animateOnPageLoad(
                                                                  animationsMap[
                                                                      'mainComponentOnPageLoadAnimation']!);
                                                            }),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                FutureBuilder<ApiCallResponse>(
                                  future: FFAppState().secondaryCategory(
                                    requestFn: () => PlantShopGroup
                                        .secondaryCategoryCall
                                        .call(),
                                  ),
                                  builder: (context, snapshot) {
                                    // Customize what your widget looks like when it's loading.
                                    if (!snapshot.hasData) {
                                      return BannerShimmerWidget(
                                        isBig: true,
                                        image: '',
                                      );
                                    }
                                    final secondaryCategorySecondaryCategoryResponse =
                                        snapshot.data!;
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.secondaryCategoryCall_statusCode_Container_aarw6z5k'] =
                                        debugSerializeParam(
                                      secondaryCategorySecondaryCategoryResponse
                                          .statusCode,
                                      ParamType.int,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                      name: 'int',
                                      nullable: false,
                                    );
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.secondaryCategoryCall_responseBody_Container_aarw6z5k'] =
                                        debugSerializeParam(
                                      secondaryCategorySecondaryCategoryResponse
                                          .bodyText,
                                      ParamType.String,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                      name: 'String',
                                      nullable: false,
                                    );
                                    debugLogWidgetClass(_model);

                                    return Container(
                                      decoration: BoxDecoration(),
                                      child: Visibility(
                                        visible: (PlantShopGroup
                                                    .secondaryCategoryCall
                                                    .status(
                                                  secondaryCategorySecondaryCategoryResponse
                                                      .jsonBody,
                                                ) ==
                                                'success') &&
                                            (PlantShopGroup
                                                        .secondaryCategoryCall
                                                        .dataList(
                                                      secondaryCategorySecondaryCategoryResponse
                                                          .jsonBody,
                                                    ) !=
                                                    null &&
                                                (PlantShopGroup
                                                        .secondaryCategoryCall
                                                        .dataList(
                                                  secondaryCategorySecondaryCategoryResponse
                                                      .jsonBody,
                                                ))!
                                                    .isNotEmpty),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 12.0, 0.0, 0.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryBackground,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Builder(
                                                  builder: (context) {
                                                    final secondaryCategoryList =
                                                        PlantShopGroup
                                                                .secondaryCategoryCall
                                                                .dataList(
                                                                  secondaryCategorySecondaryCategoryResponse
                                                                      .jsonBody,
                                                                )
                                                                ?.toList() ??
                                                            [];
                                                    _model.debugGeneratorVariables[
                                                            'secondaryCategoryList${secondaryCategoryList.length > 100 ? ' (first 100)' : ''}'] =
                                                        debugSerializeParam(
                                                      secondaryCategoryList
                                                          .take(100),
                                                      ParamType.JSON,
                                                      isList: true,
                                                      link:
                                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                      name: 'dynamic',
                                                      nullable: false,
                                                    );
                                                    debugLogWidgetClass(_model);

                                                    return Container(
                                                      width: double.infinity,
                                                      height: () {
                                                        if (MediaQuery.sizeOf(
                                                                    context)
                                                                .width <
                                                            kBreakpointSmall) {
                                                          return 154.0;
                                                        } else if (MediaQuery
                                                                    .sizeOf(
                                                                        context)
                                                                .width <
                                                            kBreakpointMedium) {
                                                          return 184.0;
                                                        } else if (MediaQuery
                                                                    .sizeOf(
                                                                        context)
                                                                .width <
                                                            kBreakpointLarge) {
                                                          return 204.0;
                                                        } else {
                                                          return 234.0;
                                                        }
                                                      }(),
                                                      child: CarouselSlider
                                                          .builder(
                                                        itemCount:
                                                            secondaryCategoryList
                                                                .length,
                                                        itemBuilder: (context,
                                                            secondaryCategoryListIndex,
                                                            _) {
                                                          final secondaryCategoryListItem =
                                                              secondaryCategoryList[
                                                                  secondaryCategoryListIndex];
                                                          return FutureBuilder<
                                                              ApiCallResponse>(
                                                            future: FFAppState()
                                                                .productDdetail(
                                                              uniqueQueryKey:
                                                                  getJsonField(
                                                                secondaryCategoryListItem,
                                                                r'''$.redirect_id''',
                                                              ).toString(),
                                                              requestFn: () =>
                                                                  PlantShopGroup
                                                                      .productDetailCall
                                                                      .call(
                                                                productId:
                                                                    getJsonField(
                                                                  secondaryCategoryListItem,
                                                                  r'''$.redirect_id''',
                                                                ).toString(),
                                                              ),
                                                            ),
                                                            builder: (context,
                                                                snapshot) {
                                                              // Customize what your widget looks like when it's loading.
                                                              if (!snapshot
                                                                  .hasData) {
                                                                return BannerShimmerWidget(
                                                                  isBig: false,
                                                                  image:
                                                                      getJsonField(
                                                                    secondaryCategoryListItem,
                                                                    r'''$.featured_image''',
                                                                  ).toString(),
                                                                );
                                                              }
                                                              final bannerProductDetailResponse =
                                                                  snapshot
                                                                      .data!;
                                                              _model.debugBackendQueries[
                                                                      'PlantShopGroup.productDetailCall_statusCode_Container_map05ry1'] =
                                                                  debugSerializeParam(
                                                                bannerProductDetailResponse
                                                                    .statusCode,
                                                                ParamType.int,
                                                                link:
                                                                    'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                                name: 'int',
                                                                nullable: false,
                                                              );
                                                              _model.debugBackendQueries[
                                                                      'PlantShopGroup.productDetailCall_responseBody_Container_map05ry1'] =
                                                                  debugSerializeParam(
                                                                bannerProductDetailResponse
                                                                    .bodyText,
                                                                ParamType
                                                                    .String,
                                                                link:
                                                                    'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                                name: 'String',
                                                                nullable: false,
                                                              );
                                                              debugLogWidgetClass(
                                                                  _model);

                                                              return Container(
                                                                decoration:
                                                                    BoxDecoration(),
                                                                child: InkWell(
                                                                  splashColor:
                                                                      Colors
                                                                          .transparent,
                                                                  focusColor: Colors
                                                                      .transparent,
                                                                  hoverColor: Colors
                                                                      .transparent,
                                                                  highlightColor:
                                                                      Colors
                                                                          .transparent,
                                                                  onTap:
                                                                      () async {
                                                                    if ('product' ==
                                                                        getJsonField(
                                                                          secondaryCategoryListItem,
                                                                          r'''$.redirect_type''',
                                                                        ).toString()) {
                                                                      context
                                                                          .pushNamed(
                                                                        ProductDetailPageWidget
                                                                            .routeName,
                                                                        queryParameters:
                                                                            {
                                                                          'productDetail':
                                                                              serializeParam(
                                                                            PlantShopGroup.productDetailCall.productDetail(
                                                                              bannerProductDetailResponse.jsonBody,
                                                                            ),
                                                                            ParamType.JSON,
                                                                          ),
                                                                          'upsellIdsList':
                                                                              serializeParam(
                                                                            (getJsonField(
                                                                              PlantShopGroup.productDetailCall.productDetail(
                                                                                bannerProductDetailResponse.jsonBody,
                                                                              ),
                                                                              r'''$.upsell_ids''',
                                                                              true,
                                                                            ) as List)
                                                                                .map<String>((s) => s.toString())
                                                                                .toList(),
                                                                            ParamType.String,
                                                                            isList:
                                                                                true,
                                                                          ),
                                                                          'relatedIdsList':
                                                                              serializeParam(
                                                                            (getJsonField(
                                                                              PlantShopGroup.productDetailCall.productDetail(
                                                                                bannerProductDetailResponse.jsonBody,
                                                                              ),
                                                                              r'''$.related_ids''',
                                                                              true,
                                                                            ) as List)
                                                                                .map<String>((s) => s.toString())
                                                                                .toList(),
                                                                            ParamType.String,
                                                                            isList:
                                                                                true,
                                                                          ),
                                                                          'imagesList':
                                                                              serializeParam(
                                                                            PlantShopGroup.productDetailCall.imagesList(
                                                                              bannerProductDetailResponse.jsonBody,
                                                                            ),
                                                                            ParamType.JSON,
                                                                            isList:
                                                                                true,
                                                                          ),
                                                                        }.withoutNulls,
                                                                      );
                                                                    } else {
                                                                      context
                                                                          .pushNamed(
                                                                        CategoryOpenPageWidget
                                                                            .routeName,
                                                                        queryParameters:
                                                                            {
                                                                          'title':
                                                                              serializeParam(
                                                                            getJsonField(
                                                                              secondaryCategoryListItem,
                                                                              r'''$.redirect_info''',
                                                                            ).toString(),
                                                                            ParamType.String,
                                                                          ),
                                                                          'catId':
                                                                              serializeParam(
                                                                            getJsonField(
                                                                              secondaryCategoryListItem,
                                                                              r'''$.redirect_id''',
                                                                            ).toString(),
                                                                            ParamType.String,
                                                                          ),
                                                                          'cateImage':
                                                                              serializeParam(
                                                                            '',
                                                                            ParamType.String,
                                                                          ),
                                                                        }.withoutNulls,
                                                                      );
                                                                    }
                                                                  },
                                                                  child:
                                                                      ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            16.0),
                                                                    child:
                                                                        CachedNetworkImage(
                                                                      fadeInDuration:
                                                                          Duration(
                                                                              milliseconds: 200),
                                                                      fadeOutDuration:
                                                                          Duration(
                                                                              milliseconds: 200),
                                                                      imageUrl:
                                                                          getJsonField(
                                                                        secondaryCategoryListItem,
                                                                        r'''$.featured_image''',
                                                                      ).toString(),
                                                                      width: double
                                                                          .infinity,
                                                                      height: double
                                                                          .infinity,
                                                                      fit: BoxFit
                                                                          .fill,
                                                                      errorWidget: (context,
                                                                              error,
                                                                              stackTrace) =>
                                                                          Image
                                                                              .asset(
                                                                        'assets/images/error_image.png',
                                                                        width: double
                                                                            .infinity,
                                                                        height:
                                                                            double.infinity,
                                                                        fit: BoxFit
                                                                            .fill,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          );
                                                        },
                                                        carouselController: _model
                                                                .carouselController2 ??=
                                                            CarouselSliderController(),
                                                        options:
                                                            CarouselOptions(
                                                          initialPage: max(
                                                              0,
                                                              min(
                                                                  1,
                                                                  secondaryCategoryList
                                                                          .length -
                                                                      1)),
                                                          viewportFraction: () {
                                                            if (MediaQuery.sizeOf(
                                                                        context)
                                                                    .width <
                                                                kBreakpointSmall) {
                                                              return 0.8;
                                                            } else if (MediaQuery
                                                                        .sizeOf(
                                                                            context)
                                                                    .width <
                                                                kBreakpointMedium) {
                                                              return 0.7;
                                                            } else if (MediaQuery
                                                                        .sizeOf(
                                                                            context)
                                                                    .width <
                                                                kBreakpointLarge) {
                                                              return 0.55;
                                                            } else {
                                                              return 0.45;
                                                            }
                                                          }(),
                                                          disableCenter: true,
                                                          enlargeCenterPage:
                                                              true,
                                                          enlargeFactor: 0.25,
                                                          enableInfiniteScroll:
                                                              true,
                                                          scrollDirection:
                                                              Axis.horizontal,
                                                          autoPlay: false,
                                                          onPageChanged:
                                                              (index, _) async {
                                                            _model.carouselCurrentIndex2 =
                                                                index;

                                                            safeSetState(() {});
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 16.0, 0.0, 16.0),
                                                  child: Builder(
                                                    builder: (context) {
                                                      final secondaryRowList =
                                                          PlantShopGroup
                                                                  .secondaryCategoryCall
                                                                  .dataList(
                                                                    secondaryCategorySecondaryCategoryResponse
                                                                        .jsonBody,
                                                                  )
                                                                  ?.toList() ??
                                                              [];
                                                      _model.debugGeneratorVariables[
                                                              'secondaryRowList${secondaryRowList.length > 100 ? ' (first 100)' : ''}'] =
                                                          debugSerializeParam(
                                                        secondaryRowList
                                                            .take(100),
                                                        ParamType.JSON,
                                                        isList: true,
                                                        link:
                                                            'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                        name: 'dynamic',
                                                        nullable: false,
                                                      );
                                                      debugLogWidgetClass(
                                                          _model);

                                                      return Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: List.generate(
                                                            secondaryRowList
                                                                .length,
                                                            (secondaryRowListIndex) {
                                                          final secondaryRowListItem =
                                                              secondaryRowList[
                                                                  secondaryRowListIndex];
                                                          return Container(
                                                            width: 10.0,
                                                            height: 10.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: secondaryRowListIndex ==
                                                                      _model
                                                                          .carouselCurrentIndex2
                                                                  ? FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary
                                                                  : FlutterFlowTheme.of(
                                                                          context)
                                                                      .black10,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                          );
                                                        }).divide(SizedBox(
                                                            width: 8.0)),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ].addToStart(
                                                  SizedBox(height: 16.0)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (FFAppState().showCategorySection)
                                  FutureBuilder<ApiCallResponse>(
                                    future: FFAppState()
                                        .categories(
                                      requestFn: () =>
                                          PlantShopGroup.categoriesCall.call(),
                                    )
                                        .then((result) {
                                      _model.apiRequestCompleted5 = true;
                                      return result;
                                    }),
                                    builder: (context, snapshot) {
                                      // Customize what your widget looks like when it's loading.
                                      if (!snapshot.hasData) {
                                        return ProductsHoreShimmerWidget(
                                          name: 'Categories',
                                        );
                                      }
                                      final categorySectionCategoriesResponse =
                                          snapshot.data!;
                                      _model.debugBackendQueries[
                                              'PlantShopGroup.categoriesCall_statusCode_Container_mhfkgd3l'] =
                                          debugSerializeParam(
                                        categorySectionCategoriesResponse
                                            .statusCode,
                                        ParamType.int,
                                        link:
                                            'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                        name: 'int',
                                        nullable: false,
                                      );
                                      _model.debugBackendQueries[
                                              'PlantShopGroup.categoriesCall_responseBody_Container_mhfkgd3l'] =
                                          debugSerializeParam(
                                        categorySectionCategoriesResponse
                                            .bodyText,
                                        ParamType.String,
                                        link:
                                            'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                        name: 'String',
                                        nullable: false,
                                      );
                                      debugLogWidgetClass(_model);

                                      return Container(
                                        decoration: BoxDecoration(),
                                        child: Builder(
                                          builder: (context) {
                                            final categorySectionIdsList =
                                                FFAppState()
                                                    .categorySectionIdsList
                                                    .toList();
                                            _model.debugGeneratorVariables[
                                                    'categorySectionIdsList${categorySectionIdsList.length > 100 ? ' (first 100)' : ''}'] =
                                                debugSerializeParam(
                                              categorySectionIdsList.take(100),
                                              ParamType.String,
                                              isList: true,
                                              link:
                                                  'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                              name: 'String',
                                              nullable: false,
                                            );
                                            debugLogWidgetClass(_model);

                                            return Column(
                                              mainAxisSize: MainAxisSize.max,
                                              children: List.generate(
                                                  categorySectionIdsList.length,
                                                  (categorySectionIdsListIndex) {
                                                final categorySectionIdsListItem =
                                                    categorySectionIdsList[
                                                        categorySectionIdsListIndex];
                                                return FutureBuilder<
                                                    ApiCallResponse>(
                                                  future: FFAppState()
                                                      .categoryOpen(
                                                    uniqueQueryKey:
                                                        categorySectionIdsListItem,
                                                    requestFn: () =>
                                                        PlantShopGroup
                                                            .categoryOpenCall
                                                            .call(
                                                      page: 1,
                                                      categoryId:
                                                          categorySectionIdsListItem,
                                                    ),
                                                  )
                                                      .then((result) {
                                                    try {
                                                      _model.apiRequestCompleted3 =
                                                          true;
                                                      _model.apiRequestLastUniqueKey3 =
                                                          categorySectionIdsListItem;
                                                    } finally {}
                                                    return result;
                                                  }),
                                                  builder: (context, snapshot) {
                                                    // Customize what your widget looks like when it's loading.
                                                    if (!snapshot.hasData) {
                                                      return ProductsHoreShimmerWidget(
                                                        name: getJsonField(
                                                          PlantShopGroup
                                                              .categoriesCall
                                                              .categoriesList(
                                                                categorySectionCategoriesResponse
                                                                    .jsonBody,
                                                              )!
                                                              .where((e) =>
                                                                  categorySectionIdsListItem ==
                                                                  getJsonField(
                                                                    e,
                                                                    r'''$.id''',
                                                                  ).toString())
                                                              .toList()
                                                              .firstOrNull,
                                                          r'''$.name''',
                                                        ).toString(),
                                                      );
                                                    }
                                                    final categorySectionCategoryOpenResponse =
                                                        snapshot.data!;
                                                    _model.debugBackendQueries[
                                                            'PlantShopGroup.categoryOpenCall_statusCode_Container_ac4w4jf4'] =
                                                        debugSerializeParam(
                                                      categorySectionCategoryOpenResponse
                                                          .statusCode,
                                                      ParamType.int,
                                                      link:
                                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                      name: 'int',
                                                      nullable: false,
                                                    );
                                                    _model.debugBackendQueries[
                                                            'PlantShopGroup.categoryOpenCall_responseBody_Container_ac4w4jf4'] =
                                                        debugSerializeParam(
                                                      categorySectionCategoryOpenResponse
                                                          .bodyText,
                                                      ParamType.String,
                                                      link:
                                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                      name: 'String',
                                                      nullable: false,
                                                    );
                                                    debugLogWidgetClass(_model);

                                                    return Container(
                                                      decoration:
                                                          BoxDecoration(),
                                                      child: Visibility(
                                                        visible: (PlantShopGroup
                                                                        .categoriesCall
                                                                        .categoriesList(
                                                                      categorySectionCategoriesResponse
                                                                          .jsonBody,
                                                                    ) !=
                                                                    null &&
                                                                (PlantShopGroup
                                                                        .categoriesCall
                                                                        .categoriesList(
                                                                  categorySectionCategoriesResponse
                                                                      .jsonBody,
                                                                ))!
                                                                    .isNotEmpty) &&
                                                            (PlantShopGroup
                                                                    .categoriesCall
                                                                    .status(
                                                                  categorySectionCategoriesResponse
                                                                      .jsonBody,
                                                                ) ==
                                                                null) &&
                                                            (PlantShopGroup
                                                                        .categoryOpenCall
                                                                        .categoryOpenList(
                                                                      categorySectionCategoryOpenResponse
                                                                          .jsonBody,
                                                                    ) !=
                                                                    null &&
                                                                (PlantShopGroup
                                                                        .categoryOpenCall
                                                                        .categoryOpenList(
                                                                  categorySectionCategoryOpenResponse
                                                                      .jsonBody,
                                                                ))!
                                                                    .isNotEmpty) &&
                                                            (PlantShopGroup
                                                                    .categoryOpenCall
                                                                    .status(
                                                                  categorySectionCategoryOpenResponse
                                                                      .jsonBody,
                                                                ) ==
                                                                null),
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      0.0,
                                                                      12.0,
                                                                      0.0,
                                                                      0.0),
                                                          child: Container(
                                                            width:
                                                                double.infinity,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primaryBackground,
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          20.0,
                                                                          0.0,
                                                                          20.0),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            12.0,
                                                                            0.0,
                                                                            12.0,
                                                                            16.0),
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        Text(
                                                                          functions
                                                                              .removeHtmlEntities(getJsonField(
                                                                            PlantShopGroup.categoriesCall
                                                                                .categoriesList(
                                                                                  categorySectionCategoriesResponse.jsonBody,
                                                                                )!
                                                                                .where((e) =>
                                                                                    categorySectionIdsListItem ==
                                                                                    getJsonField(
                                                                                      e,
                                                                                      r'''$.id''',
                                                                                    ).toString())
                                                                                .toList()
                                                                                .firstOrNull,
                                                                            r'''$.name''',
                                                                          ).toString()),
                                                                          textAlign:
                                                                              TextAlign.start,
                                                                          maxLines:
                                                                              1,
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .override(
                                                                                fontFamily: 'SF Pro Display',
                                                                                color: FlutterFlowTheme.of(context).primaryText,
                                                                                fontSize: 20.0,
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FontWeight.bold,
                                                                                useGoogleFonts: false,
                                                                                lineHeight: 1.5,
                                                                              ),
                                                                        ),
                                                                        InkWell(
                                                                          splashColor:
                                                                              Colors.transparent,
                                                                          focusColor:
                                                                              Colors.transparent,
                                                                          hoverColor:
                                                                              Colors.transparent,
                                                                          highlightColor:
                                                                              Colors.transparent,
                                                                          onTap:
                                                                              () async {
                                                                            context.pushNamed(
                                                                              CategoryOpenPageWidget.routeName,
                                                                              queryParameters: {
                                                                                'title': serializeParam(
                                                                                  getJsonField(
                                                                                    PlantShopGroup.categoriesCall
                                                                                        .categoriesList(
                                                                                          categorySectionCategoriesResponse.jsonBody,
                                                                                        )
                                                                                        ?.where((e) =>
                                                                                            categorySectionIdsListItem ==
                                                                                            getJsonField(
                                                                                              e,
                                                                                              r'''$.id''',
                                                                                            ).toString())
                                                                                        .toList()
                                                                                        ?.firstOrNull,
                                                                                    r'''$.name''',
                                                                                  ).toString(),
                                                                                  ParamType.String,
                                                                                ),
                                                                                'catId': serializeParam(
                                                                                  getJsonField(
                                                                                    PlantShopGroup.categoriesCall
                                                                                        .categoriesList(
                                                                                          categorySectionCategoriesResponse.jsonBody,
                                                                                        )
                                                                                        ?.where((e) =>
                                                                                            categorySectionIdsListItem ==
                                                                                            getJsonField(
                                                                                              e,
                                                                                              r'''$.id''',
                                                                                            ).toString())
                                                                                        .toList()
                                                                                        ?.firstOrNull,
                                                                                    r'''$.id''',
                                                                                  ).toString(),
                                                                                  ParamType.String,
                                                                                ),
                                                                                'cateImage': serializeParam(
                                                                                  getJsonField(
                                                                                    PlantShopGroup.categoriesCall
                                                                                        .categoriesList(
                                                                                          categorySectionCategoriesResponse.jsonBody,
                                                                                        )
                                                                                        ?.where((e) =>
                                                                                            categorySectionIdsListItem ==
                                                                                            getJsonField(
                                                                                              e,
                                                                                              r'''$.id''',
                                                                                            ).toString())
                                                                                        .toList()
                                                                                        ?.firstOrNull,
                                                                                    r'''$.image.src''',
                                                                                  ).toString(),
                                                                                  ParamType.String,
                                                                                ),
                                                                              }.withoutNulls,
                                                                            );
                                                                          },
                                                                          child:
                                                                              Container(
                                                                            height:
                                                                                29.0,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: FlutterFlowTheme.of(context).black10,
                                                                              borderRadius: BorderRadius.circular(30.0),
                                                                            ),
                                                                            alignment:
                                                                                AlignmentDirectional(0.0, 0.0),
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 10.0, 0.0),
                                                                              child: Text(
                                                                                FFLocalizations.of(context).getText(
                                                                                  'vlzt95wn' /* View all */,
                                                                                ),
                                                                                textAlign: TextAlign.center,
                                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                      fontFamily: 'SF Pro Display',
                                                                                      fontSize: 14.0,
                                                                                      letterSpacing: 0.0,
                                                                                      fontWeight: FontWeight.normal,
                                                                                      useGoogleFonts: false,
                                                                                      lineHeight: 1.0,
                                                                                    ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    width: double
                                                                        .infinity,
                                                                    decoration:
                                                                        BoxDecoration(),
                                                                    child:
                                                                        Builder(
                                                                      builder:
                                                                          (context) {
                                                                        final categoryOpenList = (PlantShopGroup.categoryOpenCall
                                                                                    .categoryOpenList(
                                                                                      categorySectionCategoryOpenResponse.jsonBody,
                                                                                    )
                                                                                    ?.toList() ??
                                                                                [])
                                                                            .take(6)
                                                                            .toList();
                                                                        _model.debugGeneratorVariables['categoryOpenList${categoryOpenList.length > 100 ? ' (first 100)' : ''}'] =
                                                                            debugSerializeParam(
                                                                          categoryOpenList
                                                                              .take(100),
                                                                          ParamType
                                                                              .JSON,
                                                                          isList:
                                                                              true,
                                                                          link:
                                                                              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                                          name:
                                                                              'dynamic',
                                                                          nullable:
                                                                              false,
                                                                        );
                                                                        debugLogWidgetClass(
                                                                            _model);

                                                                        return SingleChildScrollView(
                                                                          scrollDirection:
                                                                              Axis.horizontal,
                                                                          child:
                                                                              Row(
                                                                            mainAxisSize:
                                                                                MainAxisSize.max,
                                                                            children:
                                                                                List.generate(categoryOpenList.length, (categoryOpenListIndex) {
                                                                              final categoryOpenListItem = categoryOpenList[categoryOpenListIndex];
                                                                              return wrapWithModel(
                                                                                model: _model.mainComponentModels3.getModel(
                                                                                  getJsonField(
                                                                                    categoryOpenListItem,
                                                                                    r'''$.id''',
                                                                                  ).toString(),
                                                                                  categoryOpenListIndex,
                                                                                ),
                                                                                updateCallback: () => safeSetState(() {}),
                                                                                child: Builder(builder: (_) {
                                                                                  return DebugFlutterFlowModelContext(
                                                                                    rootModel: _model.rootModel,
                                                                                    child: MainComponentWidget(
                                                                                      key: Key(
                                                                                        'Keyzg4_${getJsonField(
                                                                                          categoryOpenListItem,
                                                                                          r'''$.id''',
                                                                                        ).toString()}',
                                                                                      ),
                                                                                      image: getJsonField(
                                                                                        categoryOpenListItem,
                                                                                        r'''$.images[0].src''',
                                                                                      ).toString(),
                                                                                      name: getJsonField(
                                                                                        categoryOpenListItem,
                                                                                        r'''$.name''',
                                                                                      ).toString(),
                                                                                      isLike: FFAppState().wishList.contains(getJsonField(
                                                                                            categoryOpenListItem,
                                                                                            r'''$.id''',
                                                                                          ).toString()),
                                                                                      regularPrice: getJsonField(
                                                                                        categoryOpenListItem,
                                                                                        r'''$.regular_price''',
                                                                                      ).toString(),
                                                                                      price: getJsonField(
                                                                                        categoryOpenListItem,
                                                                                        r'''$.price''',
                                                                                      ).toString(),
                                                                                      review: getJsonField(
                                                                                        categoryOpenListItem,
                                                                                        r'''$.rating_count''',
                                                                                      ).toString(),
                                                                                      isBigContainer: true,
                                                                                      height: ('' !=
                                                                                                  getJsonField(
                                                                                                    categoryOpenListItem,
                                                                                                    r'''$.images[0].src''',
                                                                                                  ).toString()) &&
                                                                                              (getJsonField(
                                                                                                    categoryOpenListItem,
                                                                                                    r'''$.images[0].src''',
                                                                                                  ) !=
                                                                                                  null) &&
                                                                                              (getJsonField(
                                                                                                    categoryOpenListItem,
                                                                                                    r'''$.images''',
                                                                                                  ) !=
                                                                                                  null)
                                                                                          ? 298.0
                                                                                          : 180.0,
                                                                                      width: 189.0,
                                                                                      onSale: getJsonField(
                                                                                        categoryOpenListItem,
                                                                                        r'''$.on_sale''',
                                                                                      ),
                                                                                      showImage: ('' !=
                                                                                              getJsonField(
                                                                                                categoryOpenListItem,
                                                                                                r'''$.images[0].src''',
                                                                                              ).toString()) &&
                                                                                          (getJsonField(
                                                                                                categoryOpenListItem,
                                                                                                r'''$.images[0].src''',
                                                                                              ) !=
                                                                                              null) &&
                                                                                          (getJsonField(
                                                                                                categoryOpenListItem,
                                                                                                r'''$.images''',
                                                                                              ) !=
                                                                                              null),
                                                                                      isLikeTap: () async {
                                                                                        if (FFAppState().isLogin) {
                                                                                          await action_blocks.addorRemoveFavourite(
                                                                                            context,
                                                                                            id: getJsonField(
                                                                                              categoryOpenListItem,
                                                                                              r'''$.id''',
                                                                                            ).toString(),
                                                                                          );
                                                                                          safeSetState(() {});
                                                                                        } else {
                                                                                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                                                            SnackBar(
                                                                                              content: Text(
                                                                                                FFLocalizations.of(context).getVariableText(
                                                                                                  enText: 'Please log in first',
                                                                                                  arText: 'الرجاء تسجيل الدخول أولاً',
                                                                                                ),
                                                                                                style: TextStyle(
                                                                                                  fontFamily: 'SF Pro Display',
                                                                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                                                                ),
                                                                                              ),
                                                                                              duration: Duration(milliseconds: 2000),
                                                                                              backgroundColor: FlutterFlowTheme.of(context).secondary,
                                                                                              action: SnackBarAction(
                                                                                                label: FFLocalizations.of(context).getVariableText(
                                                                                                  enText: 'Login',
                                                                                                  arText: 'تسجيل الدخول',
                                                                                                ),
                                                                                                textColor: FlutterFlowTheme.of(context).primary,
                                                                                                onPressed: () async {
                                                                                                  context.pushNamed(SignInPageWidget.routeName);
                                                                                                },
                                                                                              ),
                                                                                            ),
                                                                                          );
                                                                                        }
                                                                                      },
                                                                                      isMainTap: () async {
                                                                                        context.pushNamed(
                                                                                          ProductDetailPageWidget.routeName,
                                                                                          queryParameters: {
                                                                                            'productDetail': serializeParam(
                                                                                              categoryOpenListItem,
                                                                                              ParamType.JSON,
                                                                                            ),
                                                                                            'upsellIdsList': serializeParam(
                                                                                              (getJsonField(
                                                                                                categoryOpenListItem,
                                                                                                r'''$.upsell_ids''',
                                                                                                true,
                                                                                              ) as List)
                                                                                                  .map<String>((s) => s.toString())
                                                                                                  .toList(),
                                                                                              ParamType.String,
                                                                                              isList: true,
                                                                                            ),
                                                                                            'relatedIdsList': serializeParam(
                                                                                              (getJsonField(
                                                                                                categoryOpenListItem,
                                                                                                r'''$.related_ids''',
                                                                                                true,
                                                                                              ) as List)
                                                                                                  .map<String>((s) => s.toString())
                                                                                                  .toList(),
                                                                                              ParamType.String,
                                                                                              isList: true,
                                                                                            ),
                                                                                            'imagesList': serializeParam(
                                                                                              getJsonField(
                                                                                                categoryOpenListItem,
                                                                                                r'''$.images''',
                                                                                                true,
                                                                                              ),
                                                                                              ParamType.JSON,
                                                                                              isList: true,
                                                                                            ),
                                                                                          }.withoutNulls,
                                                                                        );
                                                                                      },
                                                                                    ),
                                                                                  );
                                                                                }),
                                                                              );
                                                                            }).divide(SizedBox(width: 12.0)).addToStart(SizedBox(width: 12.0)).addToEnd(SizedBox(width: 12.0)),
                                                                          ),
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              }),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                FutureBuilder<ApiCallResponse>(
                                  future: FFAppState()
                                      .popularProducts(
                                    requestFn: () =>
                                        PlantShopGroup.popularProductsCall.call(
                                      page: 1,
                                    ),
                                  )
                                      .then((result) {
                                    _model.apiRequestCompleted6 = true;
                                    return result;
                                  }),
                                  builder: (context, snapshot) {
                                    // Customize what your widget looks like when it's loading.
                                    if (!snapshot.hasData) {
                                      return BigSavingShimmerWidget();
                                    }
                                    final popularProductsPopularProductsResponse =
                                        snapshot.data!;
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.popularProductsCall_statusCode_Container_oz6h6h62'] =
                                        debugSerializeParam(
                                      popularProductsPopularProductsResponse
                                          .statusCode,
                                      ParamType.int,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                      name: 'int',
                                      nullable: false,
                                    );
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.popularProductsCall_responseBody_Container_oz6h6h62'] =
                                        debugSerializeParam(
                                      popularProductsPopularProductsResponse
                                          .bodyText,
                                      ParamType.String,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                      name: 'String',
                                      nullable: false,
                                    );
                                    debugLogWidgetClass(_model);

                                    return Container(
                                      decoration: BoxDecoration(),
                                      child: Visibility(
                                        visible: (PlantShopGroup
                                                    .popularProductsCall
                                                    .status(
                                                  popularProductsPopularProductsResponse
                                                      .jsonBody,
                                                ) ==
                                                null) &&
                                            (PlantShopGroup.popularProductsCall
                                                        .popularProductsList(
                                                      popularProductsPopularProductsResponse
                                                          .jsonBody,
                                                    ) !=
                                                    null &&
                                                (PlantShopGroup
                                                        .popularProductsCall
                                                        .popularProductsList(
                                                  popularProductsPopularProductsResponse
                                                      .jsonBody,
                                                ))!
                                                    .isNotEmpty),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 12.0, 0.0, 0.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondary,
                                              borderRadius:
                                                  BorderRadius.circular(0.0),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 16.0, 0.0, 14.0),
                                              child: Container(
                                                width: double.infinity,
                                                height: 298.0,
                                                decoration: BoxDecoration(),
                                                child: SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    0.0,
                                                                    0.0,
                                                                    12.0,
                                                                    0.0),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .getText(
                                                                'x3jbgg32' /* Popular 
products 🔥 */
                                                                ,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText,
                                                                    fontSize:
                                                                        20.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    useGoogleFonts:
                                                                        false,
                                                                    lineHeight:
                                                                        1.5,
                                                                  ),
                                                            ),
                                                            InkWell(
                                                              splashColor: Colors
                                                                  .transparent,
                                                              focusColor: Colors
                                                                  .transparent,
                                                              hoverColor: Colors
                                                                  .transparent,
                                                              highlightColor:
                                                                  Colors
                                                                      .transparent,
                                                              onTap: () async {
                                                                context.pushNamed(
                                                                    PopularProductsPageWidget
                                                                        .routeName);
                                                              },
                                                              child: Container(
                                                                width: 100.0,
                                                                height: 36.0,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              4.0),
                                                                ),
                                                                alignment:
                                                                    AlignmentDirectional(
                                                                        0.0,
                                                                        0.0),
                                                                child: Text(
                                                                  FFLocalizations.of(
                                                                          context)
                                                                      .getText(
                                                                    '80202dlg' /* View all */,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  maxLines: 1,
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        fontFamily:
                                                                            'SF Pro Display',
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            17.0,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        useGoogleFonts:
                                                                            false,
                                                                      ),
                                                                ),
                                                              ),
                                                            ),
                                                          ].divide(SizedBox(
                                                              height: 16.0)),
                                                        ),
                                                      ),
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(),
                                                        child: Builder(
                                                          builder: (context) {
                                                            final bigSavingsList =
                                                                (PlantShopGroup
                                                                            .popularProductsCall
                                                                            .popularProductsList(
                                                                              popularProductsPopularProductsResponse.jsonBody,
                                                                            )
                                                                            ?.toList() ??
                                                                        [])
                                                                    .take(6)
                                                                    .toList();
                                                            _model.debugGeneratorVariables[
                                                                    'bigSavingsList${bigSavingsList.length > 100 ? ' (first 100)' : ''}'] =
                                                                debugSerializeParam(
                                                              bigSavingsList
                                                                  .take(100),
                                                              ParamType.JSON,
                                                              isList: true,
                                                              link:
                                                                  'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                              name: 'dynamic',
                                                              nullable: false,
                                                            );
                                                            debugLogWidgetClass(
                                                                _model);

                                                            return Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              children: List.generate(
                                                                  bigSavingsList
                                                                      .length,
                                                                  (bigSavingsListIndex) {
                                                                final bigSavingsListItem =
                                                                    bigSavingsList[
                                                                        bigSavingsListIndex];
                                                                return wrapWithModel(
                                                                  model: _model
                                                                      .mainComponentModels4
                                                                      .getModel(
                                                                    getJsonField(
                                                                      bigSavingsListItem,
                                                                      r'''$.id''',
                                                                    ).toString(),
                                                                    bigSavingsListIndex,
                                                                  ),
                                                                  updateCallback: () =>
                                                                      safeSetState(
                                                                          () {}),
                                                                  child: Builder(
                                                                      builder:
                                                                          (_) {
                                                                    return DebugFlutterFlowModelContext(
                                                                      rootModel:
                                                                          _model
                                                                              .rootModel,
                                                                      child:
                                                                          MainComponentWidget(
                                                                        key:
                                                                            Key(
                                                                          'Key6ug_${getJsonField(
                                                                            bigSavingsListItem,
                                                                            r'''$.id''',
                                                                          ).toString()}',
                                                                        ),
                                                                        image:
                                                                            getJsonField(
                                                                          bigSavingsListItem,
                                                                          r'''$.images[0].src''',
                                                                        ).toString(),
                                                                        name:
                                                                            getJsonField(
                                                                          bigSavingsListItem,
                                                                          r'''$.name''',
                                                                        ).toString(),
                                                                        isLike: FFAppState()
                                                                            .wishList
                                                                            .contains(getJsonField(
                                                                              bigSavingsListItem,
                                                                              r'''$.id''',
                                                                            ).toString()),
                                                                        regularPrice:
                                                                            getJsonField(
                                                                          bigSavingsListItem,
                                                                          r'''$.regular_price''',
                                                                        ).toString(),
                                                                        price:
                                                                            getJsonField(
                                                                          bigSavingsListItem,
                                                                          r'''$.price''',
                                                                        ).toString(),
                                                                        review:
                                                                            getJsonField(
                                                                          bigSavingsListItem,
                                                                          r'''$.rating_count''',
                                                                        ).toString(),
                                                                        isBigContainer:
                                                                            true,
                                                                        height: ('' !=
                                                                                    getJsonField(
                                                                                      bigSavingsListItem,
                                                                                      r'''$.images[0].src''',
                                                                                    ).toString()) &&
                                                                                (getJsonField(
                                                                                      bigSavingsListItem,
                                                                                      r'''$.images[0].src''',
                                                                                    ) !=
                                                                                    null) &&
                                                                                (getJsonField(
                                                                                      bigSavingsListItem,
                                                                                      r'''$.images''',
                                                                                    ) !=
                                                                                    null)
                                                                            ? 298.0
                                                                            : 180.0,
                                                                        width:
                                                                            189.0,
                                                                        onSale:
                                                                            getJsonField(
                                                                          bigSavingsListItem,
                                                                          r'''$.on_sale''',
                                                                        ),
                                                                        showImage: ('' !=
                                                                                getJsonField(
                                                                                  bigSavingsListItem,
                                                                                  r'''$.images[0].src''',
                                                                                ).toString()) &&
                                                                            (getJsonField(
                                                                                  bigSavingsListItem,
                                                                                  r'''$.images[0].src''',
                                                                                ) !=
                                                                                null) &&
                                                                            (getJsonField(
                                                                                  bigSavingsListItem,
                                                                                  r'''$.images''',
                                                                                ) !=
                                                                                null),
                                                                        isNotBorder:
                                                                            true,
                                                                        isLikeTap:
                                                                            () async {
                                                                          if (FFAppState()
                                                                              .isLogin) {
                                                                            await action_blocks.addorRemoveFavourite(
                                                                              context,
                                                                              id: getJsonField(
                                                                                bigSavingsListItem,
                                                                                r'''$.id''',
                                                                              ).toString(),
                                                                            );
                                                                            safeSetState(() {});
                                                                          } else {
                                                                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                                              SnackBar(
                                                                                content: Text(
                                                                                  FFLocalizations.of(context).getVariableText(
                                                                                    enText: 'Please log in first',
                                                                                    arText: 'الرجاء تسجيل الدخول أولاً',
                                                                                  ),
                                                                                  style: TextStyle(
                                                                                    fontFamily: 'SF Pro Display',
                                                                                    color: FlutterFlowTheme.of(context).primaryText,
                                                                                  ),
                                                                                ),
                                                                                duration: Duration(milliseconds: 2000),
                                                                                backgroundColor: FlutterFlowTheme.of(context).secondary,
                                                                                action: SnackBarAction(
                                                                                  label: FFLocalizations.of(context).getVariableText(
                                                                                    enText: 'Login',
                                                                                    arText: 'تسجيل الدخول',
                                                                                  ),
                                                                                  textColor: FlutterFlowTheme.of(context).primary,
                                                                                  onPressed: () async {
                                                                                    context.pushNamed(SignInPageWidget.routeName);
                                                                                  },
                                                                                ),
                                                                              ),
                                                                            );
                                                                          }
                                                                        },
                                                                        isMainTap:
                                                                            () async {
                                                                          context
                                                                              .pushNamed(
                                                                            ProductDetailPageWidget.routeName,
                                                                            queryParameters:
                                                                                {
                                                                              'productDetail': serializeParam(
                                                                                bigSavingsListItem,
                                                                                ParamType.JSON,
                                                                              ),
                                                                              'upsellIdsList': serializeParam(
                                                                                (getJsonField(
                                                                                  bigSavingsListItem,
                                                                                  r'''$.upsell_ids''',
                                                                                  true,
                                                                                ) as List)
                                                                                    .map<String>((s) => s.toString())
                                                                                    .toList(),
                                                                                ParamType.String,
                                                                                isList: true,
                                                                              ),
                                                                              'relatedIdsList': serializeParam(
                                                                                (getJsonField(
                                                                                  bigSavingsListItem,
                                                                                  r'''$.related_ids''',
                                                                                  true,
                                                                                ) as List)
                                                                                    .map<String>((s) => s.toString())
                                                                                    .toList(),
                                                                                ParamType.String,
                                                                                isList: true,
                                                                              ),
                                                                              'imagesList': serializeParam(
                                                                                getJsonField(
                                                                                  bigSavingsListItem,
                                                                                  r'''$.images''',
                                                                                  true,
                                                                                ),
                                                                                ParamType.JSON,
                                                                                isList: true,
                                                                              ),
                                                                            }.withoutNulls,
                                                                          );
                                                                        },
                                                                      ),
                                                                    );
                                                                  }),
                                                                );
                                                              }).divide(SizedBox(
                                                                  width: 12.0)),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ]
                                                        .addToStart(SizedBox(
                                                            width: 12.0))
                                                        .addToEnd(SizedBox(
                                                            width: 12.0)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                FutureBuilder<ApiCallResponse>(
                                  future: FFAppState().otherCategory(
                                    requestFn: () =>
                                        PlantShopGroup.otherCategoryCall.call(),
                                  ),
                                  builder: (context, snapshot) {
                                    // Customize what your widget looks like when it's loading.
                                    if (!snapshot.hasData) {
                                      return BannerShimmerWidget(
                                        isBig: true,
                                        image: '',
                                      );
                                    }
                                    final otherCategoryOtherCategoryResponse =
                                        snapshot.data!;
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.otherCategoryCall_statusCode_Container_if2oufee'] =
                                        debugSerializeParam(
                                      otherCategoryOtherCategoryResponse
                                          .statusCode,
                                      ParamType.int,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                      name: 'int',
                                      nullable: false,
                                    );
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.otherCategoryCall_responseBody_Container_if2oufee'] =
                                        debugSerializeParam(
                                      otherCategoryOtherCategoryResponse
                                          .bodyText,
                                      ParamType.String,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                      name: 'String',
                                      nullable: false,
                                    );
                                    debugLogWidgetClass(_model);

                                    return Container(
                                      decoration: BoxDecoration(),
                                      child: Visibility(
                                        visible: (PlantShopGroup
                                                    .otherCategoryCall
                                                    .status(
                                                  otherCategoryOtherCategoryResponse
                                                      .jsonBody,
                                                ) ==
                                                'success') &&
                                            (PlantShopGroup.otherCategoryCall
                                                        .dataList(
                                                      otherCategoryOtherCategoryResponse
                                                          .jsonBody,
                                                    ) !=
                                                    null &&
                                                (PlantShopGroup
                                                        .otherCategoryCall
                                                        .dataList(
                                                  otherCategoryOtherCategoryResponse
                                                      .jsonBody,
                                                ))!
                                                    .isNotEmpty),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 12.0, 0.0, 0.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryBackground,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Builder(
                                                  builder: (context) {
                                                    final otherCategoryList =
                                                        PlantShopGroup
                                                                .otherCategoryCall
                                                                .dataList(
                                                                  otherCategoryOtherCategoryResponse
                                                                      .jsonBody,
                                                                )
                                                                ?.toList() ??
                                                            [];
                                                    _model.debugGeneratorVariables[
                                                            'otherCategoryList${otherCategoryList.length > 100 ? ' (first 100)' : ''}'] =
                                                        debugSerializeParam(
                                                      otherCategoryList
                                                          .take(100),
                                                      ParamType.JSON,
                                                      isList: true,
                                                      link:
                                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                      name: 'dynamic',
                                                      nullable: false,
                                                    );
                                                    debugLogWidgetClass(_model);

                                                    return Container(
                                                      width: double.infinity,
                                                      height: () {
                                                        if (MediaQuery.sizeOf(
                                                                    context)
                                                                .width <
                                                            kBreakpointSmall) {
                                                          return 154.0;
                                                        } else if (MediaQuery
                                                                    .sizeOf(
                                                                        context)
                                                                .width <
                                                            kBreakpointMedium) {
                                                          return 184.0;
                                                        } else if (MediaQuery
                                                                    .sizeOf(
                                                                        context)
                                                                .width <
                                                            kBreakpointLarge) {
                                                          return 204.0;
                                                        } else {
                                                          return 234.0;
                                                        }
                                                      }(),
                                                      child: CarouselSlider
                                                          .builder(
                                                        itemCount:
                                                            otherCategoryList
                                                                .length,
                                                        itemBuilder: (context,
                                                            otherCategoryListIndex,
                                                            _) {
                                                          final otherCategoryListItem =
                                                              otherCategoryList[
                                                                  otherCategoryListIndex];
                                                          return FutureBuilder<
                                                              ApiCallResponse>(
                                                            future: FFAppState()
                                                                .productDdetail(
                                                              uniqueQueryKey:
                                                                  getJsonField(
                                                                otherCategoryListItem,
                                                                r'''$.redirect_id''',
                                                              ).toString(),
                                                              requestFn: () =>
                                                                  PlantShopGroup
                                                                      .productDetailCall
                                                                      .call(
                                                                productId:
                                                                    getJsonField(
                                                                  otherCategoryListItem,
                                                                  r'''$.redirect_id''',
                                                                ).toString(),
                                                              ),
                                                            ),
                                                            builder: (context,
                                                                snapshot) {
                                                              // Customize what your widget looks like when it's loading.
                                                              if (!snapshot
                                                                  .hasData) {
                                                                return BannerShimmerWidget(
                                                                  isBig: false,
                                                                  image:
                                                                      getJsonField(
                                                                    otherCategoryListItem,
                                                                    r'''$.featured_image''',
                                                                  ).toString(),
                                                                );
                                                              }
                                                              final bannerProductDetailResponse =
                                                                  snapshot
                                                                      .data!;
                                                              _model.debugBackendQueries[
                                                                      'PlantShopGroup.productDetailCall_statusCode_Container_12jd9l9z'] =
                                                                  debugSerializeParam(
                                                                bannerProductDetailResponse
                                                                    .statusCode,
                                                                ParamType.int,
                                                                link:
                                                                    'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                                name: 'int',
                                                                nullable: false,
                                                              );
                                                              _model.debugBackendQueries[
                                                                      'PlantShopGroup.productDetailCall_responseBody_Container_12jd9l9z'] =
                                                                  debugSerializeParam(
                                                                bannerProductDetailResponse
                                                                    .bodyText,
                                                                ParamType
                                                                    .String,
                                                                link:
                                                                    'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                                name: 'String',
                                                                nullable: false,
                                                              );
                                                              debugLogWidgetClass(
                                                                  _model);

                                                              return Container(
                                                                decoration:
                                                                    BoxDecoration(),
                                                                child: InkWell(
                                                                  splashColor:
                                                                      Colors
                                                                          .transparent,
                                                                  focusColor: Colors
                                                                      .transparent,
                                                                  hoverColor: Colors
                                                                      .transparent,
                                                                  highlightColor:
                                                                      Colors
                                                                          .transparent,
                                                                  onTap:
                                                                      () async {
                                                                    if ('product' ==
                                                                        getJsonField(
                                                                          otherCategoryListItem,
                                                                          r'''$.redirect_type''',
                                                                        ).toString()) {
                                                                      context
                                                                          .pushNamed(
                                                                        ProductDetailPageWidget
                                                                            .routeName,
                                                                        queryParameters:
                                                                            {
                                                                          'productDetail':
                                                                              serializeParam(
                                                                            PlantShopGroup.productDetailCall.productDetail(
                                                                              bannerProductDetailResponse.jsonBody,
                                                                            ),
                                                                            ParamType.JSON,
                                                                          ),
                                                                          'upsellIdsList':
                                                                              serializeParam(
                                                                            (getJsonField(
                                                                              PlantShopGroup.productDetailCall.productDetail(
                                                                                bannerProductDetailResponse.jsonBody,
                                                                              ),
                                                                              r'''$.upsell_ids''',
                                                                              true,
                                                                            ) as List)
                                                                                .map<String>((s) => s.toString())
                                                                                .toList(),
                                                                            ParamType.String,
                                                                            isList:
                                                                                true,
                                                                          ),
                                                                          'relatedIdsList':
                                                                              serializeParam(
                                                                            (getJsonField(
                                                                              PlantShopGroup.productDetailCall.productDetail(
                                                                                bannerProductDetailResponse.jsonBody,
                                                                              ),
                                                                              r'''$.related_ids''',
                                                                              true,
                                                                            ) as List)
                                                                                .map<String>((s) => s.toString())
                                                                                .toList(),
                                                                            ParamType.String,
                                                                            isList:
                                                                                true,
                                                                          ),
                                                                          'imagesList':
                                                                              serializeParam(
                                                                            PlantShopGroup.productDetailCall.imagesList(
                                                                              bannerProductDetailResponse.jsonBody,
                                                                            ),
                                                                            ParamType.JSON,
                                                                            isList:
                                                                                true,
                                                                          ),
                                                                        }.withoutNulls,
                                                                      );
                                                                    } else {
                                                                      context
                                                                          .pushNamed(
                                                                        CategoryOpenPageWidget
                                                                            .routeName,
                                                                        queryParameters:
                                                                            {
                                                                          'title':
                                                                              serializeParam(
                                                                            getJsonField(
                                                                              otherCategoryListItem,
                                                                              r'''$.redirect_info''',
                                                                            ).toString(),
                                                                            ParamType.String,
                                                                          ),
                                                                          'catId':
                                                                              serializeParam(
                                                                            getJsonField(
                                                                              otherCategoryListItem,
                                                                              r'''$.redirect_id''',
                                                                            ).toString(),
                                                                            ParamType.String,
                                                                          ),
                                                                          'cateImage':
                                                                              serializeParam(
                                                                            '',
                                                                            ParamType.String,
                                                                          ),
                                                                        }.withoutNulls,
                                                                      );
                                                                    }
                                                                  },
                                                                  child:
                                                                      ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            16.0),
                                                                    child:
                                                                        CachedNetworkImage(
                                                                      fadeInDuration:
                                                                          Duration(
                                                                              milliseconds: 200),
                                                                      fadeOutDuration:
                                                                          Duration(
                                                                              milliseconds: 200),
                                                                      imageUrl:
                                                                          getJsonField(
                                                                        otherCategoryListItem,
                                                                        r'''$.featured_image''',
                                                                      ).toString(),
                                                                      width: double
                                                                          .infinity,
                                                                      height: double
                                                                          .infinity,
                                                                      fit: BoxFit
                                                                          .fill,
                                                                      errorWidget: (context,
                                                                              error,
                                                                              stackTrace) =>
                                                                          Image
                                                                              .asset(
                                                                        'assets/images/error_image.png',
                                                                        width: double
                                                                            .infinity,
                                                                        height:
                                                                            double.infinity,
                                                                        fit: BoxFit
                                                                            .fill,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          );
                                                        },
                                                        carouselController: _model
                                                                .carouselController3 ??=
                                                            CarouselSliderController(),
                                                        options:
                                                            CarouselOptions(
                                                          initialPage: max(
                                                              0,
                                                              min(
                                                                  1,
                                                                  otherCategoryList
                                                                          .length -
                                                                      1)),
                                                          viewportFraction: () {
                                                            if (MediaQuery.sizeOf(
                                                                        context)
                                                                    .width <
                                                                kBreakpointSmall) {
                                                              return 0.8;
                                                            } else if (MediaQuery
                                                                        .sizeOf(
                                                                            context)
                                                                    .width <
                                                                kBreakpointMedium) {
                                                              return 0.7;
                                                            } else if (MediaQuery
                                                                        .sizeOf(
                                                                            context)
                                                                    .width <
                                                                kBreakpointLarge) {
                                                              return 0.55;
                                                            } else {
                                                              return 0.45;
                                                            }
                                                          }(),
                                                          disableCenter: true,
                                                          enlargeCenterPage:
                                                              true,
                                                          enlargeFactor: 0.25,
                                                          enableInfiniteScroll:
                                                              true,
                                                          scrollDirection:
                                                              Axis.horizontal,
                                                          autoPlay: false,
                                                          onPageChanged:
                                                              (index, _) async {
                                                            _model.carouselCurrentIndex3 =
                                                                index;

                                                            safeSetState(() {});
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 16.0, 0.0, 16.0),
                                                  child: Builder(
                                                    builder: (context) {
                                                      final otherRowList =
                                                          PlantShopGroup
                                                                  .otherCategoryCall
                                                                  .dataList(
                                                                    otherCategoryOtherCategoryResponse
                                                                        .jsonBody,
                                                                  )
                                                                  ?.toList() ??
                                                              [];
                                                      _model.debugGeneratorVariables[
                                                              'otherRowList${otherRowList.length > 100 ? ' (first 100)' : ''}'] =
                                                          debugSerializeParam(
                                                        otherRowList.take(100),
                                                        ParamType.JSON,
                                                        isList: true,
                                                        link:
                                                            'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                        name: 'dynamic',
                                                        nullable: false,
                                                      );
                                                      debugLogWidgetClass(
                                                          _model);

                                                      return Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: List.generate(
                                                            otherRowList.length,
                                                            (otherRowListIndex) {
                                                          final otherRowListItem =
                                                              otherRowList[
                                                                  otherRowListIndex];
                                                          return Container(
                                                            width: 10.0,
                                                            height: 10.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: otherRowListIndex ==
                                                                      _model
                                                                          .carouselCurrentIndex3
                                                                  ? FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary
                                                                  : FlutterFlowTheme.of(
                                                                          context)
                                                                      .black10,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                          );
                                                        }).divide(SizedBox(
                                                            width: 8.0)),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ].addToStart(
                                                  SizedBox(height: 16.0)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                FutureBuilder<ApiCallResponse>(
                                  future: FFAppState()
                                      .latestProducts(
                                    requestFn: () =>
                                        PlantShopGroup.latestProductsCall.call(
                                      page: 1,
                                    ),
                                  )
                                      .then((result) {
                                    _model.apiRequestCompleted4 = true;
                                    return result;
                                  }),
                                  builder: (context, snapshot) {
                                    // Customize what your widget looks like when it's loading.
                                    if (!snapshot.hasData) {
                                      return ProductsHoreShimmerWidget(
                                        name: 'Latest products',
                                      );
                                    }
                                    final latestProductsLatestProductsResponse =
                                        snapshot.data!;
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.latestProductsCall_statusCode_Container_fqm2nkn2'] =
                                        debugSerializeParam(
                                      latestProductsLatestProductsResponse
                                          .statusCode,
                                      ParamType.int,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                      name: 'int',
                                      nullable: false,
                                    );
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.latestProductsCall_responseBody_Container_fqm2nkn2'] =
                                        debugSerializeParam(
                                      latestProductsLatestProductsResponse
                                          .bodyText,
                                      ParamType.String,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                      name: 'String',
                                      nullable: false,
                                    );
                                    debugLogWidgetClass(_model);

                                    return Container(
                                      decoration: BoxDecoration(),
                                      child: Visibility(
                                        visible: (PlantShopGroup
                                                    .latestProductsCall
                                                    .status(
                                                  latestProductsLatestProductsResponse
                                                      .jsonBody,
                                                ) ==
                                                null) &&
                                            (PlantShopGroup.latestProductsCall
                                                        .latestProductsList(
                                                      latestProductsLatestProductsResponse
                                                          .jsonBody,
                                                    ) !=
                                                    null &&
                                                (PlantShopGroup
                                                        .latestProductsCall
                                                        .latestProductsList(
                                                  latestProductsLatestProductsResponse
                                                      .jsonBody,
                                                ))!
                                                    .isNotEmpty),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 12.0, 0.0, 0.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryBackground,
                                            ),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 20.0, 0.0, 20.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(12.0, 0.0,
                                                                12.0, 16.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          FFLocalizations.of(
                                                                  context)
                                                              .getText(
                                                            '8g0rz082' /* Latest products */,
                                                          ),
                                                          textAlign:
                                                              TextAlign.start,
                                                          maxLines: 1,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                                fontSize: 20.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                useGoogleFonts:
                                                                    false,
                                                                lineHeight: 1.5,
                                                              ),
                                                        ),
                                                        InkWell(
                                                          splashColor: Colors
                                                              .transparent,
                                                          focusColor: Colors
                                                              .transparent,
                                                          hoverColor: Colors
                                                              .transparent,
                                                          highlightColor: Colors
                                                              .transparent,
                                                          onTap: () async {
                                                            context.pushNamed(
                                                                LatestProductsPageWidget
                                                                    .routeName);
                                                          },
                                                          child: Container(
                                                            height: 29.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .black10,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          30.0),
                                                            ),
                                                            alignment:
                                                                AlignmentDirectional(
                                                                    0.0, 0.0),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          10.0,
                                                                          0.0,
                                                                          10.0,
                                                                          0.0),
                                                              child: Text(
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  'vomlpa1l' /* View all */,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      fontSize:
                                                                          14.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal,
                                                                      useGoogleFonts:
                                                                          false,
                                                                      lineHeight:
                                                                          1.0,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(),
                                                    child: Builder(
                                                      builder: (context) {
                                                        final latestProductsList =
                                                            (PlantShopGroup
                                                                        .latestProductsCall
                                                                        .latestProductsList(
                                                                          latestProductsLatestProductsResponse
                                                                              .jsonBody,
                                                                        )
                                                                        ?.toList() ??
                                                                    [])
                                                                .take(6)
                                                                .toList();
                                                        _model.debugGeneratorVariables[
                                                                'latestProductsList${latestProductsList.length > 100 ? ' (first 100)' : ''}'] =
                                                            debugSerializeParam(
                                                          latestProductsList
                                                              .take(100),
                                                          ParamType.JSON,
                                                          isList: true,
                                                          link:
                                                              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                          name: 'dynamic',
                                                          nullable: false,
                                                        );
                                                        debugLogWidgetClass(
                                                            _model);

                                                        return SingleChildScrollView(
                                                          scrollDirection:
                                                              Axis.horizontal,
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            children: List.generate(
                                                                    latestProductsList
                                                                        .length,
                                                                    (latestProductsListIndex) {
                                                              final latestProductsListItem =
                                                                  latestProductsList[
                                                                      latestProductsListIndex];
                                                              return wrapWithModel(
                                                                model: _model
                                                                    .mainComponentModels5
                                                                    .getModel(
                                                                  getJsonField(
                                                                    latestProductsListItem,
                                                                    r'''$.id''',
                                                                  ).toString(),
                                                                  latestProductsListIndex,
                                                                ),
                                                                updateCallback: () =>
                                                                    safeSetState(
                                                                        () {}),
                                                                child: Builder(
                                                                    builder:
                                                                        (_) {
                                                                  return DebugFlutterFlowModelContext(
                                                                    rootModel:
                                                                        _model
                                                                            .rootModel,
                                                                    child:
                                                                        MainComponentWidget(
                                                                      key: Key(
                                                                        'Keyye9_${getJsonField(
                                                                          latestProductsListItem,
                                                                          r'''$.id''',
                                                                        ).toString()}',
                                                                      ),
                                                                      image:
                                                                          getJsonField(
                                                                        latestProductsListItem,
                                                                        r'''$.images[0].src''',
                                                                      ).toString(),
                                                                      name:
                                                                          getJsonField(
                                                                        latestProductsListItem,
                                                                        r'''$.name''',
                                                                      ).toString(),
                                                                      isLike: FFAppState()
                                                                          .wishList
                                                                          .contains(
                                                                              getJsonField(
                                                                            latestProductsListItem,
                                                                            r'''$.id''',
                                                                          ).toString()),
                                                                      regularPrice:
                                                                          getJsonField(
                                                                        latestProductsListItem,
                                                                        r'''$.regular_price''',
                                                                      ).toString(),
                                                                      price:
                                                                          getJsonField(
                                                                        latestProductsListItem,
                                                                        r'''$.price''',
                                                                      ).toString(),
                                                                      review:
                                                                          getJsonField(
                                                                        latestProductsListItem,
                                                                        r'''$.rating_count''',
                                                                      ).toString(),
                                                                      isBigContainer:
                                                                          true,
                                                                      height: ('' !=
                                                                                  getJsonField(
                                                                                    latestProductsListItem,
                                                                                    r'''$.images[0].src''',
                                                                                  ).toString()) &&
                                                                              (getJsonField(
                                                                                    latestProductsListItem,
                                                                                    r'''$.images[0].src''',
                                                                                  ) !=
                                                                                  null) &&
                                                                              (getJsonField(
                                                                                    latestProductsListItem,
                                                                                    r'''$.images''',
                                                                                  ) !=
                                                                                  null)
                                                                          ? 298.0
                                                                          : 180.0,
                                                                      width:
                                                                          189.0,
                                                                      onSale:
                                                                          getJsonField(
                                                                        latestProductsListItem,
                                                                        r'''$.on_sale''',
                                                                      ),
                                                                      showImage: ('' !=
                                                                              getJsonField(
                                                                                latestProductsListItem,
                                                                                r'''$.images[0].src''',
                                                                              ).toString()) &&
                                                                          (getJsonField(
                                                                                latestProductsListItem,
                                                                                r'''$.images[0].src''',
                                                                              ) !=
                                                                              null) &&
                                                                          (getJsonField(
                                                                                latestProductsListItem,
                                                                                r'''$.images''',
                                                                              ) !=
                                                                              null),
                                                                      isLikeTap:
                                                                          () async {
                                                                        if (FFAppState()
                                                                            .isLogin) {
                                                                          await action_blocks
                                                                              .addorRemoveFavourite(
                                                                            context,
                                                                            id: getJsonField(
                                                                              latestProductsListItem,
                                                                              r'''$.id''',
                                                                            ).toString(),
                                                                          );
                                                                          safeSetState(
                                                                              () {});
                                                                        } else {
                                                                          ScaffoldMessenger.of(context)
                                                                              .hideCurrentSnackBar();
                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(
                                                                            SnackBar(
                                                                              content: Text(
                                                                                FFLocalizations.of(context).getVariableText(
                                                                                  enText: 'Please log in first',
                                                                                  arText: 'الرجاء تسجيل الدخول أولاً',
                                                                                ),
                                                                                style: TextStyle(
                                                                                  fontFamily: 'SF Pro Display',
                                                                                  color: FlutterFlowTheme.of(context).primaryText,
                                                                                ),
                                                                              ),
                                                                              duration: Duration(milliseconds: 2000),
                                                                              backgroundColor: FlutterFlowTheme.of(context).secondary,
                                                                              action: SnackBarAction(
                                                                                label: FFLocalizations.of(context).getVariableText(
                                                                                  enText: 'Login',
                                                                                  arText: 'تسجيل الدخول',
                                                                                ),
                                                                                textColor: FlutterFlowTheme.of(context).primary,
                                                                                onPressed: () async {
                                                                                  context.pushNamed(SignInPageWidget.routeName);
                                                                                },
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }
                                                                      },
                                                                      isMainTap:
                                                                          () async {
                                                                        context
                                                                            .pushNamed(
                                                                          ProductDetailPageWidget
                                                                              .routeName,
                                                                          queryParameters:
                                                                              {
                                                                            'productDetail':
                                                                                serializeParam(
                                                                              latestProductsListItem,
                                                                              ParamType.JSON,
                                                                            ),
                                                                            'upsellIdsList':
                                                                                serializeParam(
                                                                              (getJsonField(
                                                                                latestProductsListItem,
                                                                                r'''$.upsell_ids''',
                                                                                true,
                                                                              ) as List)
                                                                                  .map<String>((s) => s.toString())
                                                                                  .toList(),
                                                                              ParamType.String,
                                                                              isList: true,
                                                                            ),
                                                                            'relatedIdsList':
                                                                                serializeParam(
                                                                              (getJsonField(
                                                                                latestProductsListItem,
                                                                                r'''$.related_ids''',
                                                                                true,
                                                                              ) as List)
                                                                                  .map<String>((s) => s.toString())
                                                                                  .toList(),
                                                                              ParamType.String,
                                                                              isList: true,
                                                                            ),
                                                                            'imagesList':
                                                                                serializeParam(
                                                                              getJsonField(
                                                                                latestProductsListItem,
                                                                                r'''$.images''',
                                                                                true,
                                                                              ),
                                                                              ParamType.JSON,
                                                                              isList: true,
                                                                            ),
                                                                          }.withoutNulls,
                                                                        );
                                                                      },
                                                                    ),
                                                                  );
                                                                }),
                                                              );
                                                            })
                                                                .divide(SizedBox(
                                                                    width:
                                                                        12.0))
                                                                .addToStart(
                                                                    SizedBox(
                                                                        width:
                                                                            12.0))
                                                                .addToEnd(SizedBox(
                                                                    width:
                                                                        12.0)),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                FutureBuilder<ApiCallResponse>(
                                  future: FFAppState()
                                      .blog(
                                    requestFn: () =>
                                        PlantShopGroup.blogCall.call(),
                                  )
                                      .then((result) {
                                    _model.apiRequestCompleted2 = true;
                                    return result;
                                  }),
                                  builder: (context, snapshot) {
                                    // Customize what your widget looks like when it's loading.
                                    if (!snapshot.hasData) {
                                      return BlogShimmerWidget();
                                    }
                                    final blogBlogResponse = snapshot.data!;
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.blogCall_statusCode_Container_a2nwhp8s'] =
                                        debugSerializeParam(
                                      blogBlogResponse.statusCode,
                                      ParamType.int,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                      name: 'int',
                                      nullable: false,
                                    );
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.blogCall_responseBody_Container_a2nwhp8s'] =
                                        debugSerializeParam(
                                      blogBlogResponse.bodyText,
                                      ParamType.String,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                      name: 'String',
                                      nullable: false,
                                    );
                                    debugLogWidgetClass(_model);

                                    return Container(
                                      decoration: BoxDecoration(),
                                      child: Visibility(
                                        visible: (PlantShopGroup.blogCall
                                                    .status(
                                                  blogBlogResponse.jsonBody,
                                                ) ==
                                                null) &&
                                            (PlantShopGroup.blogCall.blogList(
                                                      blogBlogResponse.jsonBody,
                                                    ) !=
                                                    null &&
                                                (PlantShopGroup.blogCall
                                                        .blogList(
                                                  blogBlogResponse.jsonBody,
                                                ))!
                                                    .isNotEmpty),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 12.0, 0.0, 0.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryBackground,
                                            ),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 20.0, 0.0, 20.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(12.0, 0.0,
                                                                12.0, 16.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          FFLocalizations.of(
                                                                  context)
                                                              .getText(
                                                            'rb8azn36' /* Blog */,
                                                          ),
                                                          textAlign:
                                                              TextAlign.start,
                                                          maxLines: 1,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                                fontSize: 20.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                useGoogleFonts:
                                                                    false,
                                                                lineHeight: 1.5,
                                                              ),
                                                        ),
                                                        InkWell(
                                                          splashColor: Colors
                                                              .transparent,
                                                          focusColor: Colors
                                                              .transparent,
                                                          hoverColor: Colors
                                                              .transparent,
                                                          highlightColor: Colors
                                                              .transparent,
                                                          onTap: () async {
                                                            context.pushNamed(
                                                                BlogPageWidget
                                                                    .routeName);
                                                          },
                                                          child: Container(
                                                            height: 29.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .black10,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          30.0),
                                                            ),
                                                            alignment:
                                                                AlignmentDirectional(
                                                                    0.0, 0.0),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          10.0,
                                                                          0.0,
                                                                          10.0,
                                                                          0.0),
                                                              child: Text(
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  '3hnspteu' /* View all */,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      fontSize:
                                                                          14.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal,
                                                                      useGoogleFonts:
                                                                          false,
                                                                      lineHeight:
                                                                          1.0,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(),
                                                    child: Builder(
                                                      builder: (context) {
                                                        final blogList =
                                                            (PlantShopGroup
                                                                        .blogCall
                                                                        .blogList(
                                                                          blogBlogResponse
                                                                              .jsonBody,
                                                                        )
                                                                        ?.toList() ??
                                                                    [])
                                                                .take(6)
                                                                .toList();
                                                        _model.debugGeneratorVariables[
                                                                'blogList${blogList.length > 100 ? ' (first 100)' : ''}'] =
                                                            debugSerializeParam(
                                                          blogList.take(100),
                                                          ParamType.JSON,
                                                          isList: true,
                                                          link:
                                                              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
                                                          name: 'dynamic',
                                                          nullable: false,
                                                        );
                                                        debugLogWidgetClass(
                                                            _model);

                                                        return SingleChildScrollView(
                                                          scrollDirection:
                                                              Axis.horizontal,
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            children: List.generate(
                                                                    blogList
                                                                        .length,
                                                                    (blogListIndex) {
                                                              final blogListItem =
                                                                  blogList[
                                                                      blogListIndex];
                                                              return InkWell(
                                                                splashColor: Colors
                                                                    .transparent,
                                                                focusColor: Colors
                                                                    .transparent,
                                                                hoverColor: Colors
                                                                    .transparent,
                                                                highlightColor:
                                                                    Colors
                                                                        .transparent,
                                                                onTap:
                                                                    () async {
                                                                  context
                                                                      .pushNamed(
                                                                    BlogDetailPageWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'title':
                                                                          serializeParam(
                                                                        getJsonField(
                                                                          blogListItem,
                                                                          r'''$.title.rendered''',
                                                                        ).toString(),
                                                                        ParamType
                                                                            .String,
                                                                      ),
                                                                      'date':
                                                                          serializeParam(
                                                                        getJsonField(
                                                                          blogListItem,
                                                                          r'''$.date''',
                                                                        ).toString(),
                                                                        ParamType
                                                                            .String,
                                                                      ),
                                                                      'detail':
                                                                          serializeParam(
                                                                        getJsonField(
                                                                          blogListItem,
                                                                          r'''$.content.rendered''',
                                                                        ).toString(),
                                                                        ParamType
                                                                            .String,
                                                                      ),
                                                                      'shareUrl':
                                                                          serializeParam(
                                                                        getJsonField(
                                                                          blogListItem,
                                                                          r'''$.link''',
                                                                        ).toString(),
                                                                        ParamType
                                                                            .String,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
                                                                },
                                                                child:
                                                                    Container(
                                                                  width: 190.0,
                                                                  height: ('' !=
                                                                              getJsonField(
                                                                                blogListItem,
                                                                                r'''$._embedded['wp:featuredmedia'][0]['source_url']''',
                                                                              ).toString()) &&
                                                                          (getJsonField(
                                                                                blogListItem,
                                                                                r'''$._embedded['wp:featuredmedia'][0]['source_url']''',
                                                                              ) !=
                                                                              null) &&
                                                                          (getJsonField(
                                                                                blogListItem,
                                                                                r'''$._embedded['wp:featuredmedia']''',
                                                                              ) !=
                                                                              null) &&
                                                                          (getJsonField(
                                                                                blogListItem,
                                                                                r'''$._embedded''',
                                                                              ) !=
                                                                              null)
                                                                      ? 245.0
                                                                      : 120.0,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryBackground,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            12.0),
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .black20,
                                                                      width:
                                                                          1.0,
                                                                    ),
                                                                  ),
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                            12.0),
                                                                    child:
                                                                        Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        if (('' !=
                                                                                getJsonField(
                                                                                  blogListItem,
                                                                                  r'''$._embedded['wp:featuredmedia'][0]['source_url']''',
                                                                                ).toString()) &&
                                                                            (getJsonField(
                                                                                  blogListItem,
                                                                                  r'''$._embedded['wp:featuredmedia'][0]['source_url']''',
                                                                                ) !=
                                                                                null) &&
                                                                            (getJsonField(
                                                                                  blogListItem,
                                                                                  r'''$._embedded['wp:featuredmedia']''',
                                                                                ) !=
                                                                                null) &&
                                                                            (getJsonField(
                                                                                  blogListItem,
                                                                                  r'''$._embedded''',
                                                                                ) !=
                                                                                null))
                                                                          Expanded(
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
                                                                              child: ClipRRect(
                                                                                borderRadius: BorderRadius.circular(12.0),
                                                                                child: CachedNetworkImage(
                                                                                  fadeInDuration: Duration(milliseconds: 200),
                                                                                  fadeOutDuration: Duration(milliseconds: 200),
                                                                                  imageUrl: getJsonField(
                                                                                    blogListItem,
                                                                                    r'''$._embedded['wp:featuredmedia'][0]['source_url']''',
                                                                                  ).toString(),
                                                                                  width: double.infinity,
                                                                                  height: double.infinity,
                                                                                  fit: BoxFit.cover,
                                                                                  errorWidget: (context, error, stackTrace) => Image.asset(
                                                                                    'assets/images/error_image.png',
                                                                                    width: double.infinity,
                                                                                    height: double.infinity,
                                                                                    fit: BoxFit.cover,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.start,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children:
                                                                              [
                                                                            Text(
                                                                              getJsonField(
                                                                                blogListItem,
                                                                                r'''$.title.rendered''',
                                                                              ).toString(),
                                                                              textAlign: TextAlign.start,
                                                                              maxLines: 1,
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    fontFamily: 'SF Pro Display',
                                                                                    fontSize: 15.0,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FontWeight.w500,
                                                                                    useGoogleFonts: false,
                                                                                    lineHeight: 1.5,
                                                                                  ),
                                                                            ),
                                                                            Text(
                                                                              (String var1) {
                                                                                return var1.replaceAll(RegExp(r'<[^>]*>'), '');
                                                                              }(getJsonField(
                                                                                blogListItem,
                                                                                r'''$.excerpt.rendered''',
                                                                              ).toString()),
                                                                              textAlign: TextAlign.start,
                                                                              maxLines: 2,
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    fontFamily: 'SF Pro Display',
                                                                                    fontSize: 13.0,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FontWeight.normal,
                                                                                    useGoogleFonts: false,
                                                                                    lineHeight: 1.5,
                                                                                  ),
                                                                            ),
                                                                            Text(
                                                                              functions.formatBlogDateTime(getJsonField(
                                                                                blogListItem,
                                                                                r'''$.date''',
                                                                              ).toString()),
                                                                              textAlign: TextAlign.start,
                                                                              maxLines: 1,
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    fontFamily: 'SF Pro Display',
                                                                                    color: FlutterFlowTheme.of(context).secondaryText,
                                                                                    fontSize: 13.0,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FontWeight.normal,
                                                                                    useGoogleFonts: false,
                                                                                    lineHeight: 1.5,
                                                                                  ),
                                                                            ),
                                                                          ].divide(SizedBox(height: 4.0)),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            })
                                                                .divide(SizedBox(
                                                                    width:
                                                                        12.0))
                                                                .addToStart(
                                                                    SizedBox(
                                                                        width:
                                                                            12.0))
                                                                .addToEnd(SizedBox(
                                                                    width:
                                                                        12.0)),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ].addToEnd(SizedBox(height: 12.0)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return wrapWithModel(
                  model: _model.responseComponentModel,
                  updateCallback: () => safeSetState(() {}),
                  child: Builder(builder: (_) {
                    return DebugFlutterFlowModelContext(
                      rootModel: _model.rootModel,
                      child: ResponseComponentWidget(),
                    );
                  }),
                );
              }
            },
          );
        } else {
          return Align(
            alignment: AlignmentDirectional(0.0, 0.0),
            child: Lottie.asset(
              'assets/jsons/No_Wifi.json',
              width: 150.0,
              height: 150.0,
              fit: BoxFit.contain,
              animate: true,
            ),
          );
        }
      },
    );
  }
}
