import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/empty_components/no_order_component/no_order_component_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'my_orders_page_model.dart';
export 'my_orders_page_model.dart';

class MyOrdersPageWidget extends StatefulWidget {
  const MyOrdersPageWidget({super.key});

  static String routeName = 'MyOrdersPage';
  static String routePath = '/myOrdersPage';

  @override
  State<MyOrdersPageWidget> createState() => _MyOrdersPageWidgetState();
}

class _MyOrdersPageWidgetState extends State<MyOrdersPageWidget>
    with RouteAware {
  late MyOrdersPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MyOrdersPageModel());

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
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).lightGray,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                wrapWithModel(
                  model: _model.mainAppbarModel,
                  updateCallback: () => safeSetState(() {}),
                  child: Builder(builder: (_) {
                    return DebugFlutterFlowModelContext(
                      rootModel: _model.rootModel,
                      child: MainAppbarWidget(
                        title: FFLocalizations.of(context).getText(
                          'khyl2n96' /* My Orders */,
                        ),
                        isBack: true,
                        isEdit: false,
                        isShare: false,
                        backAction: () async {
                          context.goNamed(HomeMainPageWidget.routeName);
                        },
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
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(),
                                child: RefreshIndicator(
                                  key: Key('RefreshIndicator_zqxxu441'),
                                  color: FlutterFlowTheme.of(context).primary,
                                  onRefresh: () async {
                                    safeSetState(() => _model
                                        .listViewPagingController
                                        ?.refresh());
                                    await _model.waitForOnePageForListView();
                                    FFAppState().clearOrderDetailCache();
                                  },
                                  child: PagedListView<ApiPagingParams,
                                      dynamic>.separated(
                                    pagingController:
                                        _model.setListViewController(
                                      (nextPageMarker) =>
                                          PlantShopGroup.getOrdersCall.call(
                                        customer: getJsonField(
                                          FFAppState().userDetail,
                                          r'''$.id''',
                                        ).toString(),
                                        perPage: 10,
                                        page: nextPageMarker.nextPageNumber + 1,
                                      ),
                                    ),
                                    padding: EdgeInsets.fromLTRB(
                                      0,
                                      12.0,
                                      0,
                                      12.0,
                                    ),
                                    reverse: false,
                                    scrollDirection: Axis.vertical,
                                    separatorBuilder: (_, __) =>
                                        SizedBox(height: 12.0),
                                    builderDelegate:
                                        PagedChildBuilderDelegate<dynamic>(
                                      // Customize what your widget looks like when it's loading the first page.
                                      firstPageProgressIndicatorBuilder: (_) =>
                                          Center(
                                        child: SizedBox(
                                          width: 40.0,
                                          height: 40.0,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              FlutterFlowTheme.of(context)
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Customize what your widget looks like when it's loading another page.
                                      newPageProgressIndicatorBuilder: (_) =>
                                          Center(
                                        child: SizedBox(
                                          width: 40.0,
                                          height: 40.0,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              FlutterFlowTheme.of(context)
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      noItemsFoundIndicatorBuilder: (_) =>
                                          Center(
                                        child: Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          child: NoOrderComponentWidget(),
                                        ),
                                      ),
                                      itemBuilder:
                                          (context, _, orderListIndex) {
                                        final orderListItem = _model
                                            .listViewPagingController!
                                            .itemList![orderListIndex];
                                        return InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
                                            context.pushNamed(
                                              OrderDetailsPageWidget.routeName,
                                              queryParameters: {
                                                'orderId': serializeParam(
                                                  getJsonField(
                                                    orderListItem,
                                                    r'''$.id''',
                                                  ),
                                                  ParamType.int,
                                                ),
                                              }.withoutNulls,
                                            );
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(12.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Expanded(
                                                        child: RichText(
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
                                                                  'jmqtoksd' /* Order ID : # */,
                                                                ),
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontSize:
                                                                      17.0,
                                                                ),
                                                              ),
                                                              TextSpan(
                                                                text:
                                                                    getJsonField(
                                                                  orderListItem,
                                                                  r'''$.id''',
                                                                ).toString(),
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontSize:
                                                                      17.0,
                                                                ),
                                                              )
                                                            ],
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  fontSize:
                                                                      17.0,
                                                                  letterSpacing:
                                                                      0.17,
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
                                                      ),
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: () {
                                                            if ('pending' ==
                                                                getJsonField(
                                                                  orderListItem,
                                                                  r'''$.status''',
                                                                ).toString()) {
                                                              return Color(
                                                                  0xFFFFF5E0);
                                                            } else if ('cancelled' ==
                                                                getJsonField(
                                                                  orderListItem,
                                                                  r'''$.status''',
                                                                ).toString()) {
                                                              return Color(
                                                                  0xFFFFF3F3);
                                                            } else if ('processing' ==
                                                                getJsonField(
                                                                  orderListItem,
                                                                  r'''$.status''',
                                                                ).toString()) {
                                                              return Color(
                                                                  0xFFF9EDF9);
                                                            } else if ('refunded' ==
                                                                getJsonField(
                                                                  orderListItem,
                                                                  r'''$.status''',
                                                                ).toString()) {
                                                              return Color(
                                                                  0xFFF5F5F5);
                                                            } else if ('on-hold' ==
                                                                getJsonField(
                                                                  orderListItem,
                                                                  r'''$.status''',
                                                                ).toString()) {
                                                              return Color(
                                                                  0xFFE5EAFB);
                                                            } else if ('failed' ==
                                                                getJsonField(
                                                                  orderListItem,
                                                                  r'''$.status''',
                                                                ).toString()) {
                                                              return Color(
                                                                  0xFFFFF3F3);
                                                            } else if ('checkout-draft' ==
                                                                getJsonField(
                                                                  orderListItem,
                                                                  r'''$.status''',
                                                                ).toString()) {
                                                              return Color(
                                                                  0xFFE8F2F1);
                                                            } else {
                                                              return Color(
                                                                  0xFFEEFCF0);
                                                            }
                                                          }(),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      37.0),
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      10.0,
                                                                      5.0,
                                                                      10.0,
                                                                      5.0),
                                                          child: Text(
                                                            functions
                                                                .capitalizeFirst(
                                                                    getJsonField(
                                                              orderListItem,
                                                              r'''$.status''',
                                                            ).toString()),
                                                            textAlign: TextAlign
                                                                .center,
                                                            maxLines: 1,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  color: () {
                                                                    if ('pending' ==
                                                                        getJsonField(
                                                                          orderListItem,
                                                                          r'''$.status''',
                                                                        ).toString()) {
                                                                      return Color(
                                                                          0xFFAD0CD9);
                                                                    } else if ('cancelled' ==
                                                                        getJsonField(
                                                                          orderListItem,
                                                                          r'''$.status''',
                                                                        ).toString()) {
                                                                      return Color(
                                                                          0xFFFC0A15);
                                                                    } else if ('processing' ==
                                                                        getJsonField(
                                                                          orderListItem,
                                                                          r'''$.status''',
                                                                        ).toString()) {
                                                                      return Color(
                                                                          0xFFB963BE);
                                                                    } else if ('refunded' ==
                                                                        getJsonField(
                                                                          orderListItem,
                                                                          r'''$.status''',
                                                                        ).toString()) {
                                                                      return Color(
                                                                          0xFF696969);
                                                                    } else if ('on-hold' ==
                                                                        getJsonField(
                                                                          orderListItem,
                                                                          r'''$.status''',
                                                                        ).toString()) {
                                                                      return Color(
                                                                          0xFF384AA7);
                                                                    } else if ('failed' ==
                                                                        getJsonField(
                                                                          orderListItem,
                                                                          r'''$.status''',
                                                                        ).toString()) {
                                                                      return Color(
                                                                          0xFFFC0A15);
                                                                    } else if ('checkout-draft' ==
                                                                        getJsonField(
                                                                          orderListItem,
                                                                          r'''$.status''',
                                                                        ).toString()) {
                                                                      return Color(
                                                                          0xFF069484);
                                                                    } else {
                                                                      return Color(
                                                                          0xFF04B155);
                                                                    }
                                                                  }(),
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
                                                                      1.2,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 4.0,
                                                                0.0, 0.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      0.0,
                                                                      0.0,
                                                                      8.0,
                                                                      0.0),
                                                          child: Container(
                                                            width: 10.0,
                                                            height: 10.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primary,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                          ),
                                                        ),
                                                        RichText(
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
                                                                  'tam1iflp' /* Order at  */,
                                                                ),
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
                                                                      useGoogleFonts:
                                                                          false,
                                                                      lineHeight:
                                                                          1.5,
                                                                    ),
                                                              ),
                                                              TextSpan(
                                                                text: functions
                                                                    .formatOrderDateTime(
                                                                        getJsonField(
                                                                  orderListItem,
                                                                  r'''$.date_created''',
                                                                ).toString()),
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
                                                                      useGoogleFonts:
                                                                          false,
                                                                      lineHeight:
                                                                          1.5,
                                                                    ),
                                                              )
                                                            ],
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  letterSpacing:
                                                                      0.0,
                                                                  useGoogleFonts:
                                                                      false,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
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
