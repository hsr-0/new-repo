import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'sucessfully_page_model.dart';
export 'sucessfully_page_model.dart';

class SucessfullyPageWidget extends StatefulWidget {
  const SucessfullyPageWidget({
    super.key,
    required this.orderDetail,
  });

  final dynamic orderDetail;

  static String routeName = 'SucessfullyPage';
  static String routePath = '/sucessfullyPage';

  @override
  State<SucessfullyPageWidget> createState() => _SucessfullyPageWidgetState();
}

class _SucessfullyPageWidgetState extends State<SucessfullyPageWidget>
    with RouteAware {
  late SucessfullyPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SucessfullyPageModel());
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

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: WillPopScope(
        onWillPop: () async => true, // يسمح بالرجوع
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).lightGray,
          body: SafeArea(
            top: true,
            child: Align(
              alignment: AlignmentDirectional(0.0, 0.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/jsons/5CeJyXS8q8.json',
                    width: 194.0,
                    height: 194.0,
                    fit: BoxFit.contain,
                    animate: true,
                  ),
                  Padding(
                    padding:
                    EdgeInsetsDirectional.fromSTEB(0.0, 32.0, 0.0, 0.0),
                    child: Text(
                      FFLocalizations.of(context).getText(
                        '5xg0wce1' /* Your order has been received */,
                      ),
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'SF Pro Display',
                        fontSize: 22.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.bold,
                        useGoogleFonts: false,
                        lineHeight: 1.5,
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                    EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 12.0),
                    child: RichText(
                      textScaler: MediaQuery.of(context).textScaler,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: FFLocalizations.of(context).getText(
                              'mk0gyhl7' /* STATUS:  */,
                            ),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                              fontFamily: 'SF Pro Display',
                              fontSize: 18.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                              useGoogleFonts: false,
                            ),
                          ),
                          TextSpan(
                            text: getJsonField(
                              widget!.orderDetail,
                              r'''$.status''',
                            ).toString().toUpperCase(),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                              fontFamily: 'SF Pro Display',
                              color: () {
                                if ('pending' ==
                                    getJsonField(
                                      widget!.orderDetail,
                                      r'''$.status''',
                                    ).toString()) {
                                  return Color(0xFFD99B0C);
                                } else if ('cancelled' ==
                                    getJsonField(
                                      widget!.orderDetail,
                                      r'''$.status''',
                                    ).toString()) {
                                  return Color(0xFFFC0A15);
                                } else if ('processing' ==
                                    getJsonField(
                                      widget!.orderDetail,
                                      r'''$.status''',
                                    ).toString()) {
                                  return Color(0xFFB963BE);
                                } else if ('refunded' ==
                                    getJsonField(
                                      widget!.orderDetail,
                                      r'''$.status''',
                                    ).toString()) {
                                  return Color(0xFF696969);
                                } else if ('on-hold' ==
                                    getJsonField(
                                      widget!.orderDetail,
                                      r'''$.status''',
                                    ).toString()) {
                                  return Color(0xFF384AA7);
                                } else if ('failed' ==
                                    getJsonField(
                                      widget!.orderDetail,
                                      r'''$.status''',
                                    ).toString()) {
                                  return Color(0xFFFC0A15);
                                } else {
                                  return Color(0xFF04B155);
                                }
                              }(),
                              fontSize: 18.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                              useGoogleFonts: false,
                            ),
                          )
                        ],
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 18.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                          useGoogleFonts: false,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  RichText(
                    textScaler: MediaQuery.of(context).textScaler,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: FFLocalizations.of(context).getText(
                            'xa98cdf1' /* Order ID:  */,
                          ),
                          style:
                          FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            fontSize: 18.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            useGoogleFonts: false,
                            lineHeight: 1.5,
                          ),
                        ),
                        TextSpan(
                          text: '#${getJsonField(
                            widget!.orderDetail,
                            r'''$.id''',
                          ).toString()}',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            color: FlutterFlowTheme.of(context).primaryText,
                            fontWeight: FontWeight.w600,
                            fontSize: 18.0,
                            height: 1.5,
                          ),
                        )
                      ],
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'SF Pro Display',
                        fontSize: 18.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                        useGoogleFonts: false,
                        lineHeight: 1.5,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Padding(
                    padding:
                    EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 39.0),
                    child: Text(
                      FFLocalizations.of(context).getText(
                        'fmlou9iw' /* Thank you for shopping with us */,
                      ),
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'SF Pro Display',
                        fontSize: 17.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w500,
                        useGoogleFonts: false,
                        lineHeight: 1.5,
                      ),
                    ),
                  ),
                  FFButtonWidget(
                    onPressed: () async {
                      // 🔥 التعديل: العودة إلى شاشة الأقسام الرئيسية
                      context.go('/sections');
                    },
                    text: FFLocalizations.of(context).getText(
                      'g9f1h2j3' /* Back to Main Menu */,
                    ),
                    options: FFButtonOptions(
                      width: 200.0,
                      height: 56.0,
                      padding:
                      EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
                      iconPadding:
                      EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      color: FlutterFlowTheme.of(context).primary,
                      textStyle:
                      FlutterFlowTheme.of(context).titleSmall.override(
                        fontFamily: 'SF Pro Display',
                        color: Colors.white,
                        letterSpacing: 0.0,
                        useGoogleFonts: false,
                      ),
                      elevation: 0.0,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}