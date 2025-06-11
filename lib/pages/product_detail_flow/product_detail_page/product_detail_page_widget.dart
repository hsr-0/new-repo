import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/dialog_components/variation_bottom_sheet/variation_bottom_sheet_widget.dart';
import '/pages/product_detail_flow/detail_component/detail_component_widget.dart';
import '/pages/product_detail_flow/image_component/image_component_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'product_detail_page_model.dart';
export 'product_detail_page_model.dart';

class ProductDetailPageWidget extends StatefulWidget {
  const ProductDetailPageWidget({
    super.key,
    required this.productDetail,
    required this.upsellIdsList,
    required this.relatedIdsList,
    required this.imagesList,
  });

  final dynamic productDetail;
  final List<String>? upsellIdsList;
  final List<String>? relatedIdsList;
  final List<dynamic>? imagesList;

  static String routeName = 'ProductDetailPage';
  static String routePath = '/productDetailPage';

  @override
  State<ProductDetailPageWidget> createState() =>
      _ProductDetailPageWidgetState();
}

class _ProductDetailPageWidgetState extends State<ProductDetailPageWidget>
    with RouteAware {
  late ProductDetailPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProductDetailPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.process = true;
      safeSetState(() {});
      await Future.wait([
        Future(() async {
          await action_blocks.responseAction(context);
          safeSetState(() {});
        }),
        Future(() async {
          _model.productVariation =
              await PlantShopGroup.productVariationsCall.call(
            productId: getJsonField(
              widget!.productDetail,
              r'''$.id''',
            ).toString().toString(),
          );

          safeSetState(() {});
        }),
      ]);
      _model.process = false;
      safeSetState(() {});
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
          child: Builder(
            builder: (context) {
              if (FFAppState().connected) {
                return Builder(
                  builder: (context) {
                    if (FFAppState().response) {
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).lightGray,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Expanded(
                                  child: custom_widgets.SliverAppBarCustom(
                                    width: double.infinity,
                                    height: double.infinity,
                                    productId: getJsonField(
                                      widget!.productDetail,
                                      r'''$.id''',
                                    ).toString(),
                                    backAction: () async {
                                      context.safePop();
                                    },
                                    favouriteAction: () async {
                                      if (FFAppState().isLogin == true) {
                                        await action_blocks
                                            .addorRemoveFavourite(
                                          context,
                                          id: getJsonField(
                                            widget!.productDetail,
                                            r'''$.id''',
                                          ).toString(),
                                        );
                                        safeSetState(() {});
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .hideCurrentSnackBar();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              FFLocalizations.of(context)
                                                  .getVariableText(
                                                enText: 'Please log in first',
                                                arText:
                                                    'الرجاء تسجيل الدخول أولاً',
                                              ),
                                              style: TextStyle(
                                                fontFamily: 'SF Pro Display',
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                              ),
                                            ),
                                            duration:
                                                Duration(milliseconds: 2000),
                                            backgroundColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondary,
                                            action: SnackBarAction(
                                              label: FFLocalizations.of(context)
                                                  .getVariableText(
                                                enText: 'Login',
                                                arText: 'تسجيل الدخول',
                                              ),
                                              textColor:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              onPressed: () async {
                                                context.pushNamed(
                                                    SignInPageWidget.routeName);
                                              },
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    searchAction: () async {
                                      context.pushNamed(
                                          SearchPageWidget.routeName);
                                    },
                                    cartAction: () async {
                                      context
                                          .pushNamed(CartPageWidget.routeName);
                                    },
                                    imageWidget: () => Builder(builder: (_) {
                                      return DebugFlutterFlowModelContext(
                                        rootModel: _model.rootModel,
                                        parentModelCallback: (m) {
                                          _model.widgetBuilderComponents[
                                              'imageWidget (widget builder)'] = m;
                                        },
                                        child: ImageComponentWidget(
                                          imageList: widget!.imagesList!,
                                          onSale: getJsonField(
                                            widget!.productDetail,
                                            r'''$.on_sale''',
                                          ),
                                        ),
                                      );
                                    }),
                                    detailWidget: () => Builder(builder: (_) {
                                      return DebugFlutterFlowModelContext(
                                        rootModel: _model.rootModel,
                                        parentModelCallback: (m) {
                                          _model.widgetBuilderComponents[
                                              'detailWidget (widget builder)'] = m;
                                        },
                                        child: DetailComponentWidget(
                                          productDetail: widget!.productDetail!,
                                          upsellIdsList:
                                              widget!.upsellIdsList != null &&
                                                      (widget!.upsellIdsList)!
                                                          .isNotEmpty
                                                  ? widget!.upsellIdsList!
                                                  : ([]),
                                          relatedIdsList:
                                              widget!.relatedIdsList != null &&
                                                      (widget!.relatedIdsList)!
                                                          .isNotEmpty
                                                  ? widget!.relatedIdsList!
                                                  : ([]),
                                          variationsList: PlantShopGroup
                                              .productVariationsCall
                                              .variationsList(
                                            (_model.productVariation
                                                    ?.jsonBody ??
                                                ''),
                                          )!,
                                          priceList: PlantShopGroup
                                                          .productVariationsCall
                                                          .priceList(
                                                        (_model.productVariation
                                                                ?.jsonBody ??
                                                            ''),
                                                      ) !=
                                                      null &&
                                                  (PlantShopGroup
                                                          .productVariationsCall
                                                          .priceList(
                                                    (_model.productVariation
                                                            ?.jsonBody ??
                                                        ''),
                                                  ))!
                                                      .isNotEmpty
                                              ? PlantShopGroup
                                                  .productVariationsCall
                                                  .priceList(
                                                  (_model.productVariation
                                                          ?.jsonBody ??
                                                      ''),
                                                )
                                              : ((String var1) {
                                                  return [var1];
                                                }(getJsonField(
                                                  widget!.productDetail,
                                                  r'''$.price''',
                                                ).toString())),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ].addToEnd(SizedBox(height: 104.0)),
                            ),
                          ),
                          Align(
                            alignment: AlignmentDirectional(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                              ),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    12.0, 12.0, 12.0, 24.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 56.0,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          border: Border.all(
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  12.0, 0.0, 12.0, 0.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                                onTap: () async {
                                                  if (_model.qty > 1) {
                                                    _model.qty =
                                                        _model.qty + -1;
                                                    safeSetState(() {});
                                                  }
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .lightGray,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Icon(
                                                      Icons.remove,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      size: 24.0,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                _model.qty <= 9
                                                    ? '0${_model.qty.toString()}'
                                                    : _model.qty.toString(),
                                                textAlign: TextAlign.start,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          fontSize: 18.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          useGoogleFonts: false,
                                                          lineHeight: 1.2,
                                                        ),
                                              ),
                                              InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                                onTap: () async {
                                                  _model.qty = _model.qty + 1;
                                                  safeSetState(() {});
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .lightGray,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Icon(
                                                      Icons.add,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      size: 24.0,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: FFButtonWidget(
                                        onPressed: _model.process
                                            ? null
                                            : () async {
                                                if (FFAppState().isLogin ==
                                                    true) {
                                                  if ('outofstock' ==
                                                      getJsonField(
                                                        widget!.productDetail,
                                                        r'''$.stock_status''',
                                                      ).toString()) {
                                                    await actions
                                                        .showCustomToastTop(
                                                      FFLocalizations.of(
                                                              context)
                                                          .getVariableText(
                                                        enText:
                                                            'Producrt is out of stock',
                                                        arText:
                                                            'المنتج غير متوفر في المخزون',
                                                      ),
                                                    );
                                                  } else {
                                                    if ((functions
                                                            .jsonToListConverter(
                                                                getJsonField(
                                                              widget!
                                                                  .productDetail,
                                                              r'''$.attributes''',
                                                              true,
                                                            )!)
                                                            .isNotEmpty) &&
                                                        (PlantShopGroup
                                                                    .productVariationsCall
                                                                    .variationsList(
                                                                  (_model.productVariation
                                                                          ?.jsonBody ??
                                                                      ''),
                                                                ) !=
                                                                null &&
                                                            (PlantShopGroup
                                                                    .productVariationsCall
                                                                    .variationsList(
                                                              (_model.productVariation
                                                                      ?.jsonBody ??
                                                                  ''),
                                                            ))!
                                                                .isNotEmpty)) {
                                                      await showModalBottomSheet(
                                                        isScrollControlled:
                                                            true,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        enableDrag: false,
                                                        context: context,
                                                        builder: (context) {
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
                                                            child: Padding(
                                                              padding: MediaQuery
                                                                  .viewInsetsOf(
                                                                      context),
                                                              child:
                                                                  VariationBottomSheetWidget(
                                                                qty: _model.qty,
                                                                attributesList:
                                                                    getJsonField(
                                                                  widget!
                                                                      .productDetail,
                                                                  r'''$.attributes''',
                                                                  true,
                                                                )!,
                                                                allVariationsList:
                                                                    PlantShopGroup
                                                                        .productVariationsCall
                                                                        .variationsList(
                                                                  (_model.productVariation
                                                                          ?.jsonBody ??
                                                                      ''),
                                                                )!,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ).then((value) =>
                                                          safeSetState(() {}));
                                                    } else {
                                                      await action_blocks
                                                          .addtoCartAction(
                                                        context,
                                                        id: getJsonField(
                                                          widget!.productDetail,
                                                          r'''$.id''',
                                                        ),
                                                        quantity: _model.qty
                                                            .toString(),
                                                        variation: functions
                                                            .addToCartListConverter(
                                                                getJsonField(
                                                                  widget!
                                                                      .productDetail,
                                                                  r'''$.attributes''',
                                                                  true,
                                                                )!,
                                                                (getJsonField(
                                                                  widget!
                                                                      .productDetail,
                                                                  r'''$.attributes''',
                                                                  true,
                                                                ) as List)
                                                                    .map<String>(
                                                                        (s) => s
                                                                            .toString())
                                                                    .toList()!),
                                                      );
                                                      safeSetState(() {});
                                                    }
                                                  }
                                                } else {
                                                  context.pushNamed(
                                                      SignInPageWidget
                                                          .routeName);

                                                  await actions
                                                      .showCustomToastTop(
                                                    FFLocalizations.of(context)
                                                        .getVariableText(
                                                      enText:
                                                          'Please log in first',
                                                      arText:
                                                          'الرجاء تسجيل الدخول أولا',
                                                    ),
                                                  );
                                                }
                                              },
                                        text:
                                            FFLocalizations.of(context).getText(
                                          'aqnmmqwq' /* Add to Cart */,
                                        ),
                                        options: FFButtonOptions(
                                          width: double.infinity,
                                          height: 56.0,
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  20.0, 0.0, 20.0, 0.0),
                                          iconPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 0.0),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          textStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .override(
                                                    fontFamily:
                                                        'SF Pro Display',
                                                    color: Colors.white,
                                                    fontSize: 18.0,
                                                    letterSpacing: 0.0,
                                                    useGoogleFonts: false,
                                                  ),
                                          elevation: 0.0,
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          disabledColor:
                                              FlutterFlowTheme.of(context)
                                                  .secondary,
                                          disabledTextColor:
                                              FlutterFlowTheme.of(context)
                                                  .primaryText,
                                        ),
                                      ),
                                    ),
                                  ].divide(SizedBox(width: 12.0)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  12.0, 16.0, 12.0, 16.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      context.safePop();
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .black10,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: SvgPicture.asset(
                                            'assets/images/back.svg',
                                            width: 24.0,
                                            height: 24.0,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: wrapWithModel(
                                model: _model.responseComponentModel,
                                updateCallback: () => safeSetState(() {}),
                                child: Builder(builder: (_) {
                                  return DebugFlutterFlowModelContext(
                                    rootModel: _model.rootModel,
                                    child: ResponseComponentWidget(),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              } else {
                return Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Container(
                    decoration: BoxDecoration(),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              12.0, 16.0, 12.0, 16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  context.safePop();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context).black10,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: SvgPicture.asset(
                                        'assets/images/back.svg',
                                        width: 24.0,
                                        height: 24.0,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Lottie.asset(
                              'assets/jsons/No_Wifi.json',
                              width: 150.0,
                              height: 150.0,
                              fit: BoxFit.contain,
                              animate: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
