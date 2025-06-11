import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/main_component/main_component_widget.dart';
import '/pages/components/review_component/review_component_widget.dart';
import '/pages/shimmer/main_component_shimmer/main_component_shimmer_widget.dart';
import '/pages/shimmer/reviews_shimmer/reviews_shimmer_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'detail_component_model.dart';
export 'detail_component_model.dart';

class DetailComponentWidget extends StatefulWidget {
  const DetailComponentWidget({
    super.key,
    required this.productDetail,
    required this.upsellIdsList,
    required this.relatedIdsList,
    required this.variationsList,
    this.priceList,
  });

  final dynamic productDetail;
  final List<String>? upsellIdsList;
  final List<String>? relatedIdsList;
  final List<dynamic>? variationsList;
  final List<String>? priceList;

  @override
  State<DetailComponentWidget> createState() => _DetailComponentWidgetState();
}

class _DetailComponentWidgetState extends State<DetailComponentWidget>
    with RouteAware {
  late DetailComponentModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DetailComponentModel());
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

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primaryBackground,
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(12.0, 20.0, 12.0, 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 20.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                          useGoogleFonts: false,
                          lineHeight: 1.5,
                        ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        (widget!.priceList != null &&
                                    (widget!.priceList)!.isNotEmpty) &&
                                (widget!.variationsList != null &&
                                    (widget!.variationsList)!.isNotEmpty) &&
                                (widget!.priceList?.firstOrNull !=
                                    widget!.priceList?.lastOrNull)
                            ? '${functions.formatPrice(widget!.priceList!.firstOrNull!, FFAppState().thousandSeparator, FFAppState().decimalSeparator, FFAppState().decimalPlaces.toString(), FFAppState().currencyPosition, FFAppState().currency)} - ${functions.formatPrice(widget!.priceList!.lastOrNull!, FFAppState().thousandSeparator, FFAppState().decimalSeparator, FFAppState().decimalPlaces.toString(), FFAppState().currencyPosition, FFAppState().currency)}'
                            : functions.formatPrice(
                                getJsonField(
                                  widget!.productDetail,
                                  r'''$.price''',
                                ).toString(),
                                FFAppState().thousandSeparator,
                                FFAppState().decimalSeparator,
                                FFAppState().decimalPlaces.toString(),
                                FFAppState().currencyPosition,
                                FFAppState().currency),
                        textAlign: TextAlign.start,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'SF Pro Display',
                              fontSize: 18.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                              useGoogleFonts: false,
                              lineHeight: 1.5,
                            ),
                      ),
                      if (getJsonField(
                            widget!.productDetail,
                            r'''$.on_sale''',
                          ) &&
                          ('' !=
                              getJsonField(
                                widget!.productDetail,
                                r'''$.regular_price''',
                              ).toString()))
                        Text(
                          functions.formatPrice(
                              getJsonField(
                                widget!.productDetail,
                                r'''$.regular_price''',
                              ).toString(),
                              FFAppState().thousandSeparator,
                              FFAppState().decimalSeparator,
                              FFAppState().decimalPlaces.toString(),
                              FFAppState().currencyPosition,
                              FFAppState().currency),
                          textAlign: TextAlign.start,
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: 'SF Pro Display',
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                fontSize: 16.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.normal,
                                decoration: TextDecoration.lineThrough,
                                useGoogleFonts: false,
                                lineHeight: 1.5,
                              ),
                        ),
                      if (getJsonField(
                            widget!.productDetail,
                            r'''$.on_sale''',
                          ) &&
                          ('' !=
                              getJsonField(
                                widget!.productDetail,
                                r'''$.regular_price''',
                              ).toString()))
                        RichText(
                          textScaler: MediaQuery.of(context).textScaler,
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
                                          widget!.productDetail,
                                          r'''$.regular_price''',
                                        ).toString())))
                                    .toString(),
                                style: TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context).success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.0,
                                  height: 1.5,
                                ),
                              ),
                              TextSpan(
                                text: FFLocalizations.of(context).getText(
                                  'du61ojol' /* % OFF */,
                                ),
                                style: TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context).success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.0,
                                  height: 1.5,
                                ),
                              )
                            ],
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context).success,
                                  fontSize: 16.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                  useGoogleFonts: false,
                                  lineHeight: 1.5,
                                ),
                          ),
                          textAlign: TextAlign.start,
                        ),
                    ].divide(SizedBox(width: 8.0)),
                  ),
                  if ('0' !=
                      (getJsonField(
                        widget!.productDetail,
                        r'''$.rating_count''',
                      ).toString()))
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        RatingBarIndicator(
                          itemBuilder: (context, index) => Icon(
                            Icons.star_rounded,
                            color: FlutterFlowTheme.of(context).warning,
                          ),
                          direction: Axis.horizontal,
                          rating: double.parse(getJsonField(
                            widget!.productDetail,
                            r'''$.average_rating''',
                          ).toString()),
                          unratedColor: FlutterFlowTheme.of(context).black20,
                          itemCount: 5,
                          itemSize: 14.0,
                        ),
                        RichText(
                          textScaler: MediaQuery.of(context).textScaler,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: getJsonField(
                                  widget!.productDetail,
                                  r'''$.rating_count''',
                                ).toString(),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'SF Pro Display',
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      fontSize: 14.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                      useGoogleFonts: false,
                                      lineHeight: 1.5,
                                    ),
                              ),
                              TextSpan(
                                text: FFLocalizations.of(context).getText(
                                  '1s2cc0bp' /*   */,
                                ),
                                style: TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.0,
                                  height: 0.5,
                                ),
                              ),
                              TextSpan(
                                text: FFLocalizations.of(context).getText(
                                  'm32l9l3d' /*  Reviews */,
                                ),
                                style: TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.0,
                                  height: 0.5,
                                ),
                              )
                            ],
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                  useGoogleFonts: false,
                                  lineHeight: 1.5,
                                ),
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ].divide(SizedBox(width: 6.0)),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      if ('' !=
                          getJsonField(
                            widget!.productDetail,
                            r'''$.sku''',
                          ).toString())
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              if ('' !=
                                  getJsonField(
                                    widget!.productDetail,
                                    r'''$.sku''',
                                  ).toString())
                                Expanded(
                                  child: Text(
                                    getJsonField(
                                      widget!.productDetail,
                                      r'''$.sku''',
                                    ).toString(),
                                    textAlign: TextAlign.start,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          fontSize: 13.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          useGoogleFonts: false,
                                          lineHeight: 1.5,
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
                                widget!.productDetail,
                                r'''$.stock_status''',
                              ).toString()) {
                            return Text(
                              FFLocalizations.of(context).getText(
                                'kre32zck' /* Out of Stock */,
                              ),
                              textAlign: TextAlign.start,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'SF Pro Display',
                                    color: FlutterFlowTheme.of(context).error,
                                    fontSize: 17.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    useGoogleFonts: false,
                                    lineHeight: 1.5,
                                  ),
                            );
                          } else if ((true ==
                                  getJsonField(
                                    widget!.productDetail,
                                    r'''$.manage_stock''',
                                  )) &&
                              (true ==
                                  getJsonField(
                                    widget!.productDetail,
                                    r'''$.backorders_allowed''',
                                  )) &&
                              ('notify' ==
                                  getJsonField(
                                    widget!.productDetail,
                                    r'''$.backorders''',
                                  ).toString())) {
                            return Text(
                              FFLocalizations.of(context).getText(
                                'u84jmyyj' /* Available on backorder */,
                              ),
                              textAlign: TextAlign.start,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'SF Pro Display',
                                    color: FlutterFlowTheme.of(context).primary,
                                    fontSize: 17.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    useGoogleFonts: false,
                                    lineHeight: 1.5,
                                  ),
                            );
                          } else if ((true ==
                                  getJsonField(
                                    widget!.productDetail,
                                    r'''$.manage_stock''',
                                  )) &&
                              (false ==
                                  getJsonField(
                                    widget!.productDetail,
                                    r'''$.backorders_allowed''',
                                  ))) {
                            return RichText(
                              textScaler: MediaQuery.of(context).textScaler,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: FFLocalizations.of(context).getText(
                                      'en4ywh8a' /* Availability :  */,
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          fontSize: 17.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w500,
                                          useGoogleFonts: false,
                                          lineHeight: 1.5,
                                        ),
                                  ),
                                  TextSpan(
                                    text: getJsonField(
                                      widget!.productDetail,
                                      r'''$.stock_quantity''',
                                    ).toString(),
                                    style: TextStyle(
                                      fontFamily: 'SF Pro Display',
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 17.0,
                                      height: 1.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: FFLocalizations.of(context).getText(
                                      '0itgqiwg' /*  in stock */,
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'SF Pro Display',
                                      color:
                                          FlutterFlowTheme.of(context).primary,
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
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      fontSize: 17.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                      useGoogleFonts: false,
                                      lineHeight: 1.5,
                                    ),
                              ),
                              textAlign: TextAlign.start,
                            );
                          } else {
                            return Container(
                              decoration: BoxDecoration(),
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
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primaryBackground,
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(12.0, 20.0, 12.0, 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          _model.dataTapIndex = 0;
                          safeSetState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Builder(
                                builder: (context) {
                                  if (_model.dataTapIndex == 0) {
                                    return Text(
                                      FFLocalizations.of(context).getText(
                                        'p54q9w73' /* Description */,
                                      ),
                                      textAlign: TextAlign.start,
                                      maxLines: 1,
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
                                      FFLocalizations.of(context).getText(
                                        'mgfw5zy4' /* Description */,
                                      ),
                                      textAlign: TextAlign.start,
                                      maxLines: 1,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
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
                              if (_model.dataTapIndex == 0)
                                Container(
                                  width: 82.0,
                                  height: 1.5,
                                  decoration: BoxDecoration(
                                    color: _model.dataTapIndex == 0
                                        ? FlutterFlowTheme.of(context).primary
                                        : Color(0x00000000),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          _model.dataTapIndex = 1;
                          safeSetState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(),
                          child: Visibility(
                            visible: '' !=
                                getJsonField(
                                  widget!.productDetail,
                                  r'''$.short_description''',
                                ).toString(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Builder(
                                  builder: (context) {
                                    if (_model.dataTapIndex == 1) {
                                      return Text(
                                        FFLocalizations.of(context).getText(
                                          'ebn4bv0v' /* Information */,
                                        ),
                                        textAlign: TextAlign.start,
                                        maxLines: 1,
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
                                        FFLocalizations.of(context).getText(
                                          'psf8b8pw' /* Information */,
                                        ),
                                        textAlign: TextAlign.start,
                                        maxLines: 1,
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
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
                                if (_model.dataTapIndex == 1)
                                  Container(
                                    width: 82.0,
                                    height: 1.5,
                                    decoration: BoxDecoration(
                                      color: _model.dataTapIndex == 1
                                          ? FlutterFlowTheme.of(context).primary
                                          : Color(0x00000000),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ].divide(SizedBox(width: 20.0)),
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
                    child: custom_widgets.HtmlConverter(
                      width: double.infinity,
                      height: 200.0,
                      text: _model.dataTapIndex == 0
                          ? getJsonField(
                              widget!.productDetail,
                              r'''$.description''',
                            ).toString()
                          : getJsonField(
                              widget!.productDetail,
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
            child: FutureBuilder<ApiCallResponse>(
              future: FFAppState().reviews(
                uniqueQueryKey: getJsonField(
                  widget!.productDetail,
                  r'''$.id''',
                ).toString(),
                requestFn: () => PlantShopGroup.productReviewCall.call(
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
                final reviewsProductReviewResponse = snapshot.data!;
                _model.debugBackendQueries[
                        'PlantShopGroup.productReviewCall_statusCode_Container_vvlj66s2'] =
                    debugSerializeParam(
                  reviewsProductReviewResponse.statusCode,
                  ParamType.int,
                  link:
                      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=DetailComponent',
                  name: 'int',
                  nullable: false,
                );
                _model.debugBackendQueries[
                        'PlantShopGroup.productReviewCall_responseBody_Container_vvlj66s2'] =
                    debugSerializeParam(
                  reviewsProductReviewResponse.bodyText,
                  ParamType.String,
                  link:
                      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=DetailComponent',
                  name: 'String',
                  nullable: false,
                );
                debugLogWidgetClass(_model);

                return Container(
                  decoration: BoxDecoration(),
                  child: Visibility(
                    visible: (PlantShopGroup.productReviewCall.status(
                              reviewsProductReviewResponse.jsonBody,
                            ) ==
                            null) &&
                        (PlantShopGroup.productReviewCall.reviewsList(
                                  reviewsProductReviewResponse.jsonBody,
                                ) !=
                                null &&
                            (PlantShopGroup.productReviewCall.reviewsList(
                              reviewsProductReviewResponse.jsonBody,
                            ))!
                                .isNotEmpty),
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primaryBackground,
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              12.0, 20.0, 12.0, 20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    FFLocalizations.of(context).getText(
                                      '2a0dr9fb' /* Reviews */,
                                    ),
                                    textAlign: TextAlign.start,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          fontSize: 20.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                          useGoogleFonts: false,
                                          lineHeight: 1.5,
                                        ),
                                  ),
                                  InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      context.pushNamed(
                                        ReviewPageWidget.routeName,
                                        queryParameters: {
                                          'reviewsList': serializeParam(
                                            PlantShopGroup.productReviewCall
                                                .reviewsList(
                                              reviewsProductReviewResponse
                                                  .jsonBody,
                                            ),
                                            ParamType.JSON,
                                            isList: true,
                                          ),
                                          'averageRating': serializeParam(
                                            getJsonField(
                                              widget!.productDetail,
                                              r'''$.average_rating''',
                                            ).toString(),
                                            ParamType.String,
                                          ),
                                        }.withoutNulls,
                                      );
                                    },
                                    child: Container(
                                      height: 29.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .black10,
                                        borderRadius:
                                            BorderRadius.circular(30.0),
                                      ),
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            10.0, 0.0, 10.0, 0.0),
                                        child: Text(
                                          FFLocalizations.of(context).getText(
                                            'mz0w24di' /* View all */,
                                          ),
                                          textAlign: TextAlign.start,
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
                                ].divide(SizedBox(width: 8.0)),
                              ),
                              Builder(
                                builder: (context) {
                                  final reviewList =
                                      PlantShopGroup.productReviewCall
                                              .reviewsList(
                                                reviewsProductReviewResponse
                                                    .jsonBody,
                                              )
                                              ?.take(2)
                                              .toList()
                                              ?.toList() ??
                                          [];
                                  _model.debugGeneratorVariables[
                                          'reviewList${reviewList.length > 100 ? ' (first 100)' : ''}'] =
                                      debugSerializeParam(
                                    reviewList.take(100),
                                    ParamType.JSON,
                                    isList: true,
                                    link:
                                        'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=DetailComponent',
                                    name: 'dynamic',
                                    nullable: false,
                                  );
                                  debugLogWidgetClass(_model);

                                  return Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: List.generate(reviewList.length,
                                            (reviewListIndex) {
                                      final reviewListItem =
                                          reviewList[reviewListIndex];
                                      return wrapWithModel(
                                        model: _model.reviewComponentModels
                                            .getModel(
                                          getJsonField(
                                            reviewListItem,
                                            r'''$.id''',
                                          ).toString(),
                                          reviewListIndex,
                                        ),
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: Builder(builder: (_) {
                                          return DebugFlutterFlowModelContext(
                                            rootModel: _model.rootModel,
                                            child: ReviewComponentWidget(
                                              key: Key(
                                                'Keyd8o_${getJsonField(
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
                                    })
                                        .divide(SizedBox(height: 20.0))
                                        .addToStart(SizedBox(height: 16.0)),
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
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primaryBackground,
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            FFLocalizations.of(context).getText(
                              's878imht' /* Up sell product */,
                            ),
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'SF Pro Display',
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  fontSize: 20.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  useGoogleFonts: false,
                                  lineHeight: 1.5,
                                ),
                          ),
                          InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              context.pushNamed(
                                UpSellProductsPageWidget.routeName,
                                queryParameters: {
                                  'upSellProductList': serializeParam(
                                    widget!.upsellIdsList,
                                    ParamType.String,
                                    isList: true,
                                  ),
                                }.withoutNulls,
                              );
                            },
                            child: Container(
                              height: 29.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).black10,
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    10.0, 0.0, 10.0, 0.0),
                                child: Text(
                                  FFLocalizations.of(context).getText(
                                    'c7wdl67m' /* View all */,
                                  ),
                                  textAlign: TextAlign.start,
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
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(),
                      child: Builder(
                        builder: (context) {
                          final upSellIdsList =
                              widget!.upsellIdsList!.toList().take(6).toList();
                          _model.debugGeneratorVariables[
                                  'upSellIdsList${upSellIdsList.length > 100 ? ' (first 100)' : ''}'] =
                              debugSerializeParam(
                            upSellIdsList.take(100),
                            ParamType.String,
                            isList: true,
                            link:
                                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=DetailComponent',
                            name: 'String',
                            nullable: false,
                          );
                          debugLogWidgetClass(_model);

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: List.generate(upSellIdsList.length,
                                      (upSellIdsListIndex) {
                                final upSellIdsListItem =
                                    upSellIdsList[upSellIdsListIndex];
                                return FutureBuilder<ApiCallResponse>(
                                  future: FFAppState().productDdetail(
                                    uniqueQueryKey: upSellIdsListItem,
                                    requestFn: () =>
                                        PlantShopGroup.productDetailCall.call(
                                      productId: upSellIdsListItem,
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
                                    final containerProductDetailResponse =
                                        snapshot.data!;
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.productDetailCall_statusCode_Container_6ze49wss'] =
                                        debugSerializeParam(
                                      containerProductDetailResponse.statusCode,
                                      ParamType.int,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=DetailComponent',
                                      name: 'int',
                                      nullable: false,
                                    );
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.productDetailCall_responseBody_Container_6ze49wss'] =
                                        debugSerializeParam(
                                      containerProductDetailResponse.bodyText,
                                      ParamType.String,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=DetailComponent',
                                      name: 'String',
                                      nullable: false,
                                    );
                                    debugLogWidgetClass(_model);

                                    return Container(
                                      decoration: BoxDecoration(),
                                      child: wrapWithModel(
                                        model: _model.mainComponentModels1
                                            .getModel(
                                          getJsonField(
                                            PlantShopGroup.productDetailCall
                                                .productDetail(
                                              containerProductDetailResponse
                                                  .jsonBody,
                                            ),
                                            r'''$.id''',
                                          ).toString(),
                                          upSellIdsListIndex,
                                        ),
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: Builder(builder: (_) {
                                          return DebugFlutterFlowModelContext(
                                            rootModel: _model.rootModel,
                                            child: MainComponentWidget(
                                              key: Key(
                                                'Keyrd0_${getJsonField(
                                                  PlantShopGroup
                                                      .productDetailCall
                                                      .productDetail(
                                                    containerProductDetailResponse
                                                        .jsonBody,
                                                  ),
                                                  r'''$.id''',
                                                ).toString()}',
                                              ),
                                              image: getJsonField(
                                                PlantShopGroup.productDetailCall
                                                    .imagesList(
                                                      containerProductDetailResponse
                                                          .jsonBody,
                                                    )!
                                                    .firstOrNull,
                                                r'''$.src''',
                                              ).toString(),
                                              name: getJsonField(
                                                PlantShopGroup.productDetailCall
                                                    .productDetail(
                                                  containerProductDetailResponse
                                                      .jsonBody,
                                                ),
                                                r'''$.name''',
                                              ).toString(),
                                              isLike: FFAppState()
                                                  .wishList
                                                  .contains(getJsonField(
                                                    PlantShopGroup
                                                        .productDetailCall
                                                        .productDetail(
                                                      containerProductDetailResponse
                                                          .jsonBody,
                                                    ),
                                                    r'''$.id''',
                                                  ).toString()),
                                              regularPrice: PlantShopGroup
                                                  .productDetailCall
                                                  .regularPrice(
                                                containerProductDetailResponse
                                                    .jsonBody,
                                              )!,
                                              price: PlantShopGroup
                                                  .productDetailCall
                                                  .price(
                                                containerProductDetailResponse
                                                    .jsonBody,
                                              )!,
                                              review: PlantShopGroup
                                                  .productDetailCall
                                                  .ratingCount(
                                                    containerProductDetailResponse
                                                        .jsonBody,
                                                  )!
                                                  .toString(),
                                              isBigContainer: true,
                                              height: ('' !=
                                                          getJsonField(
                                                            PlantShopGroup
                                                                .productDetailCall
                                                                .productDetail(
                                                              containerProductDetailResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.images[0].src''',
                                                          ).toString()) &&
                                                      (getJsonField(
                                                            PlantShopGroup
                                                                .productDetailCall
                                                                .productDetail(
                                                              containerProductDetailResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.images[0].src''',
                                                          ) !=
                                                          null) &&
                                                      (getJsonField(
                                                            PlantShopGroup
                                                                .productDetailCall
                                                                .productDetail(
                                                              containerProductDetailResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.images''',
                                                          ) !=
                                                          null)
                                                  ? 298.0
                                                  : 180.0,
                                              width: 189.0,
                                              onSale: PlantShopGroup
                                                  .productDetailCall
                                                  .onSale(
                                                containerProductDetailResponse
                                                    .jsonBody,
                                              )!,
                                              showImage: ('' !=
                                                      getJsonField(
                                                        PlantShopGroup
                                                            .productDetailCall
                                                            .productDetail(
                                                          containerProductDetailResponse
                                                              .jsonBody,
                                                        ),
                                                        r'''$.images[0].src''',
                                                      ).toString()) &&
                                                  (getJsonField(
                                                        PlantShopGroup
                                                            .productDetailCall
                                                            .productDetail(
                                                          containerProductDetailResponse
                                                              .jsonBody,
                                                        ),
                                                        r'''$.images[0].src''',
                                                      ) !=
                                                      null) &&
                                                  (getJsonField(
                                                        PlantShopGroup
                                                            .productDetailCall
                                                            .productDetail(
                                                          containerProductDetailResponse
                                                              .jsonBody,
                                                        ),
                                                        r'''$.images''',
                                                      ) !=
                                                      null),
                                              isLikeTap: () async {
                                                if (FFAppState().isLogin) {
                                                  await action_blocks
                                                      .addorRemoveFavourite(
                                                    context,
                                                    id: getJsonField(
                                                      PlantShopGroup
                                                          .productDetailCall
                                                          .productDetail(
                                                        containerProductDetailResponse
                                                            .jsonBody,
                                                      ),
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
                                                        FFLocalizations.of(
                                                                context)
                                                            .getVariableText(
                                                          enText:
                                                              'Please log in first',
                                                          arText:
                                                              'الرجاء تسجيل الدخول أولاً',
                                                        ),
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          color: FlutterFlowTheme
                                                                  .of(context)
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
                                                        label: FFLocalizations
                                                                .of(context)
                                                            .getVariableText(
                                                          enText: 'Login',
                                                          arText:
                                                              'تسجيل الدخول',
                                                        ),
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
                                              isMainTap: () async {
                                                context.pushNamed(
                                                  ProductDetailPageWidget
                                                      .routeName,
                                                  queryParameters: {
                                                    'productDetail':
                                                        serializeParam(
                                                      PlantShopGroup
                                                          .productDetailCall
                                                          .productDetail(
                                                        containerProductDetailResponse
                                                            .jsonBody,
                                                      ),
                                                      ParamType.JSON,
                                                    ),
                                                    'upsellIdsList':
                                                        serializeParam(
                                                      (getJsonField(
                                                        PlantShopGroup
                                                            .productDetailCall
                                                            .productDetail(
                                                          containerProductDetailResponse
                                                              .jsonBody,
                                                        ),
                                                        r'''$.upsell_ids''',
                                                        true,
                                                      ) as List)
                                                          .map<String>((s) =>
                                                              s.toString())
                                                          .toList(),
                                                      ParamType.String,
                                                      isList: true,
                                                    ),
                                                    'relatedIdsList':
                                                        serializeParam(
                                                      (getJsonField(
                                                        PlantShopGroup
                                                            .productDetailCall
                                                            .productDetail(
                                                          containerProductDetailResponse
                                                              .jsonBody,
                                                        ),
                                                        r'''$.related_ids''',
                                                        true,
                                                      ) as List)
                                                          .map<String>((s) =>
                                                              s.toString())
                                                          .toList(),
                                                      ParamType.String,
                                                      isList: true,
                                                    ),
                                                    'imagesList':
                                                        serializeParam(
                                                      PlantShopGroup
                                                          .productDetailCall
                                                          .imagesList(
                                                        containerProductDetailResponse
                                                            .jsonBody,
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
                                  .divide(SizedBox(width: 12.0))
                                  .addToStart(SizedBox(width: 12.0))
                                  .addToEnd(SizedBox(width: 12.0)),
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
            (widget!.relatedIdsList)!.isNotEmpty)
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primaryBackground,
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            FFLocalizations.of(context).getText(
                              '7lgx0dud' /* Related product */,
                            ),
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'SF Pro Display',
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  fontSize: 20.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  useGoogleFonts: false,
                                  lineHeight: 1.5,
                                ),
                          ),
                          InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              context.pushNamed(
                                RelatedProductsPageWidget.routeName,
                                queryParameters: {
                                  'relatedProductList': serializeParam(
                                    widget!.relatedIdsList,
                                    ParamType.String,
                                    isList: true,
                                  ),
                                }.withoutNulls,
                              );
                            },
                            child: Container(
                              height: 29.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).black10,
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    10.0, 0.0, 10.0, 0.0),
                                child: Text(
                                  FFLocalizations.of(context).getText(
                                    'po2o18d4' /* View all */,
                                  ),
                                  textAlign: TextAlign.start,
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
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(),
                      child: Builder(
                        builder: (context) {
                          final relatedIdsList =
                              widget!.relatedIdsList!.toList().take(6).toList();
                          _model.debugGeneratorVariables[
                                  'relatedIdsList${relatedIdsList.length > 100 ? ' (first 100)' : ''}'] =
                              debugSerializeParam(
                            relatedIdsList.take(100),
                            ParamType.String,
                            isList: true,
                            link:
                                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=DetailComponent',
                            name: 'String',
                            nullable: false,
                          );
                          debugLogWidgetClass(_model);

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: List.generate(relatedIdsList.length,
                                      (relatedIdsListIndex) {
                                final relatedIdsListItem =
                                    relatedIdsList[relatedIdsListIndex];
                                return FutureBuilder<ApiCallResponse>(
                                  future: FFAppState().productDdetail(
                                    uniqueQueryKey: relatedIdsListItem,
                                    requestFn: () =>
                                        PlantShopGroup.productDetailCall.call(
                                      productId: relatedIdsListItem,
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
                                    final containerProductDetailResponse =
                                        snapshot.data!;
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.productDetailCall_statusCode_Container_pk8debwz'] =
                                        debugSerializeParam(
                                      containerProductDetailResponse.statusCode,
                                      ParamType.int,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=DetailComponent',
                                      name: 'int',
                                      nullable: false,
                                    );
                                    _model.debugBackendQueries[
                                            'PlantShopGroup.productDetailCall_responseBody_Container_pk8debwz'] =
                                        debugSerializeParam(
                                      containerProductDetailResponse.bodyText,
                                      ParamType.String,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=DetailComponent',
                                      name: 'String',
                                      nullable: false,
                                    );
                                    debugLogWidgetClass(_model);

                                    return Container(
                                      decoration: BoxDecoration(),
                                      child: wrapWithModel(
                                        model: _model.mainComponentModels2
                                            .getModel(
                                          getJsonField(
                                            PlantShopGroup.productDetailCall
                                                .productDetail(
                                              containerProductDetailResponse
                                                  .jsonBody,
                                            ),
                                            r'''$.id''',
                                          ).toString(),
                                          relatedIdsListIndex,
                                        ),
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: Builder(builder: (_) {
                                          return DebugFlutterFlowModelContext(
                                            rootModel: _model.rootModel,
                                            child: MainComponentWidget(
                                              key: Key(
                                                'Keyvyz_${getJsonField(
                                                  PlantShopGroup
                                                      .productDetailCall
                                                      .productDetail(
                                                    containerProductDetailResponse
                                                        .jsonBody,
                                                  ),
                                                  r'''$.id''',
                                                ).toString()}',
                                              ),
                                              image: getJsonField(
                                                PlantShopGroup.productDetailCall
                                                    .imagesList(
                                                      containerProductDetailResponse
                                                          .jsonBody,
                                                    )!
                                                    .firstOrNull,
                                                r'''$.src''',
                                              ).toString(),
                                              name: getJsonField(
                                                PlantShopGroup.productDetailCall
                                                    .productDetail(
                                                  containerProductDetailResponse
                                                      .jsonBody,
                                                ),
                                                r'''$.name''',
                                              ).toString(),
                                              isLike: FFAppState()
                                                  .wishList
                                                  .contains(getJsonField(
                                                    PlantShopGroup
                                                        .productDetailCall
                                                        .productDetail(
                                                      containerProductDetailResponse
                                                          .jsonBody,
                                                    ),
                                                    r'''$.id''',
                                                  ).toString()),
                                              regularPrice: PlantShopGroup
                                                  .productDetailCall
                                                  .regularPrice(
                                                containerProductDetailResponse
                                                    .jsonBody,
                                              )!,
                                              price: PlantShopGroup
                                                  .productDetailCall
                                                  .price(
                                                containerProductDetailResponse
                                                    .jsonBody,
                                              )!,
                                              review: PlantShopGroup
                                                  .productDetailCall
                                                  .ratingCount(
                                                    containerProductDetailResponse
                                                        .jsonBody,
                                                  )!
                                                  .toString(),
                                              isBigContainer: true,
                                              height: ('' !=
                                                          getJsonField(
                                                            PlantShopGroup
                                                                .productDetailCall
                                                                .productDetail(
                                                              containerProductDetailResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.images[0].src''',
                                                          ).toString()) &&
                                                      (getJsonField(
                                                            PlantShopGroup
                                                                .productDetailCall
                                                                .productDetail(
                                                              containerProductDetailResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.images[0].src''',
                                                          ) !=
                                                          null) &&
                                                      (getJsonField(
                                                            PlantShopGroup
                                                                .productDetailCall
                                                                .productDetail(
                                                              containerProductDetailResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.images[0].src''',
                                                          ) !=
                                                          null)
                                                  ? 298.0
                                                  : 180.0,
                                              width: 189.0,
                                              onSale: PlantShopGroup
                                                  .productDetailCall
                                                  .onSale(
                                                containerProductDetailResponse
                                                    .jsonBody,
                                              )!,
                                              showImage: ('' !=
                                                      getJsonField(
                                                        PlantShopGroup
                                                            .productDetailCall
                                                            .productDetail(
                                                          containerProductDetailResponse
                                                              .jsonBody,
                                                        ),
                                                        r'''$.images[0].src''',
                                                      ).toString()) &&
                                                  (getJsonField(
                                                        PlantShopGroup
                                                            .productDetailCall
                                                            .productDetail(
                                                          containerProductDetailResponse
                                                              .jsonBody,
                                                        ),
                                                        r'''$.images[0].src''',
                                                      ) !=
                                                      null) &&
                                                  (getJsonField(
                                                        PlantShopGroup
                                                            .productDetailCall
                                                            .productDetail(
                                                          containerProductDetailResponse
                                                              .jsonBody,
                                                        ),
                                                        r'''$.images[0].src''',
                                                      ) !=
                                                      null),
                                              isLikeTap: () async {
                                                if (FFAppState().isLogin) {
                                                  await action_blocks
                                                      .addorRemoveFavourite(
                                                    context,
                                                    id: getJsonField(
                                                      PlantShopGroup
                                                          .productDetailCall
                                                          .productDetail(
                                                        containerProductDetailResponse
                                                            .jsonBody,
                                                      ),
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
                                                        FFLocalizations.of(
                                                                context)
                                                            .getVariableText(
                                                          enText:
                                                              'Please log in first',
                                                          arText:
                                                              'الرجاء تسجيل الدخول أولاً',
                                                        ),
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          color: FlutterFlowTheme
                                                                  .of(context)
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
                                                        label: FFLocalizations
                                                                .of(context)
                                                            .getVariableText(
                                                          enText: 'Login',
                                                          arText:
                                                              'تسجيل الدخول',
                                                        ),
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
                                              isMainTap: () async {
                                                context.pushNamed(
                                                  ProductDetailPageWidget
                                                      .routeName,
                                                  queryParameters: {
                                                    'productDetail':
                                                        serializeParam(
                                                      PlantShopGroup
                                                          .productDetailCall
                                                          .productDetail(
                                                        containerProductDetailResponse
                                                            .jsonBody,
                                                      ),
                                                      ParamType.JSON,
                                                    ),
                                                    'upsellIdsList':
                                                        serializeParam(
                                                      (getJsonField(
                                                        PlantShopGroup
                                                            .productDetailCall
                                                            .productDetail(
                                                          containerProductDetailResponse
                                                              .jsonBody,
                                                        ),
                                                        r'''$.upsell_ids''',
                                                        true,
                                                      ) as List)
                                                          .map<String>((s) =>
                                                              s.toString())
                                                          .toList(),
                                                      ParamType.String,
                                                      isList: true,
                                                    ),
                                                    'relatedIdsList':
                                                        serializeParam(
                                                      (getJsonField(
                                                        PlantShopGroup
                                                            .productDetailCall
                                                            .productDetail(
                                                          containerProductDetailResponse
                                                              .jsonBody,
                                                        ),
                                                        r'''$.related_ids''',
                                                        true,
                                                      ) as List)
                                                          .map<String>((s) =>
                                                              s.toString())
                                                          .toList(),
                                                      ParamType.String,
                                                      isList: true,
                                                    ),
                                                    'imagesList':
                                                        serializeParam(
                                                      PlantShopGroup
                                                          .productDetailCall
                                                          .imagesList(
                                                        containerProductDetailResponse
                                                            .jsonBody,
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
                                  .divide(SizedBox(width: 12.0))
                                  .addToStart(SizedBox(width: 12.0))
                                  .addToEnd(SizedBox(width: 12.0)),
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
      ],
    );
  }
}
