import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'main_component_model.dart';
export 'main_component_model.dart';

class MainComponentWidget extends StatefulWidget {
  const MainComponentWidget({
    super.key,
    required this.image,
    required this.name,
    bool? isLike,
    required this.regularPrice,
    required this.price,
    required this.isLikeTap,
    required this.isMainTap,
    required this.review,
    bool? isBigContainer,
    required this.height,
    required this.width,
    bool? onSale,
    required this.showImage,
    bool? isNotBorder,
  })  : this.isLike = isLike ?? false,
        this.isBigContainer = isBigContainer ?? false,
        this.onSale = onSale ?? false,
        this.isNotBorder = isNotBorder ?? false;

  final String? image;
  final String? name;
  final bool isLike;
  final String? regularPrice;
  final String? price;
  final Future Function()? isLikeTap;
  final Future Function()? isMainTap;
  final String? review;
  final bool isBigContainer;
  final double? height;
  final double? width;
  final bool onSale;
  final bool? showImage;
  final bool isNotBorder;

  @override
  State<MainComponentWidget> createState() => _MainComponentWidgetState();
}

class _MainComponentWidgetState extends State<MainComponentWidget>
    with RouteAware {
  late MainComponentModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MainComponentModel());
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
        if (widget!.isBigContainer == false) {
          return InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              await widget.isMainTap?.call();
            },
            child: Container(
              width: widget!.width,
              height: widget!.height,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primaryBackground,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: widget!.isNotBorder == true
                      ? Colors.transparent
                      : FlutterFlowTheme.of(context).black20,
                  width: widget!.isNotBorder == true ? 0.0 : 1.0,
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget!.showImage ?? true)
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(0.0),
                              bottomRight: Radius.circular(0.0),
                              topLeft: Radius.circular(12.0),
                              topRight: Radius.circular(12.0),
                            ),
                            child: CachedNetworkImage(
                              fadeInDuration: Duration(milliseconds: 200),
                              fadeOutDuration: Duration(milliseconds: 200),
                              imageUrl: widget!.image!,
                              fit: BoxFit.contain,
                              errorWidget: (context, error, stackTrace) =>
                                  Image.asset(
                                'assets/images/error_image.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      if (!widget!.showImage!)
                        Container(
                          width: double.infinity,
                          height: 30.0,
                          decoration: BoxDecoration(),
                        ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            8.0, 10.0, 8.0, 10.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (('0' != widget!.review) || widget!.onSale)
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  if ('0' != widget!.review)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(0.0),
                                      child: SvgPicture.asset(
                                        'assets/images/rating.svg',
                                        width: 10.0,
                                        height: 10.0,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  if ('0' != widget!.review)
                                    Text(
                                      valueOrDefault<String>(
                                        widget!.review,
                                        '5',
                                      ),
                                      textAlign: TextAlign.start,
                                      maxLines: 1,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            fontSize: 10.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.normal,
                                            useGoogleFonts: false,
                                          ),
                                    ),
                                  if ('0' != widget!.review)
                                    Expanded(
                                      child: Text(
                                        FFAppConstants.reviewText,
                                        textAlign: TextAlign.start,
                                        maxLines: 1,
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              fontSize: 10.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.normal,
                                              useGoogleFonts: false,
                                            ),
                                      ),
                                    ),
                                ].divide(SizedBox(width: 4.0)),
                              ),
                            if (('' != widget!.regularPrice) && widget!.onSale)
                              RichText(
                                textScaler: MediaQuery.of(context).textScaler,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: (100 *
                                              ((double.parse((widget!
                                                      .regularPrice!))) -
                                                  (double.parse(
                                                      (widget!.price!)))) ~/
                                              (double.parse(
                                                  (widget!.regularPrice!))))
                                          .toString(),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            color: FlutterFlowTheme.of(context)
                                                .success,
                                            fontSize: 12.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w500,
                                            useGoogleFonts: false,
                                            lineHeight: 1.5,
                                          ),
                                    ),
                                    TextSpan(
                                      text: FFLocalizations.of(context).getText(
                                        '2alg9xtu' /* % OFF */,
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'SF Pro Display',
                                        color: FlutterFlowTheme.of(context)
                                            .success,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12.0,
                                        height: 1.5,
                                      ),
                                    )
                                  ],
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'SF Pro Display',
                                        color: FlutterFlowTheme.of(context)
                                            .success,
                                        fontSize: 12.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        useGoogleFonts: false,
                                      ),
                                ),
                                textAlign: TextAlign.start,
                                maxLines: 1,
                              ),
                            Text(
                              functions
                                  .removeHtmlEntities(valueOrDefault<String>(
                                widget!.name,
                                'Name',
                              )),
                              textAlign: TextAlign.start,
                              maxLines: 2,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 13.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.normal,
                                    useGoogleFonts: false,
                                    lineHeight: 1.2,
                                  ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 2.0, 0.0, 0.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Flexible(
                                    child: AutoSizeText(
                                      functions.formatPrice(
                                          widget!.price!,
                                          FFAppState().thousandSeparator,
                                          FFAppState().decimalSeparator,
                                          FFAppState().decimalPlaces.toString(),
                                          FFAppState().currencyPosition,
                                          FFAppState().currency),
                                      textAlign: TextAlign.start,
                                      maxLines: 1,
                                      minFontSize: 12.0,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            fontSize: 14.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w500,
                                            useGoogleFonts: false,
                                          ),
                                    ),
                                  ),
                                  if (('' != widget!.regularPrice) &&
                                      widget!.onSale)
                                    Flexible(
                                      child: AutoSizeText(
                                        functions.formatPrice(
                                            widget!.regularPrice!,
                                            FFAppState().thousandSeparator,
                                            FFAppState().decimalSeparator,
                                            FFAppState()
                                                .decimalPlaces
                                                .toString(),
                                            FFAppState().currencyPosition,
                                            FFAppState().currency),
                                        textAlign: TextAlign.start,
                                        maxLines: 1,
                                        minFontSize: 10.0,
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .black30,
                                              fontSize: 14.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.normal,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              useGoogleFonts: false,
                                            ),
                                      ),
                                    ),
                                ].divide(SizedBox(width: 2.0)),
                              ),
                            ),
                          ].divide(SizedBox(height: 4.0)),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            if (widget!.onSale) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).primary,
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 4.0, 8.0, 4.0),
                                  child: Text(
                                    FFLocalizations.of(context).getText(
                                      '1dj04jko' /* SALE */,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          color: FlutterFlowTheme.of(context)
                                              .primaryBackground,
                                          fontSize: 12.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          useGoogleFonts: false,
                                          lineHeight: 1.0,
                                        ),
                                  ),
                                ),
                              );
                            } else {
                              return Container(
                                decoration: BoxDecoration(),
                              );
                            }
                          },
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            await widget.isLikeTap?.call();
                          },
                          child: Container(
                            width: 24.0,
                            height: 24.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 2.0,
                                  color:
                                      FlutterFlowTheme.of(context).shadowColor,
                                  offset: Offset(
                                    0.0,
                                    1.0,
                                  ),
                                  spreadRadius: 0.0,
                                )
                              ],
                              shape: BoxShape.circle,
                            ),
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Builder(
                              builder: (context) {
                                if (widget!.isLike) {
                                  return Icon(
                                    Icons.favorite_rounded,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 16.0,
                                  );
                                } else {
                                  return Icon(
                                    Icons.favorite_border_rounded,
                                    color: Colors.black,
                                    size: 16.0,
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ].divide(SizedBox(width: 4.0)),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              await widget.isMainTap?.call();
            },
            child: Container(
              width: widget!.width,
              height: widget!.height,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primaryBackground,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: widget!.isNotBorder == true
                      ? Colors.transparent
                      : FlutterFlowTheme.of(context).black20,
                  width: widget!.isNotBorder == true ? 0.0 : 1.0,
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget!.showImage ?? true)
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(0.0),
                              bottomRight: Radius.circular(0.0),
                              topLeft: Radius.circular(12.0),
                              topRight: Radius.circular(12.0),
                            ),
                            child: CachedNetworkImage(
                              fadeInDuration: Duration(milliseconds: 200),
                              fadeOutDuration: Duration(milliseconds: 200),
                              imageUrl: widget!.image!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.contain,
                              errorWidget: (context, error, stackTrace) =>
                                  Image.asset(
                                'assets/images/error_image.png',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      if (!widget!.showImage!)
                        Container(
                          width: double.infinity,
                          height: 35.0,
                          decoration: BoxDecoration(),
                        ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            12.0, 12.0, 12.0, 15.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (('0' != widget!.review) || widget!.onSale)
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  if ('0' != widget!.review)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(0.0),
                                      child: SvgPicture.asset(
                                        'assets/images/rating.svg',
                                        width: 12.0,
                                        height: 12.0,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  if ('0' != widget!.review)
                                    Text(
                                      valueOrDefault<String>(
                                        widget!.review,
                                        '5',
                                      ),
                                      textAlign: TextAlign.start,
                                      maxLines: 1,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            fontSize: 12.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.bold,
                                            useGoogleFonts: false,
                                            lineHeight: 1.0,
                                          ),
                                    ),
                                  if ('0' != widget!.review)
                                    Expanded(
                                      child: Text(
                                        FFAppConstants.reviewText,
                                        textAlign: TextAlign.start,
                                        maxLines: 1,
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              fontSize: 12.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                              useGoogleFonts: false,
                                              lineHeight: 1.0,
                                            ),
                                      ),
                                    ),
                                  if (('' != widget!.regularPrice) &&
                                      widget!.onSale)
                                    RichText(
                                      textScaler:
                                          MediaQuery.of(context).textScaler,
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: (100 *
                                                    ((double.parse((widget!
                                                            .regularPrice!))) -
                                                        (double.parse((widget!
                                                            .price!)))) ~/
                                                    (double.parse((widget!
                                                        .regularPrice!))))
                                                .toString(),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'SF Pro Display',
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .success,
                                                  fontSize: 14.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w500,
                                                  useGoogleFonts: false,
                                                  lineHeight: 1.2,
                                                ),
                                          ),
                                          TextSpan(
                                            text: FFLocalizations.of(context)
                                                .getText(
                                              'votmzinj' /* % OFF */,
                                            ),
                                            style: TextStyle(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .success,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14.0,
                                              height: 1.2,
                                            ),
                                          )
                                        ],
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .success,
                                              fontSize: 14.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w500,
                                              useGoogleFonts: false,
                                              lineHeight: 1.2,
                                            ),
                                      ),
                                      textAlign: TextAlign.end,
                                      maxLines: 1,
                                    ),
                                ].divide(SizedBox(width: 4.0)),
                              ),
                            Text(
                              functions
                                  .removeHtmlEntities(valueOrDefault<String>(
                                widget!.name,
                                'Name',
                              )),
                              textAlign: TextAlign.start,
                              maxLines: 2,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    useGoogleFonts: false,
                                    lineHeight: 1.5,
                                  ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Flexible(
                                  child: AutoSizeText(
                                    functions.formatPrice(
                                        widget!.price!,
                                        FFAppState().thousandSeparator,
                                        FFAppState().decimalSeparator,
                                        FFAppState().decimalPlaces.toString(),
                                        FFAppState().currencyPosition,
                                        FFAppState().currency),
                                    textAlign: TextAlign.start,
                                    maxLines: 1,
                                    minFontSize: 12.0,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          fontSize: 17.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w500,
                                          useGoogleFonts: false,
                                        ),
                                  ),
                                ),
                                if (('' != widget!.regularPrice) &&
                                    widget!.onSale)
                                  Flexible(
                                    child: AutoSizeText(
                                      functions.formatPrice(
                                          widget!.regularPrice!,
                                          FFAppState().thousandSeparator,
                                          FFAppState().decimalSeparator,
                                          FFAppState().decimalPlaces.toString(),
                                          FFAppState().currencyPosition,
                                          FFAppState().currency),
                                      textAlign: TextAlign.start,
                                      maxLines: 1,
                                      minFontSize: 10.0,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            color: FlutterFlowTheme.of(context)
                                                .black30,
                                            fontSize: 14.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w500,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            useGoogleFonts: false,
                                          ),
                                    ),
                                  ),
                              ].divide(SizedBox(width: 2.0)),
                            ),
                          ].divide(SizedBox(height: 8.0)),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            if (widget!.onSale) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).primary,
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 4.0, 8.0, 4.0),
                                  child: Text(
                                    FFLocalizations.of(context).getText(
                                      'n9flzvjc' /* SALE */,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          color: FlutterFlowTheme.of(context)
                                              .primaryBackground,
                                          fontSize: 12.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          useGoogleFonts: false,
                                          lineHeight: 1.0,
                                        ),
                                  ),
                                ),
                              );
                            } else {
                              return Container(
                                decoration: BoxDecoration(),
                              );
                            }
                          },
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            await widget.isLikeTap?.call();
                          },
                          child: Container(
                            width: 24.0,
                            height: 24.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 2.0,
                                  color:
                                      FlutterFlowTheme.of(context).shadowColor,
                                  offset: Offset(
                                    0.0,
                                    1.0,
                                  ),
                                  spreadRadius: 0.0,
                                )
                              ],
                              shape: BoxShape.circle,
                            ),
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Builder(
                              builder: (context) {
                                if (widget!.isLike) {
                                  return Icon(
                                    Icons.favorite_rounded,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 16.0,
                                  );
                                } else {
                                  return Icon(
                                    Icons.favorite_border_rounded,
                                    color: Colors.black,
                                    size: 16.0,
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ].divide(SizedBox(width: 4.0)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
