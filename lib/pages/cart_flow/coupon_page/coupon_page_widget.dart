import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/empty_components/no_coupon_component/no_coupon_component_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/random_data_util.dart' as random_data;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'coupon_page_model.dart';
export 'coupon_page_model.dart';

class CouponPageWidget extends StatefulWidget {
  const CouponPageWidget({
    super.key,
    required this.nonce,
  });

  final String? nonce;

  static String routeName = 'CouponPage';
  static String routePath = '/couponPage';

  @override
  State<CouponPageWidget> createState() => _CouponPageWidgetState();
}

class _CouponPageWidgetState extends State<CouponPageWidget>
    with TickerProviderStateMixin, RouteAware {
  late CouponPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CouponPageModel());

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
          _model.coupons = await PlantShopGroup.couponCodeCall.call();
        }),
      ]);
      _model.process = false;
      safeSetState(() {});
    });

    _model.textController ??= TextEditingController()
      ..addListener(() {
        debugLogWidgetClass(_model);
      });
    _model.textFieldFocusNode ??= FocusNode();

    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ShimmerEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            color: FlutterFlowTheme.of(context).black20,
            angle: 0.524,
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
                      title: FFLocalizations.of(context).getText(
                        'hrtaedlx' /* My Coupon */,
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
                            return ListView(
                              padding: EdgeInsets.fromLTRB(
                                0,
                                12.0,
                                0,
                                12.0,
                              ),
                              shrinkWrap: true,
                              scrollDirection: Axis.vertical,
                              children: [
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      12.0, 0.0, 12.0, 0.0),
                                  child: Text(
                                    FFLocalizations.of(context).getText(
                                      '51k041fu' /* Have a coupon Code */,
                                    ),
                                    textAlign: TextAlign.start,
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
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      12.0, 8.0, 12.0, 0.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _model.textController,
                                          focusNode: _model.textFieldFocusNode,
                                          autofocus: false,
                                          textInputAction: TextInputAction.done,
                                          obscureText: false,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            labelStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      fontFamily:
                                                          'SF Pro Display',
                                                      fontSize: 16.0,
                                                      letterSpacing: 0.0,
                                                      useGoogleFonts: false,
                                                    ),
                                            hintText:
                                                FFLocalizations.of(context)
                                                    .getText(
                                              'yecfghwv' /* Enter coupon code */,
                                            ),
                                            hintStyle: FlutterFlowTheme.of(
                                                    context)
                                                .labelMedium
                                                .override(
                                                  fontFamily: 'SF Pro Display',
                                                  fontSize: 16.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.normal,
                                                  useGoogleFonts: false,
                                                ),
                                            errorStyle: FlutterFlowTheme.of(
                                                    context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'SF Pro Display',
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  fontSize: 14.0,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts: false,
                                                ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 0.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 0.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16.0),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 0.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16.0),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0x00000000),
                                                width: 0.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16.0),
                                            ),
                                            filled: true,
                                            fillColor:
                                                FlutterFlowTheme.of(context)
                                                    .lightGray,
                                            contentPadding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 20.0, 16.0, 20.0),
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
                                              FlutterFlowTheme.of(context)
                                                  .primaryText,
                                          validator: _model
                                              .textControllerValidator
                                              .asValidator(context),
                                        ),
                                      ),
                                      FFButtonWidget(
                                        onPressed: () async {
                                          _model.apply = await PlantShopGroup
                                              .applyCouponCodeCall
                                              .call(
                                            code: _model.textController.text,
                                            nonce: widget!.nonce,
                                            token: FFAppState().token,
                                          );

                                          if (PlantShopGroup.applyCouponCodeCall
                                                  .status(
                                                (_model.apply?.jsonBody ?? ''),
                                              ) ==
                                              null) {
                                            FFAppState().clearCartCache();
                                            safeSetState(() {
                                              _model.textController?.clear();
                                            });
                                            await actions.showCustomToastTop(
                                              FFLocalizations.of(context)
                                                  .getVariableText(
                                                enText:
                                                    'Coupon code applied successfully.',
                                                arText:
                                                    'تم تطبيق رمز القسيمة بنجاح.',
                                              ),
                                            );
                                            context.safePop();
                                          } else {
                                            await actions.showCustomToastTop(
                                              PlantShopGroup.applyCouponCodeCall
                                                  .message(
                                                (_model.apply?.jsonBody ?? ''),
                                              )!,
                                            );
                                          }

                                          safeSetState(() {});
                                        },
                                        text:
                                            FFLocalizations.of(context).getText(
                                          '63i60tuh' /* Apply */,
                                        ),
                                        options: FFButtonOptions(
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
                                                    fontWeight: FontWeight.bold,
                                                    useGoogleFonts: false,
                                                  ),
                                          elevation: 0.0,
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                      ),
                                    ].divide(SizedBox(width: 8.0)),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      12.0, 20.0, 12.0, 0.0),
                                  child: Text(
                                    FFLocalizations.of(context).getText(
                                      'wh1nj53v' /* Promo Code */,
                                    ),
                                    textAlign: TextAlign.start,
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
                                Builder(
                                  builder: (context) {
                                    if (!_model.process) {
                                      return Builder(
                                        builder: (context) {
                                          final couponsList = PlantShopGroup
                                                  .couponCodeCall
                                                  .couponsList(
                                                    (_model.coupons?.jsonBody ??
                                                        ''),
                                                  )
                                                  ?.where((e) =>
                                                      functions.checkExpire(
                                                          getJsonField(
                                                        e,
                                                        r'''$.date_expires''',
                                                      ).toString()) ==
                                                      false)
                                                  .toList()
                                                  ?.toList() ??
                                              [];
                                          if (couponsList.isEmpty) {
                                            return Container(
                                              width: MediaQuery.sizeOf(context)
                                                      .width *
                                                  1.0,
                                              height: MediaQuery.sizeOf(context)
                                                      .height *
                                                  0.6,
                                              child: NoCouponComponentWidget(),
                                            );
                                          }
                                          _model.debugGeneratorVariables[
                                                  'couponsList${couponsList.length > 100 ? ' (first 100)' : ''}'] =
                                              debugSerializeParam(
                                            couponsList.take(100),
                                            ParamType.JSON,
                                            isList: true,
                                            link:
                                                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CouponPage',
                                            name: 'dynamic',
                                            nullable: false,
                                          );
                                          debugLogWidgetClass(_model);

                                          return Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: List.generate(
                                                    couponsList.length,
                                                    (couponsListIndex) {
                                              final couponsListItem =
                                                  couponsList[couponsListIndex];
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
                                                    await Clipboard.setData(
                                                        ClipboardData(
                                                            text: getJsonField(
                                                      couponsListItem,
                                                      r'''$.code''',
                                                    ).toString()));
                                                    safeSetState(() {
                                                      _model.textController
                                                          ?.text = getJsonField(
                                                        couponsListItem,
                                                        r'''$.code''',
                                                      ).toString();
                                                      _model.textFieldFocusNode
                                                          ?.requestFocus();
                                                      WidgetsBinding.instance
                                                          .addPostFrameCallback(
                                                              (_) {
                                                        _model.textController
                                                                ?.selection =
                                                            TextSelection
                                                                .collapsed(
                                                          offset: _model
                                                              .textController!
                                                              .text
                                                              .length,
                                                        );
                                                      });
                                                    });
                                                  },
                                                  child: Container(
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .lightGray,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12.0),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(20.0),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              getJsonField(
                                                                couponsListItem,
                                                                r'''$.code''',
                                                              ).toString(),
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
                                                                        15.0,
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
                                                          ),
                                                          SvgPicture.asset(
                                                            'assets/images/Copy.svg',
                                                            width: 27.0,
                                                            height: 24.0,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            })
                                                .divide(SizedBox(height: 8.0))
                                                .addToStart(
                                                    SizedBox(height: 8.0))
                                                .addToEnd(
                                                    SizedBox(height: 8.0)),
                                          );
                                        },
                                      );
                                    } else {
                                      return Builder(
                                        builder: (context) {
                                          final list = List.generate(
                                              random_data.randomInteger(4, 4),
                                              (index) => random_data.randomName(
                                                  true, false)).toList();
                                          _model.debugGeneratorVariables[
                                                  'list${list.length > 100 ? ' (first 100)' : ''}'] =
                                              debugSerializeParam(
                                            list.take(100),
                                            ParamType.String,
                                            isList: true,
                                            link:
                                                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CouponPage',
                                            name: 'String',
                                            nullable: false,
                                          );
                                          debugLogWidgetClass(_model);

                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: List.generate(list.length,
                                                    (listIndex) {
                                              final listItem = list[listIndex];
                                              return Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        12.0, 0.0, 12.0, 0.0),
                                                child: Container(
                                                  width: double.infinity,
                                                  height: 64.0,
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .black10,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12.0),
                                                  ),
                                                ).animateOnPageLoad(animationsMap[
                                                    'containerOnPageLoadAnimation']!),
                                              );
                                            })
                                                .divide(SizedBox(height: 8.0))
                                                .addToStart(
                                                    SizedBox(height: 8.0))
                                                .addToEnd(
                                                    SizedBox(height: 8.0)),
                                          );
                                        },
                                      );
                                    }
                                  },
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
      ),
    );
  }
}
