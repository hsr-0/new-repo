import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/dialog_components/cancle_order_component/cancle_order_component_widget.dart';
import '/pages/shimmer/order_detail_shimmer/order_detail_shimmer_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'order_details_page_model.dart';
export 'order_details_page_model.dart';

class OrderDetailsPageWidget extends StatefulWidget {
  const OrderDetailsPageWidget({
    super.key,
    required this.orderId,
  });

  final int? orderId;

  static String routeName = 'OrderDetailsPage';
  static String routePath = '/orderDetailsPage';

  @override
  State<OrderDetailsPageWidget> createState() => _OrderDetailsPageWidgetState();
}

class _OrderDetailsPageWidgetState extends State<OrderDetailsPageWidget>
    with TickerProviderStateMixin, RouteAware {
  late OrderDetailsPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OrderDetailsPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await action_blocks.responseAction(context);
      safeSetState(() {});
    });

    animationsMap.addAll({
      'textOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 0.0),
            end: Offset(1.0, 1.0),
          ),
        ],
      ),
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);

    _model.dispose();

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

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Container(
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).lightGray,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                wrapWithModel(
                  model: _model.mainAppbarModel,
                  updateCallback: () => safeSetState(() {}),
                  child: Builder(builder: (_) {
                    return DebugFlutterFlowModelContext(
                      rootModel: _model.rootModel,
                      child: MainAppbarWidget(
                        title: FFLocalizations.of(context).getText(
                          '3583upp2' /* Order Details */,
                        ),
                        isBack: false,
                        isEdit: false,
                        isShare: false,
                        backAction: () async {},
                        editAction: () async {},
                      ),
                    );
                  }),
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (FFAppState().connected) {
                        return Builder(
                          builder: (context) {
                            if (FFAppState().response) {
                              return FutureBuilder<ApiCallResponse>(
                                future: FFAppState()
                                    .orderDetail(
                                  uniqueQueryKey: valueOrDefault<String>(
                                    widget!.orderId?.toString(),
                                    'sf',
                                  ),
                                  requestFn: () =>
                                      PlantShopGroup.orderDetailCall.call(
                                    orderId: widget!.orderId,
                                  ),
                                )
                                    .then((result) {
                                  try {
                                    _model.apiRequestCompleted = true;
                                    _model.apiRequestLastUniqueKey =
                                        valueOrDefault<String>(
                                      widget!.orderId?.toString(),
                                      'sf',
                                    );
                                  } finally {}
                                  return result;
                                }),
                                builder: (context, snapshot) {
                                  // Customize what your widget looks like when it's loading.
                                  if (!snapshot.hasData) {
                                    return OrderDetailShimmerWidget();
                                  }
                                  final listViewOrderDetailResponse =
                                      snapshot.data!;
                                  _model.debugBackendQueries[
                                          'PlantShopGroup.orderDetailCall_statusCode_ListView_uqu45xyy'] =
                                      debugSerializeParam(
                                    listViewOrderDetailResponse.statusCode,
                                    ParamType.int,
                                    link:
                                        'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=OrderDetailsPage',
                                    name: 'int',
                                    nullable: false,
                                  );
                                  _model.debugBackendQueries[
                                          'PlantShopGroup.orderDetailCall_responseBody_ListView_uqu45xyy'] =
                                      debugSerializeParam(
                                    listViewOrderDetailResponse.bodyText,
                                    ParamType.String,
                                    link:
                                        'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=OrderDetailsPage',
                                    name: 'String',
                                    nullable: false,
                                  );
                                  debugLogWidgetClass(_model);

                                  return RefreshIndicator(
                                    key: Key('RefreshIndicator_jpz7zvo3'),
                                    color: FlutterFlowTheme.of(context).primary,
                                    onRefresh: () async {
                                      safeSetState(() {
                                        FFAppState().clearOrderDetailCacheKey(
                                            _model.apiRequestLastUniqueKey);
                                        _model.apiRequestCompleted = false;
                                      });
                                      await _model.waitForApiRequestCompleted();
                                    },
                                    child: ListView(
                                      padding: EdgeInsets.fromLTRB(
                                        0,
                                        12.0,
                                        0,
                                        0,
                                      ),
                                      scrollDirection: Axis.vertical,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(12.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Expanded(
                                                      child: RichText(
                                                        textScaler:
                                                            MediaQuery.of(
                                                                    context)
                                                                .textScaler,
                                                        text: TextSpan(
                                                          children: [
                                                            TextSpan(
                                                              text: FFLocalizations
                                                                      .of(context)
                                                                  .getText(
                                                                '70i6tngn' /* Order ID : # */,
                                                              ),
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontSize: 17.0,
                                                              ),
                                                            ),
                                                            TextSpan(
                                                              text:
                                                                  valueOrDefault<
                                                                      String>(
                                                                widget!.orderId
                                                                    ?.toString(),
                                                                '1',
                                                              ),
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontSize: 17.0,
                                                              ),
                                                            )
                                                          ],
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                fontSize: 17.0,
                                                                letterSpacing:
                                                                    0.17,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                useGoogleFonts:
                                                                    false,
                                                                lineHeight: 1.5,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        color: () {
                                                          if ('pending' ==
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .orderDetailCall
                                                                    .orderDetail(
                                                                  listViewOrderDetailResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.status''',
                                                              ).toString()) {
                                                            return Color(
                                                                0xFFFFF5E0);
                                                          } else if ('cancelled' ==
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .orderDetailCall
                                                                    .orderDetail(
                                                                  listViewOrderDetailResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.status''',
                                                              ).toString()) {
                                                            return Color(
                                                                0xFFFFF3F3);
                                                          } else if ('processing' ==
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .orderDetailCall
                                                                    .orderDetail(
                                                                  listViewOrderDetailResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.status''',
                                                              ).toString()) {
                                                            return Color(
                                                                0xFFF9EDF9);
                                                          } else if ('refunded' ==
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .orderDetailCall
                                                                    .orderDetail(
                                                                  listViewOrderDetailResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.status''',
                                                              ).toString()) {
                                                            return Color(
                                                                0xFFF5F5F5);
                                                          } else if ('on-hold' ==
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .orderDetailCall
                                                                    .orderDetail(
                                                                  listViewOrderDetailResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.status''',
                                                              ).toString()) {
                                                            return Color(
                                                                0xFFE5EAFB);
                                                          } else if ('failed' ==
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .orderDetailCall
                                                                    .orderDetail(
                                                                  listViewOrderDetailResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.status''',
                                                              ).toString()) {
                                                            return Color(
                                                                0xFFFFF3F3);
                                                          } else if ('checkout-draft' ==
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .orderDetailCall
                                                                    .orderDetail(
                                                                  listViewOrderDetailResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.status''',
                                                              ).toString()) {
                                                            return Color(
                                                                0xFFE8F2F1);
                                                          } else {
                                                            return Color(
                                                                0xFFEEFCF0);
                                                          }
                                                        }(),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(37.0),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    10.0,
                                                                    5.0,
                                                                    10.0,
                                                                    5.0),
                                                        child: Text(
                                                          functions
                                                              .capitalizeFirst(
                                                                  getJsonField(
                                                            PlantShopGroup
                                                                .orderDetailCall
                                                                .orderDetail(
                                                              listViewOrderDetailResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.status''',
                                                          ).toString()),
                                                          textAlign:
                                                              TextAlign.center,
                                                          maxLines: 1,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                color: () {
                                                                  if ('pending' ==
                                                                      getJsonField(
                                                                        PlantShopGroup
                                                                            .orderDetailCall
                                                                            .orderDetail(
                                                                          listViewOrderDetailResponse
                                                                              .jsonBody,
                                                                        ),
                                                                        r'''$.status''',
                                                                      ).toString()) {
                                                                    return Color(
                                                                        0xFFD99B0C);
                                                                  } else if ('cancelled' ==
                                                                      getJsonField(
                                                                        PlantShopGroup
                                                                            .orderDetailCall
                                                                            .orderDetail(
                                                                          listViewOrderDetailResponse
                                                                              .jsonBody,
                                                                        ),
                                                                        r'''$.status''',
                                                                      ).toString()) {
                                                                    return Color(
                                                                        0xFFFC0A15);
                                                                  } else if ('processing' ==
                                                                      getJsonField(
                                                                        PlantShopGroup
                                                                            .orderDetailCall
                                                                            .orderDetail(
                                                                          listViewOrderDetailResponse
                                                                              .jsonBody,
                                                                        ),
                                                                        r'''$.status''',
                                                                      ).toString()) {
                                                                    return Color(
                                                                        0xFFB963BE);
                                                                  } else if ('refunded' ==
                                                                      getJsonField(
                                                                        PlantShopGroup
                                                                            .orderDetailCall
                                                                            .orderDetail(
                                                                          listViewOrderDetailResponse
                                                                              .jsonBody,
                                                                        ),
                                                                        r'''$.status''',
                                                                      ).toString()) {
                                                                    return Color(
                                                                        0xFF696969);
                                                                  } else if ('on-hold' ==
                                                                      getJsonField(
                                                                        PlantShopGroup
                                                                            .orderDetailCall
                                                                            .orderDetail(
                                                                          listViewOrderDetailResponse
                                                                              .jsonBody,
                                                                        ),
                                                                        r'''$.status''',
                                                                      ).toString()) {
                                                                    return Color(
                                                                        0xFF384AA7);
                                                                  } else if ('failed' ==
                                                                      getJsonField(
                                                                        PlantShopGroup
                                                                            .orderDetailCall
                                                                            .orderDetail(
                                                                          listViewOrderDetailResponse
                                                                              .jsonBody,
                                                                        ),
                                                                        r'''$.status''',
                                                                      ).toString()) {
                                                                    return Color(
                                                                        0xFFFC0A15);
                                                                  } else if ('checkout-draft' ==
                                                                      getJsonField(
                                                                        PlantShopGroup
                                                                            .orderDetailCall
                                                                            .orderDetail(
                                                                          listViewOrderDetailResponse
                                                                              .jsonBody,
                                                                        ),
                                                                        r'''$.status''',
                                                                      ).toString()) {
                                                                    return Color(
                                                                        0xFF069484);
                                                                  } else {
                                                                    return Color(
                                                                        0xFF04B155);
                                                                  }
                                                                }(),
                                                                fontSize: 16.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                                useGoogleFonts:
                                                                    false,
                                                                lineHeight: 1.5,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 4.0, 0.0, 0.0),
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
                                                                    8.0,
                                                                    0.0),
                                                        child: Container(
                                                          width: 10.0,
                                                          height: 10.0,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primary,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: RichText(
                                                          textScaler:
                                                              MediaQuery.of(
                                                                      context)
                                                                  .textScaler,
                                                          text: TextSpan(
                                                            children: [
                                                              TextSpan(
                                                                text: FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  'sokhjacz' /* Order at  */,
                                                                ),
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      fontSize:
                                                                          16.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal,
                                                                      useGoogleFonts:
                                                                          false,
                                                                      lineHeight:
                                                                          1.5,
                                                                    ),
                                                              ),
                                                              TextSpan(
                                                                text: functions
                                                                    .formatOrderDateTime(
                                                                        getJsonField(
                                                                  PlantShopGroup
                                                                      .orderDetailCall
                                                                      .orderDetail(
                                                                    listViewOrderDetailResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  r'''$.date_created''',
                                                                ).toString()),
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                  fontSize:
                                                                      16.0,
                                                                  height: 1.5,
                                                                ),
                                                              )
                                                            ],
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  fontSize:
                                                                      16.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                  useGoogleFonts:
                                                                      false,
                                                                  lineHeight:
                                                                      1.5,
                                                                ),
                                                          ),
                                                          textAlign:
                                                              TextAlign.start,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 5.0, 0.0, 0.0),
                                                  child: RichText(
                                                    textScaler:
                                                        MediaQuery.of(context)
                                                            .textScaler,
                                                    text: TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text: FFLocalizations
                                                                  .of(context)
                                                              .getText(
                                                            'knp9t4zs' /* Payment Method:  */,
                                                          ),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                fontSize: 16.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                                useGoogleFonts:
                                                                    false,
                                                                lineHeight: 1.5,
                                                              ),
                                                        ),
                                                        TextSpan(
                                                          text: getJsonField(
                                                            PlantShopGroup
                                                                .orderDetailCall
                                                                .orderDetail(
                                                              listViewOrderDetailResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.payment_method_title''',
                                                          ).toString(),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                fontSize: 16.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                useGoogleFonts:
                                                                    false,
                                                                lineHeight: 1.5,
                                                              ),
                                                        )
                                                      ],
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            fontFamily:
                                                                'SF Pro Display',
                                                            fontSize: 16.0,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            useGoogleFonts:
                                                                false,
                                                            lineHeight: 1.5,
                                                          ),
                                                    ),
                                                    textAlign: TextAlign.start,
                                                  ),
                                                ),
                                                if ('pending' ==
                                                    getJsonField(
                                                      PlantShopGroup
                                                          .orderDetailCall
                                                          .orderDetail(
                                                        listViewOrderDetailResponse
                                                            .jsonBody,
                                                      ),
                                                      r'''$.status''',
                                                    ).toString())
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 9.0,
                                                                0.0, 0.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceAround,
                                                      children: [
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
                                                            await showModalBottomSheet(
                                                              isScrollControlled:
                                                                  true,
                                                              backgroundColor:
                                                                  Colors
                                                                      .transparent,
                                                              enableDrag: false,
                                                              context: context,
                                                              builder:
                                                                  (context) {
                                                                return GestureDetector(
                                                                  onTap: () {
                                                                    FocusScope.of(
                                                                            context)
                                                                        .unfocus();
                                                                    FocusManager
                                                                        .instance
                                                                        .primaryFocus
                                                                        ?.unfocus();
                                                                  },
                                                                  child:
                                                                      Padding(
                                                                    padding: MediaQuery
                                                                        .viewInsetsOf(
                                                                            context),
                                                                    child:
                                                                        CancleOrderComponentWidget(
                                                                      onTapYes:
                                                                          () async {
                                                                        _model.sucess =
                                                                            await action_blocks.updateStatus(
                                                                          context,
                                                                          productDetail: PlantShopGroup
                                                                              .orderDetailCall
                                                                              .orderDetail(
                                                                            listViewOrderDetailResponse.jsonBody,
                                                                          ),
                                                                          status:
                                                                              'cancelled',
                                                                        );
                                                                        if (_model
                                                                            .sucess!) {
                                                                          safeSetState(
                                                                              () {
                                                                            FFAppState().clearOrderDetailCacheKey(_model.apiRequestLastUniqueKey);
                                                                            _model.apiRequestCompleted =
                                                                                false;
                                                                          });
                                                                          await _model
                                                                              .waitForApiRequestCompleted();
                                                                          Navigator.pop(
                                                                              context);

                                                                          context
                                                                              .goNamed(HomeMainPageWidget.routeName);

                                                                          context
                                                                              .pushNamed(MyOrdersPageWidget.routeName);
                                                                        } else {
                                                                          Navigator.pop(
                                                                              context);
                                                                        }
                                                                      },
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ).then((value) =>
                                                                safeSetState(
                                                                    () {}));

                                                            safeSetState(() {});
                                                          },
                                                          child: Text(
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                              'ssfg60su' /* Cancel Order? */,
                                                            ),
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .error,
                                                                  fontSize:
                                                                      14.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  useGoogleFonts:
                                                                      false,
                                                                  lineHeight:
                                                                      1.5,
                                                                ),
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
                                                              PayForOderPageWidget
                                                                  .routeName,
                                                              queryParameters: {
                                                                'orderDetail':
                                                                    serializeParam(
                                                                  PlantShopGroup
                                                                      .orderDetailCall
                                                                      .orderDetail(
                                                                    listViewOrderDetailResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  ParamType
                                                                      .JSON,
                                                                ),
                                                              }.withoutNulls,
                                                            );
                                                          },
                                                          child: Text(
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                              'ljska8ls' /* Pay for this order */,
                                                            ),
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .success,
                                                                  fontSize:
                                                                      14.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  useGoogleFonts:
                                                                      false,
                                                                  lineHeight:
                                                                      1.5,
                                                                ),
                                                          ),
                                                        ).animateOnPageLoad(
                                                            animationsMap[
                                                                'textOnPageLoadAnimation']!),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Builder(
                                          builder: (context) {
                                            final productList = getJsonField(
                                              PlantShopGroup.orderDetailCall
                                                  .orderDetail(
                                                listViewOrderDetailResponse
                                                    .jsonBody,
                                              ),
                                              r'''$.line_items''',
                                            ).toList();
                                            _model.debugGeneratorVariables[
                                                    'productList${productList.length > 100 ? ' (first 100)' : ''}'] =
                                                debugSerializeParam(
                                              productList.take(100),
                                              ParamType.JSON,
                                              link:
                                                  'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=OrderDetailsPage',
                                              name: 'dynamic',
                                              nullable: false,
                                            );
                                            debugLogWidgetClass(_model);

                                            return Column(
                                              mainAxisSize: MainAxisSize.max,
                                              children: List.generate(
                                                      productList.length,
                                                      (productListIndex) {
                                                final productListItem =
                                                    productList[
                                                        productListIndex];
                                                return Container(
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryBackground,
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                                12.0,
                                                                12.0,
                                                                12.0,
                                                                12.0),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            if (('' !=
                                                                    getJsonField(
                                                                      productListItem,
                                                                      r'''$.image.src''',
                                                                    ).toString()) &&
                                                                (getJsonField(
                                                                      productListItem,
                                                                      r'''$.image.src''',
                                                                    ) !=
                                                                    null) &&
                                                                (getJsonField(
                                                                      productListItem,
                                                                      r'''$.image''',
                                                                    ) !=
                                                                    null))
                                                              Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            16.0,
                                                                            0.0),
                                                                child:
                                                                    Container(
                                                                  width: 88.0,
                                                                  height: 88.0,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            16.0),
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
                                                                        productListItem,
                                                                        r'''$.image.src''',
                                                                      ).toString(),
                                                                      width: double
                                                                          .infinity,
                                                                      height: double
                                                                          .infinity,
                                                                      fit: BoxFit
                                                                          .cover,
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
                                                                            .cover,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            Expanded(
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .start,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    functions
                                                                        .removeHtmlEntities(
                                                                            getJsonField(
                                                                      productListItem,
                                                                      r'''$.name''',
                                                                    ).toString()),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .start,
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .override(
                                                                          fontFamily:
                                                                              'SF Pro Display',
                                                                          fontSize:
                                                                              16.0,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                          useGoogleFonts:
                                                                              false,
                                                                          lineHeight:
                                                                              1.5,
                                                                        ),
                                                                  ),
                                                                  Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .start,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .end,
                                                                    children: [
                                                                      if ('0' !=
                                                                          (getJsonField(
                                                                            productListItem,
                                                                            r'''$.variation_id''',
                                                                          ).toString()))
                                                                        Expanded(
                                                                          child:
                                                                              Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                0.0,
                                                                                12.0,
                                                                                0.0,
                                                                                0.0),
                                                                            child:
                                                                                Builder(
                                                                              builder: (context) {
                                                                                final variationList = getJsonField(
                                                                                  productListItem,
                                                                                  r'''$.meta_data''',
                                                                                ).toList();
                                                                                _model.debugGeneratorVariables['variationList${variationList.length > 100 ? ' (first 100)' : ''}'] = debugSerializeParam(
                                                                                  variationList.take(100),
                                                                                  ParamType.JSON,
                                                                                  link: 'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=OrderDetailsPage',
                                                                                  name: 'dynamic',
                                                                                  nullable: false,
                                                                                );
                                                                                debugLogWidgetClass(_model);

                                                                                return Column(
                                                                                  mainAxisSize: MainAxisSize.max,
                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                  children: List.generate(variationList.length, (variationListIndex) {
                                                                                    final variationListItem = variationList[variationListIndex];
                                                                                    return RichText(
                                                                                      textScaler: MediaQuery.of(context).textScaler,
                                                                                      text: TextSpan(
                                                                                        children: [
                                                                                          TextSpan(
                                                                                            text: getJsonField(
                                                                                              variationListItem,
                                                                                              r'''$.display_key''',
                                                                                            ).toString(),
                                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                  fontFamily: 'SF Pro Display',
                                                                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                                                                  fontSize: 15.0,
                                                                                                  letterSpacing: 0.0,
                                                                                                  fontWeight: FontWeight.w500,
                                                                                                  useGoogleFonts: false,
                                                                                                ),
                                                                                          ),
                                                                                          TextSpan(
                                                                                            text: FFLocalizations.of(context).getText(
                                                                                              'l5n4uaum' /*  :  */,
                                                                                            ),
                                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                  fontFamily: 'SF Pro Display',
                                                                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                                                                  fontSize: 15.0,
                                                                                                  letterSpacing: 0.0,
                                                                                                  fontWeight: FontWeight.w500,
                                                                                                  useGoogleFonts: false,
                                                                                                ),
                                                                                          ),
                                                                                          TextSpan(
                                                                                            text: getJsonField(
                                                                                              variationListItem,
                                                                                              r'''$.display_value''',
                                                                                            ).toString(),
                                                                                            style: TextStyle(
                                                                                              color: FlutterFlowTheme.of(context).primaryText,
                                                                                              fontWeight: FontWeight.w500,
                                                                                              fontSize: 15.0,
                                                                                            ),
                                                                                          )
                                                                                        ],
                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                              fontFamily: 'SF Pro Display',
                                                                                              color: FlutterFlowTheme.of(context).primaryText,
                                                                                              fontSize: 14.0,
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FontWeight.normal,
                                                                                              useGoogleFonts: false,
                                                                                            ),
                                                                                      ),
                                                                                    );
                                                                                  }),
                                                                                );
                                                                              },
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      Expanded(
                                                                        child:
                                                                            Padding(
                                                                          padding: EdgeInsetsDirectional.fromSTEB(
                                                                              0.0,
                                                                              12.0,
                                                                              0.0,
                                                                              0.0),
                                                                          child:
                                                                              Column(
                                                                            mainAxisSize:
                                                                                MainAxisSize.max,
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.end,
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              RichText(
                                                                                textScaler: MediaQuery.of(context).textScaler,
                                                                                text: TextSpan(
                                                                                  children: [
                                                                                    TextSpan(
                                                                                      text: FFLocalizations.of(context).getText(
                                                                                        '2kv89zxg' /* Qty :  */,
                                                                                      ),
                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                            fontFamily: 'SF Pro Display',
                                                                                            color: FlutterFlowTheme.of(context).secondaryText,
                                                                                            fontSize: 15.0,
                                                                                            letterSpacing: 0.0,
                                                                                            fontWeight: FontWeight.w500,
                                                                                            useGoogleFonts: false,
                                                                                          ),
                                                                                    ),
                                                                                    TextSpan(
                                                                                      text: getJsonField(
                                                                                        productListItem,
                                                                                        r'''$.quantity''',
                                                                                      ).toString(),
                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                            fontFamily: 'SF Pro Display',
                                                                                            fontSize: 15.0,
                                                                                            letterSpacing: 0.0,
                                                                                            fontWeight: FontWeight.w500,
                                                                                            useGoogleFonts: false,
                                                                                          ),
                                                                                    )
                                                                                  ],
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        fontFamily: 'SF Pro Display',
                                                                                        color: FlutterFlowTheme.of(context).primaryText,
                                                                                        fontSize: 15.0,
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FontWeight.w500,
                                                                                        useGoogleFonts: false,
                                                                                      ),
                                                                                ),
                                                                              ),
                                                                              Padding(
                                                                                padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
                                                                                child: RichText(
                                                                                  textScaler: MediaQuery.of(context).textScaler,
                                                                                  text: TextSpan(
                                                                                    children: [
                                                                                      TextSpan(
                                                                                        text: FFLocalizations.of(context).getText(
                                                                                          'rezv8r0s' /* Total :  */,
                                                                                        ),
                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                              fontFamily: 'SF Pro Display',
                                                                                              color: FlutterFlowTheme.of(context).secondaryText,
                                                                                              fontSize: 15.0,
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FontWeight.w500,
                                                                                              useGoogleFonts: false,
                                                                                            ),
                                                                                      ),
                                                                                      TextSpan(
                                                                                        text: functions.formatPrice(
                                                                                            getJsonField(
                                                                                              productListItem,
                                                                                              r'''$.subtotal''',
                                                                                            ).toString(),
                                                                                            FFAppState().thousandSeparator,
                                                                                            FFAppState().decimalSeparator,
                                                                                            FFAppState().decimalPlaces.toString(),
                                                                                            FFAppState().currencyPosition,
                                                                                            FFAppState().currency),
                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                              fontFamily: 'SF Pro Display',
                                                                                              fontSize: 15.0,
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FontWeight.w500,
                                                                                              useGoogleFonts: false,
                                                                                            ),
                                                                                      )
                                                                                    ],
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          fontFamily: 'SF Pro Display',
                                                                                          color: FlutterFlowTheme.of(context).primaryText,
                                                                                          fontSize: 15.0,
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FontWeight.w500,
                                                                                          useGoogleFonts: false,
                                                                                        ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ].divide(SizedBox(
                                                                        width:
                                                                            12.0)),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        if ('completed' ==
                                                            getJsonField(
                                                              PlantShopGroup
                                                                  .orderDetailCall
                                                                  .orderDetail(
                                                                listViewOrderDetailResponse
                                                                    .jsonBody,
                                                              ),
                                                              r'''$.status''',
                                                            ).toString())
                                                          Align(
                                                            alignment:
                                                                AlignmentDirectional(
                                                                    1.0, 0.0),
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
                                                              onTap: () async {
                                                                context
                                                                    .pushNamed(
                                                                  WriteReviewPageWidget
                                                                      .routeName,
                                                                  queryParameters:
                                                                      {
                                                                    'productDetail':
                                                                        serializeParam(
                                                                      productListItem,
                                                                      ParamType
                                                                          .JSON,
                                                                    ),
                                                                  }.withoutNulls,
                                                                );
                                                              },
                                                              child: Text(
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  'ikxgviv7' /* Rate this product now */,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .end,
                                                                maxLines: 1,
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .warning,
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
                                                                          1.5,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                      ].divide(SizedBox(
                                                          height: 24.0)),
                                                    ),
                                                  ),
                                                );
                                              })
                                                  .divide(
                                                      SizedBox(height: 12.0))
                                                  .addToStart(
                                                      SizedBox(height: 12.0))
                                                  .addToEnd(
                                                      SizedBox(height: 12.0)),
                                            );
                                          },
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryBackground,
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.all(12.0),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getText(
                                                        'cqtqt1eu' /* Billing Address */,
                                                      ),
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            fontFamily:
                                                                'SF Pro Display',
                                                            fontSize: 17.0,
                                                            letterSpacing: 0.17,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            useGoogleFonts:
                                                                false,
                                                            lineHeight: 1.5,
                                                          ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  8.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Text(
                                                        '${getJsonField(
                                                          PlantShopGroup
                                                              .orderDetailCall
                                                              .orderDetail(
                                                            listViewOrderDetailResponse
                                                                .jsonBody,
                                                          ),
                                                          r'''$.billing.address_1''',
                                                        ).toString()}, ${'' != getJsonField(
                                                              PlantShopGroup
                                                                  .orderDetailCall
                                                                  .orderDetail(
                                                                listViewOrderDetailResponse
                                                                    .jsonBody,
                                                              ),
                                                              r'''$.billing.address_2''',
                                                            ).toString() ? getJsonField(
                                                            PlantShopGroup
                                                                .orderDetailCall
                                                                .orderDetail(
                                                              listViewOrderDetailResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.billing.address_2''',
                                                          ).toString() : ''}${'' != getJsonField(
                                                              PlantShopGroup
                                                                  .orderDetailCall
                                                                  .orderDetail(
                                                                listViewOrderDetailResponse
                                                                    .jsonBody,
                                                              ),
                                                              r'''$.billing.address_2''',
                                                            ).toString() ? ', ' : ''}${getJsonField(
                                                          PlantShopGroup
                                                              .orderDetailCall
                                                              .orderDetail(
                                                            listViewOrderDetailResponse
                                                                .jsonBody,
                                                          ),
                                                          r'''$.billing.city''',
                                                        ).toString()}, ${getJsonField(
                                                          PlantShopGroup
                                                              .orderDetailCall
                                                              .orderDetail(
                                                            listViewOrderDetailResponse
                                                                .jsonBody,
                                                          ),
                                                          r'''$.billing.postcode''',
                                                        ).toString()}, ${'' != getJsonField(
                                                              PlantShopGroup
                                                                  .orderDetailCall
                                                                  .orderDetail(
                                                                listViewOrderDetailResponse
                                                                    .jsonBody,
                                                              ),
                                                              r'''$.billing.state''',
                                                            ).toString() ? getJsonField(
                                                            functions
                                                                .jsonToListConverter(
                                                                    getJsonField(
                                                                  FFAppState()
                                                                      .allCountrysList
                                                                      .where((e) =>
                                                                          getJsonField(
                                                                            PlantShopGroup.orderDetailCall.orderDetail(
                                                                              listViewOrderDetailResponse.jsonBody,
                                                                            ),
                                                                            r'''$.billing.country''',
                                                                          ) ==
                                                                          getJsonField(
                                                                            e,
                                                                            r'''$.code''',
                                                                          ))
                                                                      .toList()
                                                                      .firstOrNull,
                                                                  r'''$.states''',
                                                                  true,
                                                                )!)
                                                                .where((e) =>
                                                                    getJsonField(
                                                                      PlantShopGroup
                                                                          .orderDetailCall
                                                                          .orderDetail(
                                                                        listViewOrderDetailResponse
                                                                            .jsonBody,
                                                                      ),
                                                                      r'''$.billing.state''',
                                                                    ) ==
                                                                    getJsonField(
                                                                      e,
                                                                      r'''$.code''',
                                                                    ))
                                                                .toList()
                                                                .firstOrNull,
                                                            r'''$.name''',
                                                          ).toString() : ''}${'' != getJsonField(
                                                              PlantShopGroup
                                                                  .orderDetailCall
                                                                  .orderDetail(
                                                                listViewOrderDetailResponse
                                                                    .jsonBody,
                                                              ),
                                                              r'''$.billing.state''',
                                                            ).toString() ? ', ' : ''}${getJsonField(
                                                          FFAppState()
                                                              .allCountrysList
                                                              .where((e) =>
                                                                  getJsonField(
                                                                    PlantShopGroup
                                                                        .orderDetailCall
                                                                        .orderDetail(
                                                                      listViewOrderDetailResponse
                                                                          .jsonBody,
                                                                    ),
                                                                    r'''$.billing.country''',
                                                                  ) ==
                                                                  getJsonField(
                                                                    e,
                                                                    r'''$.code''',
                                                                  ))
                                                              .toList()
                                                              .firstOrNull,
                                                          r'''$.name''',
                                                        ).toString()}',
                                                        textAlign:
                                                            TextAlign.start,
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodyMedium
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              fontSize: 16.0,
                                                              letterSpacing:
                                                                  0.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              useGoogleFonts:
                                                                  false,
                                                              lineHeight: 1.5,
                                                            ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  8.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Text(
                                                        getJsonField(
                                                          PlantShopGroup
                                                              .orderDetailCall
                                                              .orderDetail(
                                                            listViewOrderDetailResponse
                                                                .jsonBody,
                                                          ),
                                                          r'''$.billing.phone''',
                                                        ).toString(),
                                                        textAlign:
                                                            TextAlign.start,
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodyMedium
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              fontSize: 16.0,
                                                              letterSpacing:
                                                                  0.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              useGoogleFonts:
                                                                  false,
                                                              lineHeight: 1.5,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ].divide(SizedBox(height: 12.0)),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 12.0, 0.0, 0.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Container(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryBackground,
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsets.all(12.0),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        FFLocalizations.of(
                                                                context)
                                                            .getText(
                                                          'oxdef9wj' /* Shipping Address */,
                                                        ),
                                                        textAlign:
                                                            TextAlign.start,
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodyMedium
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              fontSize: 17.0,
                                                              letterSpacing:
                                                                  0.17,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              useGoogleFonts:
                                                                  false,
                                                              lineHeight: 1.5,
                                                            ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    0.0,
                                                                    8.0,
                                                                    0.0,
                                                                    0.0),
                                                        child: Text(
                                                          '${getJsonField(
                                                            PlantShopGroup
                                                                .orderDetailCall
                                                                .orderDetail(
                                                              listViewOrderDetailResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.shipping.address_1''',
                                                          ).toString()}, ${'' != getJsonField(
                                                                PlantShopGroup
                                                                    .orderDetailCall
                                                                    .orderDetail(
                                                                  listViewOrderDetailResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.shipping.address_2''',
                                                              ).toString() ? getJsonField(
                                                              PlantShopGroup
                                                                  .orderDetailCall
                                                                  .orderDetail(
                                                                listViewOrderDetailResponse
                                                                    .jsonBody,
                                                              ),
                                                              r'''$.shipping.address_2''',
                                                            ).toString() : ''}${'' != getJsonField(
                                                                PlantShopGroup
                                                                    .orderDetailCall
                                                                    .orderDetail(
                                                                  listViewOrderDetailResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.shipping.address_2''',
                                                              ).toString() ? ', ' : ''}${getJsonField(
                                                            PlantShopGroup
                                                                .orderDetailCall
                                                                .orderDetail(
                                                              listViewOrderDetailResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.shipping.city''',
                                                          ).toString()}, ${getJsonField(
                                                            PlantShopGroup
                                                                .orderDetailCall
                                                                .orderDetail(
                                                              listViewOrderDetailResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.shipping.postcode''',
                                                          ).toString()}, ${'' != getJsonField(
                                                                PlantShopGroup
                                                                    .orderDetailCall
                                                                    .orderDetail(
                                                                  listViewOrderDetailResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.shipping.state''',
                                                              ).toString() ? getJsonField(
                                                              functions
                                                                  .jsonToListConverter(
                                                                      getJsonField(
                                                                    FFAppState()
                                                                        .allCountrysList
                                                                        .where((e) =>
                                                                            getJsonField(
                                                                              PlantShopGroup.orderDetailCall.orderDetail(
                                                                                listViewOrderDetailResponse.jsonBody,
                                                                              ),
                                                                              r'''$.shipping.country''',
                                                                            ) ==
                                                                            getJsonField(
                                                                              e,
                                                                              r'''$.code''',
                                                                            ))
                                                                        .toList()
                                                                        .firstOrNull,
                                                                    r'''$.states''',
                                                                    true,
                                                                  )!)
                                                                  .where((e) =>
                                                                      getJsonField(
                                                                        PlantShopGroup
                                                                            .orderDetailCall
                                                                            .orderDetail(
                                                                          listViewOrderDetailResponse
                                                                              .jsonBody,
                                                                        ),
                                                                        r'''$.shipping.state''',
                                                                      ) ==
                                                                      getJsonField(
                                                                        e,
                                                                        r'''$.code''',
                                                                      ))
                                                                  .toList()
                                                                  .firstOrNull,
                                                              r'''$.name''',
                                                            ).toString() : ''}${'' != getJsonField(
                                                                PlantShopGroup
                                                                    .orderDetailCall
                                                                    .orderDetail(
                                                                  listViewOrderDetailResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.shipping.state''',
                                                              ).toString() ? ', ' : ''}${getJsonField(
                                                            FFAppState()
                                                                .allCountrysList
                                                                .where((e) =>
                                                                    getJsonField(
                                                                      PlantShopGroup
                                                                          .orderDetailCall
                                                                          .orderDetail(
                                                                        listViewOrderDetailResponse
                                                                            .jsonBody,
                                                                      ),
                                                                      r'''$.shipping.country''',
                                                                    ) ==
                                                                    getJsonField(
                                                                      e,
                                                                      r'''$.code''',
                                                                    ))
                                                                .toList()
                                                                .firstOrNull,
                                                            r'''$.name''',
                                                          ).toString()}',
                                                          textAlign:
                                                              TextAlign.start,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                fontSize: 16.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                                useGoogleFonts:
                                                                    false,
                                                                lineHeight: 1.5,
                                                              ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    0.0,
                                                                    8.0,
                                                                    0.0,
                                                                    0.0),
                                                        child: Text(
                                                          getJsonField(
                                                            PlantShopGroup
                                                                .orderDetailCall
                                                                .orderDetail(
                                                              listViewOrderDetailResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.shipping.phone''',
                                                          ).toString(),
                                                          textAlign:
                                                              TextAlign.start,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                fontSize: 16.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                                useGoogleFonts:
                                                                    false,
                                                                lineHeight: 1.5,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ].divide(SizedBox(height: 12.0)),
                                          ),
                                        ),
                                        Padding(
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
                                              padding: EdgeInsets.all(12.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    FFLocalizations.of(context)
                                                        .getText(
                                                      'vs0pl8z9' /* Payment Summary */,
                                                    ),
                                                    textAlign: TextAlign.start,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          fontSize: 17.0,
                                                          letterSpacing: 0.17,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          useGoogleFonts: false,
                                                          lineHeight: 1.5,
                                                        ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 13.0,
                                                                0.0, 12.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                              'igghtok3' /* Sub Total */,
                                                            ),
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  fontSize:
                                                                      17.0,
                                                                  letterSpacing:
                                                                      0.17,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  useGoogleFonts:
                                                                      false,
                                                                  lineHeight:
                                                                      1.5,
                                                                ),
                                                          ),
                                                        ),
                                                        Text(
                                                          functions.formatPrice(
                                                              functions
                                                                  .calculateTotal(
                                                                      getJsonField(
                                                                PlantShopGroup
                                                                    .orderDetailCall
                                                                    .orderDetail(
                                                                  listViewOrderDetailResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.line_items''',
                                                                true,
                                                              )!),
                                                              FFAppState()
                                                                  .thousandSeparator,
                                                              FFAppState()
                                                                  .decimalSeparator,
                                                              FFAppState()
                                                                  .decimalPlaces
                                                                  .toString(),
                                                              FFAppState()
                                                                  .currencyPosition,
                                                              FFAppState()
                                                                  .currency),
                                                          textAlign:
                                                              TextAlign.start,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                fontSize: 17.0,
                                                                letterSpacing:
                                                                    0.17,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                useGoogleFonts:
                                                                    false,
                                                                lineHeight: 1.5,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Divider(
                                                    height: 1.0,
                                                    thickness: 1.0,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .black20,
                                                  ),
                                                  if (functions
                                                      .jsonToListConverter(
                                                          getJsonField(
                                                        PlantShopGroup
                                                            .orderDetailCall
                                                            .orderDetail(
                                                          listViewOrderDetailResponse
                                                              .jsonBody,
                                                        ),
                                                        r'''$.coupon_lines''',
                                                        true,
                                                      )!)
                                                      .isNotEmpty)
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  12.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Builder(
                                                        builder: (context) {
                                                          final couponLinesList =
                                                              getJsonField(
                                                            PlantShopGroup
                                                                .orderDetailCall
                                                                .orderDetail(
                                                              listViewOrderDetailResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.coupon_lines''',
                                                          ).toList();
                                                          _model.debugGeneratorVariables[
                                                                  'couponLinesList${couponLinesList.length > 100 ? ' (first 100)' : ''}'] =
                                                              debugSerializeParam(
                                                            couponLinesList
                                                                .take(100),
                                                            ParamType.JSON,
                                                            link:
                                                                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=OrderDetailsPage',
                                                            name: 'dynamic',
                                                            nullable: false,
                                                          );
                                                          debugLogWidgetClass(
                                                              _model);

                                                          return Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            children: List.generate(
                                                                couponLinesList
                                                                    .length,
                                                                (couponLinesListIndex) {
                                                              final couponLinesListItem =
                                                                  couponLinesList[
                                                                      couponLinesListIndex];
                                                              return Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  Expanded(
                                                                    child:
                                                                        RichText(
                                                                      textScaler:
                                                                          MediaQuery.of(context)
                                                                              .textScaler,
                                                                      text:
                                                                          TextSpan(
                                                                        children: [
                                                                          TextSpan(
                                                                            text:
                                                                                FFLocalizations.of(context).getText(
                                                                              'lb4m7i28' /* Discount :  */,
                                                                            ),
                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                  fontFamily: 'SF Pro Display',
                                                                                  fontSize: 17.0,
                                                                                  letterSpacing: 0.17,
                                                                                  fontWeight: FontWeight.w500,
                                                                                  useGoogleFonts: false,
                                                                                  lineHeight: 1.5,
                                                                                ),
                                                                          ),
                                                                          TextSpan(
                                                                            text:
                                                                                getJsonField(
                                                                              couponLinesListItem,
                                                                              r'''$.code''',
                                                                            ).toString(),
                                                                            style:
                                                                                TextStyle(
                                                                              fontFamily: 'SF Pro Display',
                                                                              color: FlutterFlowTheme.of(context).primaryText,
                                                                              fontWeight: FontWeight.w500,
                                                                              fontSize: 17.0,
                                                                              height: 1.5,
                                                                            ),
                                                                          )
                                                                        ],
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .override(
                                                                              fontFamily: 'SF Pro Display',
                                                                              fontSize: 17.0,
                                                                              letterSpacing: 0.17,
                                                                              fontWeight: FontWeight.w500,
                                                                              useGoogleFonts: false,
                                                                              lineHeight: 1.5,
                                                                            ),
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .start,
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    '- ${functions.formatPrice(getJsonField(
                                                                          couponLinesListItem,
                                                                          r'''$.discount''',
                                                                        ).toString(), FFAppState().thousandSeparator, FFAppState().decimalSeparator, FFAppState().decimalPlaces.toString(), FFAppState().currencyPosition, FFAppState().currency)}',
                                                                    textAlign:
                                                                        TextAlign
                                                                            .start,
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .override(
                                                                          fontFamily:
                                                                              'SF Pro Display',
                                                                          color:
                                                                              FlutterFlowTheme.of(context).success,
                                                                          fontSize:
                                                                              17.0,
                                                                          letterSpacing:
                                                                              0.17,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                          useGoogleFonts:
                                                                              false,
                                                                          lineHeight:
                                                                              1.5,
                                                                        ),
                                                                  ),
                                                                ],
                                                              );
                                                            }).divide(SizedBox(
                                                                height: 12.0)),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 12.0,
                                                                0.0, 0.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                              'd8us270o' /* Shipping */,
                                                            ),
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  fontSize:
                                                                      17.0,
                                                                  letterSpacing:
                                                                      0.17,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  useGoogleFonts:
                                                                      false,
                                                                  lineHeight:
                                                                      1.5,
                                                                ),
                                                          ),
                                                        ),
                                                        Text(
                                                          '+${functions.formatPrice(getJsonField(
                                                                PlantShopGroup
                                                                    .orderDetailCall
                                                                    .orderDetail(
                                                                  listViewOrderDetailResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.shipping_total''',
                                                              ).toString(), FFAppState().thousandSeparator, FFAppState().decimalSeparator, FFAppState().decimalPlaces.toString(), FFAppState().currencyPosition, FFAppState().currency)}',
                                                          textAlign:
                                                              TextAlign.start,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                                fontSize: 17.0,
                                                                letterSpacing:
                                                                    0.17,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                useGoogleFonts:
                                                                    false,
                                                                lineHeight: 1.5,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 6.0,
                                                                0.0, 12.0),
                                                    child: Builder(
                                                      builder: (context) {
                                                        final shippingList =
                                                            getJsonField(
                                                          PlantShopGroup
                                                              .orderDetailCall
                                                              .orderDetail(
                                                            listViewOrderDetailResponse
                                                                .jsonBody,
                                                          ),
                                                          r'''$.shipping_lines''',
                                                        ).toList();
                                                        _model.debugGeneratorVariables[
                                                                'shippingList${shippingList.length > 100 ? ' (first 100)' : ''}'] =
                                                            debugSerializeParam(
                                                          shippingList
                                                              .take(100),
                                                          ParamType.JSON,
                                                          link:
                                                              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=OrderDetailsPage',
                                                          name: 'dynamic',
                                                          nullable: false,
                                                        );
                                                        debugLogWidgetClass(
                                                            _model);

                                                        return Column(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: List.generate(
                                                              shippingList
                                                                  .length,
                                                              (shippingListIndex) {
                                                            final shippingListItem =
                                                                shippingList[
                                                                    shippingListIndex];
                                                            return RichText(
                                                              textScaler:
                                                                  MediaQuery.of(
                                                                          context)
                                                                      .textScaler,
                                                              text: TextSpan(
                                                                children: [
                                                                  TextSpan(
                                                                    text: FFLocalizations.of(
                                                                            context)
                                                                        .getText(
                                                                      '2zrytvyg' /* Via  */,
                                                                    ),
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .override(
                                                                          fontFamily:
                                                                              'SF Pro Display',
                                                                          fontSize:
                                                                              14.0,
                                                                          letterSpacing:
                                                                              0.14,
                                                                          fontWeight:
                                                                              FontWeight.normal,
                                                                          useGoogleFonts:
                                                                              false,
                                                                          lineHeight:
                                                                              1.5,
                                                                        ),
                                                                  ),
                                                                  TextSpan(
                                                                    text:
                                                                        getJsonField(
                                                                      shippingListItem,
                                                                      r'''$.method_title''',
                                                                    ).toString(),
                                                                    style:
                                                                        TextStyle(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                      fontSize:
                                                                          14.0,
                                                                      height:
                                                                          1.5,
                                                                    ),
                                                                  )
                                                                ],
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      fontSize:
                                                                          14.0,
                                                                      letterSpacing:
                                                                          0.14,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal,
                                                                      useGoogleFonts:
                                                                          false,
                                                                      lineHeight:
                                                                          1.5,
                                                                    ),
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                            );
                                                          }).divide(SizedBox(
                                                              height: 6.0)),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 12.0,
                                                                0.0, 0.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                              'rnty6xud' /* Tax */,
                                                            ),
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  fontSize:
                                                                      17.0,
                                                                  letterSpacing:
                                                                      0.17,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  useGoogleFonts:
                                                                      false,
                                                                  lineHeight:
                                                                      1.5,
                                                                ),
                                                          ),
                                                        ),
                                                        Text(
                                                          '+${functions.formatPrice(getJsonField(
                                                                PlantShopGroup
                                                                    .orderDetailCall
                                                                    .orderDetail(
                                                                  listViewOrderDetailResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.total_tax''',
                                                              ).toString(), FFAppState().thousandSeparator, FFAppState().decimalSeparator, FFAppState().decimalPlaces.toString(), FFAppState().currencyPosition, FFAppState().currency)}',
                                                          textAlign:
                                                              TextAlign.start,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                                fontSize: 17.0,
                                                                letterSpacing:
                                                                    0.17,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                useGoogleFonts:
                                                                    false,
                                                                lineHeight: 1.5,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 12.0,
                                                                0.0, 12.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                              '4ru38dmu' /* Refund */,
                                                            ),
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  fontSize:
                                                                      17.0,
                                                                  letterSpacing:
                                                                      0.17,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  useGoogleFonts:
                                                                      false,
                                                                  lineHeight:
                                                                      1.5,
                                                                ),
                                                          ),
                                                        ),
                                                        Text(
                                                          '-${functions.formatPrice(getJsonField(
                                                                PlantShopGroup
                                                                    .orderDetailCall
                                                                    .orderDetail(
                                                                  listViewOrderDetailResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.total''',
                                                              ).toString(), FFAppState().thousandSeparator, FFAppState().decimalSeparator, FFAppState().decimalPlaces.toString(), FFAppState().currencyPosition, FFAppState().currency)}',
                                                          textAlign:
                                                              TextAlign.start,
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                                fontSize: 17.0,
                                                                letterSpacing:
                                                                    0.17,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                useGoogleFonts:
                                                                    false,
                                                                lineHeight: 1.5,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Divider(
                                                    height: 1.0,
                                                    thickness: 1.0,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .black20,
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 16.0,
                                                                0.0, 0.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                              'va24mxdw' /* Total Payment Amount */,
                                                            ),
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  fontSize:
                                                                      17.0,
                                                                  letterSpacing:
                                                                      0.17,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  useGoogleFonts:
                                                                      false,
                                                                  lineHeight:
                                                                      1.5,
                                                                ),
                                                          ),
                                                        ),
                                                        Builder(
                                                          builder: (context) {
                                                            if ('refunded' !=
                                                                getJsonField(
                                                                  PlantShopGroup
                                                                      .orderDetailCall
                                                                      .orderDetail(
                                                                    listViewOrderDetailResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  r'''$.status''',
                                                                ).toString()) {
                                                              return Text(
                                                                functions.formatPrice(
                                                                    getJsonField(
                                                                      PlantShopGroup
                                                                          .orderDetailCall
                                                                          .orderDetail(
                                                                        listViewOrderDetailResponse
                                                                            .jsonBody,
                                                                      ),
                                                                      r'''$.total''',
                                                                    ).toString(),
                                                                    FFAppState().thousandSeparator,
                                                                    FFAppState().decimalSeparator,
                                                                    FFAppState().decimalPlaces.toString(),
                                                                    FFAppState().currencyPosition,
                                                                    FFAppState().currency),
                                                                textAlign:
                                                                    TextAlign
                                                                        .start,
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                      fontSize:
                                                                          17.0,
                                                                      letterSpacing:
                                                                          0.17,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      useGoogleFonts:
                                                                          false,
                                                                      lineHeight:
                                                                          1.5,
                                                                    ),
                                                              );
                                                            } else {
                                                              return Text(
                                                                functions.formatPrice(
                                                                    getJsonField(
                                                                      PlantShopGroup
                                                                          .orderDetailCall
                                                                          .orderDetail(
                                                                        listViewOrderDetailResponse
                                                                            .jsonBody,
                                                                      ),
                                                                      r'''$.total''',
                                                                    ).toString(),
                                                                    FFAppState().thousandSeparator,
                                                                    FFAppState().decimalSeparator,
                                                                    FFAppState().decimalPlaces.toString(),
                                                                    FFAppState().currencyPosition,
                                                                    FFAppState().currency),
                                                                textAlign:
                                                                    TextAlign
                                                                        .start,
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                      fontSize:
                                                                          17.0,
                                                                      letterSpacing:
                                                                          0.17,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      decoration:
                                                                          TextDecoration
                                                                              .lineThrough,
                                                                      useGoogleFonts:
                                                                          false,
                                                                      lineHeight:
                                                                          1.5,
                                                                    ),
                                                              );
                                                            }
                                                          },
                                                        ),
                                                        if ('refunded' ==
                                                            getJsonField(
                                                              PlantShopGroup
                                                                  .orderDetailCall
                                                                  .orderDetail(
                                                                listViewOrderDetailResponse
                                                                    .jsonBody,
                                                              ),
                                                              r'''$.status''',
                                                            ).toString())
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        4.0,
                                                                        0.0,
                                                                        0.0,
                                                                        0.0),
                                                            child: Text(
                                                              functions.formatPrice(
                                                                  '0',
                                                                  FFAppState()
                                                                      .thousandSeparator,
                                                                  FFAppState()
                                                                      .decimalSeparator,
                                                                  FFAppState()
                                                                      .decimalPlaces
                                                                      .toString(),
                                                                  FFAppState()
                                                                      .currencyPosition,
                                                                  FFAppState()
                                                                      .currency),
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
                                                                        17.0,
                                                                    letterSpacing:
                                                                        0.17,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    useGoogleFonts:
                                                                        false,
                                                                    lineHeight:
                                                                        1.5,
                                                                  ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
