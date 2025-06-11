import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/empty_components/no_address_component/no_address_component_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'my_address_page_model.dart';
export 'my_address_page_model.dart';

class MyAddressPageWidget extends StatefulWidget {
  const MyAddressPageWidget({super.key});

  static String routeName = 'MyAddressPage';
  static String routePath = '/myAddressPage';

  @override
  State<MyAddressPageWidget> createState() => _MyAddressPageWidgetState();
}

class _MyAddressPageWidgetState extends State<MyAddressPageWidget>
    with RouteAware {
  late MyAddressPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MyAddressPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await action_blocks.responseAction(context);
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
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).lightGray,
            ),
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
                          'qdz0wtt9' /* My Address */,
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
                              return Container(
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).lightGray,
                                ),
                                child: Builder(
                                  builder: (context) {
                                    if (('' !=
                                            getJsonField(
                                              FFAppState().userDetail,
                                              r'''$.billing.first_name''',
                                            ).toString()) &&
                                        ('' !=
                                            getJsonField(
                                              FFAppState().userDetail,
                                              r'''$.billing.last_name''',
                                            ).toString()) &&
                                        ('' !=
                                            getJsonField(
                                              FFAppState().userDetail,
                                              r'''$.billing.address_1''',
                                            ).toString()) &&
                                        ('' !=
                                            getJsonField(
                                              FFAppState().userDetail,
                                              r'''$.billing.city''',
                                            ).toString()) &&
                                        ('' !=
                                            getJsonField(
                                              FFAppState().userDetail,
                                              r'''$.billing.postcode''',
                                            ).toString()) &&
                                        ('' !=
                                            getJsonField(
                                              FFAppState().userDetail,
                                              r'''$.billing.country''',
                                            ).toString()) &&
                                        ('' !=
                                            getJsonField(
                                              FFAppState().userDetail,
                                              r'''$.billing.phone''',
                                            ).toString())) {
                                      return ListView(
                                        padding: EdgeInsets.fromLTRB(
                                          0,
                                          12.0,
                                          0,
                                          12.0,
                                        ),
                                        scrollDirection: Axis.vertical,
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryBackground,
                                            ),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      12.0, 7.0, 7.0, 12.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 34.0,
                                                    height: 34.0,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    alignment:
                                                        AlignmentDirectional(
                                                            0.0, 0.0),
                                                    child: Icon(
                                                      Icons.location_on_rounded,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      size: 20.0,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  16.0,
                                                                  0.0,
                                                                  3.0,
                                                                  0.0),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
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
                                                                child: Text(
                                                                  FFLocalizations.of(
                                                                          context)
                                                                      .getText(
                                                                    '89wgw45e' /* Billing address */,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .start,
                                                                  maxLines: 1,
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        fontFamily:
                                                                            'SF Pro Display',
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
                                                              ),
                                                              Text(
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                                  'wu93zfc7' /* Default */,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .end,
                                                                maxLines: 1,
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .success,
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
                                                            ],
                                                          ),
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        6.0,
                                                                        0.0,
                                                                        4.0),
                                                            child: Text(
                                                              '${getJsonField(
                                                                FFAppState()
                                                                    .userDetail,
                                                                r'''$.billing.address_1''',
                                                              ).toString()}, ${'' != getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.billing.address_2''',
                                                                  ).toString() ? getJsonField(
                                                                  FFAppState()
                                                                      .userDetail,
                                                                  r'''$.billing.address_2''',
                                                                ).toString() : ''}${'' != getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.billing.address_2''',
                                                                  ).toString() ? ', ' : ''}${getJsonField(
                                                                FFAppState()
                                                                    .userDetail,
                                                                r'''$.billing.city''',
                                                              ).toString()}, ${getJsonField(
                                                                FFAppState()
                                                                    .userDetail,
                                                                r'''$.billing.postcode''',
                                                              ).toString()}, ${'' != getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.billing.state''',
                                                                  ).toString() ? getJsonField(
                                                                  functions
                                                                      .jsonToListConverter(
                                                                          getJsonField(
                                                                        FFAppState()
                                                                            .allCountrysList
                                                                            .where((e) =>
                                                                                getJsonField(
                                                                                  FFAppState().userDetail,
                                                                                  r'''$.billing.country''',
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
                                                                            FFAppState().userDetail,
                                                                            r'''$.billing.state''',
                                                                          ) ==
                                                                          getJsonField(
                                                                            e,
                                                                            r'''$.code''',
                                                                          ))
                                                                      .toList()
                                                                      .firstOrNull,
                                                                  r'''$.name''',
                                                                ).toString() : ''}${'' != getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.billing.state''',
                                                                  ).toString() ? ', ' : ''}${getJsonField(
                                                                FFAppState()
                                                                    .allCountrysList
                                                                    .where((e) =>
                                                                        getJsonField(
                                                                          FFAppState()
                                                                              .userDetail,
                                                                          r'''$.billing.country''',
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
                                                              maxLines: 2,
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    fontSize:
                                                                        16.0,
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
                                                          ),
                                                          Text(
                                                            getJsonField(
                                                              FFAppState()
                                                                  .userDetail,
                                                              r'''$.billing.phone''',
                                                            ).toString(),
                                                            textAlign:
                                                                TextAlign.start,
                                                            maxLines: 1,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  fontSize:
                                                                      16.0,
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
                                                      context.pushNamed(
                                                        AddAddressPageWidget
                                                            .routeName,
                                                        queryParameters: {
                                                          'isEdit':
                                                              serializeParam(
                                                            true,
                                                            ParamType.bool,
                                                          ),
                                                          'isShipping':
                                                              serializeParam(
                                                            false,
                                                            ParamType.bool,
                                                          ),
                                                          'address':
                                                              serializeParam(
                                                            getJsonField(
                                                              FFAppState()
                                                                  .userDetail,
                                                              r'''$.billing''',
                                                            ),
                                                            ParamType.JSON,
                                                          ),
                                                        }.withoutNulls,
                                                      );
                                                    },
                                                    child: Container(
                                                      decoration:
                                                          BoxDecoration(),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.all(5.0),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      0.0),
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
                                            ),
                                          ),
                                          Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryBackground,
                                            ),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      12.0, 7.0, 7.0, 12.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 34.0,
                                                    height: 34.0,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    alignment:
                                                        AlignmentDirectional(
                                                            0.0, 0.0),
                                                    child: Icon(
                                                      Icons.location_on_rounded,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      size: 20.0,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  16.0,
                                                                  0.0,
                                                                  3.0,
                                                                  0.0),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
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
                                                                child: Text(
                                                                  FFLocalizations.of(
                                                                          context)
                                                                      .getText(
                                                                    'ty2d5a18' /* Shipping address */,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .start,
                                                                  maxLines: 1,
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        fontFamily:
                                                                            'SF Pro Display',
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
                                                              ),
                                                            ],
                                                          ),
                                                          if (!(('' !=
                                                                  getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.shipping.first_name''',
                                                                  ).toString()) &&
                                                              ('' !=
                                                                  getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.shipping.last_name''',
                                                                  ).toString()) &&
                                                              ('' !=
                                                                  getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.shipping.address_1''',
                                                                  ).toString()) &&
                                                              ('' !=
                                                                  getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.shipping.city''',
                                                                  ).toString()) &&
                                                              ('' !=
                                                                  getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.shipping.postcode''',
                                                                  ).toString()) &&
                                                              ('' !=
                                                                  getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.shipping.country''',
                                                                  ).toString()) &&
                                                              ('' !=
                                                                  getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.shipping.phone''',
                                                                  ).toString())))
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
                                                                      true,
                                                                      ParamType
                                                                          .bool,
                                                                    ),
                                                                    'address':
                                                                        serializeParam(
                                                                      getJsonField(
                                                                        FFAppState()
                                                                            .userDetail,
                                                                        r'''$.shipping''',
                                                                      ),
                                                                      ParamType
                                                                          .JSON,
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
                                                                          0.0,
                                                                          6.0,
                                                                          0.0,
                                                                          4.0),
                                                                  child: Text(
                                                                    FFLocalizations.of(
                                                                            context)
                                                                        .getText(
                                                                      '3r8rvd96' /* Add shipping address */,
                                                                    ),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .start,
                                                                    maxLines: 2,
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
                                                              ),
                                                            ),
                                                          if (('' !=
                                                                  getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.shipping.first_name''',
                                                                  ).toString()) &&
                                                              ('' !=
                                                                  getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.shipping.last_name''',
                                                                  ).toString()) &&
                                                              ('' !=
                                                                  getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.shipping.address_1''',
                                                                  ).toString()) &&
                                                              ('' !=
                                                                  getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.shipping.city''',
                                                                  ).toString()) &&
                                                              ('' !=
                                                                  getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.shipping.postcode''',
                                                                  ).toString()) &&
                                                              ('' !=
                                                                  getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.shipping.country''',
                                                                  ).toString()) &&
                                                              ('' !=
                                                                  getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.shipping.phone''',
                                                                  ).toString()))
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          6.0,
                                                                          0.0,
                                                                          4.0),
                                                              child: Text(
                                                                '${getJsonField(
                                                                  FFAppState()
                                                                      .userDetail,
                                                                  r'''$.shipping.address_1''',
                                                                ).toString()}, ${'' != getJsonField(
                                                                      FFAppState()
                                                                          .userDetail,
                                                                      r'''$.shipping.address_2''',
                                                                    ).toString() ? getJsonField(
                                                                    FFAppState()
                                                                        .userDetail,
                                                                    r'''$.shipping.address_2''',
                                                                  ).toString() : ''}${'' != getJsonField(
                                                                      FFAppState()
                                                                          .userDetail,
                                                                      r'''$.shipping.address_2''',
                                                                    ).toString() ? ', ' : ''}${getJsonField(
                                                                  FFAppState()
                                                                      .userDetail,
                                                                  r'''$.shipping.city''',
                                                                ).toString()}, ${getJsonField(
                                                                  FFAppState()
                                                                      .userDetail,
                                                                  r'''$.shipping.postcode''',
                                                                ).toString()}, ${'' != getJsonField(
                                                                      FFAppState()
                                                                          .userDetail,
                                                                      r'''$.shipping.state''',
                                                                    ).toString() ? getJsonField(
                                                                    functions
                                                                        .jsonToListConverter(
                                                                            getJsonField(
                                                                          FFAppState()
                                                                              .allCountrysList
                                                                              .where((e) =>
                                                                                  getJsonField(
                                                                                    FFAppState().userDetail,
                                                                                    r'''$.shipping.country''',
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
                                                                              FFAppState().userDetail,
                                                                              r'''$.shipping.state''',
                                                                            ) ==
                                                                            getJsonField(
                                                                              e,
                                                                              r'''$.code''',
                                                                            ))
                                                                        .toList()
                                                                        .firstOrNull,
                                                                    r'''$.name''',
                                                                  ).toString() : ''}${'' != getJsonField(
                                                                      FFAppState()
                                                                          .userDetail,
                                                                      r'''$.shipping.state''',
                                                                    ).toString() ? ', ' : ''}${getJsonField(
                                                                  FFAppState()
                                                                      .allCountrysList
                                                                      .where((e) =>
                                                                          getJsonField(
                                                                            FFAppState().userDetail,
                                                                            r'''$.shipping.country''',
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
                                                                maxLines: 2,
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
                                                                          FontWeight
                                                                              .normal,
                                                                      useGoogleFonts:
                                                                          false,
                                                                      lineHeight:
                                                                          1.5,
                                                                    ),
                                                              ),
                                                            ),
                                                          if ('' !=
                                                              getJsonField(
                                                                FFAppState()
                                                                    .userDetail,
                                                                r'''$.shipping.phone''',
                                                              ).toString())
                                                            Text(
                                                              getJsonField(
                                                                FFAppState()
                                                                    .userDetail,
                                                                r'''$.shipping.phone''',
                                                              ).toString(),
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                              maxLines: 1,
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    fontSize:
                                                                        16.0,
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
                                                      context.pushNamed(
                                                        AddAddressPageWidget
                                                            .routeName,
                                                        queryParameters: {
                                                          'isEdit':
                                                              serializeParam(
                                                            true,
                                                            ParamType.bool,
                                                          ),
                                                          'isShipping':
                                                              serializeParam(
                                                            true,
                                                            ParamType.bool,
                                                          ),
                                                          'address':
                                                              serializeParam(
                                                            getJsonField(
                                                              FFAppState()
                                                                  .userDetail,
                                                              r'''$.shipping''',
                                                            ),
                                                            ParamType.JSON,
                                                          ),
                                                        }.withoutNulls,
                                                      );
                                                    },
                                                    child: Container(
                                                      decoration:
                                                          BoxDecoration(),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.all(5.0),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      0.0),
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
                                            ),
                                          ),
                                        ].divide(SizedBox(height: 12.0)),
                                      );
                                    } else {
                                      return wrapWithModel(
                                        model: _model.noAddressComponentModel,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: Builder(builder: (_) {
                                          return DebugFlutterFlowModelContext(
                                            rootModel: _model.rootModel,
                                            child: NoAddressComponentWidget(),
                                          );
                                        }),
                                      );
                                    }
                                  },
                                ),
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
      ),
    );
  }
}
