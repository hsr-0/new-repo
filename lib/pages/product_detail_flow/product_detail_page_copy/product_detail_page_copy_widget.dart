import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_expanded_image_view.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_component/main_component_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/components/review_component/review_component_widget.dart';
import '/pages/dialog_components/variation_bottom_sheet/variation_bottom_sheet_widget.dart';
import '/pages/shimmer/main_component_shimmer/main_component_shimmer_widget.dart';
import '/pages/shimmer/reviews_shimmer/reviews_shimmer_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'product_detail_page_copy_model.dart';
export 'product_detail_page_copy_model.dart';

class ProductDetailPageCopyWidget extends StatefulWidget {
  const ProductDetailPageCopyWidget({
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

  static String routeName = 'ProductDetailPageCopy';
  static String routePath = '/productDetailPageCopy';

  @override
  State<ProductDetailPageCopyWidget> createState() =>
      _ProductDetailPageCopyWidgetState();
}

class _ProductDetailPageCopyWidgetState
    extends State<ProductDetailPageCopyWidget> with RouteAware {
  late ProductDetailPageCopyModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProductDetailPageCopyModel());

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
                                Container(
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        12.0, 16.0, 12.0, 16.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
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
                                              color:
                                                  FlutterFlowTheme.of(context)
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
                                        Expanded(
                                          child: Container(
                                            height: 1.0,
                                            decoration: BoxDecoration(),
                                          ),
                                        ),
                                        InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
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
                                                    'Please log in first',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          'SF Pro Display',
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                    ),
                                                  ),
                                                  duration: Duration(
                                                      milliseconds: 2000),
                                                  backgroundColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .secondary,
                                                  action: SnackBarAction(
                                                    label: 'Login',
                                                    textColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primary,
                                                    onPressed: () async {
                                                      context.pushNamed(
                                                          SignInPageWidget
                                                              .routeName);
                                                    },
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .black10,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Builder(
                                                builder: (context) {
                                                  if (FFAppState()
                                                      .wishList
                                                      .contains(getJsonField(
                                                        widget!.productDetail,
                                                        r'''$.id''',
                                                      ).toString())) {
                                                    return Icon(
                                                      Icons.favorite_rounded,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      size: 24.0,
                                                    );
                                                  } else {
                                                    return Icon(
                                                      Icons
                                                          .favorite_border_rounded,
                                                      color: Colors.black,
                                                      size: 24.0,
                                                    );
                                                  }
                                                },
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
                                            context.pushNamed(
                                                SearchPageWidget.routeName);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .black10,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                child: SvgPicture.asset(
                                                  'assets/images/search.svg',
                                                  width: 24.0,
                                                  height: 24.0,
                                                  fit: BoxFit.cover,
                                                ),
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
                                            context.pushNamed(
                                                CartPageWidget.routeName);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(),
                                            child: Stack(
                                              alignment: AlignmentDirectional(
                                                  1.3, -2.2),
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .black10,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Icon(
                                                      Icons
                                                          .shopping_cart_outlined,
                                                      color: Colors.black,
                                                      size: 24.0,
                                                    ),
                                                  ),
                                                ),
                                                if ((FFAppState().cartCount !=
                                                        '0') &&
                                                    FFAppState().isLogin)
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(5.0),
                                                      child: Text(
                                                        FFAppState().cartCount,
                                                        textAlign:
                                                            TextAlign.start,
                                                        maxLines: 1,
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodyMedium
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primaryBackground,
                                                              fontSize: 13.0,
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
                                          ),
                                        ),
                                      ].divide(SizedBox(width: 12.0)),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: SingleChildScrollView(
                                    primary: false,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        if (('' !=
                                                getJsonField(
                                                  widget!.productDetail,
                                                  r'''$.images[0].src''',
                                                ).toString()) &&
                                            (getJsonField(
                                                  widget!.productDetail,
                                                  r'''$.images[0].src''',
                                                ) !=
                                                null) &&
                                            (getJsonField(
                                                  widget!.productDetail,
                                                  r'''$.images''',
                                                ) !=
                                                null))
                                          Container(
                                            width: double.infinity,
                                            height: 423.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                            ),
                                            child: Stack(
                                              children: [
                                                Builder(
                                                  builder: (context) {
                                                    final imagesList = widget!
                                                        .imagesList!
                                                        .toList();
                                                    _model.debugGeneratorVariables[
                                                            'imagesList${imagesList.length > 100 ? ' (first 100)' : ''}'] =
                                                        debugSerializeParam(
                                                      imagesList.take(100),
                                                      ParamType.JSON,
                                                      isList: true,
                                                      link:
                                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
                                                      name: 'dynamic',
                                                      nullable: false,
                                                    );
                                                    debugLogWidgetClass(_model);

                                                    return Container(
                                                      width: double.infinity,
                                                      child: PageView.builder(
                                                        controller: _model
                                                                .pageViewController ??=
                                                            PageController(
                                                                initialPage: max(
                                                                    0,
                                                                    min(
                                                                        0,
                                                                        imagesList.length -
                                                                            1)))
                                                              ..addListener(() {
                                                                debugLogWidgetClass(
                                                                    _model);
                                                              }),
                                                        onPageChanged:
                                                            (_) async {
                                                          safeSetState(() {});
                                                        },
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        itemCount:
                                                            imagesList.length,
                                                        itemBuilder: (context,
                                                            imagesListIndex) {
                                                          final imagesListItem =
                                                              imagesList[
                                                                  imagesListIndex];
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
                                                            onTap: () async {
                                                              await Navigator
                                                                  .push(
                                                                context,
                                                                PageTransition(
                                                                  type:
                                                                      PageTransitionType
                                                                          .fade,
                                                                  child:
                                                                      FlutterFlowExpandedImageView(
                                                                    image:
                                                                        CachedNetworkImage(
                                                                      fadeInDuration:
                                                                          Duration(
                                                                              milliseconds: 200),
                                                                      fadeOutDuration:
                                                                          Duration(
                                                                              milliseconds: 200),
                                                                      imageUrl:
                                                                          getJsonField(
                                                                        imagesListItem,
                                                                        r'''$.src''',
                                                                      ).toString(),
                                                                      fit: BoxFit
                                                                          .contain,
                                                                      errorWidget: (context,
                                                                              error,
                                                                              stackTrace) =>
                                                                          Image
                                                                              .asset(
                                                                        'assets/images/error_image.png',
                                                                        fit: BoxFit
                                                                            .contain,
                                                                      ),
                                                                    ),
                                                                    allowRotation:
                                                                        false,
                                                                    useHeroAnimation:
                                                                        false,
                                                                  ),
                                                                ),
                                                              );
                                                            },
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
                                                                imagesListItem,
                                                                r'''$.src''',
                                                              ).toString(),
                                                              fit: BoxFit
                                                                  .contain,
                                                              errorWidget: (context,
                                                                      error,
                                                                      stackTrace) =>
                                                                  Image.asset(
                                                                'assets/images/error_image.png',
                                                                fit: BoxFit
                                                                    .contain,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                ),
                                                Align(
                                                  alignment:
                                                      AlignmentDirectional(
                                                          0.0, 1.0),
                                                  child: Container(
                                                    decoration: BoxDecoration(),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  12.0,
                                                                  0.0,
                                                                  12.0,
                                                                  20.0),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .lightGray,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          24.0),
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          20.0,
                                                                          6.0,
                                                                          20.0,
                                                                          6.0),
                                                              child: RichText(
                                                                textScaler: MediaQuery.of(
                                                                        context)
                                                                    .textScaler,
                                                                text: TextSpan(
                                                                  children: [
                                                                    TextSpan(
                                                                      text: (_model.pageViewCurrentIndex +
                                                                              1)
                                                                          .toString(),
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .override(
                                                                            fontFamily:
                                                                                'SF Pro Display',
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primary,
                                                                            fontSize:
                                                                                16.0,
                                                                            letterSpacing:
                                                                                0.16,
                                                                            useGoogleFonts:
                                                                                false,
                                                                          ),
                                                                    ),
                                                                    TextSpan(
                                                                      text: FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        'mw5f2pyt' /*  /  */,
                                                                      ),
                                                                      style:
                                                                          TextStyle(
                                                                        fontFamily:
                                                                            'SF Pro Display',
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryText,
                                                                        fontSize:
                                                                            14.0,
                                                                      ),
                                                                    ),
                                                                    TextSpan(
                                                                      text: widget!
                                                                          .imagesList!
                                                                          .length
                                                                          .toString(),
                                                                      style:
                                                                          TextStyle(
                                                                        fontFamily:
                                                                            'SF Pro Display',
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryText,
                                                                        fontSize:
                                                                            14.0,
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
                                                                            16.0,
                                                                        letterSpacing:
                                                                            0.16,
                                                                        useGoogleFonts:
                                                                            false,
                                                                      ),
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            ),
                                                          ),
                                                          if (getJsonField(
                                                            widget!
                                                                .productDetail,
                                                            r'''$.on_sale''',
                                                          ))
                                                            Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12.0),
                                                              ),
                                                              child: Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            8.0,
                                                                            2.0,
                                                                            8.0,
                                                                            2.0),
                                                                child: Text(
                                                                  FFLocalizations.of(
                                                                          context)
                                                                      .getText(
                                                                    'vzwjr0kq' /* SALE */,
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
                                                                            .primaryBackground,
                                                                        fontSize:
                                                                            12.0,
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
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
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
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      12.0, 20.0, 12.0, 20.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    valueOrDefault<String>(
                                                      getJsonField(
                                                        widget!.productDetail,
                                                        r'''$.name''',
                                                      )?.toString(),
                                                      'Name',
                                                    ),
                                                    textAlign: TextAlign.start,
                                                    maxLines: 2,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          fontSize: 20.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          useGoogleFonts: false,
                                                          lineHeight: 1.5,
                                                        ),
                                                  ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Text(
                                                        (PlantShopGroup.productVariationsCall
                                                                        .status(
                                                                      (_model.productVariation
                                                                              ?.jsonBody ??
                                                                          ''),
                                                                    ) ==
                                                                    null) &&
                                                                (PlantShopGroup
                                                                            .productVariationsCall
                                                                            .variationsList(
                                                                          (_model.productVariation?.jsonBody ??
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
                                                                        .isNotEmpty) &&
                                                                (PlantShopGroup
                                                                        .productVariationsCall
                                                                        .priceList(
                                                                          (_model.productVariation?.jsonBody ??
                                                                              ''),
                                                                        )
                                                                        ?.firstOrNull !=
                                                                    PlantShopGroup
                                                                        .productVariationsCall
                                                                        .priceList(
                                                                          (_model.productVariation?.jsonBody ??
                                                                              ''),
                                                                        )
                                                                        ?.lastOrNull)
                                                            ? '${functions.formatPrice(PlantShopGroup.productVariationsCall.priceList(
                                                                  (_model.productVariation
                                                                          ?.jsonBody ??
                                                                      ''),
                                                                )!.firstOrNull!, FFAppState().thousandSeparator, FFAppState().decimalSeparator, FFAppState().decimalPlaces.toString(), FFAppState().currencyPosition, FFAppState().currency)} - ${functions.formatPrice(PlantShopGroup.productVariationsCall.priceList(
                                                                  (_model.productVariation
                                                                          ?.jsonBody ??
                                                                      ''),
                                                                )!.lastOrNull!, FFAppState().thousandSeparator, FFAppState().decimalSeparator, FFAppState().decimalPlaces.toString(), FFAppState().currencyPosition, FFAppState().currency)}'
                                                            : functions
                                                                .formatPrice(
                                                                    getJsonField(
                                                                      widget!
                                                                          .productDetail,
                                                                      r'''$.price''',
                                                                    )
                                                                        .toString(),
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
                                                              lineHeight: 1.5,
                                                            ),
                                                      ),
                                                      if (getJsonField(
                                                            widget!
                                                                .productDetail,
                                                            r'''$.on_sale''',
                                                          ) &&
                                                          ('' !=
                                                              getJsonField(
                                                                widget!
                                                                    .productDetail,
                                                                r'''$.regular_price''',
                                                              ).toString()))
                                                        Text(
                                                          functions.formatPrice(
                                                              getJsonField(
                                                                widget!
                                                                    .productDetail,
                                                                r'''$.regular_price''',
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
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryText,
                                                                fontSize: 16.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                                decoration:
                                                                    TextDecoration
                                                                        .lineThrough,
                                                                useGoogleFonts:
                                                                    false,
                                                                lineHeight: 1.5,
                                                              ),
                                                        ),
                                                      if (getJsonField(
                                                            widget!
                                                                .productDetail,
                                                            r'''$.on_sale''',
                                                          ) &&
                                                          ('' !=
                                                              getJsonField(
                                                                widget!
                                                                    .productDetail,
                                                                r'''$.regular_price''',
                                                              ).toString()))
                                                        RichText(
                                                          textScaler:
                                                              MediaQuery.of(
                                                                      context)
                                                                  .textScaler,
                                                          text: TextSpan(
                                                            children: [
                                                              TextSpan(
                                                                text: (100 *
                                                                        ((double.parse(getJsonField(
                                                                              widget!.productDetail,
                                                                              r'''$.regular_price''',
                                                                            ).toString())) -
                                                                            (double.parse(getJsonField(
                                                                              widget!.productDetail,
                                                                              r'''$.price''',
                                                                            ).toString()))) ~/
                                                                        (double.parse(getJsonField(
                                                                          widget!
                                                                              .productDetail,
                                                                          r'''$.regular_price''',
                                                                        ).toString())))
                                                                    .toString(),
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .success,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize:
                                                                      16.0,
                                                                  height: 1.5,
                                                                ),
                                                              ),
                                                              TextSpan(
                                                                text: FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  'u4jwt0r7' /* % OFF */,
                                                                ),
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .success,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
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
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .success,
                                                                  fontSize:
                                                                      16.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  useGoogleFonts:
                                                                      false,
                                                                  lineHeight:
                                                                      1.5,
                                                                ),
                                                          ),
                                                          textAlign:
                                                              TextAlign.start,
                                                        ),
                                                    ].divide(
                                                        SizedBox(width: 8.0)),
                                                  ),
                                                  if ('0' !=
                                                      (getJsonField(
                                                        widget!.productDetail,
                                                        r'''$.rating_count''',
                                                      ).toString()))
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        RatingBarIndicator(
                                                          itemBuilder: (context,
                                                                  index) =>
                                                              Icon(
                                                            Icons.star_rounded,
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .warning,
                                                          ),
                                                          direction:
                                                              Axis.horizontal,
                                                          rating: double.parse(
                                                              getJsonField(
                                                            widget!
                                                                .productDetail,
                                                            r'''$.average_rating''',
                                                          ).toString()),
                                                          unratedColor:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .black20,
                                                          itemCount: 5,
                                                          itemSize: 14.0,
                                                        ),
                                                        RichText(
                                                          textScaler:
                                                              MediaQuery.of(
                                                                      context)
                                                                  .textScaler,
                                                          text: TextSpan(
                                                            children: [
                                                              TextSpan(
                                                                text:
                                                                    getJsonField(
                                                                  widget!
                                                                      .productDetail,
                                                                  r'''$.rating_count''',
                                                                ).toString(),
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
                                                              TextSpan(
                                                                text:
                                                                    ' ${FFAppConstants.reviewText}',
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontSize:
                                                                      14.0,
                                                                  height: 0.5,
                                                                ),
                                                              )
                                                            ],
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
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
                                                          textAlign:
                                                              TextAlign.start,
                                                        ),
                                                      ].divide(
                                                          SizedBox(width: 6.0)),
                                                    ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      if ('' !=
                                                          getJsonField(
                                                            widget!
                                                                .productDetail,
                                                            r'''$.sku''',
                                                          ).toString())
                                                        Expanded(
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            children: [
                                                              if ('' !=
                                                                  getJsonField(
                                                                    widget!
                                                                        .productDetail,
                                                                    r'''$.sku''',
                                                                  ).toString())
                                                                Expanded(
                                                                  child: Text(
                                                                    getJsonField(
                                                                      widget!
                                                                          .productDetail,
                                                                      r'''$.sku''',
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
                                                                              13.0,
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
                                                            ],
                                                          ),
                                                        ),
                                                      Builder(
                                                        builder: (context) {
                                                          if ('outofstock' ==
                                                              getJsonField(
                                                                widget!
                                                                    .productDetail,
                                                                r'''$.stock_status''',
                                                              ).toString()) {
                                                            return Text(
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .getText(
                                                                '8x0wv4hs' /* Out of Stock */,
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
                                                                        .error,
                                                                    fontSize:
                                                                        17.0,
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
                                                            );
                                                          } else if ((true ==
                                                                  getJsonField(
                                                                    widget!
                                                                        .productDetail,
                                                                    r'''$.manage_stock''',
                                                                  )) &&
                                                              (true ==
                                                                  getJsonField(
                                                                    widget!
                                                                        .productDetail,
                                                                    r'''$.backorders_allowed''',
                                                                  )) &&
                                                              ('notify' ==
                                                                  getJsonField(
                                                                    widget!
                                                                        .productDetail,
                                                                    r'''$.backorders''',
                                                                  ).toString())) {
                                                            return Text(
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .getText(
                                                                'j4wjuy2o' /* Available on backorder */,
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
                                                                        .primary,
                                                                    fontSize:
                                                                        17.0,
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
                                                            );
                                                          } else if ((true ==
                                                                  getJsonField(
                                                                    widget!
                                                                        .productDetail,
                                                                    r'''$.manage_stock''',
                                                                  )) &&
                                                              (false ==
                                                                  getJsonField(
                                                                    widget!
                                                                        .productDetail,
                                                                    r'''$.backorders_allowed''',
                                                                  ))) {
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
                                                                      '31is92sl' /* Availability :  */,
                                                                    ),
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
                                                                              0.0,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                          useGoogleFonts:
                                                                              false,
                                                                          lineHeight:
                                                                              1.5,
                                                                        ),
                                                                  ),
                                                                  TextSpan(
                                                                    text:
                                                                        getJsonField(
                                                                      widget!
                                                                          .productDetail,
                                                                      r'''$.stock_quantity''',
                                                                    ).toString(),
                                                                    style:
                                                                        TextStyle(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primary,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      fontSize:
                                                                          17.0,
                                                                      height:
                                                                          1.5,
                                                                    ),
                                                                  ),
                                                                  TextSpan(
                                                                    text: FFLocalizations.of(
                                                                            context)
                                                                        .getText(
                                                                      'bd2pkygo' /*  in stock */,
                                                                    ),
                                                                    style:
                                                                        TextStyle(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primary,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      fontSize:
                                                                          17.0,
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
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primary,
                                                                      fontSize:
                                                                          17.0,
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
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                            );
                                                          } else {
                                                            return Container(
                                                              decoration:
                                                                  BoxDecoration(),
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ].divide(SizedBox(height: 8.0)),
                                              ),
                                            ),
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
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      12.0, 20.0, 12.0, 20.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      InkWell(
                                                        splashColor:
                                                            Colors.transparent,
                                                        focusColor:
                                                            Colors.transparent,
                                                        hoverColor:
                                                            Colors.transparent,
                                                        highlightColor:
                                                            Colors.transparent,
                                                        onTap: () async {
                                                          _model.dataTapIndex =
                                                              0;
                                                          safeSetState(() {});
                                                        },
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Builder(
                                                                builder:
                                                                    (context) {
                                                                  if (_model
                                                                          .dataTapIndex ==
                                                                      0) {
                                                                    return Text(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        'jqrbxy6s' /* Description */,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .start,
                                                                      maxLines:
                                                                          1,
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
                                                                                FontWeight.w600,
                                                                            useGoogleFonts:
                                                                                false,
                                                                            lineHeight:
                                                                                1.5,
                                                                          ),
                                                                    );
                                                                  } else {
                                                                    return Text(
                                                                      FFLocalizations.of(
                                                                              context)
                                                                          .getText(
                                                                        '1z77lbxm' /* Description */,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .start,
                                                                      maxLines:
                                                                          1,
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .override(
                                                                            fontFamily:
                                                                                'SF Pro Display',
                                                                            color:
                                                                                FlutterFlowTheme.of(context).secondaryText,
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
                                                                    );
                                                                  }
                                                                },
                                                              ),
                                                              if (_model
                                                                      .dataTapIndex ==
                                                                  0)
                                                                Container(
                                                                  width: 82.0,
                                                                  height: 1.5,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: _model.dataTapIndex ==
                                                                            0
                                                                        ? FlutterFlowTheme.of(context)
                                                                            .primary
                                                                        : Color(
                                                                            0x00000000),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
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
                                                        onTap: () async {
                                                          _model.dataTapIndex =
                                                              1;
                                                          safeSetState(() {});
                                                        },
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(),
                                                          child: Visibility(
                                                            visible: '' !=
                                                                getJsonField(
                                                                  widget!
                                                                      .productDetail,
                                                                  r'''$.short_description''',
                                                                ).toString(),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Builder(
                                                                  builder:
                                                                      (context) {
                                                                    if (_model
                                                                            .dataTapIndex ==
                                                                        1) {
                                                                      return Text(
                                                                        FFLocalizations.of(context)
                                                                            .getText(
                                                                          'v2kv6rtz' /* Information */,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.start,
                                                                        maxLines:
                                                                            1,
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .override(
                                                                              fontFamily: 'SF Pro Display',
                                                                              fontSize: 16.0,
                                                                              letterSpacing: 0.16,
                                                                              fontWeight: FontWeight.w600,
                                                                              useGoogleFonts: false,
                                                                              lineHeight: 1.5,
                                                                            ),
                                                                      );
                                                                    } else {
                                                                      return Text(
                                                                        FFLocalizations.of(context)
                                                                            .getText(
                                                                          'egc1dmow' /* Information */,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.start,
                                                                        maxLines:
                                                                            1,
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .override(
                                                                              fontFamily: 'SF Pro Display',
                                                                              color: FlutterFlowTheme.of(context).secondaryText,
                                                                              fontSize: 16.0,
                                                                              letterSpacing: 0.16,
                                                                              fontWeight: FontWeight.normal,
                                                                              useGoogleFonts: false,
                                                                              lineHeight: 1.5,
                                                                            ),
                                                                      );
                                                                    }
                                                                  },
                                                                ),
                                                                if (_model
                                                                        .dataTapIndex ==
                                                                    1)
                                                                  Container(
                                                                    width: 82.0,
                                                                    height: 1.5,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: _model.dataTapIndex == 1
                                                                          ? FlutterFlowTheme.of(context)
                                                                              .primary
                                                                          : Color(
                                                                              0x00000000),
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ].divide(
                                                        SizedBox(width: 20.0)),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 12.0,
                                                                0.0, 0.0),
                                                    child: custom_widgets
                                                        .HtmlConverter(
                                                      width: double.infinity,
                                                      height: 200.0,
                                                      text:
                                                          _model.dataTapIndex ==
                                                                  0
                                                              ? getJsonField(
                                                                  widget!
                                                                      .productDetail,
                                                                  r'''$.description''',
                                                                ).toString()
                                                              : getJsonField(
                                                                  widget!
                                                                      .productDetail,
                                                                  r'''$.short_description''',
                                                                ).toString(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        if ('0' !=
                                            (getJsonField(
                                              widget!.productDetail,
                                              r'''$.rating_count''',
                                            ).toString()))
                                          Container(
                                            decoration: BoxDecoration(),
                                            child:
                                                FutureBuilder<ApiCallResponse>(
                                              future: FFAppState().reviews(
                                                uniqueQueryKey: getJsonField(
                                                  widget!.productDetail,
                                                  r'''$.id''',
                                                ).toString(),
                                                requestFn: () => PlantShopGroup
                                                    .productReviewCall
                                                    .call(
                                                  id: getJsonField(
                                                    widget!.productDetail,
                                                    r'''$.id''',
                                                  ).toString(),
                                                ),
                                              ),
                                              builder: (context, snapshot) {
                                                // Customize what your widget looks like when it's loading.
                                                if (!snapshot.hasData) {
                                                  return ReviewsShimmerWidget();
                                                }
                                                final reviewsProductReviewResponse =
                                                    snapshot.data!;
                                                _model.debugBackendQueries[
                                                        'PlantShopGroup.productReviewCall_statusCode_Container_h07mlx1z'] =
                                                    debugSerializeParam(
                                                  reviewsProductReviewResponse
                                                      .statusCode,
                                                  ParamType.int,
                                                  link:
                                                      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
                                                  name: 'int',
                                                  nullable: false,
                                                );
                                                _model.debugBackendQueries[
                                                        'PlantShopGroup.productReviewCall_responseBody_Container_h07mlx1z'] =
                                                    debugSerializeParam(
                                                  reviewsProductReviewResponse
                                                      .bodyText,
                                                  ParamType.String,
                                                  link:
                                                      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
                                                  name: 'String',
                                                  nullable: false,
                                                );
                                                debugLogWidgetClass(_model);

                                                return Container(
                                                  decoration: BoxDecoration(),
                                                  child: Visibility(
                                                    visible: (PlantShopGroup
                                                                .productReviewCall
                                                                .status(
                                                              reviewsProductReviewResponse
                                                                  .jsonBody,
                                                            ) ==
                                                            null) &&
                                                        (PlantShopGroup
                                                                    .productReviewCall
                                                                    .reviewsList(
                                                                  reviewsProductReviewResponse
                                                                      .jsonBody,
                                                                ) !=
                                                                null &&
                                                            (PlantShopGroup
                                                                    .productReviewCall
                                                                    .reviewsList(
                                                              reviewsProductReviewResponse
                                                                  .jsonBody,
                                                            ))!
                                                                .isNotEmpty),
                                                    child: Padding(
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
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      12.0,
                                                                      20.0,
                                                                      12.0,
                                                                      20.0),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Text(
                                                                    FFLocalizations.of(
                                                                            context)
                                                                        .getText(
                                                                      'rls9ruwy' /* Reviews */,
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
                                                                              FontWeight.bold,
                                                                          useGoogleFonts:
                                                                              false,
                                                                          lineHeight:
                                                                              1.5,
                                                                        ),
                                                                  ),
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
                                                                      context
                                                                          .pushNamed(
                                                                        ReviewPageWidget
                                                                            .routeName,
                                                                        queryParameters:
                                                                            {
                                                                          'reviewsList':
                                                                              serializeParam(
                                                                            PlantShopGroup.productReviewCall.reviewsList(
                                                                              reviewsProductReviewResponse.jsonBody,
                                                                            ),
                                                                            ParamType.JSON,
                                                                            isList:
                                                                                true,
                                                                          ),
                                                                          'averageRating':
                                                                              serializeParam(
                                                                            getJsonField(
                                                                              widget!.productDetail,
                                                                              r'''$.average_rating''',
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
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .black10,
                                                                        borderRadius:
                                                                            BorderRadius.circular(30.0),
                                                                      ),
                                                                      alignment:
                                                                          AlignmentDirectional(
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
                                                                          FFLocalizations.of(context)
                                                                              .getText(
                                                                            'mwb0vbdi' /* View all */,
                                                                          ),
                                                                          textAlign:
                                                                              TextAlign.start,
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .override(
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
                                                                ].divide(SizedBox(
                                                                    width:
                                                                        8.0)),
                                                              ),
                                                              Builder(
                                                                builder:
                                                                    (context) {
                                                                  final reviewList = PlantShopGroup
                                                                          .productReviewCall
                                                                          .reviewsList(
                                                                            reviewsProductReviewResponse.jsonBody,
                                                                          )
                                                                          ?.take(
                                                                              2)
                                                                          .toList()
                                                                          ?.toList() ??
                                                                      [];
                                                                  _model.debugGeneratorVariables[
                                                                          'reviewList${reviewList.length > 100 ? ' (first 100)' : ''}'] =
                                                                      debugSerializeParam(
                                                                    reviewList
                                                                        .take(
                                                                            100),
                                                                    ParamType
                                                                        .JSON,
                                                                    isList:
                                                                        true,
                                                                    link:
                                                                        'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
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
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: List.generate(
                                                                        reviewList
                                                                            .length,
                                                                        (reviewListIndex) {
                                                                      final reviewListItem =
                                                                          reviewList[
                                                                              reviewListIndex];
                                                                      return wrapWithModel(
                                                                        model: _model
                                                                            .reviewComponentModels
                                                                            .getModel(
                                                                          getJsonField(
                                                                            reviewListItem,
                                                                            r'''$.id''',
                                                                          ).toString(),
                                                                          reviewListIndex,
                                                                        ),
                                                                        updateCallback:
                                                                            () =>
                                                                                safeSetState(() {}),
                                                                        child: Builder(builder:
                                                                            (_) {
                                                                          return DebugFlutterFlowModelContext(
                                                                            rootModel:
                                                                                _model.rootModel,
                                                                            child:
                                                                                ReviewComponentWidget(
                                                                              key: Key(
                                                                                'Keyquj_${getJsonField(
                                                                                  reviewListItem,
                                                                                  r'''$.id''',
                                                                                ).toString()}',
                                                                              ),
                                                                              image: getJsonField(
                                                                                reviewListItem,
                                                                                r'''$.reviewer_avatar_urls['48']''',
                                                                              ).toString(),
                                                                              userName: getJsonField(
                                                                                reviewListItem,
                                                                                r'''$.reviewer''',
                                                                              ).toString(),
                                                                              createAt: getJsonField(
                                                                                reviewListItem,
                                                                                r'''$.date_created''',
                                                                              ).toString(),
                                                                              rate: double.parse(getJsonField(
                                                                                reviewListItem,
                                                                                r'''$.rating''',
                                                                              ).toString()),
                                                                              description: getJsonField(
                                                                                reviewListItem,
                                                                                r'''$.review''',
                                                                              ).toString(),
                                                                              isDivider: reviewListIndex != 1,
                                                                            ),
                                                                          );
                                                                        }),
                                                                      );
                                                                    }).divide(SizedBox(height: 20.0)).addToStart(
                                                                        SizedBox(
                                                                            height:
                                                                                16.0)),
                                                                  );
                                                                },
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
                                          ),
                                        if (widget!.upsellIdsList != null &&
                                            (widget!.upsellIdsList)!.isNotEmpty)
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
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 20.0, 0.0, 20.0),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  12.0,
                                                                  0.0,
                                                                  12.0,
                                                                  16.0),
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
                                                              'eflyxdfb' /* Up sell product */,
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
                                                                UpSellProductsPageWidget
                                                                    .routeName,
                                                                queryParameters:
                                                                    {
                                                                  'upSellProductList':
                                                                      serializeParam(
                                                                    widget!
                                                                        .upsellIdsList,
                                                                    ParamType
                                                                        .String,
                                                                    isList:
                                                                        true,
                                                                  ),
                                                                }.withoutNulls,
                                                              );
                                                            },
                                                            child: Container(
                                                              height: 29.0,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
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
                                                                padding: EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        10.0,
                                                                        0.0,
                                                                        10.0,
                                                                        0.0),
                                                                child: Text(
                                                                  FFLocalizations.of(
                                                                          context)
                                                                      .getText(
                                                                    'dcwiobsj' /* View all */,
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
                                                                            FontWeight.normal,
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
                                                      decoration:
                                                          BoxDecoration(),
                                                      child: Builder(
                                                        builder: (context) {
                                                          final upSellIdsList =
                                                              widget!
                                                                  .upsellIdsList!
                                                                  .toList()
                                                                  .take(6)
                                                                  .toList();
                                                          _model.debugGeneratorVariables[
                                                                  'upSellIdsList${upSellIdsList.length > 100 ? ' (first 100)' : ''}'] =
                                                              debugSerializeParam(
                                                            upSellIdsList
                                                                .take(100),
                                                            ParamType.String,
                                                            isList: true,
                                                            link:
                                                                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
                                                            name: 'String',
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
                                                                      upSellIdsList
                                                                          .length,
                                                                      (upSellIdsListIndex) {
                                                                final upSellIdsListItem =
                                                                    upSellIdsList[
                                                                        upSellIdsListIndex];
                                                                return FutureBuilder<
                                                                    ApiCallResponse>(
                                                                  future: FFAppState()
                                                                      .productDdetail(
                                                                    uniqueQueryKey:
                                                                        upSellIdsListItem,
                                                                    requestFn: () =>
                                                                        PlantShopGroup
                                                                            .productDetailCall
                                                                            .call(
                                                                      productId:
                                                                          upSellIdsListItem,
                                                                    ),
                                                                  ),
                                                                  builder: (context,
                                                                      snapshot) {
                                                                    // Customize what your widget looks like when it's loading.
                                                                    if (!snapshot
                                                                        .hasData) {
                                                                      return MainComponentShimmerWidget(
                                                                        isBig:
                                                                            true,
                                                                        width:
                                                                            189.0,
                                                                        height:
                                                                            298.0,
                                                                      );
                                                                    }
                                                                    final containerProductDetailResponse =
                                                                        snapshot
                                                                            .data!;
                                                                    _model.debugBackendQueries[
                                                                            'PlantShopGroup.productDetailCall_statusCode_Container_rf2y4dk9'] =
                                                                        debugSerializeParam(
                                                                      containerProductDetailResponse
                                                                          .statusCode,
                                                                      ParamType
                                                                          .int,
                                                                      link:
                                                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
                                                                      name:
                                                                          'int',
                                                                      nullable:
                                                                          false,
                                                                    );
                                                                    _model.debugBackendQueries[
                                                                            'PlantShopGroup.productDetailCall_responseBody_Container_rf2y4dk9'] =
                                                                        debugSerializeParam(
                                                                      containerProductDetailResponse
                                                                          .bodyText,
                                                                      ParamType
                                                                          .String,
                                                                      link:
                                                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
                                                                      name:
                                                                          'String',
                                                                      nullable:
                                                                          false,
                                                                    );
                                                                    debugLogWidgetClass(
                                                                        _model);

                                                                    return Container(
                                                                      decoration:
                                                                          BoxDecoration(),
                                                                      child:
                                                                          wrapWithModel(
                                                                        model: _model
                                                                            .mainComponentModels1
                                                                            .getModel(
                                                                          getJsonField(
                                                                            PlantShopGroup.productDetailCall.productDetail(
                                                                              containerProductDetailResponse.jsonBody,
                                                                            ),
                                                                            r'''$.id''',
                                                                          ).toString(),
                                                                          upSellIdsListIndex,
                                                                        ),
                                                                        updateCallback:
                                                                            () =>
                                                                                safeSetState(() {}),
                                                                        child: Builder(builder:
                                                                            (_) {
                                                                          return DebugFlutterFlowModelContext(
                                                                            rootModel:
                                                                                _model.rootModel,
                                                                            child:
                                                                                MainComponentWidget(
                                                                              key: Key(
                                                                                'Key1l0_${getJsonField(
                                                                                  PlantShopGroup.productDetailCall.productDetail(
                                                                                    containerProductDetailResponse.jsonBody,
                                                                                  ),
                                                                                  r'''$.id''',
                                                                                ).toString()}',
                                                                              ),
                                                                              image: getJsonField(
                                                                                PlantShopGroup.productDetailCall
                                                                                    .imagesList(
                                                                                      containerProductDetailResponse.jsonBody,
                                                                                    )!
                                                                                    .firstOrNull,
                                                                                r'''$.src''',
                                                                              ).toString(),
                                                                              name: getJsonField(
                                                                                PlantShopGroup.productDetailCall.productDetail(
                                                                                  containerProductDetailResponse.jsonBody,
                                                                                ),
                                                                                r'''$.name''',
                                                                              ).toString(),
                                                                              isLike: FFAppState().wishList.contains(getJsonField(
                                                                                    PlantShopGroup.productDetailCall.productDetail(
                                                                                      containerProductDetailResponse.jsonBody,
                                                                                    ),
                                                                                    r'''$.id''',
                                                                                  ).toString()),
                                                                              regularPrice: PlantShopGroup.productDetailCall.regularPrice(
                                                                                containerProductDetailResponse.jsonBody,
                                                                              )!,
                                                                              price: PlantShopGroup.productDetailCall.price(
                                                                                containerProductDetailResponse.jsonBody,
                                                                              )!,
                                                                              review: PlantShopGroup.productDetailCall
                                                                                  .ratingCount(
                                                                                    containerProductDetailResponse.jsonBody,
                                                                                  )!
                                                                                  .toString(),
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
                                                                              onSale: PlantShopGroup.productDetailCall.onSale(
                                                                                containerProductDetailResponse.jsonBody,
                                                                              )!,
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
                                                                                    id: getJsonField(
                                                                                      PlantShopGroup.productDetailCall.productDetail(
                                                                                        containerProductDetailResponse.jsonBody,
                                                                                      ),
                                                                                      r'''$.id''',
                                                                                    ).toString(),
                                                                                  );
                                                                                  safeSetState(() {});
                                                                                } else {
                                                                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                                    SnackBar(
                                                                                      content: Text(
                                                                                        'Please log in first',
                                                                                        style: TextStyle(
                                                                                          fontFamily: 'SF Pro Display',
                                                                                          color: FlutterFlowTheme.of(context).primaryText,
                                                                                        ),
                                                                                      ),
                                                                                      duration: Duration(milliseconds: 2000),
                                                                                      backgroundColor: FlutterFlowTheme.of(context).secondary,
                                                                                      action: SnackBarAction(
                                                                                        label: 'Login',
                                                                                        textColor: FlutterFlowTheme.of(context).primary,
                                                                                        onPressed: () async {
                                                                                          context.pushNamed(
                                                                                            SignInPageWidget.routeName,
                                                                                            queryParameters: {
                                                                                              'isInner': serializeParam(
                                                                                                true,
                                                                                                ParamType.bool,
                                                                                              ),
                                                                                            }.withoutNulls,
                                                                                          );
                                                                                        },
                                                                                      ),
                                                                                    ),
                                                                                  );
                                                                                }
                                                                              },
                                                                              isMainTap: () async {
                                                                                context.pushNamed(
                                                                                  ProductDetailPageCopyWidget.routeName,
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
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (widget!.relatedIdsList != null &&
                                            (widget!.relatedIdsList)!
                                                .isNotEmpty)
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
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 20.0, 0.0, 20.0),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  12.0,
                                                                  0.0,
                                                                  12.0,
                                                                  16.0),
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
                                                              'tgvyfo3c' /* Related product */,
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
                                                                RelatedProductsPageWidget
                                                                    .routeName,
                                                                queryParameters:
                                                                    {
                                                                  'relatedProductList':
                                                                      serializeParam(
                                                                    widget!
                                                                        .relatedIdsList,
                                                                    ParamType
                                                                        .String,
                                                                    isList:
                                                                        true,
                                                                  ),
                                                                }.withoutNulls,
                                                              );
                                                            },
                                                            child: Container(
                                                              height: 29.0,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
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
                                                                padding: EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        10.0,
                                                                        0.0,
                                                                        10.0,
                                                                        0.0),
                                                                child: Text(
                                                                  FFLocalizations.of(
                                                                          context)
                                                                      .getText(
                                                                    'itf618zm' /* View all */,
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
                                                                            FontWeight.normal,
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
                                                      decoration:
                                                          BoxDecoration(),
                                                      child: Builder(
                                                        builder: (context) {
                                                          final relatedIdsList =
                                                              widget!
                                                                  .relatedIdsList!
                                                                  .toList()
                                                                  .take(6)
                                                                  .toList();
                                                          _model.debugGeneratorVariables[
                                                                  'relatedIdsList${relatedIdsList.length > 100 ? ' (first 100)' : ''}'] =
                                                              debugSerializeParam(
                                                            relatedIdsList
                                                                .take(100),
                                                            ParamType.String,
                                                            isList: true,
                                                            link:
                                                                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
                                                            name: 'String',
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
                                                                      relatedIdsList
                                                                          .length,
                                                                      (relatedIdsListIndex) {
                                                                final relatedIdsListItem =
                                                                    relatedIdsList[
                                                                        relatedIdsListIndex];
                                                                return FutureBuilder<
                                                                    ApiCallResponse>(
                                                                  future: FFAppState()
                                                                      .productDdetail(
                                                                    uniqueQueryKey:
                                                                        relatedIdsListItem,
                                                                    requestFn: () =>
                                                                        PlantShopGroup
                                                                            .productDetailCall
                                                                            .call(
                                                                      productId:
                                                                          relatedIdsListItem,
                                                                    ),
                                                                  ),
                                                                  builder: (context,
                                                                      snapshot) {
                                                                    // Customize what your widget looks like when it's loading.
                                                                    if (!snapshot
                                                                        .hasData) {
                                                                      return MainComponentShimmerWidget(
                                                                        isBig:
                                                                            true,
                                                                        width:
                                                                            189.0,
                                                                        height:
                                                                            298.0,
                                                                      );
                                                                    }
                                                                    final containerProductDetailResponse =
                                                                        snapshot
                                                                            .data!;
                                                                    _model.debugBackendQueries[
                                                                            'PlantShopGroup.productDetailCall_statusCode_Container_f3ywgbvw'] =
                                                                        debugSerializeParam(
                                                                      containerProductDetailResponse
                                                                          .statusCode,
                                                                      ParamType
                                                                          .int,
                                                                      link:
                                                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
                                                                      name:
                                                                          'int',
                                                                      nullable:
                                                                          false,
                                                                    );
                                                                    _model.debugBackendQueries[
                                                                            'PlantShopGroup.productDetailCall_responseBody_Container_f3ywgbvw'] =
                                                                        debugSerializeParam(
                                                                      containerProductDetailResponse
                                                                          .bodyText,
                                                                      ParamType
                                                                          .String,
                                                                      link:
                                                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
                                                                      name:
                                                                          'String',
                                                                      nullable:
                                                                          false,
                                                                    );
                                                                    debugLogWidgetClass(
                                                                        _model);

                                                                    return Container(
                                                                      decoration:
                                                                          BoxDecoration(),
                                                                      child:
                                                                          wrapWithModel(
                                                                        model: _model
                                                                            .mainComponentModels2
                                                                            .getModel(
                                                                          getJsonField(
                                                                            PlantShopGroup.productDetailCall.productDetail(
                                                                              containerProductDetailResponse.jsonBody,
                                                                            ),
                                                                            r'''$.id''',
                                                                          ).toString(),
                                                                          relatedIdsListIndex,
                                                                        ),
                                                                        updateCallback:
                                                                            () =>
                                                                                safeSetState(() {}),
                                                                        child: Builder(builder:
                                                                            (_) {
                                                                          return DebugFlutterFlowModelContext(
                                                                            rootModel:
                                                                                _model.rootModel,
                                                                            child:
                                                                                MainComponentWidget(
                                                                              key: Key(
                                                                                'Keyno1_${getJsonField(
                                                                                  PlantShopGroup.productDetailCall.productDetail(
                                                                                    containerProductDetailResponse.jsonBody,
                                                                                  ),
                                                                                  r'''$.id''',
                                                                                ).toString()}',
                                                                              ),
                                                                              image: getJsonField(
                                                                                PlantShopGroup.productDetailCall
                                                                                    .imagesList(
                                                                                      containerProductDetailResponse.jsonBody,
                                                                                    )!
                                                                                    .firstOrNull,
                                                                                r'''$.src''',
                                                                              ).toString(),
                                                                              name: getJsonField(
                                                                                PlantShopGroup.productDetailCall.productDetail(
                                                                                  containerProductDetailResponse.jsonBody,
                                                                                ),
                                                                                r'''$.name''',
                                                                              ).toString(),
                                                                              isLike: FFAppState().wishList.contains(getJsonField(
                                                                                    PlantShopGroup.productDetailCall.productDetail(
                                                                                      containerProductDetailResponse.jsonBody,
                                                                                    ),
                                                                                    r'''$.id''',
                                                                                  ).toString()),
                                                                              regularPrice: PlantShopGroup.productDetailCall.regularPrice(
                                                                                containerProductDetailResponse.jsonBody,
                                                                              )!,
                                                                              price: PlantShopGroup.productDetailCall.price(
                                                                                containerProductDetailResponse.jsonBody,
                                                                              )!,
                                                                              review: PlantShopGroup.productDetailCall
                                                                                  .ratingCount(
                                                                                    containerProductDetailResponse.jsonBody,
                                                                                  )!
                                                                                  .toString(),
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
                                                                                            r'''$.images[0].src''',
                                                                                          ) !=
                                                                                          null)
                                                                                  ? 298.0
                                                                                  : 180.0,
                                                                              width: 189.0,
                                                                              onSale: PlantShopGroup.productDetailCall.onSale(
                                                                                containerProductDetailResponse.jsonBody,
                                                                              )!,
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
                                                                                        r'''$.images[0].src''',
                                                                                      ) !=
                                                                                      null),
                                                                              isLikeTap: () async {
                                                                                if (FFAppState().isLogin) {
                                                                                  await action_blocks.addorRemoveFavourite(
                                                                                    context,
                                                                                    id: getJsonField(
                                                                                      PlantShopGroup.productDetailCall.productDetail(
                                                                                        containerProductDetailResponse.jsonBody,
                                                                                      ),
                                                                                      r'''$.id''',
                                                                                    ).toString(),
                                                                                  );
                                                                                  safeSetState(() {});
                                                                                } else {
                                                                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                                    SnackBar(
                                                                                      content: Text(
                                                                                        'Please log in first',
                                                                                        style: TextStyle(
                                                                                          fontFamily: 'SF Pro Display',
                                                                                          color: FlutterFlowTheme.of(context).primaryText,
                                                                                        ),
                                                                                      ),
                                                                                      duration: Duration(milliseconds: 2000),
                                                                                      backgroundColor: FlutterFlowTheme.of(context).secondary,
                                                                                      action: SnackBarAction(
                                                                                        label: 'Login',
                                                                                        textColor: FlutterFlowTheme.of(context).primary,
                                                                                        onPressed: () async {
                                                                                          context.pushNamed(
                                                                                            SignInPageWidget.routeName,
                                                                                            queryParameters: {
                                                                                              'isInner': serializeParam(
                                                                                                true,
                                                                                                ParamType.bool,
                                                                                              ),
                                                                                            }.withoutNulls,
                                                                                          );
                                                                                        },
                                                                                      ),
                                                                                    ),
                                                                                  );
                                                                                }
                                                                              },
                                                                              isMainTap: () async {
                                                                                context.pushNamed(
                                                                                  ProductDetailPageCopyWidget.routeName,
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
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                      ].addToEnd(SizedBox(height: 12.0)),
                                    ),
                                  ),
                                ),
                              ].addToEnd(SizedBox(height: 92.0)),
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
                                                      'Producrt is out of stock',
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
                                                    'Please log in first',
                                                  );
                                                }
                                              },
                                        text:
                                            FFLocalizations.of(context).getText(
                                          'hswqpgon' /* Add to Cart */,
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
