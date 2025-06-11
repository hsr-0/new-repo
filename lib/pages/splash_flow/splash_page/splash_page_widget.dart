import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import
'/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/logo_component/logo_component_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'splash_page_model.dart';
export 'splash_page_model.dart';

class SplashPageWidget extends StatefulWidget {
  const SplashPageWidget({super.key});

  static String routeName = 'SplashPage';
  static String routePath = '/splashPage';

  @override
  State<SplashPageWidget> createState() => _SplashPageWidgetState();
}

class _SplashPageWidgetState extends State<SplashPageWidget>
    with TickerProviderStateMixin, RouteAware {
  late SplashPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SplashPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      while (true) {
        if (FFAppState().connected) {
          _model.isTokenExpired = await actions.tokenValidater(
            FFAppState().token,
          );
          if (_model.isTokenExpired!) {
            FFAppState().isLogin = false;
            safeSetState(() {});
          }
          await Future.wait([
            Future(() async {
              _model.currency = await PlantShopGroup.currentCurrencyCall.call();

              if (PlantShopGroup.currentCurrencyCall.status(
                    (_model.currency?.jsonBody ?? ''),
                  ) ==
                  null) {
                _model.currencySymbol = await actions.currencyConverter(
                  PlantShopGroup.currentCurrencyCall.symbol(
                    (_model.currency?.jsonBody ?? ''),
                  )!,
                );
                FFAppState().currency = _model.currencySymbol!;
                FFAppState().currencyCode =
                    PlantShopGroup.currentCurrencyCall.code(
                  (_model.currency?.jsonBody ?? ''),
                )!;
                FFAppState().update(() {});
              } else {
                FFAppState().currency = '\$';
                FFAppState().currencyCode = 'USD';
                FFAppState().update(() {});
              }
            }),
            Future(() async {
              _model.currencyPosition =
                  await PlantShopGroup.currencyPositionCall.call();

              if (PlantShopGroup.currencyPositionCall.status(
                    (_model.currencyPosition?.jsonBody ?? ''),
                  ) ==
                  null) {
                FFAppState().currencyPosition =
                    PlantShopGroup.currencyPositionCall.value(
                  (_model.currencyPosition?.jsonBody ?? ''),
                )!;
                FFAppState().update(() {});
              } else {
                FFAppState().currencyPosition = 'left';
                FFAppState().update(() {});
              }
            }),
            Future(() async {
              _model.thousandSeparator =
                  await PlantShopGroup.thousandSeparatorCall.call();

              if (PlantShopGroup.thousandSeparatorCall.status(
                    (_model.thousandSeparator?.jsonBody ?? ''),
                  ) ==
                  null) {
                FFAppState().thousandSeparator =
                    PlantShopGroup.thousandSeparatorCall.value(
                  (_model.thousandSeparator?.jsonBody ?? ''),
                )!;
                FFAppState().update(() {});
              } else {
                FFAppState().thousandSeparator = ',';
                FFAppState().update(() {});
              }
            }),
            Future(() async {
              _model.decimalSeparator =
                  await PlantShopGroup.decimalSeparatorCall.call();

              if (PlantShopGroup.decimalSeparatorCall.status(
                    (_model.decimalSeparator?.jsonBody ?? ''),
                  ) ==
                  null) {
                FFAppState().decimalSeparator =
                    PlantShopGroup.decimalSeparatorCall.value(
                  (_model.decimalSeparator?.jsonBody ?? ''),
                )!;
                FFAppState().update(() {});
              } else {
                FFAppState().decimalSeparator = '.';
                FFAppState().update(() {});
              }
            }),
            Future(() async {
              _model.numberofDecimals =
                  await PlantShopGroup.numberOfDecimalsCall.call();

              if (PlantShopGroup.numberOfDecimalsCall.status(
                    (_model.numberofDecimals?.jsonBody ?? ''),
                  ) ==
                  null) {
                FFAppState().decimalPlaces =
                    int.parse((PlantShopGroup.numberOfDecimalsCall.value(
                  (_model.numberofDecimals?.jsonBody ?? ''),
                )!));
                FFAppState().update(() {});
              } else {
                FFAppState().decimalPlaces = 2;
                FFAppState().update(() {});
              }
            }),
            Future(() async {
              await action_blocks.listAllCountries(context);
              safeSetState(() {});
            }),
            Future(() async {
              _model.success = await action_blocks.getCustomer(context);
            }),
            Future(() async {
              await action_blocks.responseAction(context);
              safeSetState(() {});
            }),
            Future(() async {
              await action_blocks.getPaymentGateways(context);
              safeSetState(() {});
            }),
            Future(() async {
              await action_blocks.cartItemCount(context);
              safeSetState(() {});
            }),
          ]);
          if (FFAppState().isIntro) {
            if (FFAppState().isLogin) {
              context.goNamed(HomeMainPageWidget.routeName);
            } else {
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
          } else {
            _model.allIntro = await PlantShopGroup.allIntroCall.call();

            if ((PlantShopGroup.allIntroCall.status(
                      (_model.allIntro?.jsonBody ?? ''),
                    ) ==
                    'success') &&
                (PlantShopGroup.allIntroCall.dataList(
                          (_model.allIntro?.jsonBody ?? ''),
                        ) !=
                        null &&
                    (PlantShopGroup.allIntroCall.dataList(
                      (_model.allIntro?.jsonBody ?? ''),
                    ))!
                        .isNotEmpty)) {
              context.goNamed(
                OnboardingPageWidget.routeName,
                queryParameters: {
                  'introList': serializeParam(
                    PlantShopGroup.allIntroCall.dataList(
                      (_model.allIntro?.jsonBody ?? ''),
                    ),
                    ParamType.JSON,
                    isList: true,
                  ),
                }.withoutNulls,
              );
            } else {
              if (FFAppState().isLogin) {
                context.goNamed(HomeMainPageWidget.routeName);
              } else {
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
            }
          }

          break;
        } else {
          await Future.delayed(const Duration(milliseconds: 3000));
          await action_blocks.internetTost(context);
        }
      }
    });

    animationsMap.addAll({
      'logoComponentOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 50.0.ms,
            duration: 2000.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'textOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 50.0.ms,
            duration: 2000.0.ms,
            begin: 0.0,
            end: 1.0,
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
          child: Align(
            alignment: AlignmentDirectional(0.0, 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                wrapWithModel(
                  model: _model.logoComponentModel,
                  updateCallback: () => safeSetState(() {}),
                  child: Builder(builder: (_) {
                    return DebugFlutterFlowModelContext(
                      rootModel: _model.rootModel,
                      child: LogoComponentWidget(
                        height: 132.0,
                        width: 132.0,
                      ),
                    );
                  }),
                ).animateOnPageLoad(
                    animationsMap['logoComponentOnPageLoadAnimation']!),
                Text(
                  FFLocalizations.of(context).getText(
                    '4ybbqts6' /* Natura */,
                  ),
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'SF Pro Display',
                        color: FlutterFlowTheme.of(context).primary,
                        fontSize: 28.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.bold,
                        useGoogleFonts: false,
                        lineHeight: 1.5,
                      ),
                ).animateOnPageLoad(animationsMap['textOnPageLoadAnimation']!),
              ].divide(SizedBox(height: 10.0)),
            ),
          ),
        ),
      ),
    );
  }
}
