import '';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/payment_images/payment_images_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'pay_for_oder_page_model.dart';
export 'pay_for_oder_page_model.dart';

class PayForOderPageWidget extends StatefulWidget {
  const PayForOderPageWidget({
    super.key,
    required this.orderDetail,
  });

  final dynamic orderDetail;

  static String routeName = 'PayForOderPage';
  static String routePath = '/payForOderPage';

  @override
  State<PayForOderPageWidget> createState() => _PayForOderPageWidgetState();
}

class _PayForOderPageWidgetState extends State<PayForOderPageWidget>
    with RouteAware {
  late PayForOderPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PayForOderPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        Future(() async {
          await action_blocks.responseAction(context);
          safeSetState(() {});
        }),
        Future(() async {
          await action_blocks.getPaymentGateways(context);
          safeSetState(() {});
        }),
      ]);
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
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).lightGray,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    wrapWithModel(
                      model: _model.mainAppbarModel,
                      updateCallback: () => safeSetState(() {}),
                      child: Builder(builder: (_) {
                        return DebugFlutterFlowModelContext(
                          rootModel: _model.rootModel,
                          child: MainAppbarWidget(
                            title: 'Pay for this order',
                            isBack: true,
                            isEdit: false,
                            backAction: () async {
                              FFAppState()
                                  .clearProductDdetailCacheKey(getJsonField(
                                widget!.orderDetail,
                                r'''$.id''',
                              ).toString());
                              _model.process = false;
                              safeSetState(() {});

                              context.goNamed(HomeMainPageWidget.routeName);

                              context.pushNamed(MyOrdersPageWidget.routeName);

                              context.pushNamed(
                                OrderDetailsPageWidget.routeName,
                                queryParameters: {
                                  'orderId': serializeParam(
                                    getJsonField(
                                      widget!.orderDetail,
                                      r'''$.id''',
                                    ),
                                    ParamType.int,
                                  ),
                                }.withoutNulls,
                              );
                            },
                            editAction: () async {
                              safeSetState(() {});
                            },
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
                                  return Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Builder(
                                          builder: (context) {
                                            final paymentGetwaysList = functions
                                                .filterPaymentList(FFAppState()
                                                    .paymentGatewaysList
                                                    .where((e) =>
                                                        (true ==
                                                            getJsonField(
                                                              e,
                                                              r'''$.enabled''',
                                                            )) &&
                                                        ('cod' !=
                                                            getJsonField(
                                                              e,
                                                              r'''$.id''',
                                                            ).toString()))
                                                    .toList())
                                                .toList();
                                            _model.debugGeneratorVariables[
                                                    'paymentGetwaysList${paymentGetwaysList.length > 100 ? ' (first 100)' : ''}'] =
                                                debugSerializeParam(
                                              paymentGetwaysList.take(100),
                                              ParamType.JSON,
                                              isList: true,
                                              link:
                                                  'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=PayForOderPage',
                                              name: 'dynamic',
                                              nullable: false,
                                            );
                                            debugLogWidgetClass(_model);

                                            return ListView.separated(
                                              padding: EdgeInsets.fromLTRB(
                                                0,
                                                12.0,
                                                0,
                                                12.0,
                                              ),
                                              scrollDirection: Axis.vertical,
                                              itemCount:
                                                  paymentGetwaysList.length,
                                              separatorBuilder: (_, __) =>
                                                  SizedBox(height: 12.0),
                                              itemBuilder: (context,
                                                  paymentGetwaysListIndex) {
                                                final paymentGetwaysListItem =
                                                    paymentGetwaysList[
                                                        paymentGetwaysListIndex];
                                                return Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          12.0, 0.0, 12.0, 0.0),
                                                  child: InkWell(
                                                    splashColor:
                                                        Colors.transparent,
                                                    focusColor:
                                                        Colors.transparent,
                                                    hoverColor:
                                                        Colors.transparent,
                                                    highlightColor:
                                                        Colors.transparent,
                                                    onTap: () async {
                                                      _model.select =
                                                          getJsonField(
                                                        paymentGetwaysListItem,
                                                        r'''$.id''',
                                                      ).toString();
                                                      _model.selectdMethod =
                                                          paymentGetwaysListItem;
                                                      safeSetState(() {});
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .primaryBackground,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12.0),
                                                      ),
                                                      child: Padding(
                                                        padding: EdgeInsets.all(
                                                            16.0),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          children: [
                                                            wrapWithModel(
                                                              model: _model
                                                                  .paymentImagesModels
                                                                  .getModel(
                                                                getJsonField(
                                                                  paymentGetwaysListItem,
                                                                  r'''$.id''',
                                                                ).toString(),
                                                                paymentGetwaysListIndex,
                                                              ),
                                                              updateCallback: () =>
                                                                  safeSetState(
                                                                      () {}),
                                                              child: Builder(
                                                                  builder: (_) {
                                                                return DebugFlutterFlowModelContext(
                                                                  rootModel: _model
                                                                      .rootModel,
                                                                  child:
                                                                      PaymentImagesWidget(
                                                                    key: Key(
                                                                      'Key1al_${getJsonField(
                                                                        paymentGetwaysListItem,
                                                                        r'''$.id''',
                                                                      ).toString()}',
                                                                    ),
                                                                    id: getJsonField(
                                                                      paymentGetwaysListItem,
                                                                      r'''$.id''',
                                                                    ).toString(),
                                                                  ),
                                                                );
                                                              }),
                                                            ),
                                                            Expanded(
                                                              child: Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            16.0,
                                                                            0.0,
                                                                            0.0,
                                                                            0.0),
                                                                child: Text(
                                                                  getJsonField(
                                                                    paymentGetwaysListItem,
                                                                    r'''$.method_title''',
                                                                  ).toString(),
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
                                                              ),
                                                            ),
                                                            Builder(
                                                              builder:
                                                                  (context) {
                                                                if (_model
                                                                        .select ==
                                                                    getJsonField(
                                                                      paymentGetwaysListItem,
                                                                      r'''$.id''',
                                                                    ).toString()) {
                                                                  return Container(
                                                                    width: 24.0,
                                                                    height:
                                                                        24.0,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      border:
                                                                          Border
                                                                              .all(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primary,
                                                                        width:
                                                                            1.0,
                                                                      ),
                                                                    ),
                                                                    alignment:
                                                                        AlignmentDirectional(
                                                                            0.0,
                                                                            0.0),
                                                                    child:
                                                                        Container(
                                                                      width:
                                                                          14.0,
                                                                      height:
                                                                          14.0,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primary,
                                                                        shape: BoxShape
                                                                            .circle,
                                                                      ),
                                                                    ),
                                                                  );
                                                                } else {
                                                                  return Container(
                                                                    width: 24.0,
                                                                    height:
                                                                        24.0,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      border:
                                                                          Border
                                                                              .all(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .black20,
                                                                        width:
                                                                            1.0,
                                                                      ),
                                                                    ),
                                                                  );
                                                                }
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                      Align(
                                        alignment:
                                            AlignmentDirectional(0.0, 1.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .primaryBackground,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
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
                                                          'v1gllvl6' /* Total */,
                                                        ),
                                                        textAlign:
                                                            TextAlign.start,
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodyMedium
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              fontSize: 12.0,
                                                              letterSpacing:
                                                                  0.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              useGoogleFonts:
                                                                  false,
                                                            ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    0.0,
                                                                    2.0,
                                                                    0.0,
                                                                    0.0),
                                                        child: Text(
                                                          functions.formatPrice(
                                                              getJsonField(
                                                                widget!
                                                                    .orderDetail,
                                                                r'''$.total''',
                                                              ).toString(),
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
                                                                fontSize: 18.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                useGoogleFonts:
                                                                    false,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Builder(
                                                  builder: (context) {
                                                    if (_model.isBack) {
                                                      return Padding(
                                                        padding: EdgeInsets.all(
                                                            12.0),
                                                        child: FFButtonWidget(
                                                          onPressed: () async {
                                                            FFAppState()
                                                                .clearProductDdetailCacheKey(
                                                                    getJsonField(
                                                              widget!
                                                                  .orderDetail,
                                                              r'''$.id''',
                                                            ).toString());
                                                            _model.process =
                                                                false;
                                                            safeSetState(() {});

                                                            context.goNamed(
                                                                HomeMainPageWidget
                                                                    .routeName);

                                                            context.pushNamed(
                                                                MyOrdersPageWidget
                                                                    .routeName);

                                                            context.pushNamed(
                                                              OrderDetailsPageWidget
                                                                  .routeName,
                                                              queryParameters: {
                                                                'orderId':
                                                                    serializeParam(
                                                                  getJsonField(
                                                                    widget!
                                                                        .orderDetail,
                                                                    r'''$.id''',
                                                                  ),
                                                                  ParamType.int,
                                                                ),
                                                              }.withoutNulls,
                                                            );
                                                          },
                                                          text: FFLocalizations
                                                                  .of(context)
                                                              .getText(
                                                            'embgk3cg' /* Back */,
                                                          ),
                                                          options:
                                                              FFButtonOptions(
                                                            height: 56.0,
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        24.0,
                                                                        0.0,
                                                                        24.0,
                                                                        0.0),
                                                            iconPadding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        0.0,
                                                                        0.0,
                                                                        0.0),
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primary,
                                                            textStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleSmall
                                                                    .override(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryBackground,
                                                                      fontSize:
                                                                          18.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      useGoogleFonts:
                                                                          false,
                                                                    ),
                                                            elevation: 0.0,
                                                            borderSide:
                                                                BorderSide(
                                                              color: Colors
                                                                  .transparent,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          showLoadingIndicator:
                                                              false,
                                                        ),
                                                      );
                                                    } else {
                                                      return Padding(
                                                        padding: EdgeInsets.all(
                                                            12.0),
                                                        child: FFButtonWidget(
                                                          onPressed: () async {
                                                            if (_model.isBack) {
                                                              FFAppState()
                                                                  .clearProductDdetailCacheKey(
                                                                      getJsonField(
                                                                widget!
                                                                    .orderDetail,
                                                                r'''$.id''',
                                                              ).toString());
                                                              _model.process =
                                                                  false;
                                                              safeSetState(
                                                                  () {});

                                                              context.goNamed(
                                                                  HomeMainPageWidget
                                                                      .routeName);

                                                              context.pushNamed(
                                                                  MyOrdersPageWidget
                                                                      .routeName);

                                                              context.pushNamed(
                                                                OrderDetailsPageWidget
                                                                    .routeName,
                                                                queryParameters:
                                                                    {
                                                                  'orderId':
                                                                      serializeParam(
                                                                    getJsonField(
                                                                      widget!
                                                                          .orderDetail,
                                                                      r'''$.id''',
                                                                    ),
                                                                    ParamType
                                                                        .int,
                                                                  ),
                                                                }.withoutNulls,
                                                              );
                                                            } else {
                                                              _model.process =
                                                                  true;
                                                              safeSetState(
                                                                  () {});
                                                              if (_model
                                                                      .select ==
                                                                  'razorpay') {
                                                                await actions
                                                                    .razorpayCustom(
                                                                  context,
                                                                  getJsonField(
                                                                    _model
                                                                        .selectdMethod,
                                                                    r'''$.settings.key_id.value''',
                                                                  ).toString(),
                                                                  getJsonField(
                                                                    widget!
                                                                        .orderDetail,
                                                                    r'''$.total''',
                                                                  ).toString(),
                                                                  FFAppState()
                                                                      .currencyCode,
                                                                  getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.username''',
                                                                  ).toString(),
                                                                  'Order using razorpay to byu a product',
                                                                  getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.billing.phone''',
                                                                  ).toString(),
                                                                  getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.billing.email''',
                                                                  ).toString(),
                                                                  (transactionId) async {
                                                                    _model.sucessRazorPay =
                                                                        await action_blocks
                                                                            .updateStatus(
                                                                      context,
                                                                      productDetail:
                                                                          widget!
                                                                              .orderDetail,
                                                                      status:
                                                                          'processing',
                                                                    );
                                                                    if (_model
                                                                        .sucessRazorPay!) {
                                                                      FFAppState()
                                                                          .clearOrderDetailCacheKey(
                                                                              getJsonField(
                                                                        widget!
                                                                            .orderDetail,
                                                                        r'''$.id''',
                                                                      ).toString());
                                                                      _model.process =
                                                                          false;
                                                                      safeSetState(
                                                                          () {});

                                                                      context.goNamed(
                                                                          HomeMainPageWidget
                                                                              .routeName);

                                                                      context.pushNamed(
                                                                          MyOrdersPageWidget
                                                                              .routeName);

                                                                      context
                                                                          .pushNamed(
                                                                        OrderDetailsPageWidget
                                                                            .routeName,
                                                                        queryParameters:
                                                                            {
                                                                          'orderId':
                                                                              serializeParam(
                                                                            getJsonField(
                                                                              widget!.orderDetail,
                                                                              r'''$.id''',
                                                                            ),
                                                                            ParamType.int,
                                                                          ),
                                                                        }.withoutNulls,
                                                                      );
                                                                    } else {
                                                                      _model.process =
                                                                          false;
                                                                      safeSetState(
                                                                          () {});
                                                                    }
                                                                  },
                                                                  (transactionId) async {
                                                                    await actions
                                                                        .showCustomToastAddtoCart(
                                                                      context,
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getVariableText(
                                                                        enText:
                                                                            'Payment failed please try again!',
                                                                        arText:
                                                                            'فشل الدفع يرجى المحاولة مرة أخرى!',
                                                                      ),
                                                                      false,
                                                                      () async {},
                                                                    );
                                                                    _model.process =
                                                                        false;
                                                                    safeSetState(
                                                                        () {});
                                                                  },
                                                                  () async {
                                                                    await actions
                                                                        .showCustomToastAddtoCart(
                                                                      context,
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getVariableText(
                                                                        enText:
                                                                            'Payment failed please try again!',
                                                                        arText:
                                                                            'فشل الدفع يرجى المحاولة مرة أخرى!',
                                                                      ),
                                                                      false,
                                                                      () async {},
                                                                    );
                                                                    _model.process =
                                                                        false;
                                                                    safeSetState(
                                                                        () {});
                                                                  },
                                                                );
                                                              } else if (_model
                                                                      .select ==
                                                                  'stripe') {
                                                                await actions
                                                                    .initStripe(
                                                                  'yes' ==
                                                                          getJsonField(
                                                                            _model.selectdMethod,
                                                                            r'''$.settings.testmode.value''',
                                                                          ).toString()
                                                                      ? getJsonField(
                                                                          _model
                                                                              .selectdMethod,
                                                                          r'''$.settings.test_publishable_key.value''',
                                                                        ).toString()
                                                                      : getJsonField(
                                                                          _model
                                                                              .selectdMethod,
                                                                          r'''$.settings.publishable_key.value''',
                                                                        ).toString(),
                                                                );
                                                                await actions
                                                                    .stripeCustom(
                                                                  context,
                                                                  getJsonField(
                                                                    widget!
                                                                        .orderDetail,
                                                                    r'''$.total''',
                                                                  ).toString(),
                                                                  FFAppState()
                                                                      .currencyCode,
                                                                  getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.billing.country''',
                                                                  ).toString(),
                                                                  (transactionId) async {
                                                                    _model.sucessStripe =
                                                                        await action_blocks
                                                                            .updateStatus(
                                                                      context,
                                                                      productDetail:
                                                                          widget!
                                                                              .orderDetail,
                                                                      status:
                                                                          'processing',
                                                                    );
                                                                    if (_model
                                                                        .sucessStripe!) {
                                                                      FFAppState()
                                                                          .clearOrderDetailCacheKey(
                                                                              getJsonField(
                                                                        widget!
                                                                            .orderDetail,
                                                                        r'''$.id''',
                                                                      ).toString());
                                                                      _model.process =
                                                                          false;
                                                                      safeSetState(
                                                                          () {});

                                                                      context.goNamed(
                                                                          HomeMainPageWidget
                                                                              .routeName);

                                                                      context.pushNamed(
                                                                          MyOrdersPageWidget
                                                                              .routeName);

                                                                      context
                                                                          .pushNamed(
                                                                        OrderDetailsPageWidget
                                                                            .routeName,
                                                                        queryParameters:
                                                                            {
                                                                          'orderId':
                                                                              serializeParam(
                                                                            getJsonField(
                                                                              widget!.orderDetail,
                                                                              r'''$.id''',
                                                                            ),
                                                                            ParamType.int,
                                                                          ),
                                                                        }.withoutNulls,
                                                                      );
                                                                    } else {
                                                                      _model.process =
                                                                          false;
                                                                      safeSetState(
                                                                          () {});
                                                                    }
                                                                  },
                                                                  (transactionId) async {
                                                                    await actions
                                                                        .showCustomToastAddtoCart(
                                                                      context,
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getVariableText(
                                                                        enText:
                                                                            'Payment failed please try again!',
                                                                        arText:
                                                                            'فشل الدفع يرجى المحاولة مرة أخرى!',
                                                                      ),
                                                                      false,
                                                                      () async {},
                                                                    );
                                                                    _model.process =
                                                                        false;
                                                                    safeSetState(
                                                                        () {});
                                                                  },
                                                                  'yes' ==
                                                                          getJsonField(
                                                                            _model.selectdMethod,
                                                                            r'''$.settings.testmode.value''',
                                                                          ).toString()
                                                                      ? getJsonField(
                                                                          _model
                                                                              .selectdMethod,
                                                                          r'''$.settings.test_secret_key.value''',
                                                                        ).toString()
                                                                      : getJsonField(
                                                                          _model
                                                                              .selectdMethod,
                                                                          r'''$.settings.secret_key.value''',
                                                                        ).toString(),
                                                                  () async {
                                                                    await actions
                                                                        .showCustomToastAddtoCart(
                                                                      context,
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getVariableText(
                                                                        enText:
                                                                            'Payment failed please try again!',
                                                                        arText:
                                                                            'فشل الدفع يرجى المحاولة مرة أخرى!',
                                                                      ),
                                                                      false,
                                                                      () async {},
                                                                    );
                                                                    _model.process =
                                                                        false;
                                                                    safeSetState(
                                                                        () {});
                                                                  },
                                                                );
                                                              } else if (_model
                                                                      .select ==
                                                                  'ppcp-gateway') {
                                                                await actions
                                                                    .paypalCustom(
                                                                  context,
                                                                  'AU9rVln8yvfm2UjNMWQKpcLwtAXfpDCg-Q_VlvB36I3u9T938qw25cNkqvzKQ78gmFT2Cwx60KdteEFN',
                                                                  'EL7Wo0g7CYfYqbSRJxNDvIx9X2IgID5U6mXqEvkTKXXrGHbsMSZ7DpIC39KDmLnzOoHAy4fG02pthApQ',
                                                                  getJsonField(
                                                                    widget!
                                                                        .orderDetail,
                                                                    r'''$.total''',
                                                                  ).toString(),
                                                                  FFAppState()
                                                                      .currencyCode,
                                                                  'Order using paypal to byu a product',
                                                                  (transactionId) async {
                                                                    _model.sucessPayPal =
                                                                        await action_blocks
                                                                            .updateStatus(
                                                                      context,
                                                                      productDetail:
                                                                          widget!
                                                                              .orderDetail,
                                                                      status:
                                                                          'processing',
                                                                    );
                                                                    if (_model
                                                                        .sucessPayPal!) {
                                                                      FFAppState()
                                                                          .clearOrderDetailCacheKey(
                                                                              getJsonField(
                                                                        widget!
                                                                            .orderDetail,
                                                                        r'''$.id''',
                                                                      ).toString());
                                                                      _model.process =
                                                                          false;
                                                                      safeSetState(
                                                                          () {});

                                                                      context.goNamed(
                                                                          HomeMainPageWidget
                                                                              .routeName);

                                                                      context.pushNamed(
                                                                          MyOrdersPageWidget
                                                                              .routeName);

                                                                      context
                                                                          .pushNamed(
                                                                        OrderDetailsPageWidget
                                                                            .routeName,
                                                                        queryParameters:
                                                                            {
                                                                          'orderId':
                                                                              serializeParam(
                                                                            getJsonField(
                                                                              widget!.orderDetail,
                                                                              r'''$.id''',
                                                                            ),
                                                                            ParamType.int,
                                                                          ),
                                                                        }.withoutNulls,
                                                                      );
                                                                    } else {
                                                                      _model.process =
                                                                          false;
                                                                      safeSetState(
                                                                          () {});
                                                                    }
                                                                  },
                                                                  (transactionId) async {
                                                                    await actions
                                                                        .showCustomToastAddtoCart(
                                                                      context,
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getVariableText(
                                                                        enText:
                                                                            'Payment failed please try again!',
                                                                        arText:
                                                                            'فشل الدفع يرجى المحاولة مرة أخرى!',
                                                                      ),
                                                                      false,
                                                                      () async {},
                                                                    );
                                                                    _model.process =
                                                                        false;
                                                                    safeSetState(
                                                                        () {});
                                                                  },
                                                                  () async {
                                                                    await actions
                                                                        .showCustomToastAddtoCart(
                                                                      context,
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getVariableText(
                                                                        enText:
                                                                            'Payment failed please try again!',
                                                                        arText:
                                                                            'فشل الدفع يرجى المحاولة مرة أخرى!',
                                                                      ),
                                                                      false,
                                                                      () async {},
                                                                    );
                                                                    _model.process =
                                                                        false;
                                                                    safeSetState(
                                                                        () {});
                                                                  },
                                                                );
                                                              } else if (_model
                                                                      .select ==
                                                                  'webview') {
                                                                _model.process =
                                                                    false;
                                                                _model.isBack =
                                                                    true;
                                                                safeSetState(
                                                                    () {});
                                                                await launchURL(
                                                                    getJsonField(
                                                                  widget!
                                                                      .orderDetail,
                                                                  r'''$.payment_url''',
                                                                ).toString());
                                                              } else {
                                                                await actions
                                                                    .showCustomToastTop(
                                                                  FFLocalizations.of(
                                                                          context)
                                                                      .getVariableText(
                                                                    enText:
                                                                        'Please select payment method!',
                                                                    arText:
                                                                        'الرجاء تحديد طريقة الدفع!',
                                                                  ),
                                                                );
                                                                _model.process =
                                                                    false;
                                                                safeSetState(
                                                                    () {});
                                                              }
                                                            }

                                                            safeSetState(() {});
                                                          },
                                                          text: FFLocalizations
                                                                  .of(context)
                                                              .getText(
                                                            'pjf0n0dp' /* Pay For This Order */,
                                                          ),
                                                          options:
                                                              FFButtonOptions(
                                                            height: 56.0,
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        24.0,
                                                                        0.0,
                                                                        24.0,
                                                                        0.0),
                                                            iconPadding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        0.0,
                                                                        0.0,
                                                                        0.0),
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primary,
                                                            textStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleSmall
                                                                    .override(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryBackground,
                                                                      fontSize:
                                                                          18.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      useGoogleFonts:
                                                                          false,
                                                                    ),
                                                            elevation: 0.0,
                                                            borderSide:
                                                                BorderSide(
                                                              color: Colors
                                                                  .transparent,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          showLoadingIndicator:
                                                              false,
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
                                    ],
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
              if (_model.process)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0x67DFEAE2),
                  ),
                  child: Align(
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Container(
                      width: 40.0,
                      height: 40.0,
                      child: custom_widgets.CirculatIndicator(
                        width: 40.0,
                        height: 40.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
