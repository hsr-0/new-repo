import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_component/main_component_widget.dart';
import '/pages/components/main_search_filter_appbar/main_search_filter_appbar_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/dialog_components/sort_by_bottom_sheet/sort_by_bottom_sheet_widget.dart';
import '/pages/empty_components/no_products_component/no_products_component_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/index.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'sale_products_page_model.dart';
export 'sale_products_page_model.dart';

class SaleProductsPageWidget extends StatefulWidget {
  const SaleProductsPageWidget({super.key});

  static String routeName = 'SaleProductsPage';
  static String routePath = '/saleProductsPage';

  @override
  State<SaleProductsPageWidget> createState() => _SaleProductsPageWidgetState();
}

class _SaleProductsPageWidgetState extends State<SaleProductsPageWidget>
    with TickerProviderStateMixin, RouteAware {
  late SaleProductsPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SaleProductsPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await action_blocks.responseAction(context);
      safeSetState(() {});
    });

    animationsMap.addAll({
      'mainComponentOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 120.0.ms,
            duration: 600.0.ms,
            begin: 0.15,
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
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).lightGray,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                wrapWithModel(
                  model: _model.mainSearchFilterAppbarModel,
                  updateCallback: () => safeSetState(() {}),
                  child: Builder(builder: (_) {
                    return DebugFlutterFlowModelContext(
                      rootModel: _model.rootModel,
                      child: MainSearchFilterAppbarWidget(
                        title: FFLocalizations.of(context).getText(
                          '5ytdhpdc' /* Sale products */,
                        ),
                        isBack: false,
                        backAction: () async {},
                        searchAction: () async {
                          context.pushNamed(SearchPageWidget.routeName);
                        },
                        filterAction: () async {
                          await showModalBottomSheet(
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            context: context,
                            builder: (context) {
                              return GestureDetector(
                                onTap: () {
                                  FocusScope.of(context).unfocus();
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                                child: Padding(
                                  padding: MediaQuery.viewInsetsOf(context),
                                  child: SortByBottomSheetWidget(
                                    newAddedAction: () async {
                                      _model.filter = 'orderby=date&order=desc';
                                      safeSetState(() {});
                                      Navigator.pop(context);
                                      safeSetState(() => _model
                                          .gridViewPagingController
                                          ?.refresh());
                                      await _model.waitForOnePageForGridView();
                                      _model.filter = 'null';
                                      safeSetState(() {});
                                    },
                                    popularityAction: () async {
                                      _model.filter =
                                          'orderby=popularity&order=desc';
                                      safeSetState(() {});
                                      Navigator.pop(context);
                                      safeSetState(() => _model
                                          .gridViewPagingController
                                          ?.refresh());
                                      await _model.waitForOnePageForGridView();
                                      _model.filter = 'null';
                                      safeSetState(() {});
                                    },
                                    ratingAction: () async {
                                      _model.filter =
                                          'orderby=rating&order=desc';
                                      safeSetState(() {});
                                      Navigator.pop(context);
                                      safeSetState(() => _model
                                          .gridViewPagingController
                                          ?.refresh());
                                      await _model.waitForOnePageForGridView();
                                      _model.filter = 'null';
                                      safeSetState(() {});
                                    },
                                    lowestPriceAction: () async {
                                      _model.filter = 'orderby=price&order=asc';
                                      safeSetState(() {});
                                      Navigator.pop(context);
                                      safeSetState(() => _model
                                          .gridViewPagingController
                                          ?.refresh());
                                      await _model.waitForOnePageForGridView();
                                      _model.filter = 'null';
                                      safeSetState(() {});
                                    },
                                    highestPriceAction: () async {
                                      _model.filter =
                                          'orderby=price&order=desc';
                                      safeSetState(() {});
                                      Navigator.pop(context);
                                      safeSetState(() => _model
                                          .gridViewPagingController
                                          ?.refresh());
                                      await _model.waitForOnePageForGridView();
                                      _model.filter = 'null';
                                      safeSetState(() {});
                                    },
                                  ),
                                ),
                              );
                            },
                          ).then((value) => safeSetState(() {}));
                        },
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
                              return Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    6.0, 0.0, 6.0, 0.0),
                                child: RefreshIndicator(
                                  key: Key('RefreshIndicator_g7aph8e5'),
                                  color: FlutterFlowTheme.of(context).primary,
                                  onRefresh: () async {
                                    safeSetState(() => _model
                                        .gridViewPagingController
                                        ?.refresh());
                                    await _model.waitForOnePageForGridView();
                                  },
                                  child:
                                      PagedGridView<ApiPagingParams, dynamic>(
                                    pagingController:
                                        _model.setGridViewController(
                                      (nextPageMarker) =>
                                          PlantShopGroup.sellProductsCall.call(
                                        page: nextPageMarker.nextPageNumber + 1,
                                        filter: _model.filter != 'null'
                                            ? _model.filter
                                            : '',
                                      ),
                                    ),
                                    padding: EdgeInsets.fromLTRB(
                                      0,
                                      6.0,
                                      0,
                                      6.0,
                                    ),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: () {
                                        if (MediaQuery.sizeOf(context).width <
                                            810.0) {
                                          return 2;
                                        } else if ((MediaQuery.sizeOf(context)
                                                    .width >=
                                                810.0) &&
                                            (MediaQuery.sizeOf(context).width <
                                                1280.0)) {
                                          return 4;
                                        } else if (MediaQuery.sizeOf(context)
                                                .width >=
                                            1280.0) {
                                          return 6;
                                        } else {
                                          return 8;
                                        }
                                      }(),
                                      childAspectRatio: 0.7,
                                    ),
                                    primary: false,
                                    scrollDirection: Axis.vertical,
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
                                          NoProductsComponentWidget(),
                                      itemBuilder:
                                          (context, _, saleProductsListIndex) {
                                        final saleProductsListItem = _model
                                            .gridViewPagingController!
                                            .itemList![saleProductsListIndex];
                                        return Padding(
                                          padding: EdgeInsets.all(6.0),
                                          child: wrapWithModel(
                                            model: _model.mainComponentModels
                                                .getModel(
                                              getJsonField(
                                                saleProductsListItem,
                                                r'''$.id''',
                                              ).toString(),
                                              saleProductsListIndex,
                                            ),
                                            updateCallback: () =>
                                                safeSetState(() {}),
                                            child: Builder(builder: (_) {
                                              return DebugFlutterFlowModelContext(
                                                rootModel: _model.rootModel,
                                                child: MainComponentWidget(
                                                  key: Key(
                                                    'Keylca_${getJsonField(
                                                      saleProductsListItem,
                                                      r'''$.id''',
                                                    ).toString()}',
                                                  ),
                                                  image: getJsonField(
                                                    saleProductsListItem,
                                                    r'''$.images[0].src''',
                                                  ).toString(),
                                                  name: getJsonField(
                                                    saleProductsListItem,
                                                    r'''$.name''',
                                                  ).toString(),
                                                  isLike: FFAppState()
                                                      .wishList
                                                      .contains(getJsonField(
                                                        saleProductsListItem,
                                                        r'''$.id''',
                                                      ).toString()),
                                                  regularPrice: getJsonField(
                                                    saleProductsListItem,
                                                    r'''$.regular_price''',
                                                  ).toString(),
                                                  price: getJsonField(
                                                    saleProductsListItem,
                                                    r'''$.price''',
                                                  ).toString(),
                                                  review: getJsonField(
                                                    saleProductsListItem,
                                                    r'''$.rating_count''',
                                                  ).toString(),
                                                  isBigContainer: true,
                                                  height: 298.0,
                                                  width: () {
                                                    if (MediaQuery.sizeOf(
                                                                context)
                                                            .width <
                                                        810.0) {
                                                      return ((MediaQuery.sizeOf(
                                                                      context)
                                                                  .width -
                                                              36) *
                                                          1 /
                                                          2);
                                                    } else if ((MediaQuery
                                                                    .sizeOf(
                                                                        context)
                                                                .width >=
                                                            810.0) &&
                                                        (MediaQuery.sizeOf(
                                                                    context)
                                                                .width <
                                                            1280.0)) {
                                                      return ((MediaQuery.sizeOf(
                                                                      context)
                                                                  .width -
                                                              60) *
                                                          1 /
                                                          4);
                                                    } else if (MediaQuery
                                                                .sizeOf(context)
                                                            .width >=
                                                        1280.0) {
                                                      return ((MediaQuery.sizeOf(
                                                                      context)
                                                                  .width -
                                                              84) *
                                                          1 /
                                                          6);
                                                    } else {
                                                      return ((MediaQuery.sizeOf(
                                                                      context)
                                                                  .width -
                                                              108) *
                                                          1 /
                                                          8);
                                                    }
                                                  }(),
                                                  onSale: getJsonField(
                                                    saleProductsListItem,
                                                    r'''$.on_sale''',
                                                  ),
                                                  showImage: true,
                                                  isLikeTap: () async {
                                                    if (FFAppState().isLogin) {
                                                      await action_blocks
                                                          .addorRemoveFavourite(
                                                        context,
                                                        id: getJsonField(
                                                          saleProductsListItem,
                                                          r'''$.id''',
                                                        ).toString(),
                                                      );
                                                      safeSetState(() {});
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .hideCurrentSnackBar();
                                                      ScaffoldMessenger.of(
                                                              context)
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
                                                              milliseconds:
                                                                  2000),
                                                          backgroundColor:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .secondary,
                                                          action:
                                                              SnackBarAction(
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
                                                            onPressed:
                                                                () async {
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
                                                          saleProductsListItem,
                                                          ParamType.JSON,
                                                        ),
                                                        'upsellIdsList':
                                                            serializeParam(
                                                          (getJsonField(
                                                            saleProductsListItem,
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
                                                            saleProductsListItem,
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
                                                          getJsonField(
                                                            saleProductsListItem,
                                                            r'''$.images''',
                                                            true,
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
                                          ).animateOnPageLoad(animationsMap[
                                              'mainComponentOnPageLoadAnimation']!),
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
