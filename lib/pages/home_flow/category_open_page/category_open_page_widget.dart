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
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'category_open_page_model.dart';
export 'category_open_page_model.dart';

class CategoryOpenPageWidget extends StatefulWidget {
  const CategoryOpenPageWidget({
    super.key,
    required this.title,
    required this.catId,
    required this.cateImage,
  });

  final String? title;
  final String? catId;
  final String? cateImage;

  static String routeName = 'CategoryOpenPage';
  static String routePath = '/categoryOpenPage';

  @override
  State<CategoryOpenPageWidget> createState() => _CategoryOpenPageWidgetState();
}

class _CategoryOpenPageWidgetState extends State<CategoryOpenPageWidget>
    with TickerProviderStateMixin, RouteAware {
  late CategoryOpenPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CategoryOpenPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.categorySelected = widget!.catId!;
      safeSetState(() {});
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
                        title: widget!.title!,
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
                              return FutureBuilder<ApiCallResponse>(
                                future: FFAppState().categoryOpenSub(
                                  uniqueQueryKey: valueOrDefault<String>(
                                    widget!.catId,
                                    'asd',
                                  ),
                                  requestFn: () =>
                                      PlantShopGroup.categoryOpenSubCall.call(
                                    categoryId: widget!.catId,
                                  ),
                                ),
                                builder: (context, snapshot) {
                                  // Customize what your widget looks like when it's loading.
                                  if (!snapshot.hasData) {
                                    return Center(
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
                                    );
                                  }
                                  final rowCategoryOpenSubResponse =
                                      snapshot.data!;
                                  _model.debugBackendQueries[
                                          'PlantShopGroup.categoryOpenSubCall_statusCode_Row_nlpqacnp'] =
                                      debugSerializeParam(
                                    rowCategoryOpenSubResponse.statusCode,
                                    ParamType.int,
                                    link:
                                        'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryOpenPage',
                                    name: 'int',
                                    nullable: false,
                                  );
                                  _model.debugBackendQueries[
                                          'PlantShopGroup.categoryOpenSubCall_responseBody_Row_nlpqacnp'] =
                                      debugSerializeParam(
                                    rowCategoryOpenSubResponse.bodyText,
                                    ParamType.String,
                                    link:
                                        'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryOpenPage',
                                    name: 'String',
                                    nullable: false,
                                  );
                                  debugLogWidgetClass(_model);

                                  return Row(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if ((PlantShopGroup.categoryOpenSubCall
                                                  .status(
                                                rowCategoryOpenSubResponse
                                                    .jsonBody,
                                              ) ==
                                              null) &&
                                          (PlantShopGroup.categoryOpenSubCall
                                                      .categoryOpenSubList(
                                                    rowCategoryOpenSubResponse
                                                        .jsonBody,
                                                  ) !=
                                                  null &&
                                              (PlantShopGroup
                                                      .categoryOpenSubCall
                                                      .categoryOpenSubList(
                                                rowCategoryOpenSubResponse
                                                    .jsonBody,
                                              ))!
                                                  .isNotEmpty))
                                        Container(
                                          width: 80.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                          ),
                                          child: ListView(
                                            padding: EdgeInsets.fromLTRB(
                                              0,
                                              0,
                                              0,
                                              12.0,
                                            ),
                                            scrollDirection: Axis.vertical,
                                            children: [
                                              Container(
                                                width: double.infinity,
                                                height: 12.0,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .lightGray,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        8.0, 0.0, 8.0, 0.0),
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
                                                    if (widget!.catId !=
                                                        _model
                                                            .categorySelected) {
                                                      _model.categorySelected =
                                                          widget!.catId!;
                                                      safeSetState(() {});
                                                      safeSetState(() => _model
                                                          .gridViewPagingController
                                                          ?.refresh());
                                                      await _model
                                                          .waitForOnePageForGridView();
                                                    }
                                                  },
                                                  child: Container(
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color: _model
                                                                  .categorySelected ==
                                                              widget!.catId
                                                          ? FlutterFlowTheme.of(
                                                                  context)
                                                              .primary
                                                          : Color(0x00000000),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4.0),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  8.0,
                                                                  10.0,
                                                                  8.0,
                                                                  10.0),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Container(
                                                            width: 48.0,
                                                            height: 48.0,
                                                            clipBehavior:
                                                                Clip.antiAlias,
                                                            decoration:
                                                                BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
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
                                                              imageUrl: widget!
                                                                  .cateImage!,
                                                              fit: BoxFit.cover,
                                                              errorWidget: (context,
                                                                      error,
                                                                      stackTrace) =>
                                                                  Image.asset(
                                                                'assets/images/error_image.png',
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            ),
                                                          ),
                                                          Text(
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                              'zl3b3m8y' /* All */,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                            maxLines: 1,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  color: _model
                                                                              .categorySelected ==
                                                                          widget!
                                                                              .catId
                                                                      ? Colors
                                                                          .white
                                                                      : FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                  fontSize:
                                                                      13.0,
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
                                                        ].divide(SizedBox(
                                                            height: 8.0)),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Builder(
                                                builder: (context) {
                                                  final categoryOpenSubList =
                                                      PlantShopGroup
                                                              .categoryOpenSubCall
                                                              .categoryOpenSubList(
                                                                rowCategoryOpenSubResponse
                                                                    .jsonBody,
                                                              )
                                                              ?.toList() ??
                                                          [];
                                                  _model.debugGeneratorVariables[
                                                          'categoryOpenSubList${categoryOpenSubList.length > 100 ? ' (first 100)' : ''}'] =
                                                      debugSerializeParam(
                                                    categoryOpenSubList
                                                        .take(100),
                                                    ParamType.JSON,
                                                    isList: true,
                                                    link:
                                                        'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryOpenPage',
                                                    name: 'dynamic',
                                                    nullable: false,
                                                  );
                                                  debugLogWidgetClass(_model);

                                                  return Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: List.generate(
                                                        categoryOpenSubList
                                                            .length,
                                                        (categoryOpenSubListIndex) {
                                                      final categoryOpenSubListItem =
                                                          categoryOpenSubList[
                                                              categoryOpenSubListIndex];
                                                      return Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    8.0,
                                                                    0.0,
                                                                    8.0,
                                                                    0.0),
                                                        child: InkWell(
                                                          splashColor: Colors
                                                              .transparent,
                                                          focusColor: Colors
                                                              .transparent,
                                                          hoverColor: Colors
                                                              .transparent,
                                                          highlightColor: Colors
                                                              .transparent,
                                                          onTap: () async {
                                                            if (_model
                                                                    .categorySelected !=
                                                                getJsonField(
                                                                  categoryOpenSubListItem,
                                                                  r'''$.id''',
                                                                ).toString()) {
                                                              _model.categorySelected =
                                                                  getJsonField(
                                                                categoryOpenSubListItem,
                                                                r'''$.id''',
                                                              ).toString();
                                                              _model.process =
                                                                  true;
                                                              safeSetState(
                                                                  () {});
                                                              _model.catOpenSub =
                                                                  await PlantShopGroup
                                                                      .categoryOpenSubCall
                                                                      .call(
                                                                categoryId:
                                                                    getJsonField(
                                                                  categoryOpenSubListItem,
                                                                  r'''$.id''',
                                                                ).toString(),
                                                              );

                                                              if ((PlantShopGroup
                                                                          .categoryOpenSubCall
                                                                          .status(
                                                                        (_model.catOpenSub?.jsonBody ??
                                                                            ''),
                                                                      ) ==
                                                                      null) &&
                                                                  (PlantShopGroup
                                                                              .categoryOpenSubCall
                                                                              .categoryOpenSubList(
                                                                            (_model.catOpenSub?.jsonBody ??
                                                                                ''),
                                                                          ) !=
                                                                          null &&
                                                                      (PlantShopGroup
                                                                              .categoryOpenSubCall
                                                                              .categoryOpenSubList(
                                                                        (_model.catOpenSub?.jsonBody ??
                                                                            ''),
                                                                      ))!
                                                                          .isNotEmpty)) {
                                                                context
                                                                    .pushNamed(
                                                                  CategoryOpenPageWidget
                                                                      .routeName,
                                                                  queryParameters:
                                                                      {
                                                                    'title':
                                                                        serializeParam(
                                                                      getJsonField(
                                                                        categoryOpenSubListItem,
                                                                        r'''$.name''',
                                                                      ).toString(),
                                                                      ParamType
                                                                          .String,
                                                                    ),
                                                                    'catId':
                                                                        serializeParam(
                                                                      getJsonField(
                                                                        categoryOpenSubListItem,
                                                                        r'''$.id''',
                                                                      ).toString(),
                                                                      ParamType
                                                                          .String,
                                                                    ),
                                                                    'cateImage':
                                                                        serializeParam(
                                                                      getJsonField(
                                                                        categoryOpenSubListItem,
                                                                        r'''$.image.src''',
                                                                      ).toString(),
                                                                      ParamType
                                                                          .String,
                                                                    ),
                                                                  }.withoutNulls,
                                                                );

                                                                _model.categorySelected =
                                                                    widget!
                                                                        .catId!;
                                                                safeSetState(
                                                                    () {});
                                                              }
                                                              _model.process =
                                                                  false;
                                                              safeSetState(
                                                                  () {});
                                                              safeSetState(() => _model
                                                                  .gridViewPagingController
                                                                  ?.refresh());
                                                              await _model
                                                                  .waitForOnePageForGridView();
                                                            }

                                                            safeSetState(() {});
                                                          },
                                                          child: Container(
                                                            width:
                                                                double.infinity,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: _model
                                                                          .categorySelected ==
                                                                      getJsonField(
                                                                        categoryOpenSubListItem,
                                                                        r'''$.id''',
                                                                      )
                                                                          .toString()
                                                                  ? FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary
                                                                  : Color(
                                                                      0x00000000),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4.0),
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          8.0,
                                                                          10.0,
                                                                          8.0,
                                                                          10.0),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Container(
                                                                    width: 48.0,
                                                                    height:
                                                                        48.0,
                                                                    clipBehavior:
                                                                        Clip.antiAlias,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                    ),
                                                                    child:
                                                                        CachedNetworkImage(
                                                                      fadeInDuration:
                                                                          Duration(
                                                                              milliseconds: 200),
                                                                      fadeOutDuration:
                                                                          Duration(
                                                                              milliseconds: 200),
                                                                      imageUrl:
                                                                          getJsonField(
                                                                        categoryOpenSubListItem,
                                                                        r'''$.image.src''',
                                                                      ).toString(),
                                                                      fit: BoxFit
                                                                          .cover,
                                                                      errorWidget: (context,
                                                                              error,
                                                                              stackTrace) =>
                                                                          Image
                                                                              .asset(
                                                                        'assets/images/error_image.png',
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    functions
                                                                        .removeHtmlEntities(
                                                                            getJsonField(
                                                                      categoryOpenSubListItem,
                                                                      r'''$.name''',
                                                                    ).toString()),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    maxLines: 2,
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .override(
                                                                          fontFamily:
                                                                              'SF Pro Display',
                                                                          color: _model.categorySelected ==
                                                                                  getJsonField(
                                                                                    categoryOpenSubListItem,
                                                                                    r'''$.id''',
                                                                                  ).toString()
                                                                              ? Colors.white
                                                                              : FlutterFlowTheme.of(context).primaryText,
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
                                                                ].divide(SizedBox(
                                                                    height:
                                                                        8.0)),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }).divide(
                                                        SizedBox(height: 12.0)),
                                                  );
                                                },
                                              ),
                                            ].divide(SizedBox(height: 12.0)),
                                          ),
                                        ),
                                      Expanded(
                                        child: Builder(
                                          builder: (context) {
                                            if (!_model.process) {
                                              return Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        6.0, 0.0, 6.0, 0.0),
                                                child: RefreshIndicator(
                                                  key: Key(
                                                      'RefreshIndicator_xxp5xzx4'),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primary,
                                                  onRefresh: () async {
                                                    safeSetState(() => _model
                                                        .gridViewPagingController
                                                        ?.refresh());
                                                    await _model
                                                        .waitForOnePageForGridView();
                                                  },
                                                  child: PagedGridView<
                                                      ApiPagingParams, dynamic>(
                                                    pagingController: _model
                                                        .setGridViewController(
                                                      (nextPageMarker) =>
                                                          PlantShopGroup
                                                              .categoryOpenCall
                                                              .call(
                                                        categoryId: _model
                                                            .categorySelected,
                                                        page: nextPageMarker
                                                                .nextPageNumber +
                                                            1,
                                                        filter: _model.filter !=
                                                                'null'
                                                            ? _model.filter
                                                            : '',
                                                      ),
                                                    ),
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                      0,
                                                      6.0,
                                                      0,
                                                      6.0,
                                                    ),
                                                    gridDelegate:
                                                        SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: () {
                                                        if (MediaQuery.sizeOf(
                                                                    context)
                                                                .width <
                                                            810.0) {
                                                          return 2;
                                                        } else if ((MediaQuery
                                                                        .sizeOf(
                                                                            context)
                                                                    .width >=
                                                                810.0) &&
                                                            (MediaQuery.sizeOf(
                                                                        context)
                                                                    .width <
                                                                1280.0)) {
                                                          return 4;
                                                        } else if (MediaQuery
                                                                    .sizeOf(
                                                                        context)
                                                                .width >=
                                                            1280.0) {
                                                          return 6;
                                                        } else {
                                                          return 8;
                                                        }
                                                      }(),
                                                      childAspectRatio: !((PlantShopGroup
                                                                      .categoryOpenSubCall
                                                                      .status(
                                                                    rowCategoryOpenSubResponse
                                                                        .jsonBody,
                                                                  ) ==
                                                                  null) &&
                                                              (PlantShopGroup
                                                                          .categoryOpenSubCall
                                                                          .categoryOpenSubList(
                                                                        rowCategoryOpenSubResponse
                                                                            .jsonBody,
                                                                      ) !=
                                                                      null &&
                                                                  (PlantShopGroup
                                                                          .categoryOpenSubCall
                                                                          .categoryOpenSubList(
                                                                    rowCategoryOpenSubResponse
                                                                        .jsonBody,
                                                                  ))!
                                                                      .isNotEmpty))
                                                          ? 0.7
                                                          : 0.6,
                                                    ),
                                                    primary: false,
                                                    scrollDirection:
                                                        Axis.vertical,
                                                    builderDelegate:
                                                        PagedChildBuilderDelegate<
                                                            dynamic>(
                                                      // Customize what your widget looks like when it's loading the first page.
                                                      firstPageProgressIndicatorBuilder:
                                                          (_) => Center(
                                                        child: SizedBox(
                                                          width: 40.0,
                                                          height: 40.0,
                                                          child:
                                                              CircularProgressIndicator(
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                    Color>(
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .primary,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      // Customize what your widget looks like when it's loading another page.
                                                      newPageProgressIndicatorBuilder:
                                                          (_) => Center(
                                                        child: SizedBox(
                                                          width: 40.0,
                                                          height: 40.0,
                                                          child:
                                                              CircularProgressIndicator(
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                    Color>(
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .primary,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      noItemsFoundIndicatorBuilder:
                                                          (_) =>
                                                              NoProductsComponentWidget(),
                                                      itemBuilder: (context, _,
                                                          categoryOpenListIndex) {
                                                        final categoryOpenListItem =
                                                            _model.gridViewPagingController!
                                                                    .itemList![
                                                                categoryOpenListIndex];
                                                        return Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  6.0),
                                                          child: wrapWithModel(
                                                            model: _model
                                                                .mainComponentModels
                                                                .getModel(
                                                              getJsonField(
                                                                categoryOpenListItem,
                                                                r'''$.id''',
                                                              ).toString(),
                                                              categoryOpenListIndex,
                                                            ),
                                                            updateCallback: () =>
                                                                safeSetState(
                                                                    () {}),
                                                            child: Builder(
                                                                builder: (_) {
                                                              return DebugFlutterFlowModelContext(
                                                                rootModel: _model
                                                                    .rootModel,
                                                                child:
                                                                    MainComponentWidget(
                                                                  key: Key(
                                                                    'Key23f_${getJsonField(
                                                                      categoryOpenListItem,
                                                                      r'''$.id''',
                                                                    ).toString()}',
                                                                  ),
                                                                  image:
                                                                      getJsonField(
                                                                    categoryOpenListItem,
                                                                    r'''$.images[0].src''',
                                                                  ).toString(),
                                                                  name:
                                                                      getJsonField(
                                                                    categoryOpenListItem,
                                                                    r'''$.name''',
                                                                  ).toString(),
                                                                  isLike: FFAppState()
                                                                      .wishList
                                                                      .contains(
                                                                          getJsonField(
                                                                        categoryOpenListItem,
                                                                        r'''$.id''',
                                                                      ).toString()),
                                                                  regularPrice:
                                                                      getJsonField(
                                                                    categoryOpenListItem,
                                                                    r'''$.regular_price''',
                                                                  ).toString(),
                                                                  price:
                                                                      getJsonField(
                                                                    categoryOpenListItem,
                                                                    r'''$.price''',
                                                                  ).toString(),
                                                                  review:
                                                                      getJsonField(
                                                                    categoryOpenListItem,
                                                                    r'''$.rating_count''',
                                                                  ).toString(),
                                                                  isBigContainer: !((PlantShopGroup
                                                                              .categoryOpenSubCall
                                                                              .status(
                                                                            rowCategoryOpenSubResponse.jsonBody,
                                                                          ) ==
                                                                          null) &&
                                                                      (PlantShopGroup.categoryOpenSubCall.categoryOpenSubList(
                                                                                rowCategoryOpenSubResponse.jsonBody,
                                                                              ) !=
                                                                              null &&
                                                                          (PlantShopGroup.categoryOpenSubCall.categoryOpenSubList(
                                                                            rowCategoryOpenSubResponse.jsonBody,
                                                                          ))!
                                                                              .isNotEmpty)),
                                                                  height: 250.0,
                                                                  width: () {
                                                                    if (MediaQuery.sizeOf(context)
                                                                            .width <
                                                                        810.0) {
                                                                      return ((MediaQuery.sizeOf(context).width -
                                                                              116) *
                                                                          1 /
                                                                          2);
                                                                    } else if ((MediaQuery.sizeOf(context).width >=
                                                                            810.0) &&
                                                                        (MediaQuery.sizeOf(context).width <
                                                                            1280.0)) {
                                                                      return ((MediaQuery.sizeOf(context).width -
                                                                              140) *
                                                                          1 /
                                                                          4);
                                                                    } else if (MediaQuery.sizeOf(context)
                                                                            .width >=
                                                                        1280.0) {
                                                                      return ((MediaQuery.sizeOf(context).width -
                                                                              164) *
                                                                          1 /
                                                                          6);
                                                                    } else {
                                                                      return ((MediaQuery.sizeOf(context).width -
                                                                              188) *
                                                                          1 /
                                                                          8);
                                                                    }
                                                                  }(),
                                                                  onSale:
                                                                      getJsonField(
                                                                    categoryOpenListItem,
                                                                    r'''$.on_sale''',
                                                                  ),
                                                                  showImage:
                                                                      true,
                                                                  isLikeTap:
                                                                      () async {
                                                                    if (FFAppState()
                                                                        .isLogin) {
                                                                      await action_blocks
                                                                          .addorRemoveFavourite(
                                                                        context,
                                                                        id: getJsonField(
                                                                          categoryOpenListItem,
                                                                          r'''$.id''',
                                                                        ).toString(),
                                                                      );
                                                                      safeSetState(
                                                                          () {});
                                                                    } else {
                                                                      ScaffoldMessenger.of(
                                                                              context)
                                                                          .hideCurrentSnackBar();
                                                                      ScaffoldMessenger.of(
                                                                              context)
                                                                          .showSnackBar(
                                                                        SnackBar(
                                                                          content:
                                                                              Text(
                                                                            FFLocalizations.of(context).getVariableText(
                                                                              enText: 'Please log in first',
                                                                              arText: 'الرجاء تسجيل الدخول أولاً',
                                                                            ),
                                                                            style:
                                                                                TextStyle(
                                                                              fontFamily: 'SF Pro Display',
                                                                              color: FlutterFlowTheme.of(context).primaryText,
                                                                            ),
                                                                          ),
                                                                          duration:
                                                                              Duration(milliseconds: 2000),
                                                                          backgroundColor:
                                                                              FlutterFlowTheme.of(context).secondary,
                                                                          action:
                                                                              SnackBarAction(
                                                                            label:
                                                                                FFLocalizations.of(context).getVariableText(
                                                                              enText: 'Login',
                                                                              arText: 'تسجيل الدخول',
                                                                            ),
                                                                            textColor:
                                                                                FlutterFlowTheme.of(context).primary,
                                                                            onPressed:
                                                                                () async {
                                                                              context.pushNamed(SignInPageWidget.routeName);
                                                                            },
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }
                                                                  },
                                                                  isMainTap:
                                                                      () async {
                                                                    context
                                                                        .pushNamed(
                                                                      ProductDetailPageWidget
                                                                          .routeName,
                                                                      queryParameters:
                                                                          {
                                                                        'productDetail':
                                                                            serializeParam(
                                                                          categoryOpenListItem,
                                                                          ParamType
                                                                              .JSON,
                                                                        ),
                                                                        'upsellIdsList':
                                                                            serializeParam(
                                                                          (getJsonField(
                                                                            categoryOpenListItem,
                                                                            r'''$.upsell_ids''',
                                                                            true,
                                                                          ) as List)
                                                                              .map<String>((s) => s.toString())
                                                                              .toList(),
                                                                          ParamType
                                                                              .String,
                                                                          isList:
                                                                              true,
                                                                        ),
                                                                        'relatedIdsList':
                                                                            serializeParam(
                                                                          (getJsonField(
                                                                            categoryOpenListItem,
                                                                            r'''$.related_ids''',
                                                                            true,
                                                                          ) as List)
                                                                              .map<String>((s) => s.toString())
                                                                              .toList(),
                                                                          ParamType
                                                                              .String,
                                                                          isList:
                                                                              true,
                                                                        ),
                                                                        'imagesList':
                                                                            serializeParam(
                                                                          getJsonField(
                                                                            categoryOpenListItem,
                                                                            r'''$.images''',
                                                                            true,
                                                                          ),
                                                                          ParamType
                                                                              .JSON,
                                                                          isList:
                                                                              true,
                                                                        ),
                                                                      }.withoutNulls,
                                                                    );
                                                                  },
                                                                ),
                                                              );
                                                            }),
                                                          ).animateOnPageLoad(
                                                              animationsMap[
                                                                  'mainComponentOnPageLoadAnimation']!),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              );
                                            } else {
                                              return Align(
                                                alignment: AlignmentDirectional(
                                                    0.0, 0.0),
                                                child: Container(
                                                  width: 40.0,
                                                  height: 40.0,
                                                  child: custom_widgets
                                                      .CirculatIndicator(
                                                    width: 40.0,
                                                    height: 40.0,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
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
