import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/center_appbar/center_appbar_widget.dart';
import '/pages/components/main_component/main_component_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/dialog_components/cart_item_delete_component/cart_item_delete_component_widget.dart';
import '/pages/empty_components/no_cart_component/no_cart_component_widget.dart';
import '/pages/shimmer/cart_shimmer/cart_shimmer_widget.dart';
import '/pages/shimmer/main_component_shimmer/main_component_shimmer_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:styled_divider/styled_divider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'cart_component_model.dart';
export 'cart_component_model.dart';

class CartComponentWidget extends StatefulWidget {
  const CartComponentWidget({
    super.key,
    bool? isBack,
  }) : this.isBack = isBack ?? false;

  final bool isBack;

  @override
  State<CartComponentWidget> createState() => _CartComponentWidgetState();
}

class _CartComponentWidgetState extends State<CartComponentWidget>
    with RouteAware {
  late CartComponentModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CartComponentModel());

    // On component load action.
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

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).lightGray,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              wrapWithModel(
                model: _model.centerAppbarModel,
                updateCallback: () => safeSetState(() {}),
                child: Builder(builder: (_) {
                  return DebugFlutterFlowModelContext(
                    rootModel: _model.rootModel,
                    child: CenterAppbarWidget(
                      title: FFLocalizations.of(context).getText(
                        'vm44u9cc' /* Cart */,
                      ),
                      isBack: widget!.isBack,
                      backAction: () async {
                        context.safePop();
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
                                final cartGetCartResponse = snapshot.data!;
                                _model.debugBackendQueries[
                                        'PlantShopGroup.getCartCall_statusCode_Container_vqlr5bx8'] =
                                    debugSerializeParam(
                                  cartGetCartResponse.statusCode,
                                  ParamType.int,
                                  link:
                                      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
                                  name: 'int',
                                  nullable: false,
                                );
                                _model.debugBackendQueries[
                                        'PlantShopGroup.getCartCall_responseBody_Container_vqlr5bx8'] =
                                    debugSerializeParam(
                                  cartGetCartResponse.bodyText,
                                  ParamType.String,
                                  link:
                                      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
                                  name: 'String',
                                  nullable: false,
                                );
                                debugLogWidgetClass(_model);

                                return Container(
                                  decoration: BoxDecoration(),
                                  child: Builder(
                                    builder: (context) {
                                      if ((FFAppState().isLogin == true) &&
                                          (PlantShopGroup.getCartCall.itemsList(
                                                    cartGetCartResponse
                                                        .jsonBody,
                                                  ) !=
                                                  null &&
                                              (PlantShopGroup.getCartCall
                                                      .itemsList(
                                                cartGetCartResponse.jsonBody,
                                              ))!
                                                  .isNotEmpty)) {
                                        return Container(
                                          decoration: BoxDecoration(),
                                          child: Stack(
                                            children: [
                                              RefreshIndicator(
                                                key: Key(
                                                    'RefreshIndicator_elrlkt7l'),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                onRefresh: () async {
                                                  safeSetState(() {
                                                    FFAppState()
                                                        .clearCartCache();
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
                                                    108.0,
                                                  ),
                                                  scrollDirection:
                                                      Axis.vertical,
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
                                                                      size:
                                                                          20.0,
                                                                    ),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          5.0,
                                                                          0.0,
                                                                          0.0),
                                                                  child: Text(
                                                                    FFLocalizations.of(
                                                                            context)
                                                                        .getText(
                                                                      'l0100w0k' /* My Cart */,
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
                                                                      height:
                                                                          1.0,
                                                                      thickness:
                                                                          0.0,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .black30,
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
                                                                        .black10,
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
                                                                          .black40,
                                                                      size:
                                                                          20.0,
                                                                    ),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          5.0,
                                                                          0.0,
                                                                          0.0),
                                                                  child: Text(
                                                                    FFLocalizations.of(
                                                                            context)
                                                                        .getText(
                                                                      'xlvvckcw' /* Payment */,
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
                                                                          color:
                                                                              FlutterFlowTheme.of(context).secondaryText,
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
                                                              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
                                                          name: 'dynamic',
                                                          nullable: false,
                                                        );
                                                        debugLogWidgetClass(
                                                            _model);

                                                        return Column(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          children: List.generate(
                                                                  cartList
                                                                      .length,
                                                                  (cartListIndex) {
                                                            final cartListItem =
                                                                cartList[
                                                                    cartListIndex];
                                                            return Container(
                                                              width: double
                                                                  .infinity,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryBackground,
                                                              ),
                                                              child: Padding(
                                                                padding: EdgeInsetsDirectional
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
                                                                      padding: EdgeInsetsDirectional.fromSTEB(
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
                                                                              fadeInDuration: Duration(milliseconds: 200),
                                                                              fadeOutDuration: Duration(milliseconds: 200),
                                                                              imageUrl: getJsonField(
                                                                                cartListItem,
                                                                                r'''$.images[0].src''',
                                                                              ).toString(),
                                                                              width: 95.0,
                                                                              height: 95.0,
                                                                              fit: BoxFit.cover,
                                                                              alignment: Alignment(0.0, 0.0),
                                                                              errorWidget: (context, error, stackTrace) => Image.asset(
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
                                                                            MainAxisSize.max,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.start,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
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
                                                                              InkWell(
                                                                                splashColor: Colors.transparent,
                                                                                focusColor: Colors.transparent,
                                                                                hoverColor: Colors.transparent,
                                                                                highlightColor: Colors.transparent,
                                                                                onTap: () async {
                                                                                  await showModalBottomSheet(
                                                                                    isScrollControlled: true,
                                                                                    backgroundColor: Colors.transparent,
                                                                                    enableDrag: false,
                                                                                    context: context,
                                                                                    builder: (context) {
                                                                                      return Padding(
                                                                                        padding: MediaQuery.viewInsetsOf(context),
                                                                                        child: CartItemDeleteComponentWidget(
                                                                                          onTapYes: () async {
                                                                                            _model.success = await action_blocks.deleteCartItem(
                                                                                              context,
                                                                                              keyId: getJsonField(
                                                                                                cartListItem,
                                                                                                r'''$.key''',
                                                                                              ).toString(),
                                                                                              nonce: cartGetCartResponse.getHeader('nonce'),
                                                                                            );
                                                                                            if (PlantShopGroup.getCartCall
                                                                                                    .itemsList(
                                                                                                      cartGetCartResponse.jsonBody,
                                                                                                    )
                                                                                                    ?.length ==
                                                                                                1) {
                                                                                              await actions.removeCouponCode(
                                                                                                PlantShopGroup.getCartCall
                                                                                                    .couponsList(
                                                                                                      cartGetCartResponse.jsonBody,
                                                                                                    )!
                                                                                                    .toList(),
                                                                                                (code) async {
                                                                                                  _model.removeCouponCopy = await PlantShopGroup.removeCouponCodeCall.call(
                                                                                                    code: code,
                                                                                                    nonce: cartGetCartResponse.getHeader('nonce'),
                                                                                                    token: FFAppState().token,
                                                                                                  );
                                                                                                },
                                                                                              );
                                                                                            }
                                                                                            safeSetState(() {
                                                                                              FFAppState().clearCartCache();
                                                                                              _model.apiRequestCompleted = false;
                                                                                            });
                                                                                            await _model.waitForApiRequestCompleted();
                                                                                            Navigator.pop(context);
                                                                                          },
                                                                                        ),
                                                                                      );
                                                                                    },
                                                                                  ).then((value) => safeSetState(() {}));

                                                                                  safeSetState(() {});
                                                                                },
                                                                                child: Container(
                                                                                  decoration: BoxDecoration(),
                                                                                  child: Padding(
                                                                                    padding: EdgeInsets.all(6.0),
                                                                                    child: SvgPicture.asset(
                                                                                      'assets/images/delete_account.svg',
                                                                                      width: 20.0,
                                                                                      height: 20.0,
                                                                                      fit: BoxFit.cover,
                                                                                    ),
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
                                                                              textAlign: TextAlign.start,
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
                                                                          Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                0.0,
                                                                                4.0,
                                                                                0.0,
                                                                                0.0),
                                                                            child:
                                                                                Row(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                                              children: [
                                                                                Expanded(
                                                                                  child: Row(
                                                                                    mainAxisSize: MainAxisSize.max,
                                                                                    children: [
                                                                                      Expanded(
                                                                                        child: Column(
                                                                                          mainAxisSize: MainAxisSize.max,
                                                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                                                          children: [
                                                                                            if (functions
                                                                                                .jsonToListConverter(getJsonField(
                                                                                                  cartListItem,
                                                                                                  r'''$.variation''',
                                                                                                  true,
                                                                                                )!)
                                                                                                .isNotEmpty)
                                                                                              Builder(
                                                                                                builder: (context) {
                                                                                                  final variationList = getJsonField(
                                                                                                    cartListItem,
                                                                                                    r'''$.variation''',
                                                                                                  ).toList();
                                                                                                  _model.debugGeneratorVariables['variationList${variationList.length > 100 ? ' (first 100)' : ''}'] = debugSerializeParam(
                                                                                                    variationList.take(100),
                                                                                                    ParamType.JSON,
                                                                                                    link: 'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
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
                                                                                                                'rb9w1nuh' /*  :  */,
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
                                                                                            RichText(
                                                                                              textScaler: MediaQuery.of(context).textScaler,
                                                                                              text: TextSpan(
                                                                                                children: [
                                                                                                  TextSpan(
                                                                                                    text: FFLocalizations.of(context).getText(
                                                                                                      'bgw2bqbg' /* Total :  */,
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
                                                                                              textAlign: TextAlign.start,
                                                                                            ),
                                                                                          ].divide(SizedBox(height: 4.0)),
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
                                                                                    if (!_model.process) {
                                                                                      _model.process = true;
                                                                                      _model.keyId = getJsonField(
                                                                                        cartListItem,
                                                                                        r'''$.key''',
                                                                                      ).toString();
                                                                                      safeSetState(() {});
                                                                                      if ('1' !=
                                                                                          getJsonField(
                                                                                            cartListItem,
                                                                                            r'''$.quantity''',
                                                                                          ).toString()) {
                                                                                        _model.successUpdate = await action_blocks.updateCart(
                                                                                          context,
                                                                                          nonce: cartGetCartResponse.getHeader('nonce'),
                                                                                          qty: (getJsonField(
                                                                                                    cartListItem,
                                                                                                    r'''$.quantity''',
                                                                                                  ) -
                                                                                                  1)
                                                                                              .toString(),
                                                                                          keyId: getJsonField(
                                                                                            cartListItem,
                                                                                            r'''$.key''',
                                                                                          ).toString(),
                                                                                          id: getJsonField(
                                                                                            cartListItem,
                                                                                            r'''$.id''',
                                                                                          ).toString(),
                                                                                        );
                                                                                        safeSetState(() {
                                                                                          FFAppState().clearCartCache();
                                                                                          _model.apiRequestCompleted = false;
                                                                                        });
                                                                                        await _model.waitForApiRequestCompleted();
                                                                                      }
                                                                                      _model.process = false;
                                                                                      _model.keyId = '5';
                                                                                      safeSetState(() {});
                                                                                    }

                                                                                    safeSetState(() {});
                                                                                  },
                                                                                  child: Container(
                                                                                    decoration: BoxDecoration(),
                                                                                    child: Padding(
                                                                                      padding: EdgeInsets.all(4.0),
                                                                                      child: Container(
                                                                                        decoration: BoxDecoration(
                                                                                          color: FlutterFlowTheme.of(context).lightGray,
                                                                                          shape: BoxShape.circle,
                                                                                        ),
                                                                                        child: Padding(
                                                                                          padding: EdgeInsets.all(5.0),
                                                                                          child: Builder(
                                                                                            builder: (context) {
                                                                                              if (!(_model.process &&
                                                                                                  (_model.keyId ==
                                                                                                      getJsonField(
                                                                                                        cartListItem,
                                                                                                        r'''$.key''',
                                                                                                      ).toString()))) {
                                                                                                return Icon(
                                                                                                  Icons.remove,
                                                                                                  color: FlutterFlowTheme.of(context).primary,
                                                                                                  size: 18.0,
                                                                                                );
                                                                                              } else {
                                                                                                return Container(
                                                                                                  width: 18.0,
                                                                                                  height: 18.0,
                                                                                                  child: custom_widgets.CirculatIndicator(
                                                                                                    width: 18.0,
                                                                                                    height: 18.0,
                                                                                                  ),
                                                                                                );
                                                                                              }
                                                                                            },
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                Padding(
                                                                                  padding: EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 10.0, 0.0),
                                                                                  child: Text(
                                                                                    getJsonField(
                                                                                      cartListItem,
                                                                                      r'''$.quantity''',
                                                                                    ).toString(),
                                                                                    textAlign: TextAlign.start,
                                                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                          fontFamily: 'SF Pro Display',
                                                                                          fontSize: 15.0,
                                                                                          letterSpacing: 0.0,
                                                                                          fontWeight: FontWeight.w500,
                                                                                          useGoogleFonts: false,
                                                                                          lineHeight: 1.5,
                                                                                        ),
                                                                                  ),
                                                                                ),
                                                                                InkWell(
                                                                                  splashColor: Colors.transparent,
                                                                                  focusColor: Colors.transparent,
                                                                                  hoverColor: Colors.transparent,
                                                                                  highlightColor: Colors.transparent,
                                                                                  onTap: () async {
                                                                                    if (!_model.process) {
                                                                                      _model.process = true;
                                                                                      _model.keyId = '${getJsonField(
                                                                                        cartListItem,
                                                                                        r'''$.key''',
                                                                                      ).toString()}add';
                                                                                      safeSetState(() {});
                                                                                      _model.successUpdateCopy = await action_blocks.updateCart(
                                                                                        context,
                                                                                        nonce: cartGetCartResponse.getHeader('nonce'),
                                                                                        qty: (getJsonField(
                                                                                                  cartListItem,
                                                                                                  r'''$.quantity''',
                                                                                                ) +
                                                                                                1)
                                                                                            .toString(),
                                                                                        keyId: getJsonField(
                                                                                          cartListItem,
                                                                                          r'''$.key''',
                                                                                        ).toString(),
                                                                                        id: getJsonField(
                                                                                          cartListItem,
                                                                                          r'''$.id''',
                                                                                        ).toString(),
                                                                                      );
                                                                                      safeSetState(() {
                                                                                        FFAppState().clearCartCache();
                                                                                        _model.apiRequestCompleted = false;
                                                                                      });
                                                                                      await _model.waitForApiRequestCompleted();
                                                                                      _model.process = false;
                                                                                      _model.keyId = '5';
                                                                                      safeSetState(() {});
                                                                                    }

                                                                                    safeSetState(() {});
                                                                                  },
                                                                                  child: Container(
                                                                                    decoration: BoxDecoration(),
                                                                                    child: Padding(
                                                                                      padding: EdgeInsets.all(4.0),
                                                                                      child: Container(
                                                                                        decoration: BoxDecoration(
                                                                                          color: FlutterFlowTheme.of(context).lightGray,
                                                                                          shape: BoxShape.circle,
                                                                                        ),
                                                                                        child: Padding(
                                                                                          padding: EdgeInsets.all(5.0),
                                                                                          child: Builder(
                                                                                            builder: (context) {
                                                                                              if (!(_model.process &&
                                                                                                  (_model.keyId ==
                                                                                                      '${getJsonField(
                                                                                                        cartListItem,
                                                                                                        r'''$.key''',
                                                                                                      ).toString()}add'))) {
                                                                                                return Icon(
                                                                                                  Icons.add,
                                                                                                  color: FlutterFlowTheme.of(context).primary,
                                                                                                  size: 18.0,
                                                                                                );
                                                                                              } else {
                                                                                                return Container(
                                                                                                  width: 18.0,
                                                                                                  height: 18.0,
                                                                                                  child: custom_widgets.CirculatIndicator(
                                                                                                    width: 18.0,
                                                                                                    height: 18.0,
                                                                                                  ),
                                                                                                );
                                                                                              }
                                                                                            },
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ],
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
                                                    if (PlantShopGroup
                                                                .getCartCall
                                                                .crossSellsIdList(
                                                              cartGetCartResponse
                                                                  .jsonBody,
                                                            ) !=
                                                            null &&
                                                        (PlantShopGroup
                                                                .getCartCall
                                                                .crossSellsIdList(
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
                                                                        FFLocalizations.of(context)
                                                                            .getText(
                                                                          'jq6v4dgk' /* There’s  More Product To Try! */,
                                                                        ),
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
                                                                          context
                                                                              .pushNamed(
                                                                            MoreProductPageWidget.routeName,
                                                                            queryParameters:
                                                                                {
                                                                              'moreProductList': serializeParam(
                                                                                PlantShopGroup.getCartCall.crossSellsIdList(
                                                                                  cartGetCartResponse.jsonBody,
                                                                                ),
                                                                                ParamType.int,
                                                                                isList: true,
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
                                                                            color:
                                                                                FlutterFlowTheme.of(context).black10,
                                                                            borderRadius:
                                                                                BorderRadius.circular(30.0),
                                                                          ),
                                                                          alignment: AlignmentDirectional(
                                                                              0.0,
                                                                              0.0),
                                                                          child:
                                                                              Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                10.0,
                                                                                0.0,
                                                                                10.0,
                                                                                0.0),
                                                                            child:
                                                                                Text(
                                                                              FFLocalizations.of(context).getText(
                                                                                'ht9njueb' /* View all */,
                                                                              ),
                                                                              textAlign: TextAlign.start,
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
                                                                      final crossSellsList = (PlantShopGroup.getCartCall
                                                                                  .crossSellsIdList(
                                                                                    cartGetCartResponse.jsonBody,
                                                                                  )
                                                                                  ?.toList() ??
                                                                              [])
                                                                          .take(6)
                                                                          .toList();
                                                                      _model.debugGeneratorVariables[
                                                                              'crossSellsList${crossSellsList.length > 100 ? ' (first 100)' : ''}'] =
                                                                          debugSerializeParam(
                                                                        crossSellsList
                                                                            .take(100),
                                                                        ParamType
                                                                            .int,
                                                                        isList:
                                                                            true,
                                                                        link:
                                                                            'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
                                                                        name:
                                                                            'int',
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
                                                                          children: List.generate(
                                                                              crossSellsList.length,
                                                                              (crossSellsListIndex) {
                                                                            final crossSellsListItem =
                                                                                crossSellsList[crossSellsListIndex];
                                                                            return FutureBuilder<ApiCallResponse>(
                                                                              future: FFAppState().productDdetail(
                                                                                uniqueQueryKey: crossSellsListItem.toString(),
                                                                                requestFn: () => PlantShopGroup.productDetailCall.call(
                                                                                  productId: crossSellsListItem.toString(),
                                                                                ),
                                                                              ),
                                                                              builder: (context, snapshot) {
                                                                                // Customize what your widget looks like when it's loading.
                                                                                if (!snapshot.hasData) {
                                                                                  return MainComponentShimmerWidget(
                                                                                    isBig: true,
                                                                                    width: 189.0,
                                                                                    height: 298.0,
                                                                                  );
                                                                                }
                                                                                final containerProductDetailResponse = snapshot.data!;
                                                                                _model.debugBackendQueries['PlantShopGroup.productDetailCall_statusCode_Container_pc052e4q'] = debugSerializeParam(
                                                                                  containerProductDetailResponse.statusCode,
                                                                                  ParamType.int,
                                                                                  link: 'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
                                                                                  name: 'int',
                                                                                  nullable: false,
                                                                                );
                                                                                _model.debugBackendQueries['PlantShopGroup.productDetailCall_responseBody_Container_pc052e4q'] = debugSerializeParam(
                                                                                  containerProductDetailResponse.bodyText,
                                                                                  ParamType.String,
                                                                                  link: 'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
                                                                                  name: 'String',
                                                                                  nullable: false,
                                                                                );
                                                                                debugLogWidgetClass(_model);

                                                                                return Container(
                                                                                  decoration: BoxDecoration(),
                                                                                  child: wrapWithModel(
                                                                                    model: _model.mainComponentModels.getModel(
                                                                                      crossSellsListItem.toString(),
                                                                                      crossSellsListIndex,
                                                                                    ),
                                                                                    updateCallback: () => safeSetState(() {}),
                                                                                    child: Builder(builder: (_) {
                                                                                      return DebugFlutterFlowModelContext(
                                                                                        rootModel: _model.rootModel,
                                                                                        child: MainComponentWidget(
                                                                                          key: Key(
                                                                                            'Keyx9u_${crossSellsListItem.toString()}',
                                                                                          ),
                                                                                          image: getJsonField(
                                                                                            PlantShopGroup.productDetailCall.productDetail(
                                                                                              containerProductDetailResponse.jsonBody,
                                                                                            ),
                                                                                            r'''$.images[0].src''',
                                                                                          ).toString(),
                                                                                          name: getJsonField(
                                                                                            PlantShopGroup.productDetailCall.productDetail(
                                                                                              containerProductDetailResponse.jsonBody,
                                                                                            ),
                                                                                            r'''$.name''',
                                                                                          ).toString(),
                                                                                          isLike: FFAppState().wishList.contains(crossSellsListItem.toString()),
                                                                                          regularPrice: getJsonField(
                                                                                            PlantShopGroup.productDetailCall.productDetail(
                                                                                              containerProductDetailResponse.jsonBody,
                                                                                            ),
                                                                                            r'''$.regular_price''',
                                                                                          ).toString(),
                                                                                          price: getJsonField(
                                                                                            PlantShopGroup.productDetailCall.productDetail(
                                                                                              containerProductDetailResponse.jsonBody,
                                                                                            ),
                                                                                            r'''$.price''',
                                                                                          ).toString(),
                                                                                          review: getJsonField(
                                                                                            PlantShopGroup.productDetailCall.productDetail(
                                                                                              containerProductDetailResponse.jsonBody,
                                                                                            ),
                                                                                            r'''$.rating_count''',
                                                                                          ).toString(),
                                                                                          isBigContainer: true,
                                                                                          height: ('' !=
                                                                                                      getJsonField(
                                                                                                        PlantShopGroup.productDetailCall.productDetail(
                                                                                                          containerProductDetailResponse.jsonBody,
                                                                                                        ),
                                                                                                        r'''$.images[0].src''',
                                                                                                      ).toString()) &&
                                                                                                  (getJsonField(
                                                                                                        PlantShopGroup.productDetailCall.productDetail(
                                                                                                          containerProductDetailResponse.jsonBody,
                                                                                                        ),
                                                                                                        r'''$.images[0].src''',
                                                                                                      ) !=
                                                                                                      null) &&
                                                                                                  (getJsonField(
                                                                                                        PlantShopGroup.productDetailCall.productDetail(
                                                                                                          containerProductDetailResponse.jsonBody,
                                                                                                        ),
                                                                                                        r'''$.images''',
                                                                                                      ) !=
                                                                                                      null)
                                                                                              ? 298.0
                                                                                              : 180.0,
                                                                                          width: 189.0,
                                                                                          onSale: getJsonField(
                                                                                            PlantShopGroup.productDetailCall.productDetail(
                                                                                              containerProductDetailResponse.jsonBody,
                                                                                            ),
                                                                                            r'''$.on_sale''',
                                                                                          ),
                                                                                          showImage: ('' !=
                                                                                                  getJsonField(
                                                                                                    PlantShopGroup.productDetailCall.productDetail(
                                                                                                      containerProductDetailResponse.jsonBody,
                                                                                                    ),
                                                                                                    r'''$.images[0].src''',
                                                                                                  ).toString()) &&
                                                                                              (getJsonField(
                                                                                                    PlantShopGroup.productDetailCall.productDetail(
                                                                                                      containerProductDetailResponse.jsonBody,
                                                                                                    ),
                                                                                                    r'''$.images[0].src''',
                                                                                                  ) !=
                                                                                                  null) &&
                                                                                              (getJsonField(
                                                                                                    PlantShopGroup.productDetailCall.productDetail(
                                                                                                      containerProductDetailResponse.jsonBody,
                                                                                                    ),
                                                                                                    r'''$.images''',
                                                                                                  ) !=
                                                                                                  null),
                                                                                          isLikeTap: () async {
                                                                                            if (FFAppState().isLogin) {
                                                                                              await action_blocks.addorRemoveFavourite(
                                                                                                context,
                                                                                                id: crossSellsListItem.toString(),
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
                                                                                                  PlantShopGroup.productDetailCall.productDetail(
                                                                                                    containerProductDetailResponse.jsonBody,
                                                                                                  ),
                                                                                                  ParamType.JSON,
                                                                                                ),
                                                                                                'upsellIdsList': serializeParam(
                                                                                                  (getJsonField(
                                                                                                    PlantShopGroup.productDetailCall.productDetail(
                                                                                                      containerProductDetailResponse.jsonBody,
                                                                                                    ),
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
                                                                                                    PlantShopGroup.productDetailCall.productDetail(
                                                                                                      containerProductDetailResponse.jsonBody,
                                                                                                    ),
                                                                                                    r'''$.related_ids''',
                                                                                                    true,
                                                                                                  ) as List)
                                                                                                      .map<String>((s) => s.toString())
                                                                                                      .toList(),
                                                                                                  ParamType.String,
                                                                                                  isList: true,
                                                                                                ),
                                                                                                'imagesList': serializeParam(
                                                                                                  PlantShopGroup.productDetailCall.imagesList(
                                                                                                    containerProductDetailResponse.jsonBody,
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
                                                                                  ),
                                                                                );
                                                                              },
                                                                            );
                                                                          }).divide(SizedBox(width: 12.0)).addToStart(SizedBox(width: 12.0)).addToEnd(
                                                                              SizedBox(width: 12.0)),
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
                                                              .primaryBackground,
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  12.0),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  'lf2y6nwh' /* Payment Summary */,
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
                                                                padding: EdgeInsetsDirectional
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
                                                                      child:
                                                                          Text(
                                                                        FFLocalizations.of(context)
                                                                            .getText(
                                                                          'hwsa58a3' /* Sub Total */,
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
                                                                      functions.formatPrice(
                                                                          functions.divideBy100(PlantShopGroup.getCartCall.totalitems(
                                                                            cartGetCartResponse.jsonBody,
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
                                                                color: FlutterFlowTheme.of(
                                                                        context)
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
                                                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
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
                                                                            couponeList[couponeListIndex];
                                                                        return Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.end,
                                                                          children: [
                                                                            Expanded(
                                                                              child: RichText(
                                                                                textScaler: MediaQuery.of(context).textScaler,
                                                                                text: TextSpan(
                                                                                  children: [
                                                                                    TextSpan(
                                                                                      text: FFLocalizations.of(context).getText(
                                                                                        '8jcjmpzl' /* Discount :  */,
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
                                                                              padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 4.0, 0.0),
                                                                              child: InkWell(
                                                                                splashColor: Colors.transparent,
                                                                                focusColor: Colors.transparent,
                                                                                hoverColor: Colors.transparent,
                                                                                highlightColor: Colors.transparent,
                                                                                onTap: () async {
                                                                                  _model.mainProcess = true;
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

                                                                                  _model.mainProcess = false;
                                                                                  safeSetState(() {});

                                                                                  safeSetState(() {});
                                                                                },
                                                                                child: Text(
                                                                                  FFLocalizations.of(context).getText(
                                                                                    's3q35ul4' /* Remove */,
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
                                                                              textAlign: TextAlign.start,
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
                                                                      }).divide(SizedBox(height: 4.0)).addToStart(SizedBox(
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
                                                                  padding: EdgeInsetsDirectional
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
                                                                            'i5xw99ot' /* Shipping */,
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
                                                                            TextAlign.start,
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .override(
                                                                              fontFamily: 'SF Pro Display',
                                                                              color: FlutterFlowTheme.of(context).primaryText,
                                                                              fontSize: 17.0,
                                                                              letterSpacing: 0.17,
                                                                              fontWeight: FontWeight.w500,
                                                                              useGoogleFonts: false,
                                                                              lineHeight: 1.5,
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
                                                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
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
                                                                            shippingRatesList[shippingRatesListIndex];
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
                                                                              _model.mainProcess = true;
                                                                              safeSetState(() {});
                                                                              _model.updateShipping = await PlantShopGroup.updateShippingCall.call(
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

                                                                              _model.mainProcess = false;
                                                                              safeSetState(() {});

                                                                              safeSetState(() {});
                                                                            },
                                                                            child:
                                                                                Container(
                                                                              decoration: BoxDecoration(),
                                                                              child: Padding(
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
                                                                padding: EdgeInsetsDirectional
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
                                                                      child:
                                                                          Text(
                                                                        FFLocalizations.of(context)
                                                                            .getText(
                                                                          'm97hvo6a' /* Tax */,
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
                                                                      '+${functions.formatPrice(functions.divideBy100(PlantShopGroup.getCartCall.totalTax(
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
                                                                      child:
                                                                          Text(
                                                                        FFLocalizations.of(context)
                                                                            .getText(
                                                                          '7qe7psl2' /* Total Payment Amount */,
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
                                                                      functions.formatPrice(
                                                                          functions.divideBy100(PlantShopGroup.getCartCall.totalPrice(
                                                                            cartGetCartResponse.jsonBody,
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
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                                12.0,
                                                                20.0,
                                                                12.0,
                                                                20.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  'tdybmzuw' /* Grand Total */,
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
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryText,
                                                                      fontSize:
                                                                          13.0,
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
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        FFButtonWidget(
                                                          onPressed: () async {
                                                            context.pushNamed(
                                                                CheckoutPageWidget
                                                                    .routeName);
                                                          },
                                                          text: FFLocalizations
                                                                  .of(context)
                                                              .getText(
                                                            'afgrh8co' /* Proceed to Payment */,
                                                          ),
                                                          options:
                                                              FFButtonOptions(
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
                                                                      color: Colors
                                                                          .white,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      useGoogleFonts:
                                                                          false,
                                                                    ),
                                                            elevation: 0.0,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
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
                                      } else {
                                        return wrapWithModel(
                                          model: _model.noCartComponentModel,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: Builder(builder: (_) {
                                            return DebugFlutterFlowModelContext(
                                              rootModel: _model.rootModel,
                                              child: NoCartComponentWidget(),
                                            );
                                          }),
                                        );
                                      }
                                    },
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
        if (_model.mainProcess)
          Container(
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
      ],
    );
  }
}
