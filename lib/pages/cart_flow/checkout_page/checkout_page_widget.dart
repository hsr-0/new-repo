import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/payment_images/payment_images_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/empty_components/no_payment_methodes_component/no_payment_methodes_component_widget.dart';
import '/pages/shimmer/cart_shimmer/cart_shimmer_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:styled_divider/styled_divider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'checkout_page_model.dart';
export 'checkout_page_model.dart';

class CheckoutPageWidget extends StatefulWidget {
  const CheckoutPageWidget({super.key});

  static String routeName = 'CheckoutPage';
  static String routePath = '/checkoutPage';

  @override
  State<CheckoutPageWidget> createState() => _CheckoutPageWidgetState();
}

class _CheckoutPageWidgetState extends State<CheckoutPageWidget>
    with RouteAware {
  late CheckoutPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CheckoutPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await action_blocks.responseAction(context);
      safeSetState(() {});
    });

    _model.textController ??= TextEditingController()
      ..addListener(() {
        debugLogWidgetClass(_model);
      });
    _model.textFieldFocusNode ??= FocusNode();
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
                              'qnae2am5' /* Checkout */,
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
                                        .cart(
                                      requestFn: () =>
                                          PlantShopGroup.getCartCall.call(
                                        token: FFAppState().token,
                                      ),
                                    )
                                        .then((result) {
                                      _model.apiRequestCompleted = true;
                                      return result;
                                    }),
                                    builder: (context, snapshot) {
                                      // Customize what your widget looks like when it's loading.
                                      if (!snapshot.hasData) {
                                        return CartShimmerWidget();
                                      }
                                      final cartGetCartResponse =
                                          snapshot.data!;
                                      _model.debugBackendQueries[
                                              'PlantShopGroup.getCartCall_statusCode_Container_64z9716f'] =
                                          debugSerializeParam(
                                        cartGetCartResponse.statusCode,
                                        ParamType.int,
                                        link:
                                            'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
                                        name: 'int',
                                        nullable: false,
                                      );
                                      _model.debugBackendQueries[
                                              'PlantShopGroup.getCartCall_responseBody_Container_64z9716f'] =
                                          debugSerializeParam(
                                        cartGetCartResponse.bodyText,
                                        ParamType.String,
                                        link:
                                            'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
                                        name: 'String',
                                        nullable: false,
                                      );
                                      debugLogWidgetClass(_model);

                                      return Container(
                                        decoration: BoxDecoration(),
                                        child: Stack(
                                          children: [
                                            RefreshIndicator(
                                              key: Key(
                                                  'RefreshIndicator_ww16bb63'),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              onRefresh: () async {
                                                safeSetState(() {
                                                  FFAppState().clearCartCache();
                                                  _model.apiRequestCompleted =
                                                      false;
                                                });
                                                await _model
                                                    .waitForApiRequestCompleted();
                                                await action_blocks
                                                    .cartItemCount(context);
                                                safeSetState(() {});
                                              },
                                              child: ListView(
                                                padding: EdgeInsets.fromLTRB(
                                                  0,
                                                  12.0,
                                                  0,
                                                  92.0,
                                                ),
                                                scrollDirection: Axis.vertical,
                                                children: [
                                                  Container(
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .primaryBackground,
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  90.0,
                                                                  10.0,
                                                                  90.0,
                                                                  14.0),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            children: [
                                                              Container(
                                                                width: 40.0,
                                                                height: 40.0,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondary,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                                child: Align(
                                                                  alignment:
                                                                      AlignmentDirectional(
                                                                          0.0,
                                                                          0.0),
                                                                  child: Icon(
                                                                    Icons
                                                                        .shopping_cart,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
                                                                    size: 20.0,
                                                                  ),
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            5.0,
                                                                            0.0,
                                                                            0.0),
                                                                child: Text(
                                                                  FFLocalizations.of(
                                                                          context)
                                                                      .getText(
                                                                    '3z9g83vu' /* My Cart */,
                                                                  ),
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
                                                                            14.0,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        useGoogleFonts:
                                                                            false,
                                                                        lineHeight:
                                                                            1.5,
                                                                      ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Expanded(
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          19.0,
                                                                          0.0,
                                                                          0.0),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  StyledDivider(
                                                                    height: 1.0,
                                                                    thickness:
                                                                        0.0,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
                                                                    lineStyle:
                                                                        DividerLineStyle
                                                                            .dashed,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            children: [
                                                              Container(
                                                                width: 40.0,
                                                                height: 40.0,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondary,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                                child: Align(
                                                                  alignment:
                                                                      AlignmentDirectional(
                                                                          0.0,
                                                                          0.0),
                                                                  child: Icon(
                                                                    Icons
                                                                        .payments_rounded,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
                                                                    size: 20.0,
                                                                  ),
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            5.0,
                                                                            0.0,
                                                                            0.0),
                                                                child: Text(
                                                                  FFLocalizations.of(
                                                                          context)
                                                                      .getText(
                                                                    'ds81gy5k' /* Payment */,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .start,
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        fontFamily:
                                                                            'SF Pro Display',
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryText,
                                                                        fontSize:
                                                                            14.0,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        useGoogleFonts:
                                                                            false,
                                                                        lineHeight:
                                                                            1.5,
                                                                      ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Builder(
                                                    builder: (context) {
                                                      if (('' ==
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .getCartCall
                                                                    .billingAddress(
                                                                  cartGetCartResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.first_name''',
                                                              ).toString()) ||
                                                          ('' ==
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .getCartCall
                                                                    .billingAddress(
                                                                  cartGetCartResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.last_name''',
                                                              ).toString()) ||
                                                          ('' ==
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .getCartCall
                                                                    .billingAddress(
                                                                  cartGetCartResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.address_1''',
                                                              ).toString()) ||
                                                          ('' ==
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .getCartCall
                                                                    .billingAddress(
                                                                  cartGetCartResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.city''',
                                                              ).toString()) ||
                                                          ('' ==
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .getCartCall
                                                                    .billingAddress(
                                                                  cartGetCartResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.postcode''',
                                                              ).toString()) ||
                                                          ('' ==
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .getCartCall
                                                                    .billingAddress(
                                                                  cartGetCartResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.country''',
                                                              ).toString()) ||
                                                          ('' ==
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .getCartCall
                                                                    .billingAddress(
                                                                  cartGetCartResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.phone''',
                                                              ).toString())) {
                                                        return Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      0.0,
                                                                      12.0,
                                                                      0.0,
                                                                      0.0),
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
                                                              context.pushNamed(
                                                                AddAddressPageWidget
                                                                    .routeName,
                                                                queryParameters:
                                                                    {
                                                                  'isEdit':
                                                                      serializeParam(
                                                                    false,
                                                                    ParamType
                                                                        .bool,
                                                                  ),
                                                                  'isShipping':
                                                                      serializeParam(
                                                                    false,
                                                                    ParamType
                                                                        .bool,
                                                                  ),
                                                                  'address':
                                                                      serializeParam(
                                                                    PlantShopGroup
                                                                        .getCartCall
                                                                        .billingAddress(
                                                                      cartGetCartResponse
                                                                          .jsonBody,
                                                                    ),
                                                                    ParamType
                                                                        .JSON,
                                                                  ),
                                                                }.withoutNulls,
                                                              );
                                                            },
                                                            child: Container(
                                                              width: double
                                                                  .infinity,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryBackground,
                                                              ),
                                                              child: Padding(
                                                                padding: EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        32.0,
                                                                        0.0,
                                                                        32.0),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          12.0,
                                                                          0.0),
                                                                      child: SvgPicture
                                                                          .asset(
                                                                        'assets/images/add-square.svg',
                                                                        width:
                                                                            24.0,
                                                                        height:
                                                                            24.0,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        '6428nib9' /* Add new address */,
                                                                      ),
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
                                                                                18.0,
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
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        return Padding(
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
                                                                  .secondaryBackground,
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          12.0,
                                                                          6.0,
                                                                          6.0,
                                                                          12.0),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    children: [
                                                                      Expanded(
                                                                        child:
                                                                            Padding(
                                                                          padding: EdgeInsetsDirectional.fromSTEB(
                                                                              0.0,
                                                                              6.0,
                                                                              0.0,
                                                                              0.0),
                                                                          child:
                                                                              Text(
                                                                            FFLocalizations.of(context).getText(
                                                                              'qifs2i4m' /* Billing Address */,
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.start,
                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                  fontFamily: 'SF Pro Display',
                                                                                  fontSize: 18.0,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FontWeight.w600,
                                                                                  useGoogleFonts: false,
                                                                                  lineHeight: 1.5,
                                                                                ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            6.0,
                                                                            0.0,
                                                                            0.0),
                                                                        child:
                                                                            Text(
                                                                          FFLocalizations.of(context)
                                                                              .getText(
                                                                            '2spvicj3' /* Default */,
                                                                          ),
                                                                          textAlign:
                                                                              TextAlign.start,
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .override(
                                                                                fontFamily: 'SF Pro Display',
                                                                                color: FlutterFlowTheme.of(context).success,
                                                                                fontSize: 16.0,
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FontWeight.normal,
                                                                                useGoogleFonts: false,
                                                                                lineHeight: 1.5,
                                                                              ),
                                                                        ),
                                                                      ),
                                                                      Container(
                                                                        width:
                                                                            6.0,
                                                                        decoration:
                                                                            BoxDecoration(),
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
                                                                          context
                                                                              .pushNamed(
                                                                            AddAddressPageWidget.routeName,
                                                                            queryParameters:
                                                                                {
                                                                              'isEdit': serializeParam(
                                                                                true,
                                                                                ParamType.bool,
                                                                              ),
                                                                              'isShipping': serializeParam(
                                                                                false,
                                                                                ParamType.bool,
                                                                              ),
                                                                              'address': serializeParam(
                                                                                PlantShopGroup.getCartCall.billingAddress(
                                                                                  cartGetCartResponse.jsonBody,
                                                                                ),
                                                                                ParamType.JSON,
                                                                              ),
                                                                            }.withoutNulls,
                                                                          );
                                                                        },
                                                                        child:
                                                                            Container(
                                                                          decoration:
                                                                              BoxDecoration(),
                                                                          child:
                                                                              Padding(
                                                                            padding:
                                                                                EdgeInsets.all(6.0),
                                                                            child:
                                                                                ClipRRect(
                                                                              borderRadius: BorderRadius.circular(0.0),
                                                                              child: SvgPicture.asset(
                                                                                'assets/images/edit.svg',
                                                                                width: 20.0,
                                                                                height: 20.0,
                                                                                fit: BoxFit.cover,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            4.0,
                                                                            0.0,
                                                                            4.0),
                                                                    child: Text(
                                                                      '${getJsonField(
                                                                        PlantShopGroup
                                                                            .getCartCall
                                                                            .billingAddress(
                                                                          cartGetCartResponse
                                                                              .jsonBody,
                                                                        ),
                                                                        r'''$.address_1''',
                                                                      ).toString()}, ${'' != getJsonField(
                                                                            PlantShopGroup.getCartCall.billingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.address_2''',
                                                                          ).toString() ? getJsonField(
                                                                          PlantShopGroup
                                                                              .getCartCall
                                                                              .billingAddress(
                                                                            cartGetCartResponse.jsonBody,
                                                                          ),
                                                                          r'''$.address_2''',
                                                                        ).toString() : ''}${'' != getJsonField(
                                                                            PlantShopGroup.getCartCall.billingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.address_2''',
                                                                          ).toString() ? ', ' : ''}${getJsonField(
                                                                        PlantShopGroup
                                                                            .getCartCall
                                                                            .billingAddress(
                                                                          cartGetCartResponse
                                                                              .jsonBody,
                                                                        ),
                                                                        r'''$.city''',
                                                                      ).toString()}, ${getJsonField(
                                                                        PlantShopGroup
                                                                            .getCartCall
                                                                            .billingAddress(
                                                                          cartGetCartResponse
                                                                              .jsonBody,
                                                                        ),
                                                                        r'''$.postcode''',
                                                                      ).toString()}, ${'' != getJsonField(
                                                                            PlantShopGroup.getCartCall.billingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.state''',
                                                                          ).toString() ? getJsonField(
                                                                          functions
                                                                              .jsonToListConverter(getJsonField(
                                                                                FFAppState()
                                                                                    .allCountrysList
                                                                                    .where((e) =>
                                                                                        getJsonField(
                                                                                          PlantShopGroup.getCartCall.billingAddress(
                                                                                            cartGetCartResponse.jsonBody,
                                                                                          ),
                                                                                          r'''$.country''',
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
                                                                                    PlantShopGroup.getCartCall.billingAddress(
                                                                                      cartGetCartResponse.jsonBody,
                                                                                    ),
                                                                                    r'''$.state''',
                                                                                  ) ==
                                                                                  getJsonField(
                                                                                    e,
                                                                                    r'''$.code''',
                                                                                  ))
                                                                              .toList()
                                                                              .firstOrNull,
                                                                          r'''$.name''',
                                                                        ).toString() : ''}${'' != getJsonField(
                                                                            PlantShopGroup.getCartCall.billingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.state''',
                                                                          ).toString() ? ', ' : ''}${getJsonField(
                                                                        FFAppState()
                                                                            .allCountrysList
                                                                            .where((e) =>
                                                                                getJsonField(
                                                                                  PlantShopGroup.getCartCall.billingAddress(
                                                                                    cartGetCartResponse.jsonBody,
                                                                                  ),
                                                                                  r'''$.country''',
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
                                                                                FontWeight.normal,
                                                                            useGoogleFonts:
                                                                                false,
                                                                            lineHeight:
                                                                                1.5,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    getJsonField(
                                                                      PlantShopGroup
                                                                          .getCartCall
                                                                          .billingAddress(
                                                                        cartGetCartResponse
                                                                            .jsonBody,
                                                                      ),
                                                                      r'''$.phone''',
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
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                  if (!(('' ==
                                                          getJsonField(
                                                            PlantShopGroup
                                                                .getCartCall
                                                                .billingAddress(
                                                              cartGetCartResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.first_name''',
                                                          ).toString()) ||
                                                      ('' ==
                                                          getJsonField(
                                                            PlantShopGroup
                                                                .getCartCall
                                                                .billingAddress(
                                                              cartGetCartResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.last_name''',
                                                          ).toString()) ||
                                                      ('' ==
                                                          getJsonField(
                                                            PlantShopGroup
                                                                .getCartCall
                                                                .billingAddress(
                                                              cartGetCartResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.address_1''',
                                                          ).toString()) ||
                                                      ('' ==
                                                          getJsonField(
                                                            PlantShopGroup
                                                                .getCartCall
                                                                .billingAddress(
                                                              cartGetCartResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.city''',
                                                          ).toString()) ||
                                                      ('' ==
                                                          getJsonField(
                                                            PlantShopGroup
                                                                .getCartCall
                                                                .billingAddress(
                                                              cartGetCartResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.postcode''',
                                                          ).toString()) ||
                                                      ('' ==
                                                          getJsonField(
                                                            PlantShopGroup
                                                                .getCartCall
                                                                .billingAddress(
                                                              cartGetCartResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.country''',
                                                          ).toString()) ||
                                                      ('' ==
                                                          getJsonField(
                                                            PlantShopGroup
                                                                .getCartCall
                                                                .billingAddress(
                                                              cartGetCartResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.phone''',
                                                          ).toString())))
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  12.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Container(
                                                        width: double.infinity,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryBackground,
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      12.0,
                                                                      6.0,
                                                                      6.0,
                                                                      12.0),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  Expanded(
                                                                    child:
                                                                        Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          6.0,
                                                                          0.0,
                                                                          0.0),
                                                                      child:
                                                                          Text(
                                                                        FFLocalizations.of(context)
                                                                            .getText(
                                                                          '9my8c7k5' /* Shipping Address */,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.start,
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
                                                                    ),
                                                                  ),
                                                                  if (!(('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.first_name''',
                                                                          ).toString()) ||
                                                                      ('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.last_name''',
                                                                          ).toString()) ||
                                                                      ('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.address_1''',
                                                                          ).toString()) ||
                                                                      ('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.city''',
                                                                          ).toString()) ||
                                                                      ('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.postcode''',
                                                                          ).toString()) ||
                                                                      ('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.country''',
                                                                          ).toString()) ||
                                                                      ('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.phone''',
                                                                          ).toString())))
                                                                    InkWell(
                                                                      splashColor:
                                                                          Colors
                                                                              .transparent,
                                                                      focusColor:
                                                                          Colors
                                                                              .transparent,
                                                                      hoverColor:
                                                                          Colors
                                                                              .transparent,
                                                                      highlightColor:
                                                                          Colors
                                                                              .transparent,
                                                                      onTap:
                                                                          () async {
                                                                        if (_model
                                                                            .differentShip) {
                                                                          context
                                                                              .pushNamed(
                                                                            AddAddressPageWidget.routeName,
                                                                            queryParameters:
                                                                                {
                                                                              'isEdit': serializeParam(
                                                                                true,
                                                                                ParamType.bool,
                                                                              ),
                                                                              'isShipping': serializeParam(
                                                                                true,
                                                                                ParamType.bool,
                                                                              ),
                                                                              'address': serializeParam(
                                                                                PlantShopGroup.getCartCall.shippingAddress(
                                                                                  cartGetCartResponse.jsonBody,
                                                                                ),
                                                                                ParamType.JSON,
                                                                              ),
                                                                            }.withoutNulls,
                                                                          );
                                                                        } else {
                                                                          await actions
                                                                              .showCustomToastTop(
                                                                            FFLocalizations.of(context).getVariableText(
                                                                              enText: 'Please select different shipping address',
                                                                              arText: 'الرجاء تحديد عنوان شحن مختلف',
                                                                            ),
                                                                          );
                                                                        }
                                                                      },
                                                                      child:
                                                                          Container(
                                                                        decoration:
                                                                            BoxDecoration(),
                                                                        child:
                                                                            Padding(
                                                                          padding:
                                                                              EdgeInsets.all(6.0),
                                                                          child:
                                                                              ClipRRect(
                                                                            borderRadius:
                                                                                BorderRadius.circular(0.0),
                                                                            child:
                                                                                SvgPicture.asset(
                                                                              'assets/images/edit.svg',
                                                                              width: 20.0,
                                                                              height: 20.0,
                                                                              fit: BoxFit.cover,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            4.0,
                                                                            0.0,
                                                                            0.0),
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
                                                                    if (('' ==
                                                                            getJsonField(
                                                                              PlantShopGroup.getCartCall.shippingAddress(
                                                                                cartGetCartResponse.jsonBody,
                                                                              ),
                                                                              r'''$.first_name''',
                                                                            ).toString()) ||
                                                                        ('' ==
                                                                            getJsonField(
                                                                              PlantShopGroup.getCartCall.shippingAddress(
                                                                                cartGetCartResponse.jsonBody,
                                                                              ),
                                                                              r'''$.last_name''',
                                                                            ).toString()) ||
                                                                        ('' ==
                                                                            getJsonField(
                                                                              PlantShopGroup.getCartCall.shippingAddress(
                                                                                cartGetCartResponse.jsonBody,
                                                                              ),
                                                                              r'''$.address_1''',
                                                                            ).toString()) ||
                                                                        ('' ==
                                                                            getJsonField(
                                                                              PlantShopGroup.getCartCall.shippingAddress(
                                                                                cartGetCartResponse.jsonBody,
                                                                              ),
                                                                              r'''$.city''',
                                                                            ).toString()) ||
                                                                        ('' ==
                                                                            getJsonField(
                                                                              PlantShopGroup.getCartCall.shippingAddress(
                                                                                cartGetCartResponse.jsonBody,
                                                                              ),
                                                                              r'''$.postcode''',
                                                                            ).toString()) ||
                                                                        ('' ==
                                                                            getJsonField(
                                                                              PlantShopGroup.getCartCall.shippingAddress(
                                                                                cartGetCartResponse.jsonBody,
                                                                              ),
                                                                              r'''$.country''',
                                                                            ).toString()) ||
                                                                        ('' ==
                                                                            getJsonField(
                                                                              PlantShopGroup.getCartCall.shippingAddress(
                                                                                cartGetCartResponse.jsonBody,
                                                                              ),
                                                                              r'''$.phone''',
                                                                            ).toString())) {
                                                                      _model.differentShip =
                                                                          !_model
                                                                              .differentShip;
                                                                      safeSetState(
                                                                          () {});

                                                                      context
                                                                          .pushNamed(
                                                                        AddAddressPageWidget
                                                                            .routeName,
                                                                        queryParameters:
                                                                            {
                                                                          'isEdit':
                                                                              serializeParam(
                                                                            false,
                                                                            ParamType.bool,
                                                                          ),
                                                                          'isShipping':
                                                                              serializeParam(
                                                                            true,
                                                                            ParamType.bool,
                                                                          ),
                                                                          'address':
                                                                              serializeParam(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            ParamType.JSON,
                                                                          ),
                                                                        }.withoutNulls,
                                                                      );
                                                                    } else {
                                                                      if (_model
                                                                          .differentShip) {
                                                                        _model.process =
                                                                            true;
                                                                        safeSetState(
                                                                            () {});
                                                                        _model.shippingAddress = await PlantShopGroup
                                                                            .editShippingAddressCall
                                                                            .call(
                                                                          userId:
                                                                              getJsonField(
                                                                            FFAppState().userDetail,
                                                                            r'''$.id''',
                                                                          ).toString(),
                                                                          firstName:
                                                                              getJsonField(
                                                                            PlantShopGroup.getCartCall.billingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.first_name''',
                                                                          ).toString(),
                                                                          lastName:
                                                                              getJsonField(
                                                                            PlantShopGroup.getCartCall.billingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.last_name''',
                                                                          ).toString(),
                                                                          address1:
                                                                              getJsonField(
                                                                            PlantShopGroup.getCartCall.billingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.address_1''',
                                                                          ).toString(),
                                                                          address2:
                                                                              getJsonField(
                                                                            PlantShopGroup.getCartCall.billingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.address_2''',
                                                                          ).toString(),
                                                                          city:
                                                                              getJsonField(
                                                                            PlantShopGroup.getCartCall.billingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.city''',
                                                                          ).toString(),
                                                                          state:
                                                                              getJsonField(
                                                                            PlantShopGroup.getCartCall.billingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.state''',
                                                                          ).toString(),
                                                                          postcode:
                                                                              getJsonField(
                                                                            PlantShopGroup.getCartCall.billingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.postcode''',
                                                                          ).toString(),
                                                                          country:
                                                                              getJsonField(
                                                                            PlantShopGroup.getCartCall.billingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.country''',
                                                                          ).toString(),
                                                                          phone:
                                                                              getJsonField(
                                                                            PlantShopGroup.getCartCall.billingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.phone''',
                                                                          ).toString(),
                                                                        );

                                                                        if (PlantShopGroup.editShippingAddressCall.status(
                                                                              (_model.shippingAddress?.jsonBody ?? ''),
                                                                            ) ==
                                                                            null) {
                                                                          _model.success =
                                                                              await action_blocks.getCustomer(context);
                                                                          if (_model
                                                                              .success!) {
                                                                            safeSetState(() {
                                                                              FFAppState().clearCartCache();
                                                                              _model.apiRequestCompleted = false;
                                                                            });
                                                                            await _model.waitForApiRequestCompleted();
                                                                          }
                                                                        } else {
                                                                          await actions
                                                                              .showCustomToastTop(
                                                                            PlantShopGroup.editShippingAddressCall.message(
                                                                              (_model.shippingAddress?.jsonBody ?? ''),
                                                                            )!,
                                                                          );
                                                                        }

                                                                        _model.process =
                                                                            false;
                                                                        _model.differentShip =
                                                                            !_model.differentShip;
                                                                        safeSetState(
                                                                            () {});
                                                                      } else {
                                                                        _model.differentShip =
                                                                            !_model.differentShip;
                                                                        safeSetState(
                                                                            () {});
                                                                      }
                                                                    }

                                                                    safeSetState(
                                                                        () {});
                                                                  },
                                                                  child: Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    children: [
                                                                      Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            8.0,
                                                                            0.0),
                                                                        child:
                                                                            Builder(
                                                                          builder:
                                                                              (context) {
                                                                            if (_model.differentShip) {
                                                                              return Container(
                                                                                width: 20.0,
                                                                                height: 20.0,
                                                                                decoration: BoxDecoration(
                                                                                  color: FlutterFlowTheme.of(context).primary,
                                                                                  borderRadius: BorderRadius.circular(6.0),
                                                                                ),
                                                                                alignment: AlignmentDirectional(0.0, 0.0),
                                                                                child: Icon(
                                                                                  Icons.done_rounded,
                                                                                  color: Colors.white,
                                                                                  size: 14.0,
                                                                                ),
                                                                              );
                                                                            } else {
                                                                              return Container(
                                                                                width: 20.0,
                                                                                height: 20.0,
                                                                                decoration: BoxDecoration(
                                                                                  borderRadius: BorderRadius.circular(6.0),
                                                                                  border: Border.all(
                                                                                    color: FlutterFlowTheme.of(context).black20,
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            }
                                                                          },
                                                                        ),
                                                                      ),
                                                                      Expanded(
                                                                        child:
                                                                            Text(
                                                                          ('' ==
                                                                                      getJsonField(
                                                                                        PlantShopGroup.getCartCall.shippingAddress(
                                                                                          cartGetCartResponse.jsonBody,
                                                                                        ),
                                                                                        r'''$.first_name''',
                                                                                      ).toString()) ||
                                                                                  ('' ==
                                                                                      getJsonField(
                                                                                        PlantShopGroup.getCartCall.shippingAddress(
                                                                                          cartGetCartResponse.jsonBody,
                                                                                        ),
                                                                                        r'''$.last_name''',
                                                                                      ).toString()) ||
                                                                                  ('' ==
                                                                                      getJsonField(
                                                                                        PlantShopGroup.getCartCall.shippingAddress(
                                                                                          cartGetCartResponse.jsonBody,
                                                                                        ),
                                                                                        r'''$.address_1''',
                                                                                      ).toString()) ||
                                                                                  ('' ==
                                                                                      getJsonField(
                                                                                        PlantShopGroup.getCartCall.shippingAddress(
                                                                                          cartGetCartResponse.jsonBody,
                                                                                        ),
                                                                                        r'''$.city''',
                                                                                      ).toString()) ||
                                                                                  ('' ==
                                                                                      getJsonField(
                                                                                        PlantShopGroup.getCartCall.shippingAddress(
                                                                                          cartGetCartResponse.jsonBody,
                                                                                        ),
                                                                                        r'''$.postcode''',
                                                                                      ).toString()) ||
                                                                                  ('' ==
                                                                                      getJsonField(
                                                                                        PlantShopGroup.getCartCall.shippingAddress(
                                                                                          cartGetCartResponse.jsonBody,
                                                                                        ),
                                                                                        r'''$.country''',
                                                                                      ).toString()) ||
                                                                                  ('' ==
                                                                                      getJsonField(
                                                                                        PlantShopGroup.getCartCall.shippingAddress(
                                                                                          cartGetCartResponse.jsonBody,
                                                                                        ),
                                                                                        r'''$.phone''',
                                                                                      ).toString())
                                                                              ? FFLocalizations.of(context).getVariableText(
                                                                                  enText: 'Add different address!',
                                                                                  arText: 'أضف عنوانًا مختلفًا!',
                                                                                )
                                                                              : FFLocalizations.of(context).getVariableText(
                                                                                  enText: 'Ship to a different address?',
                                                                                  arText: 'الشحن إلى عنوان مختلف؟',
                                                                                ),
                                                                          textAlign:
                                                                              TextAlign.start,
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .override(
                                                                                fontFamily: 'SF Pro Display',
                                                                                fontSize: 16.0,
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FontWeight.normal,
                                                                                useGoogleFonts: false,
                                                                                lineHeight: 1.5,
                                                                              ),
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            6.0,
                                                                            0.0),
                                                                        child: SvgPicture
                                                                            .asset(
                                                                          'assets/images/arrow-right.svg',
                                                                          width:
                                                                              16.0,
                                                                          height:
                                                                              16.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              if (_model
                                                                      .differentShip &&
                                                                  !(('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.first_name''',
                                                                          ).toString()) ||
                                                                      ('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.last_name''',
                                                                          ).toString()) ||
                                                                      ('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.address_1''',
                                                                          ).toString()) ||
                                                                      ('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.city''',
                                                                          ).toString()) ||
                                                                      ('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.postcode''',
                                                                          ).toString()) ||
                                                                      ('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.country''',
                                                                          ).toString()) ||
                                                                      ('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.phone''',
                                                                          ).toString())))
                                                                Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          4.0,
                                                                          0.0,
                                                                          4.0),
                                                                  child: Text(
                                                                    '${getJsonField(
                                                                      PlantShopGroup
                                                                          .getCartCall
                                                                          .shippingAddress(
                                                                        cartGetCartResponse
                                                                            .jsonBody,
                                                                      ),
                                                                      r'''$.address_1''',
                                                                    ).toString()}, ${'' != getJsonField(
                                                                          PlantShopGroup
                                                                              .getCartCall
                                                                              .shippingAddress(
                                                                            cartGetCartResponse.jsonBody,
                                                                          ),
                                                                          r'''$.address_2''',
                                                                        ).toString() ? getJsonField(
                                                                        PlantShopGroup
                                                                            .getCartCall
                                                                            .shippingAddress(
                                                                          cartGetCartResponse
                                                                              .jsonBody,
                                                                        ),
                                                                        r'''$.address_2''',
                                                                      ).toString() : ''}${'' != getJsonField(
                                                                          PlantShopGroup
                                                                              .getCartCall
                                                                              .shippingAddress(
                                                                            cartGetCartResponse.jsonBody,
                                                                          ),
                                                                          r'''$.address_2''',
                                                                        ).toString() ? ', ' : ''}${getJsonField(
                                                                      PlantShopGroup
                                                                          .getCartCall
                                                                          .shippingAddress(
                                                                        cartGetCartResponse
                                                                            .jsonBody,
                                                                      ),
                                                                      r'''$.city''',
                                                                    ).toString()}, ${getJsonField(
                                                                      PlantShopGroup
                                                                          .getCartCall
                                                                          .shippingAddress(
                                                                        cartGetCartResponse
                                                                            .jsonBody,
                                                                      ),
                                                                      r'''$.postcode''',
                                                                    ).toString()}, ${'' != getJsonField(
                                                                          PlantShopGroup
                                                                              .getCartCall
                                                                              .shippingAddress(
                                                                            cartGetCartResponse.jsonBody,
                                                                          ),
                                                                          r'''$.state''',
                                                                        ).toString() ? getJsonField(
                                                                        functions
                                                                            .jsonToListConverter(getJsonField(
                                                                              FFAppState()
                                                                                  .allCountrysList
                                                                                  .where((e) =>
                                                                                      getJsonField(
                                                                                        PlantShopGroup.getCartCall.shippingAddress(
                                                                                          cartGetCartResponse.jsonBody,
                                                                                        ),
                                                                                        r'''$.country''',
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
                                                                                  PlantShopGroup.getCartCall.shippingAddress(
                                                                                    cartGetCartResponse.jsonBody,
                                                                                  ),
                                                                                  r'''$.state''',
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
                                                                              .getCartCall
                                                                              .shippingAddress(
                                                                            cartGetCartResponse.jsonBody,
                                                                          ),
                                                                          r'''$.state''',
                                                                        ).toString() ? ', ' : ''}${getJsonField(
                                                                      FFAppState()
                                                                          .allCountrysList
                                                                          .where((e) =>
                                                                              getJsonField(
                                                                                PlantShopGroup.getCartCall.shippingAddress(
                                                                                  cartGetCartResponse.jsonBody,
                                                                                ),
                                                                                r'''$.country''',
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
                                                                              FontWeight.normal,
                                                                          useGoogleFonts:
                                                                              false,
                                                                          lineHeight:
                                                                              1.5,
                                                                        ),
                                                                  ),
                                                                ),
                                                              if (_model
                                                                      .differentShip &&
                                                                  !(('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.first_name''',
                                                                          ).toString()) ||
                                                                      ('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.last_name''',
                                                                          ).toString()) ||
                                                                      ('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.address_1''',
                                                                          ).toString()) ||
                                                                      ('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.city''',
                                                                          ).toString()) ||
                                                                      ('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.postcode''',
                                                                          ).toString()) ||
                                                                      ('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.country''',
                                                                          ).toString()) ||
                                                                      ('' ==
                                                                          getJsonField(
                                                                            PlantShopGroup.getCartCall.shippingAddress(
                                                                              cartGetCartResponse.jsonBody,
                                                                            ),
                                                                            r'''$.phone''',
                                                                          ).toString())))
                                                                Text(
                                                                  getJsonField(
                                                                    PlantShopGroup
                                                                        .getCartCall
                                                                        .shippingAddress(
                                                                      cartGetCartResponse
                                                                          .jsonBody,
                                                                    ),
                                                                    r'''$.phone''',
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
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  Builder(
                                                    builder: (context) {
                                                      final cartList =
                                                          PlantShopGroup
                                                                  .getCartCall
                                                                  .itemsList(
                                                                    cartGetCartResponse
                                                                        .jsonBody,
                                                                  )
                                                                  ?.toList() ??
                                                              [];
                                                      _model.debugGeneratorVariables[
                                                              'cartList${cartList.length > 100 ? ' (first 100)' : ''}'] =
                                                          debugSerializeParam(
                                                        cartList.take(100),
                                                        ParamType.JSON,
                                                        isList: true,
                                                        link:
                                                            'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
                                                        name: 'dynamic',
                                                        nullable: false,
                                                      );
                                                      debugLogWidgetClass(
                                                          _model);

                                                      return Column(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: List.generate(
                                                                cartList.length,
                                                                (cartListIndex) {
                                                          final cartListItem =
                                                              cartList[
                                                                  cartListIndex];
                                                          return Container(
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
                                                                          12.0,
                                                                          10.0,
                                                                          6.0,
                                                                          12.0),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            16.0,
                                                                            0.0),
                                                                    child:
                                                                        Container(
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(16.0),
                                                                        border:
                                                                            Border.all(
                                                                          color:
                                                                              FlutterFlowTheme.of(context).black20,
                                                                          width:
                                                                              1.0,
                                                                        ),
                                                                      ),
                                                                      child:
                                                                          Visibility(
                                                                        visible: ('' !=
                                                                                getJsonField(
                                                                                  cartListItem,
                                                                                  r'''$.images[0].src''',
                                                                                ).toString()) &&
                                                                            (getJsonField(
                                                                                  cartListItem,
                                                                                  r'''$.images[0].src''',
                                                                                ) !=
                                                                                null) &&
                                                                            (getJsonField(
                                                                                  cartListItem,
                                                                                  r'''$.images''',
                                                                                ) !=
                                                                                null),
                                                                        child:
                                                                            ClipRRect(
                                                                          borderRadius:
                                                                              BorderRadius.circular(16.0),
                                                                          child:
                                                                              CachedNetworkImage(
                                                                            fadeInDuration:
                                                                                Duration(milliseconds: 200),
                                                                            fadeOutDuration:
                                                                                Duration(milliseconds: 200),
                                                                            imageUrl:
                                                                                getJsonField(
                                                                              cartListItem,
                                                                              r'''$.images[0].src''',
                                                                            ).toString(),
                                                                            width:
                                                                                95.0,
                                                                            height:
                                                                                95.0,
                                                                            fit:
                                                                                BoxFit.cover,
                                                                            alignment:
                                                                                Alignment(0.0, 0.0),
                                                                            errorWidget: (context, error, stackTrace) =>
                                                                                Image.asset(
                                                                              'assets/images/error_image.png',
                                                                              width: 95.0,
                                                                              height: 95.0,
                                                                              fit: BoxFit.cover,
                                                                              alignment: Alignment(0.0, 0.0),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child:
                                                                        Column(
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
                                                                        Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          children: [
                                                                            Expanded(
                                                                              child: Text(
                                                                                functions.removeHtmlEntities(getJsonField(
                                                                                  cartListItem,
                                                                                  r'''$.name''',
                                                                                ).toString()),
                                                                                textAlign: TextAlign.start,
                                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                      fontFamily: 'SF Pro Display',
                                                                                      fontSize: 17.0,
                                                                                      letterSpacing: 0.17,
                                                                                      fontWeight: FontWeight.w500,
                                                                                      useGoogleFonts: false,
                                                                                      lineHeight: 1.5,
                                                                                    ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        Padding(
                                                                          padding: EdgeInsetsDirectional.fromSTEB(
                                                                              0.0,
                                                                              4.0,
                                                                              0.0,
                                                                              0.0),
                                                                          child:
                                                                              Text(
                                                                            functions.formatPrice(
                                                                                functions.divideBy100(getJsonField(
                                                                                  cartListItem,
                                                                                  r'''$.prices.price''',
                                                                                ).toString()),
                                                                                FFAppState().thousandSeparator,
                                                                                FFAppState().decimalSeparator,
                                                                                FFAppState().decimalPlaces.toString(),
                                                                                FFAppState().currencyPosition,
                                                                                FFAppState().currency),
                                                                            textAlign:
                                                                                TextAlign.start,
                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                  fontFamily: 'SF Pro Display',
                                                                                  fontSize: 16.0,
                                                                                  letterSpacing: 0.16,
                                                                                  fontWeight: FontWeight.w600,
                                                                                  useGoogleFonts: false,
                                                                                  lineHeight: 1.5,
                                                                                ),
                                                                          ),
                                                                        ),
                                                                        if (functions
                                                                            .jsonToListConverter(getJsonField(
                                                                              cartListItem,
                                                                              r'''$.variation''',
                                                                              true,
                                                                            )!)
                                                                            .isNotEmpty)
                                                                          Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                0.0,
                                                                                4.0,
                                                                                0.0,
                                                                                0.0),
                                                                            child:
                                                                                Builder(
                                                                              builder: (context) {
                                                                                final variationList = getJsonField(
                                                                                  cartListItem,
                                                                                  r'''$.variation''',
                                                                                ).toList();
                                                                                _model.debugGeneratorVariables['variationList${variationList.length > 100 ? ' (first 100)' : ''}'] = debugSerializeParam(
                                                                                  variationList.take(100),
                                                                                  ParamType.JSON,
                                                                                  link: 'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
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
                                                                                              r'''$.attribute''',
                                                                                            ).toString(),
                                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                  fontFamily: 'SF Pro Display',
                                                                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                                                                  letterSpacing: 0.0,
                                                                                                  fontWeight: FontWeight.w500,
                                                                                                  useGoogleFonts: false,
                                                                                                ),
                                                                                          ),
                                                                                          TextSpan(
                                                                                            text: FFLocalizations.of(context).getText(
                                                                                              'ukiu0111' /*  :  */,
                                                                                            ),
                                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                  fontFamily: 'SF Pro Display',
                                                                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                                                                  letterSpacing: 0.0,
                                                                                                  fontWeight: FontWeight.w500,
                                                                                                  useGoogleFonts: false,
                                                                                                ),
                                                                                          ),
                                                                                          TextSpan(
                                                                                            text: getJsonField(
                                                                                              variationListItem,
                                                                                              r'''$.value''',
                                                                                            ).toString(),
                                                                                            style: TextStyle(
                                                                                              fontFamily: 'SF Pro Display',
                                                                                              color: FlutterFlowTheme.of(context).primaryText,
                                                                                              fontWeight: FontWeight.w500,
                                                                                              fontSize: 14.0,
                                                                                            ),
                                                                                          )
                                                                                        ],
                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                              fontFamily: 'SF Pro Display',
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FontWeight.w500,
                                                                                              useGoogleFonts: false,
                                                                                              lineHeight: 1.5,
                                                                                            ),
                                                                                      ),
                                                                                    );
                                                                                  }).divide(SizedBox(height: 4.0)),
                                                                                );
                                                                              },
                                                                            ),
                                                                          ),
                                                                        Padding(
                                                                          padding: EdgeInsetsDirectional.fromSTEB(
                                                                              0.0,
                                                                              4.0,
                                                                              0.0,
                                                                              0.0),
                                                                          child:
                                                                              RichText(
                                                                            textScaler:
                                                                                MediaQuery.of(context).textScaler,
                                                                            text:
                                                                                TextSpan(
                                                                              children: [
                                                                                TextSpan(
                                                                                  text: FFLocalizations.of(context).getText(
                                                                                    'qz0lzb8i' /* Quantity :  */,
                                                                                  ),
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        fontFamily: 'SF Pro Display',
                                                                                        fontSize: 16.0,
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FontWeight.w600,
                                                                                        useGoogleFonts: false,
                                                                                        lineHeight: 1.5,
                                                                                      ),
                                                                                ),
                                                                                TextSpan(
                                                                                  text: getJsonField(
                                                                                    cartListItem,
                                                                                    r'''$.quantity''',
                                                                                  ).toString(),
                                                                                  style: TextStyle(
                                                                                    fontFamily: 'SF Pro Display',
                                                                                    color: FlutterFlowTheme.of(context).primaryText,
                                                                                    fontWeight: FontWeight.w600,
                                                                                    fontSize: 16.0,
                                                                                    height: 1.5,
                                                                                  ),
                                                                                )
                                                                              ],
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    fontFamily: 'SF Pro Display',
                                                                                    fontSize: 16.0,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FontWeight.w600,
                                                                                    useGoogleFonts: false,
                                                                                    lineHeight: 1.5,
                                                                                  ),
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.start,
                                                                          ),
                                                                        ),
                                                                        Padding(
                                                                          padding: EdgeInsetsDirectional.fromSTEB(
                                                                              0.0,
                                                                              4.0,
                                                                              0.0,
                                                                              0.0),
                                                                          child:
                                                                              RichText(
                                                                            textScaler:
                                                                                MediaQuery.of(context).textScaler,
                                                                            text:
                                                                                TextSpan(
                                                                              children: [
                                                                                TextSpan(
                                                                                  text: FFLocalizations.of(context).getText(
                                                                                    't0l7aq1r' /* Total :  */,
                                                                                  ),
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        fontFamily: 'SF Pro Display',
                                                                                        fontSize: 16.0,
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FontWeight.w600,
                                                                                        useGoogleFonts: false,
                                                                                        lineHeight: 1.5,
                                                                                      ),
                                                                                ),
                                                                                TextSpan(
                                                                                  text: functions.formatPrice(
                                                                                      functions.divideBy100(getJsonField(
                                                                                        cartListItem,
                                                                                        r'''$.totals.line_total''',
                                                                                      ).toString()),
                                                                                      FFAppState().thousandSeparator,
                                                                                      FFAppState().decimalSeparator,
                                                                                      FFAppState().decimalPlaces.toString(),
                                                                                      FFAppState().currencyPosition,
                                                                                      FFAppState().currency),
                                                                                  style: TextStyle(
                                                                                    fontFamily: 'SF Pro Display',
                                                                                    color: FlutterFlowTheme.of(context).primaryText,
                                                                                    fontWeight: FontWeight.w600,
                                                                                    fontSize: 16.0,
                                                                                    height: 1.5,
                                                                                  ),
                                                                                )
                                                                              ],
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                    fontFamily: 'SF Pro Display',
                                                                                    fontSize: 16.0,
                                                                                    letterSpacing: 0.0,
                                                                                    fontWeight: FontWeight.w600,
                                                                                    useGoogleFonts: false,
                                                                                    lineHeight: 1.5,
                                                                                  ),
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.start,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        })
                                                            .divide(SizedBox(
                                                                height: 12.0))
                                                            .addToStart(
                                                                SizedBox(
                                                                    height:
                                                                        12.0)),
                                                      );
                                                    },
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 12.0,
                                                                0.0, 0.0),
                                                    child: Container(
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .primaryBackground,
                                                      ),
                                                      child: Padding(
                                                        padding: EdgeInsets.all(
                                                            12.0),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Expanded(
                                                              child: Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .lightGray,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              6.0),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Expanded(
                                                                      child:
                                                                          TextFormField(
                                                                        controller:
                                                                            _model.textController,
                                                                        focusNode:
                                                                            _model.textFieldFocusNode,
                                                                        onChanged:
                                                                            (_) =>
                                                                                EasyDebounce.debounce(
                                                                          '_model.textController',
                                                                          Duration(
                                                                              milliseconds: 100),
                                                                          () =>
                                                                              safeSetState(() {}),
                                                                        ),
                                                                        autofocus:
                                                                            false,
                                                                        textInputAction:
                                                                            TextInputAction.done,
                                                                        obscureText:
                                                                            false,
                                                                        decoration:
                                                                            InputDecoration(
                                                                          isDense:
                                                                              true,
                                                                          labelStyle: FlutterFlowTheme.of(context)
                                                                              .labelMedium
                                                                              .override(
                                                                                fontFamily: 'SF Pro Display',
                                                                                fontSize: 16.0,
                                                                                letterSpacing: 0.0,
                                                                                useGoogleFonts: false,
                                                                              ),
                                                                          hintText:
                                                                              FFLocalizations.of(context).getText(
                                                                            'tmu1zwcy' /* Enter coupon code */,
                                                                          ),
                                                                          hintStyle: FlutterFlowTheme.of(context)
                                                                              .labelMedium
                                                                              .override(
                                                                                fontFamily: 'SF Pro Display',
                                                                                fontSize: 16.0,
                                                                                letterSpacing: 0.16,
                                                                                fontWeight: FontWeight.normal,
                                                                                useGoogleFonts: false,
                                                                              ),
                                                                          errorStyle: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .override(
                                                                                fontFamily: 'SF Pro Display',
                                                                                color: FlutterFlowTheme.of(context).error,
                                                                                fontSize: 14.0,
                                                                                letterSpacing: 0.0,
                                                                                useGoogleFonts: false,
                                                                              ),
                                                                          enabledBorder:
                                                                              InputBorder.none,
                                                                          focusedBorder:
                                                                              InputBorder.none,
                                                                          errorBorder:
                                                                              InputBorder.none,
                                                                          focusedErrorBorder:
                                                                              InputBorder.none,
                                                                          contentPadding: EdgeInsetsDirectional.fromSTEB(
                                                                              16.0,
                                                                              14.0,
                                                                              16.0,
                                                                              14.0),
                                                                        ),
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .override(
                                                                              fontFamily: 'SF Pro Display',
                                                                              fontSize: 16.0,
                                                                              letterSpacing: 0.0,
                                                                              useGoogleFonts: false,
                                                                            ),
                                                                        cursorColor:
                                                                            FlutterFlowTheme.of(context).primaryText,
                                                                        validator: _model
                                                                            .textControllerValidator
                                                                            .asValidator(context),
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      decoration:
                                                                          BoxDecoration(),
                                                                      child:
                                                                          Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            10.0,
                                                                            15.0,
                                                                            10.0),
                                                                        child:
                                                                            FFButtonWidget(
                                                                          onPressed:
                                                                              () async {
                                                                            if (_model.textController.text != null &&
                                                                                _model.textController.text != '') {
                                                                              _model.applyCode = await PlantShopGroup.applyCouponCodeCall.call(
                                                                                code: _model.textController.text,
                                                                                nonce: cartGetCartResponse.getHeader('nonce'),
                                                                                token: FFAppState().token,
                                                                              );

                                                                              if (PlantShopGroup.applyCouponCodeCall.status(
                                                                                    (_model.applyCode?.jsonBody ?? ''),
                                                                                  ) ==
                                                                                  null) {
                                                                                safeSetState(() {
                                                                                  FFAppState().clearCartCache();
                                                                                  _model.apiRequestCompleted = false;
                                                                                });
                                                                                await _model.waitForApiRequestCompleted();
                                                                                safeSetState(() {
                                                                                  _model.textController?.clear();
                                                                                });
                                                                                await actions.showCustomToastTop(
                                                                                  FFLocalizations.of(context).getVariableText(
                                                                                    enText: 'Coupon code applied successfully.',
                                                                                    arText: 'تم تطبيق رمز القسيمة بنجاح.',
                                                                                  ),
                                                                                );
                                                                              } else {
                                                                                await actions.showCustomToastTop(
                                                                                  PlantShopGroup.applyCouponCodeCall.message(
                                                                                    (_model.applyCode?.jsonBody ?? ''),
                                                                                  )!,
                                                                                );
                                                                              }
                                                                            } else {
                                                                              await actions.showCustomToastTop(
                                                                                FFLocalizations.of(context).getVariableText(
                                                                                  enText: 'Please enter coupon code',
                                                                                  arText: 'الرجاء إدخال رمز القسيمة',
                                                                                ),
                                                                              );
                                                                            }

                                                                            safeSetState(() {});
                                                                          },
                                                                          text:
                                                                              FFLocalizations.of(context).getText(
                                                                            'iihsc0wr' /* Apply */,
                                                                          ),
                                                                          options:
                                                                              FFButtonOptions(
                                                                            width:
                                                                                60.0,
                                                                            height:
                                                                                32.0,
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                0.0,
                                                                                0.0,
                                                                                0.0,
                                                                                0.0),
                                                                            iconPadding: EdgeInsetsDirectional.fromSTEB(
                                                                                0.0,
                                                                                0.0,
                                                                                0.0,
                                                                                0.0),
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primary,
                                                                            textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                                                                  fontFamily: 'SF Pro Display',
                                                                                  color: Colors.white,
                                                                                  fontSize: 16.0,
                                                                                  letterSpacing: 0.16,
                                                                                  fontWeight: FontWeight.normal,
                                                                                  useGoogleFonts: false,
                                                                                ),
                                                                            elevation:
                                                                                0.0,
                                                                            borderRadius:
                                                                                BorderRadius.circular(7.0),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
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
                                                              highlightColor:
                                                                  Colors
                                                                      .transparent,
                                                              onTap: () async {
                                                                context
                                                                    .pushNamed(
                                                                  CouponPageWidget
                                                                      .routeName,
                                                                  queryParameters:
                                                                      {
                                                                    'nonce':
                                                                        serializeParam(
                                                                      cartGetCartResponse
                                                                          .getHeader(
                                                                              'nonce'),
                                                                      ParamType
                                                                          .String,
                                                                    ),
                                                                  }.withoutNulls,
                                                                );
                                                              },
                                                              child: Container(
                                                                decoration:
                                                                    BoxDecoration(),
                                                                child: Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          10.0,
                                                                          4.0,
                                                                          10.0,
                                                                          4.0),
                                                                  child: Text(
                                                                    FFLocalizations.of(
                                                                            context)
                                                                        .getText(
                                                                      'jknh9898' /* View all */,
                                                                    ),
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
                                                                              0.16,
                                                                          fontWeight:
                                                                              FontWeight.normal,
                                                                          useGoogleFonts:
                                                                              false,
                                                                          lineHeight:
                                                                              1.5,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ].divide(SizedBox(
                                                              width: 12.0)),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 12.0,
                                                                0.0, 0.0),
                                                    child: Container(
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .primaryBackground,
                                                      ),
                                                      child: Padding(
                                                        padding: EdgeInsets.all(
                                                            12.0),
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
                                                                'ytlg9ykw' /* Payment Summary */,
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
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          13.0,
                                                                          0.0,
                                                                          12.0),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  Expanded(
                                                                    child: Text(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        'z1z1z0cx' /* Sub Total */,
                                                                      ),
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
                                                                  ),
                                                                  Text(
                                                                    functions.formatPrice(
                                                                        functions.divideBy100(PlantShopGroup.getCartCall.totalitems(
                                                                          cartGetCartResponse
                                                                              .jsonBody,
                                                                        )!),
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
                                                              ),
                                                            ),
                                                            Divider(
                                                              height: 1.0,
                                                              thickness: 1.0,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .black20,
                                                            ),
                                                            if (PlantShopGroup
                                                                        .getCartCall
                                                                        .couponsList(
                                                                      cartGetCartResponse
                                                                          .jsonBody,
                                                                    ) !=
                                                                    null &&
                                                                (PlantShopGroup
                                                                        .getCartCall
                                                                        .couponsList(
                                                                  cartGetCartResponse
                                                                      .jsonBody,
                                                                ))!
                                                                    .isNotEmpty)
                                                              Builder(
                                                                builder:
                                                                    (context) {
                                                                  final couponeList = PlantShopGroup
                                                                          .getCartCall
                                                                          .couponsList(
                                                                            cartGetCartResponse.jsonBody,
                                                                          )
                                                                          ?.toList() ??
                                                                      [];
                                                                  _model.debugGeneratorVariables[
                                                                          'couponeList${couponeList.length > 100 ? ' (first 100)' : ''}'] =
                                                                      debugSerializeParam(
                                                                    couponeList
                                                                        .take(
                                                                            100),
                                                                    ParamType
                                                                        .JSON,
                                                                    isList:
                                                                        true,
                                                                    link:
                                                                        'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
                                                                    name:
                                                                        'dynamic',
                                                                    nullable:
                                                                        false,
                                                                  );
                                                                  debugLogWidgetClass(
                                                                      _model);

                                                                  return Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    children: List.generate(
                                                                        couponeList
                                                                            .length,
                                                                        (couponeListIndex) {
                                                                      final couponeListItem =
                                                                          couponeList[
                                                                              couponeListIndex];
                                                                      return Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.end,
                                                                        children: [
                                                                          Expanded(
                                                                            child:
                                                                                RichText(
                                                                              textScaler: MediaQuery.of(context).textScaler,
                                                                              text: TextSpan(
                                                                                children: [
                                                                                  TextSpan(
                                                                                    text: FFLocalizations.of(context).getText(
                                                                                      'n3mf80hc' /* Discount :  */,
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
                                                                                    text: getJsonField(
                                                                                      couponeListItem,
                                                                                      r'''$.code''',
                                                                                    ).toString(),
                                                                                    style: TextStyle(
                                                                                      fontFamily: 'SF Pro Display',
                                                                                      color: FlutterFlowTheme.of(context).primaryText,
                                                                                      fontSize: 16.0,
                                                                                    ),
                                                                                  )
                                                                                ],
                                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                      fontFamily: 'SF Pro Display',
                                                                                      fontSize: 17.0,
                                                                                      letterSpacing: 0.17,
                                                                                      fontWeight: FontWeight.w500,
                                                                                      useGoogleFonts: false,
                                                                                      lineHeight: 1.5,
                                                                                    ),
                                                                              ),
                                                                              textAlign: TextAlign.start,
                                                                            ),
                                                                          ),
                                                                          Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                0.0,
                                                                                0.0,
                                                                                4.0,
                                                                                0.0),
                                                                            child:
                                                                                InkWell(
                                                                              splashColor: Colors.transparent,
                                                                              focusColor: Colors.transparent,
                                                                              hoverColor: Colors.transparent,
                                                                              highlightColor: Colors.transparent,
                                                                              onTap: () async {
                                                                                _model.process = true;
                                                                                safeSetState(() {});
                                                                                _model.removeCoupon = await PlantShopGroup.removeCouponCodeCall.call(
                                                                                  code: getJsonField(
                                                                                    couponeListItem,
                                                                                    r'''$.code''',
                                                                                  ).toString(),
                                                                                  nonce: cartGetCartResponse.getHeader('nonce'),
                                                                                  token: FFAppState().token,
                                                                                );

                                                                                if (PlantShopGroup.removeCouponCodeCall.status(
                                                                                      (_model.removeCoupon?.jsonBody ?? ''),
                                                                                    ) ==
                                                                                    null) {
                                                                                  safeSetState(() {
                                                                                    FFAppState().clearCartCache();
                                                                                    _model.apiRequestCompleted = false;
                                                                                  });
                                                                                  await _model.waitForApiRequestCompleted();
                                                                                  await actions.showCustomToastTop(
                                                                                    FFLocalizations.of(context).getVariableText(
                                                                                      enText: 'Coupon code removed successfully.',
                                                                                      arText: 'تمت إزالة رمز القسيمة بنجاح.',
                                                                                    ),
                                                                                  );
                                                                                } else {
                                                                                  await actions.showCustomToastTop(
                                                                                    PlantShopGroup.removeCouponCodeCall.message(
                                                                                      (_model.removeCoupon?.jsonBody ?? ''),
                                                                                    )!,
                                                                                  );
                                                                                }

                                                                                _model.process = false;
                                                                                safeSetState(() {});

                                                                                safeSetState(() {});
                                                                              },
                                                                              child: Text(
                                                                                FFLocalizations.of(context).getText(
                                                                                  'l1hd4xt8' /* Remove */,
                                                                                ),
                                                                                textAlign: TextAlign.start,
                                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                      fontFamily: 'SF Pro Display',
                                                                                      color: FlutterFlowTheme.of(context).error,
                                                                                      fontSize: 17.0,
                                                                                      letterSpacing: 0.17,
                                                                                      fontWeight: FontWeight.w500,
                                                                                      useGoogleFonts: false,
                                                                                      lineHeight: 1.5,
                                                                                    ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            '-${functions.formatPrice(functions.divideBy100(getJsonField(
                                                                                  couponeListItem,
                                                                                  r'''$.totals.total_discount''',
                                                                                ).toString()), FFAppState().thousandSeparator, FFAppState().decimalSeparator, FFAppState().decimalPlaces.toString(), FFAppState().currencyPosition, FFAppState().currency)}',
                                                                            textAlign:
                                                                                TextAlign.start,
                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                  fontFamily: 'SF Pro Display',
                                                                                  color: FlutterFlowTheme.of(context).success,
                                                                                  fontSize: 17.0,
                                                                                  letterSpacing: 0.17,
                                                                                  fontWeight: FontWeight.w500,
                                                                                  useGoogleFonts: false,
                                                                                  lineHeight: 1.5,
                                                                                ),
                                                                          ),
                                                                        ],
                                                                      );
                                                                    }).divide(SizedBox(height: 4.0)).addToStart(
                                                                        SizedBox(
                                                                            height:
                                                                                12.0)),
                                                                  );
                                                                },
                                                              ),
                                                            if (PlantShopGroup
                                                                        .getCartCall
                                                                        .shippingRates(
                                                                      cartGetCartResponse
                                                                          .jsonBody,
                                                                    ) !=
                                                                    null &&
                                                                (PlantShopGroup
                                                                        .getCartCall
                                                                        .shippingRates(
                                                                  cartGetCartResponse
                                                                      .jsonBody,
                                                                ))!
                                                                    .isNotEmpty)
                                                              Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            12.0,
                                                                            0.0,
                                                                            0.0),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: [
                                                                    Expanded(
                                                                      child:
                                                                          Text(
                                                                        FFLocalizations.of(context)
                                                                            .getText(
                                                                          'zyyjtu2a' /* Shipping */,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.start,
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
                                                                    ),
                                                                    Text(
                                                                      '+${functions.formatPrice(functions.divideBy100(PlantShopGroup.getCartCall.totalShipping(
                                                                            cartGetCartResponse.jsonBody,
                                                                          )!), FFAppState().thousandSeparator, FFAppState().decimalSeparator, FFAppState().decimalPlaces.toString(), FFAppState().currencyPosition, FFAppState().currency)}',
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
                                                                                FlutterFlowTheme.of(context).primaryText,
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
                                                                ),
                                                              ),
                                                            if (PlantShopGroup
                                                                        .getCartCall
                                                                        .shippingRates(
                                                                      cartGetCartResponse
                                                                          .jsonBody,
                                                                    ) !=
                                                                    null &&
                                                                (PlantShopGroup
                                                                        .getCartCall
                                                                        .shippingRates(
                                                                  cartGetCartResponse
                                                                      .jsonBody,
                                                                ))!
                                                                    .isNotEmpty)
                                                              Builder(
                                                                builder:
                                                                    (context) {
                                                                  final shippingRatesList = PlantShopGroup
                                                                          .getCartCall
                                                                          .shippingRates(
                                                                            cartGetCartResponse.jsonBody,
                                                                          )
                                                                          ?.toList() ??
                                                                      [];
                                                                  _model.debugGeneratorVariables[
                                                                          'shippingRatesList${shippingRatesList.length > 100 ? ' (first 100)' : ''}'] =
                                                                      debugSerializeParam(
                                                                    shippingRatesList
                                                                        .take(
                                                                            100),
                                                                    ParamType
                                                                        .JSON,
                                                                    isList:
                                                                        true,
                                                                    link:
                                                                        'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
                                                                    name:
                                                                        'dynamic',
                                                                    nullable:
                                                                        false,
                                                                  );
                                                                  debugLogWidgetClass(
                                                                      _model);

                                                                  return Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    children: List.generate(
                                                                        shippingRatesList
                                                                            .length,
                                                                        (shippingRatesListIndex) {
                                                                      final shippingRatesListItem =
                                                                          shippingRatesList[
                                                                              shippingRatesListIndex];
                                                                      return Padding(
                                                                        padding: EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            1.0,
                                                                            0.0,
                                                                            0.0),
                                                                        child:
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
                                                                            _model.process =
                                                                                true;
                                                                            safeSetState(() {});
                                                                            _model.updateShipping =
                                                                                await PlantShopGroup.updateShippingCall.call(
                                                                              shippingMethod: getJsonField(
                                                                                shippingRatesListItem,
                                                                                r'''$.rate_id''',
                                                                              ).toString(),
                                                                              token: FFAppState().token,
                                                                            );

                                                                            if (PlantShopGroup.updateShippingCall.status(
                                                                                  (_model.updateShipping?.jsonBody ?? ''),
                                                                                ) ==
                                                                                null) {
                                                                              safeSetState(() {
                                                                                FFAppState().clearCartCache();
                                                                                _model.apiRequestCompleted = false;
                                                                              });
                                                                              await _model.waitForApiRequestCompleted();
                                                                            } else {
                                                                              await actions.showCustomToastTop(
                                                                                PlantShopGroup.updateShippingCall.message(
                                                                                  (_model.updateShipping?.jsonBody ?? ''),
                                                                                )!,
                                                                              );
                                                                            }

                                                                            _model.process =
                                                                                false;
                                                                            safeSetState(() {});

                                                                            safeSetState(() {});
                                                                          },
                                                                          child:
                                                                              Container(
                                                                            decoration:
                                                                                BoxDecoration(),
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsetsDirectional.fromSTEB(0.0, 6.0, 0.0, 6.0),
                                                                              child: Row(
                                                                                mainAxisSize: MainAxisSize.max,
                                                                                children: [
                                                                                  Builder(
                                                                                    builder: (context) {
                                                                                      if (getJsonField(
                                                                                        shippingRatesListItem,
                                                                                        r'''$.selected''',
                                                                                      )) {
                                                                                        return Container(
                                                                                          width: 18.0,
                                                                                          height: 18.0,
                                                                                          decoration: BoxDecoration(
                                                                                            color: FlutterFlowTheme.of(context).primary,
                                                                                            borderRadius: BorderRadius.circular(6.0),
                                                                                          ),
                                                                                          alignment: AlignmentDirectional(0.0, 0.0),
                                                                                          child: Icon(
                                                                                            Icons.done_rounded,
                                                                                            color: Colors.white,
                                                                                            size: 12.0,
                                                                                          ),
                                                                                        );
                                                                                      } else {
                                                                                        return Container(
                                                                                          width: 18.0,
                                                                                          height: 18.0,
                                                                                          decoration: BoxDecoration(
                                                                                            borderRadius: BorderRadius.circular(6.0),
                                                                                            border: Border.all(
                                                                                              color: FlutterFlowTheme.of(context).black20,
                                                                                            ),
                                                                                          ),
                                                                                        );
                                                                                      }
                                                                                    },
                                                                                  ),
                                                                                  Padding(
                                                                                    padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 0.0, 0.0),
                                                                                    child: Text(
                                                                                      getJsonField(
                                                                                        shippingRatesListItem,
                                                                                        r'''$.name''',
                                                                                      ).toString(),
                                                                                      textAlign: TextAlign.start,
                                                                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                            fontFamily: 'SF Pro Display',
                                                                                            fontSize: 14.0,
                                                                                            letterSpacing: 0.14,
                                                                                            fontWeight: FontWeight.normal,
                                                                                            useGoogleFonts: false,
                                                                                            lineHeight: 1.5,
                                                                                          ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }),
                                                                  );
                                                                },
                                                              ),
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          12.0,
                                                                          0.0,
                                                                          12.0),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  Expanded(
                                                                    child: Text(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        'rvnboy3d' /* Tax */,
                                                                      ),
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
                                                                  ),
                                                                  Text(
                                                                    '+${functions.formatPrice(functions.divideBy100(PlantShopGroup.getCartCall.totalTax(
                                                                          cartGetCartResponse
                                                                              .jsonBody,
                                                                        )!), FFAppState().thousandSeparator, FFAppState().decimalSeparator, FFAppState().decimalPlaces.toString(), FFAppState().currencyPosition, FFAppState().currency)}',
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
                                                                              FlutterFlowTheme.of(context).primaryText,
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
                                                              ),
                                                            ),
                                                            Divider(
                                                              height: 1.0,
                                                              thickness: 1.0,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .black20,
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          16.0,
                                                                          0.0,
                                                                          0.0),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  Expanded(
                                                                    child: Text(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        'l74q8jia' /* Total Payment Amount */,
                                                                      ),
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
                                                                  ),
                                                                  Text(
                                                                    functions.formatPrice(
                                                                        functions.divideBy100(PlantShopGroup.getCartCall.totalPrice(
                                                                          cartGetCartResponse
                                                                              .jsonBody,
                                                                        )!),
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
                                                                          color:
                                                                              FlutterFlowTheme.of(context).primaryText,
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
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 12.0,
                                                                0.0, 0.0),
                                                    child: Container(
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .primaryBackground,
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    12.0,
                                                                    12.0,
                                                                    12.0,
                                                                    4.0),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .getText(
                                                                'kkjz9j7a' /* Choose your Payment Mode */,
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
                                                            Builder(
                                                              builder:
                                                                  (context) {
                                                                final paymentList = functions
                                                                    .filterPaymentList(FFAppState()
                                                                        .paymentGatewaysList
                                                                        .where((e) =>
                                                                            true ==
                                                                            getJsonField(
                                                                              e,
                                                                              r'''$.enabled''',
                                                                            ))
                                                                        .toList())
                                                                    .toList();
                                                                if (paymentList
                                                                    .isEmpty) {
                                                                  return Container(
                                                                    height:
                                                                        MediaQuery.sizeOf(context).height *
                                                                            0.2,
                                                                    child:
                                                                        NoPaymentMethodesComponentWidget(),
                                                                  );
                                                                }
                                                                _model.debugGeneratorVariables[
                                                                        'paymentList${paymentList.length > 100 ? ' (first 100)' : ''}'] =
                                                                    debugSerializeParam(
                                                                  paymentList
                                                                      .take(
                                                                          100),
                                                                  ParamType
                                                                      .JSON,
                                                                  isList: true,
                                                                  link:
                                                                      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
                                                                  name:
                                                                      'dynamic',
                                                                  nullable:
                                                                      false,
                                                                );
                                                                debugLogWidgetClass(
                                                                    _model);

                                                                return Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  children: List.generate(
                                                                      paymentList
                                                                          .length,
                                                                      (paymentListIndex) {
                                                                    final paymentListItem =
                                                                        paymentList[
                                                                            paymentListIndex];
                                                                    return InkWell(
                                                                      splashColor:
                                                                          Colors
                                                                              .transparent,
                                                                      focusColor:
                                                                          Colors
                                                                              .transparent,
                                                                      hoverColor:
                                                                          Colors
                                                                              .transparent,
                                                                      highlightColor:
                                                                          Colors
                                                                              .transparent,
                                                                      onTap:
                                                                          () async {
                                                                        _model.select =
                                                                            getJsonField(
                                                                          paymentListItem,
                                                                          r'''$.id''',
                                                                        ).toString();
                                                                        _model.selectedMethode =
                                                                            paymentListItem;
                                                                        safeSetState(
                                                                            () {});
                                                                      },
                                                                      child:
                                                                          Container(
                                                                        decoration:
                                                                            BoxDecoration(),
                                                                        child:
                                                                            Padding(
                                                                          padding: EdgeInsetsDirectional.fromSTEB(
                                                                              0.0,
                                                                              16.0,
                                                                              0.0,
                                                                              12.0),
                                                                          child:
                                                                              Row(
                                                                            mainAxisSize:
                                                                                MainAxisSize.max,
                                                                            children: [
                                                                              wrapWithModel(
                                                                                model: _model.paymentImagesModels.getModel(
                                                                                  getJsonField(
                                                                                    paymentListItem,
                                                                                    r'''$.id''',
                                                                                  ).toString(),
                                                                                  paymentListIndex,
                                                                                ),
                                                                                updateCallback: () => safeSetState(() {}),
                                                                                child: Builder(builder: (_) {
                                                                                  return DebugFlutterFlowModelContext(
                                                                                    rootModel: _model.rootModel,
                                                                                    child: PaymentImagesWidget(
                                                                                      key: Key(
                                                                                        'Keyozt_${getJsonField(
                                                                                          paymentListItem,
                                                                                          r'''$.id''',
                                                                                        ).toString()}',
                                                                                      ),
                                                                                      id: getJsonField(
                                                                                        paymentListItem,
                                                                                        r'''$.id''',
                                                                                      ).toString(),
                                                                                    ),
                                                                                  );
                                                                                }),
                                                                              ),
                                                                              Expanded(
                                                                                child: Padding(
                                                                                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 0.0, 0.0),
                                                                                  child: Text(
                                                                                    getJsonField(
                                                                                      paymentListItem,
                                                                                      r'''$.method_title''',
                                                                                    ).toString(),
                                                                                    textAlign: TextAlign.start,
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          fontFamily: 'SF Pro Display',
                                                                                          fontSize: 16.0,
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FontWeight.w600,
                                                                                          useGoogleFonts: false,
                                                                                          lineHeight: 1.5,
                                                                                        ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              Builder(
                                                                                builder: (context) {
                                                                                  if (_model.select ==
                                                                                      getJsonField(
                                                                                        paymentListItem,
                                                                                        r'''$.id''',
                                                                                      ).toString()) {
                                                                                    return Container(
                                                                                      width: 24.0,
                                                                                      height: 24.0,
                                                                                      decoration: BoxDecoration(
                                                                                        shape: BoxShape.circle,
                                                                                        border: Border.all(
                                                                                          color: FlutterFlowTheme.of(context).primary,
                                                                                          width: 1.0,
                                                                                        ),
                                                                                      ),
                                                                                      alignment: AlignmentDirectional(0.0, 0.0),
                                                                                      child: Container(
                                                                                        width: 14.0,
                                                                                        height: 14.0,
                                                                                        decoration: BoxDecoration(
                                                                                          color: FlutterFlowTheme.of(context).primary,
                                                                                          shape: BoxShape.circle,
                                                                                        ),
                                                                                      ),
                                                                                    );
                                                                                  } else {
                                                                                    return Container(
                                                                                      width: 24.0,
                                                                                      height: 24.0,
                                                                                      decoration: BoxDecoration(
                                                                                        shape: BoxShape.circle,
                                                                                        border: Border.all(
                                                                                          color: FlutterFlowTheme.of(context).black20,
                                                                                          width: 1.0,
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
                                                                    );
                                                                  }),
                                                                );
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Align(
                                              alignment: AlignmentDirectional(
                                                  0.0, 1.0),
                                              child: Container(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryBackground,
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsets.all(12.0),
                                                  child: FFButtonWidget(
                                                    onPressed: () async {
                                                      if (('' !=
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .getCartCall
                                                                    .shippingAddress(
                                                                  cartGetCartResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.first_name''',
                                                              ).toString()) &&
                                                          ('' !=
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .getCartCall
                                                                    .shippingAddress(
                                                                  cartGetCartResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.last_name''',
                                                              ).toString()) &&
                                                          ('' !=
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .getCartCall
                                                                    .shippingAddress(
                                                                  cartGetCartResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.address_1''',
                                                              ).toString()) &&
                                                          ('' !=
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .getCartCall
                                                                    .shippingAddress(
                                                                  cartGetCartResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.city''',
                                                              ).toString()) &&
                                                          ('' !=
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .getCartCall
                                                                    .shippingAddress(
                                                                  cartGetCartResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.postcode''',
                                                              ).toString()) &&
                                                          ('' !=
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .getCartCall
                                                                    .shippingAddress(
                                                                  cartGetCartResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.country''',
                                                              ).toString()) &&
                                                          ('' !=
                                                              getJsonField(
                                                                PlantShopGroup
                                                                    .getCartCall
                                                                    .shippingAddress(
                                                                  cartGetCartResponse
                                                                      .jsonBody,
                                                                ),
                                                                r'''$.phone''',
                                                              ).toString())) {
                                                        if (PlantShopGroup
                                                                    .getCartCall
                                                                    .shippingRates(
                                                                  cartGetCartResponse
                                                                      .jsonBody,
                                                                ) !=
                                                                null &&
                                                            (PlantShopGroup
                                                                    .getCartCall
                                                                    .shippingRates(
                                                              cartGetCartResponse
                                                                  .jsonBody,
                                                            ))!
                                                                .isNotEmpty) {
                                                          _model.process = true;
                                                          safeSetState(() {});
                                                          if (_model.select ==
                                                              'cod') {
                                                            _model.orderDetailCod =
                                                                await action_blocks
                                                                    .createOrder(
                                                              context,
                                                              paymentMethod:
                                                                  getJsonField(
                                                                _model
                                                                    .selectedMethode,
                                                                r'''$.id''',
                                                              ).toString(),
                                                              paymentMethodTitle:
                                                                  getJsonField(
                                                                _model
                                                                    .selectedMethode,
                                                                r'''$.method_title''',
                                                              ).toString(),
                                                              billing: PlantShopGroup
                                                                  .getCartCall
                                                                  .billingAddress(
                                                                cartGetCartResponse
                                                                    .jsonBody,
                                                              ),
                                                              shipping: PlantShopGroup
                                                                  .getCartCall
                                                                  .shippingAddress(
                                                                cartGetCartResponse
                                                                    .jsonBody,
                                                              ),
                                                              setPaid: false,
                                                              shippingLines:
                                                                  PlantShopGroup
                                                                      .getCartCall
                                                                      .shippingRates(
                                                                cartGetCartResponse
                                                                    .jsonBody,
                                                              ),
                                                              lineItems:
                                                                  PlantShopGroup
                                                                      .getCartCall
                                                                      .itemsList(
                                                                cartGetCartResponse
                                                                    .jsonBody,
                                                              ),
                                                              couponLines:
                                                                  PlantShopGroup
                                                                      .getCartCall
                                                                      .couponsList(
                                                                cartGetCartResponse
                                                                    .jsonBody,
                                                              ),
                                                              taxlines:
                                                                  getJsonField(
                                                                cartGetCartResponse
                                                                    .jsonBody,
                                                                r'''$.totals''',
                                                              ),
                                                              nonce: cartGetCartResponse
                                                                  .getHeader(
                                                                      'nonce'),
                                                            );
                                                            if (false ==
                                                                getJsonField(
                                                                  _model
                                                                      .orderDetailCod,
                                                                  r'''$.sucess''',
                                                                )) {
                                                              await actions
                                                                  .showCustomToastAddtoCart(
                                                                context,
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getVariableText(
                                                                  enText:
                                                                      'Something went wrong please try again!',
                                                                  arText:
                                                                      'حدث خطأ ما، يرجى المحاولة مرة أخرى!',
                                                                ),
                                                                false,
                                                                () async {},
                                                              );
                                                              _model.process =
                                                                  false;
                                                              safeSetState(
                                                                  () {});
                                                            } else {
                                                              _model.process =
                                                                  false;
                                                              safeSetState(
                                                                  () {});
                                                              if (Navigator.of(
                                                                      context)
                                                                  .canPop()) {
                                                                context.pop();
                                                              }
                                                              context.pushNamed(
                                                                SucessfullyPageWidget
                                                                    .routeName,
                                                                queryParameters:
                                                                    {
                                                                  'orderDetail':
                                                                      serializeParam(
                                                                    _model
                                                                        .orderDetailCod,
                                                                    ParamType
                                                                        .JSON,
                                                                  ),
                                                                }.withoutNulls,
                                                              );
                                                            }
                                                          } else if (_model
                                                                  .select ==
                                                              'razorpay') {
                                                            await actions
                                                                .razorpayCustom(
                                                              context,
                                                              getJsonField(
                                                                _model
                                                                    .selectedMethode,
                                                                r'''$.settings.key_id.value''',
                                                              ).toString(),
                                                              functions.divideBy100(
                                                                  PlantShopGroup
                                                                      .getCartCall
                                                                      .totalPrice(
                                                                cartGetCartResponse
                                                                    .jsonBody,
                                                              )!),
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
                                                                _model.orderDetailRazorpay =
                                                                    await action_blocks
                                                                        .createOrder(
                                                                  context,
                                                                  paymentMethod:
                                                                      getJsonField(
                                                                    _model
                                                                        .selectedMethode,
                                                                    r'''$.id''',
                                                                  ).toString(),
                                                                  paymentMethodTitle:
                                                                      getJsonField(
                                                                    _model
                                                                        .selectedMethode,
                                                                    r'''$.method_title''',
                                                                  ).toString(),
                                                                  billing: PlantShopGroup
                                                                      .getCartCall
                                                                      .billingAddress(
                                                                    cartGetCartResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  shipping: PlantShopGroup
                                                                      .getCartCall
                                                                      .shippingAddress(
                                                                    cartGetCartResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  setPaid: true,
                                                                  shippingLines:
                                                                      PlantShopGroup
                                                                          .getCartCall
                                                                          .shippingRates(
                                                                    cartGetCartResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  lineItems: PlantShopGroup
                                                                      .getCartCall
                                                                      .itemsList(
                                                                    cartGetCartResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  couponLines:
                                                                      PlantShopGroup
                                                                          .getCartCall
                                                                          .couponsList(
                                                                    cartGetCartResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  taxlines:
                                                                      getJsonField(
                                                                    cartGetCartResponse
                                                                        .jsonBody,
                                                                    r'''$.totals''',
                                                                  ),
                                                                  nonce: cartGetCartResponse
                                                                      .getHeader(
                                                                          'nonce'),
                                                                );
                                                                if (false ==
                                                                    getJsonField(
                                                                      _model
                                                                          .orderDetailRazorpay,
                                                                      r'''$.sucess''',
                                                                    )) {
                                                                  await actions
                                                                      .showCustomToastAddtoCart(
                                                                    context,
                                                                    FFLocalizations.of(
                                                                            context)
                                                                        .getVariableText(
                                                                      enText:
                                                                          'Something went wrong please try again!',
                                                                      arText:
                                                                          'حدث خطأ ما، يرجى المحاولة مرة أخرى!',
                                                                    ),
                                                                    false,
                                                                    () async {},
                                                                  );
                                                                  _model.process =
                                                                      false;
                                                                  safeSetState(
                                                                      () {});
                                                                } else {
                                                                  _model.process =
                                                                      false;
                                                                  safeSetState(
                                                                      () {});
                                                                  if (Navigator.of(
                                                                          context)
                                                                      .canPop()) {
                                                                    context
                                                                        .pop();
                                                                  }
                                                                  context
                                                                      .pushNamed(
                                                                    SucessfullyPageWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'orderDetail':
                                                                          serializeParam(
                                                                        _model
                                                                            .orderDetailRazorpay,
                                                                        ParamType
                                                                            .JSON,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
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
                                                                        _model
                                                                            .selectedMethode,
                                                                        r'''$.settings.testmode.value''',
                                                                      ).toString()
                                                                  ? getJsonField(
                                                                      _model
                                                                          .selectedMethode,
                                                                      r'''$.settings.test_publishable_key.value''',
                                                                    ).toString()
                                                                  : getJsonField(
                                                                      _model
                                                                          .selectedMethode,
                                                                      r'''$.settings.publishable_key.value''',
                                                                    ).toString(),
                                                            );
                                                            await actions
                                                                .stripeCustom(
                                                              context,
                                                              functions.divideBy100(
                                                                  PlantShopGroup
                                                                      .getCartCall
                                                                      .totalPrice(
                                                                cartGetCartResponse
                                                                    .jsonBody,
                                                              )!),
                                                              FFAppState()
                                                                  .currencyCode,
                                                              getJsonField(
                                                                FFAppState()
                                                                    .userDetail,
                                                                r'''$.billing.country''',
                                                              ).toString(),
                                                              (transactionId) async {
                                                                _model.orderDetailStripe =
                                                                    await action_blocks
                                                                        .createOrder(
                                                                  context,
                                                                  paymentMethod:
                                                                      getJsonField(
                                                                    _model
                                                                        .selectedMethode,
                                                                    r'''$.id''',
                                                                  ).toString(),
                                                                  paymentMethodTitle:
                                                                      getJsonField(
                                                                    _model
                                                                        .selectedMethode,
                                                                    r'''$.method_title''',
                                                                  ).toString(),
                                                                  billing: PlantShopGroup
                                                                      .getCartCall
                                                                      .billingAddress(
                                                                    cartGetCartResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  shipping: PlantShopGroup
                                                                      .getCartCall
                                                                      .shippingAddress(
                                                                    cartGetCartResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  setPaid: true,
                                                                  shippingLines:
                                                                      PlantShopGroup
                                                                          .getCartCall
                                                                          .shippingRates(
                                                                    cartGetCartResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  lineItems: PlantShopGroup
                                                                      .getCartCall
                                                                      .itemsList(
                                                                    cartGetCartResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  couponLines:
                                                                      PlantShopGroup
                                                                          .getCartCall
                                                                          .couponsList(
                                                                    cartGetCartResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  taxlines:
                                                                      getJsonField(
                                                                    cartGetCartResponse
                                                                        .jsonBody,
                                                                    r'''$.totals''',
                                                                  ),
                                                                  nonce: cartGetCartResponse
                                                                      .getHeader(
                                                                          'nonce'),
                                                                );
                                                                if (false ==
                                                                    getJsonField(
                                                                      _model
                                                                          .orderDetailStripe,
                                                                      r'''$.sucess''',
                                                                    )) {
                                                                  await actions
                                                                      .showCustomToastAddtoCart(
                                                                    context,
                                                                    FFLocalizations.of(
                                                                            context)
                                                                        .getVariableText(
                                                                      enText:
                                                                          'Something went wrong please try again!',
                                                                      arText:
                                                                          'حدث خطأ ما، يرجى المحاولة مرة أخرى!',
                                                                    ),
                                                                    false,
                                                                    () async {},
                                                                  );
                                                                  _model.process =
                                                                      false;
                                                                  safeSetState(
                                                                      () {});
                                                                } else {
                                                                  _model.process =
                                                                      false;
                                                                  safeSetState(
                                                                      () {});
                                                                  if (Navigator.of(
                                                                          context)
                                                                      .canPop()) {
                                                                    context
                                                                        .pop();
                                                                  }
                                                                  context
                                                                      .pushNamed(
                                                                    SucessfullyPageWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'orderDetail':
                                                                          serializeParam(
                                                                        _model
                                                                            .orderDetailStripe,
                                                                        ParamType
                                                                            .JSON,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
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
                                                                        _model
                                                                            .selectedMethode,
                                                                        r'''$.settings.testmode.value''',
                                                                      ).toString()
                                                                  ? getJsonField(
                                                                      _model
                                                                          .selectedMethode,
                                                                      r'''$.settings.test_secret_key.value''',
                                                                    ).toString()
                                                                  : getJsonField(
                                                                      _model
                                                                          .selectedMethode,
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
                                                              functions.divideBy100(
                                                                  PlantShopGroup
                                                                      .getCartCall
                                                                      .totalPrice(
                                                                cartGetCartResponse
                                                                    .jsonBody,
                                                              )!),
                                                              FFAppState()
                                                                  .currencyCode,
                                                              'Order using paypal to byu a product',
                                                              (transactionId) async {
                                                                _model.orderDetailPayPal =
                                                                    await action_blocks
                                                                        .createOrder(
                                                                  context,
                                                                  paymentMethod:
                                                                      getJsonField(
                                                                    _model
                                                                        .selectedMethode,
                                                                    r'''$.id''',
                                                                  ).toString(),
                                                                  paymentMethodTitle:
                                                                      getJsonField(
                                                                    _model
                                                                        .selectedMethode,
                                                                    r'''$.method_title''',
                                                                  ).toString(),
                                                                  billing: PlantShopGroup
                                                                      .getCartCall
                                                                      .billingAddress(
                                                                    cartGetCartResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  shipping: PlantShopGroup
                                                                      .getCartCall
                                                                      .shippingAddress(
                                                                    cartGetCartResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  setPaid: true,
                                                                  shippingLines:
                                                                      PlantShopGroup
                                                                          .getCartCall
                                                                          .shippingRates(
                                                                    cartGetCartResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  lineItems: PlantShopGroup
                                                                      .getCartCall
                                                                      .itemsList(
                                                                    cartGetCartResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  couponLines:
                                                                      PlantShopGroup
                                                                          .getCartCall
                                                                          .couponsList(
                                                                    cartGetCartResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  taxlines:
                                                                      getJsonField(
                                                                    cartGetCartResponse
                                                                        .jsonBody,
                                                                    r'''$.totals''',
                                                                  ),
                                                                  nonce: cartGetCartResponse
                                                                      .getHeader(
                                                                          'nonce'),
                                                                );
                                                                if (false ==
                                                                    getJsonField(
                                                                      _model
                                                                          .orderDetailPayPal,
                                                                      r'''$.sucess''',
                                                                    )) {
                                                                  await actions
                                                                      .showCustomToastAddtoCart(
                                                                    context,
                                                                    FFLocalizations.of(
                                                                            context)
                                                                        .getVariableText(
                                                                      enText:
                                                                          'Something went wrong please try again!',
                                                                      arText:
                                                                          'حدث خطأ ما، يرجى المحاولة مرة أخرى!',
                                                                    ),
                                                                    false,
                                                                    () async {},
                                                                  );
                                                                  _model.process =
                                                                      false;
                                                                  safeSetState(
                                                                      () {});
                                                                } else {
                                                                  _model.process =
                                                                      false;
                                                                  safeSetState(
                                                                      () {});
                                                                  if (Navigator.of(
                                                                          context)
                                                                      .canPop()) {
                                                                    context
                                                                        .pop();
                                                                  }
                                                                  context
                                                                      .pushNamed(
                                                                    SucessfullyPageWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'orderDetail':
                                                                          serializeParam(
                                                                        _model
                                                                            .orderDetailPayPal,
                                                                        ParamType
                                                                            .JSON,
                                                                      ),
                                                                    }.withoutNulls,
                                                                  );
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
                                                            _model.orderDetailWebview =
                                                                await action_blocks
                                                                    .createOrder(
                                                              context,
                                                              paymentMethod:
                                                                  'cod',
                                                              paymentMethodTitle:
                                                                  'Cash on delivery',
                                                              billing: PlantShopGroup
                                                                  .getCartCall
                                                                  .billingAddress(
                                                                cartGetCartResponse
                                                                    .jsonBody,
                                                              ),
                                                              shipping: PlantShopGroup
                                                                  .getCartCall
                                                                  .shippingAddress(
                                                                cartGetCartResponse
                                                                    .jsonBody,
                                                              ),
                                                              setPaid: false,
                                                              shippingLines:
                                                                  PlantShopGroup
                                                                      .getCartCall
                                                                      .shippingRates(
                                                                cartGetCartResponse
                                                                    .jsonBody,
                                                              ),
                                                              lineItems:
                                                                  PlantShopGroup
                                                                      .getCartCall
                                                                      .itemsList(
                                                                cartGetCartResponse
                                                                    .jsonBody,
                                                              ),
                                                              couponLines:
                                                                  PlantShopGroup
                                                                      .getCartCall
                                                                      .couponsList(
                                                                cartGetCartResponse
                                                                    .jsonBody,
                                                              ),
                                                              taxlines:
                                                                  getJsonField(
                                                                cartGetCartResponse
                                                                    .jsonBody,
                                                                r'''$.totals''',
                                                              ),
                                                              nonce: cartGetCartResponse
                                                                  .getHeader(
                                                                      'nonce'),
                                                            );
                                                            if (false ==
                                                                getJsonField(
                                                                  _model
                                                                      .orderDetailWebview,
                                                                  r'''$.sucess''',
                                                                )) {
                                                              await actions
                                                                  .showCustomToastAddtoCart(
                                                                context,
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getVariableText(
                                                                  enText:
                                                                      'Something went wrong please try again!',
                                                                  arText:
                                                                      'حدث خطأ ما، يرجى المحاولة مرة أخرى!',
                                                                ),
                                                                false,
                                                                () async {},
                                                              );
                                                              _model.process =
                                                                  false;
                                                              safeSetState(
                                                                  () {});
                                                            } else {
                                                              _model.process =
                                                                  false;
                                                              safeSetState(
                                                                  () {});
                                                              await actions
                                                                  .showCustomToastTop(
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getVariableText(
                                                                  enText:
                                                                      'Please tap \'Pay for this order\' to check out in website',
                                                                  arText:
                                                                      'الرجاء الضغط على \"الدفع مقابل هذا الطلب\" للتحقق من الموقع',
                                                                ),
                                                              );

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
                                                                      _model
                                                                          .orderDetailWebview,
                                                                      r'''$.id''',
                                                                    ),
                                                                    ParamType
                                                                        .int,
                                                                  ),
                                                                }.withoutNulls,
                                                              );
                                                            }
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
                                                            safeSetState(() {});
                                                          }
                                                        }



                                                      } else {
                                                        await actions
                                                            .showCustomToastTop(
                                                          FFLocalizations.of(
                                                                  context)
                                                              .getVariableText(
                                                            enText:
                                                                'Please add shipping address.',
                                                            arText:
                                                                'الرجاء إضافة عنوان الشحن.',
                                                          ),
                                                        );
                                                      }

                                                      safeSetState(() {});
                                                    },
                                                    text: FFLocalizations.of(
                                                            context)
                                                        .getText(
                                                      'tmlmzccj' /* Confirm Payment */,
                                                    ),
                                                    options: FFButtonOptions(
                                                      width: double.infinity,
                                                      height: 56.0,
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  20.0,
                                                                  0.0,
                                                                  20.0,
                                                                  0.0),
                                                      iconPadding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      textStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleSmall
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                color: Colors
                                                                    .white,
                                                                letterSpacing:
                                                                    0.0,
                                                                useGoogleFonts:
                                                                    false,
                                                              ),
                                                      elevation: 0.0,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12.0),
                                                    ),
                                                    showLoadingIndicator: false,
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
              if (_model.process)
                InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () async {},
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Color(0x19000000),
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}
