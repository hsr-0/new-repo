import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/index.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'onboarding_page_model.dart';
export 'onboarding_page_model.dart';

class OnboardingPageWidget extends StatefulWidget {
  const OnboardingPageWidget({
    super.key,
    required this.introList,
  });

  final List<dynamic>? introList;

  static String routeName = 'OnboardingPage';
  static String routePath = '/onboardingPage';

  @override
  State<OnboardingPageWidget> createState() => _OnboardingPageWidgetState();
}

class _OnboardingPageWidgetState extends State<OnboardingPageWidget>
    with TickerProviderStateMixin, RouteAware {
  late OnboardingPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OnboardingPageModel());

    animationsMap.addAll({
      'containerOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'containerOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 400.0.ms,
            begin: Offset(0.0, -20.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation3': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 400.0.ms,
            begin: Offset(0.0, -20.0),
            end: Offset(0.0, 0.0),
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

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Stack(
          children: [
            Builder(
              builder: (context) {
                final introList = widget!.introList!.toList();
                _model.debugGeneratorVariables[
                        'introList${introList.length > 100 ? ' (first 100)' : ''}'] =
                    debugSerializeParam(
                  introList.take(100),
                  ParamType.JSON,
                  isList: true,
                  link:
                      'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=OnboardingPage',
                  name: 'dynamic',
                  nullable: false,
                );
                debugLogWidgetClass(_model);

                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: PageView.builder(
                    controller: _model.pageViewController ??= PageController(
                        initialPage: max(0, min(0, introList.length - 1)))
                      ..addListener(() {
                        debugLogWidgetClass(_model);
                      }),
                    onPageChanged: (_) async {
                      safeSetState(() {});
                    },
                    scrollDirection: Axis.horizontal,
                    itemCount: introList.length,
                    itemBuilder: (context, introListIndex) {
                      final introListItem = introList[introListIndex];
                      return Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Container(
                            height: MediaQuery.sizeOf(context).height * 0.087,
                            decoration: BoxDecoration(),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                width: MediaQuery.sizeOf(context).width * 0.062,
                                decoration: BoxDecoration(),
                              ),
                              Expanded(
                                child: Container(
                                  height:
                                      MediaQuery.sizeOf(context).height * 0.458,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16.0),
                                    child: CachedNetworkImage(
                                      fadeInDuration:
                                          Duration(milliseconds: 200),
                                      fadeOutDuration:
                                          Duration(milliseconds: 200),
                                      imageUrl: getJsonField(
                                        introListItem,
                                        r'''$.featured_image''',
                                      ).toString(),
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.contain,
                                      alignment: Alignment(0.0, 0.0),
                                      errorWidget:
                                          (context, error, stackTrace) =>
                                              Image.asset(
                                        'assets/images/error_image.png',
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.contain,
                                        alignment: Alignment(0.0, 0.0),
                                      ),
                                    ),
                                  ),
                                ).animateOnPageLoad(animationsMap[
                                    'containerOnPageLoadAnimation1']!),
                              ),
                              Container(
                                width: MediaQuery.sizeOf(context).width * 0.062,
                                decoration: BoxDecoration(),
                              ),
                            ],
                          ),
                          Container(
                            height: MediaQuery.sizeOf(context).height * 0.053,
                            decoration: BoxDecoration(),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                width: MediaQuery.sizeOf(context).width * 0.048,
                                decoration: BoxDecoration(),
                              ),
                              Expanded(
                                child: Container(
                                  height:
                                      MediaQuery.sizeOf(context).height * 0.093,
                                  decoration: BoxDecoration(),
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: AutoSizeText(
                                    getJsonField(
                                      introListItem,
                                      r'''$.title''',
                                    ).toString(),
                                    textAlign: TextAlign.center,
                                    minFontSize: 20.0,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          fontSize: 36.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                          useGoogleFonts: false,
                                          lineHeight: 1.5,
                                        ),
                                  ),
                                ).animateOnPageLoad(animationsMap[
                                    'containerOnPageLoadAnimation2']!),
                              ),
                              Container(
                                width: MediaQuery.sizeOf(context).width * 0.048,
                                decoration: BoxDecoration(),
                              ),
                            ],
                          ),
                          Container(
                            height: MediaQuery.sizeOf(context).height * 0.017,
                            decoration: BoxDecoration(),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                width: MediaQuery.sizeOf(context).width * 0.048,
                                decoration: BoxDecoration(),
                              ),
                              Expanded(
                                child: Container(
                                  height:
                                      MediaQuery.sizeOf(context).height * 0.053,
                                  decoration: BoxDecoration(),
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: AutoSizeText(
                                    getJsonField(
                                      introListItem,
                                      r'''$.description''',
                                    ).toString(),
                                    textAlign: TextAlign.center,
                                    minFontSize: 12.0,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          fontSize: 36.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          useGoogleFonts: false,
                                          lineHeight: 1.5,
                                        ),
                                  ),
                                ).animateOnPageLoad(animationsMap[
                                    'containerOnPageLoadAnimation3']!),
                              ),
                              Container(
                                width: MediaQuery.sizeOf(context).width * 0.048,
                                decoration: BoxDecoration(),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
            Align(
              alignment: AlignmentDirectional(0.0, 1.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(
                    builder: (context) {
                      final list = widget!.introList!.toList();
                      _model.debugGeneratorVariables[
                              'list${list.length > 100 ? ' (first 100)' : ''}'] =
                          debugSerializeParam(
                        list.take(100),
                        ParamType.JSON,
                        isList: true,
                        link:
                            'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=OnboardingPage',
                        name: 'dynamic',
                        nullable: false,
                      );
                      debugLogWidgetClass(_model);

                      return Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(list.length, (listIndex) {
                          final listItem = list[listIndex];
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            decoration: BoxDecoration(
                              color: _model.pageViewCurrentIndex == listIndex
                                  ? FlutterFlowTheme.of(context).primary
                                  : FlutterFlowTheme.of(context).black20,
                              shape: BoxShape.circle,
                            ),
                          );
                        }).divide(SizedBox(width: 8.0)),
                      );
                    },
                  ),
                  Container(
                    height: MediaQuery.sizeOf(context).height * 0.026,
                    decoration: BoxDecoration(),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        width: MediaQuery.sizeOf(context).width * 0.048,
                        decoration: BoxDecoration(),
                      ),
                      Expanded(
                        child: FFButtonWidget(
                          onPressed: () async {
                            if (_model.pageViewCurrentIndex !=
                                (widget!.introList!.length - 1)) {
                              await _model.pageViewController?.nextPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.ease,
                              );
                            } else {
                              FFAppState().isIntro = true;
                              FFAppState().update(() {});

                              context.goNamed(
                                SignInPageWidget.routeName,
                                queryParameters: {
                                  'isInner': serializeParam(
                                    false,
                                    ParamType.bool,
                                  ),
                                }.withoutNulls,
                              );
                            }
                          },
                          text: _model.pageViewCurrentIndex !=
                                  (widget!.introList!.length - 1)
                              ? FFLocalizations.of(context).getVariableText(
                                  enText: 'التالي',
                                  arText: 'التالي',
                                )
                              : FFLocalizations.of(context).getVariableText(
                                  enText: 'ابدا',
                                  arText: 'ابدأ',
                                ),
                          options: FFButtonOptions(
                            width: 200.0,
                            height: MediaQuery.sizeOf(context).height * 0.062,
                            padding: EdgeInsetsDirectional.fromSTEB(
                                20.0, 0.0, 20.0, 0.0),
                            iconPadding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            color: FlutterFlowTheme.of(context).primary,
                            textStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .override(
                                  fontFamily: 'SF Pro Display',
                                  color: Colors.white,
                                  fontSize: 18.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  useGoogleFonts: false,
                                ),
                            elevation: 0.0,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          showLoadingIndicator: false,
                        ),
                      ),
                      Container(
                        width: MediaQuery.sizeOf(context).width * 0.048,
                        decoration: BoxDecoration(),
                      ),
                    ],
                  ),
                  Container(
                    height: MediaQuery.sizeOf(context).height * 0.017,
                    decoration: BoxDecoration(),
                  ),
                  Container(
                    height: MediaQuery.sizeOf(context).height * 0.026,
                    decoration: BoxDecoration(),
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Opacity(
                      opacity: _model.pageViewCurrentIndex !=
                              (widget!.introList!.length - 1)
                          ? 1.0
                          : 0.0,
                      child: InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          if (_model.pageViewCurrentIndex !=
                              (widget!.introList!.length - 1)) {
                            FFAppState().isIntro = true;
                            safeSetState(() {});

                            context.goNamed(
                              SignInPageWidget.routeName,
                              queryParameters: {
                                'isInner': serializeParam(
                                  false,
                                  ParamType.bool,
                                ),
                              }.withoutNulls,
                            );
                          }
                        },
                        child: AutoSizeText(
                          FFLocalizations.of(context).getText(
                            'j0ngg6c9' /* Skip */,
                          ),
                          textAlign: TextAlign.center,
                          minFontSize: 14.0,
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: 'SF Pro Display',
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                fontSize: 36.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.normal,
                                useGoogleFonts: false,
                                lineHeight: 1.5,
                              ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: MediaQuery.sizeOf(context).height * 0.066,
                    decoration: BoxDecoration(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
