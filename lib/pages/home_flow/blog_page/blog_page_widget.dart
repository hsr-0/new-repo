import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/shimmer/blog_vert_shimmer/blog_vert_shimmer_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'blog_page_model.dart';
export 'blog_page_model.dart';

class BlogPageWidget extends StatefulWidget {
  const BlogPageWidget({super.key});

  static String routeName = 'BlogPage';
  static String routePath = '/blogPage';

  @override
  State<BlogPageWidget> createState() => _BlogPageWidgetState();
}

class _BlogPageWidgetState extends State<BlogPageWidget>
    with TickerProviderStateMixin, RouteAware {
  late BlogPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BlogPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await action_blocks.responseAction(context);
      safeSetState(() {});
    });

    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: null,
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
                          'qibzwzaz' /* Blog */,
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
                              return RefreshIndicator(
                                key: Key('RefreshIndicator_xiocf1ef'),
                                color: FlutterFlowTheme.of(context).primary,
                                onRefresh: () async {
                                  safeSetState(() {
                                    FFAppState().clearBlogCache();
                                    _model.apiRequestCompleted = false;
                                  });
                                  await _model.waitForApiRequestCompleted();
                                },
                                child: ListView(
                                  padding: EdgeInsets.fromLTRB(
                                    0,
                                    12.0,
                                    0,
                                    12.0,
                                  ),
                                  scrollDirection: Axis.vertical,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 0.0, 12.0, 0.0),
                                      child: FutureBuilder<ApiCallResponse>(
                                        future: FFAppState()
                                            .blog(
                                          requestFn: () =>
                                              PlantShopGroup.blogCall.call(),
                                        )
                                            .then((result) {
                                          _model.apiRequestCompleted = true;
                                          return result;
                                        }),
                                        builder: (context, snapshot) {
                                          // Customize what your widget looks like when it's loading.
                                          if (!snapshot.hasData) {
                                            return BlogVertShimmerWidget();
                                          }
                                          final wrapBlogResponse =
                                              snapshot.data!;
                                          _model.debugBackendQueries[
                                                  'PlantShopGroup.blogCall_statusCode_ListView_7ysv12lf'] =
                                              debugSerializeParam(
                                            wrapBlogResponse.statusCode,
                                            ParamType.int,
                                            link:
                                                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=BlogPage',
                                            name: 'int',
                                            nullable: false,
                                          );
                                          _model.debugBackendQueries[
                                                  'PlantShopGroup.blogCall_responseBody_ListView_7ysv12lf'] =
                                              debugSerializeParam(
                                            wrapBlogResponse.bodyText,
                                            ParamType.String,
                                            link:
                                                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=BlogPage',
                                            name: 'String',
                                            nullable: false,
                                          );
                                          debugLogWidgetClass(_model);

                                          return Builder(
                                            builder: (context) {
                                              final blogList =
                                                  PlantShopGroup.blogCall
                                                          .blogList(
                                                            wrapBlogResponse
                                                                .jsonBody,
                                                          )
                                                          ?.toList() ??
                                                      [];
                                              _model.debugGeneratorVariables[
                                                      'blogList${blogList.length > 100 ? ' (first 100)' : ''}'] =
                                                  debugSerializeParam(
                                                blogList.take(100),
                                                ParamType.JSON,
                                                isList: true,
                                                link:
                                                    'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=BlogPage',
                                                name: 'dynamic',
                                                nullable: false,
                                              );
                                              debugLogWidgetClass(_model);

                                              return Wrap(
                                                spacing: 12.0,
                                                runSpacing: 12.0,
                                                alignment: WrapAlignment.start,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.start,
                                                direction: Axis.horizontal,
                                                runAlignment:
                                                    WrapAlignment.start,
                                                verticalDirection:
                                                    VerticalDirection.down,
                                                clipBehavior: Clip.none,
                                                children: List.generate(
                                                    blogList.length,
                                                    (blogListIndex) {
                                                  final blogListItem =
                                                      blogList[blogListIndex];
                                                  return InkWell(
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
                                                        BlogDetailPageWidget
                                                            .routeName,
                                                        queryParameters: {
                                                          'title':
                                                              serializeParam(
                                                            getJsonField(
                                                              blogListItem,
                                                              r'''$.title.rendered''',
                                                            ).toString(),
                                                            ParamType.String,
                                                          ),
                                                          'date':
                                                              serializeParam(
                                                            getJsonField(
                                                              blogListItem,
                                                              r'''$.date''',
                                                            ).toString(),
                                                            ParamType.String,
                                                          ),
                                                          'detail':
                                                              serializeParam(
                                                            getJsonField(
                                                              blogListItem,
                                                              r'''$.content.rendered''',
                                                            ).toString(),
                                                            ParamType.String,
                                                          ),
                                                          'shareUrl':
                                                              serializeParam(
                                                            getJsonField(
                                                              blogListItem,
                                                              r'''$.link''',
                                                            ).toString(),
                                                            ParamType.String,
                                                          ),
                                                        }.withoutNulls,
                                                      );
                                                    },
                                                    child: Container(
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
                                                                    .sizeOf(
                                                                        context)
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
                                                      height: ('' !=
                                                                  getJsonField(
                                                                    blogListItem,
                                                                    r'''$._embedded['wp:featuredmedia'][0]['source_url']''',
                                                                  ).toString()) &&
                                                              (getJsonField(
                                                                    blogListItem,
                                                                    r'''$._embedded['wp:featuredmedia'][0]['source_url']''',
                                                                  ) !=
                                                                  null) &&
                                                              (getJsonField(
                                                                    blogListItem,
                                                                    r'''$._embedded['wp:featuredmedia']''',
                                                                  ) !=
                                                                  null) &&
                                                              (getJsonField(
                                                                    blogListItem,
                                                                    r'''$._embedded''',
                                                                  ) !=
                                                                  null)
                                                          ? 245.0
                                                          : 120.0,
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .primaryBackground,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12.0),
                                                        border: Border.all(
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .black20,
                                                        ),
                                                      ),
                                                      child: Padding(
                                                        padding: EdgeInsets.all(
                                                            12.0),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            if (('' !=
                                                                    getJsonField(
                                                                      blogListItem,
                                                                      r'''$._embedded['wp:featuredmedia'][0]['source_url']''',
                                                                    ).toString()) &&
                                                                (getJsonField(
                                                                      blogListItem,
                                                                      r'''$._embedded['wp:featuredmedia'][0]['source_url']''',
                                                                    ) !=
                                                                    null) &&
                                                                (getJsonField(
                                                                      blogListItem,
                                                                      r'''$._embedded['wp:featuredmedia']''',
                                                                    ) !=
                                                                    null) &&
                                                                (getJsonField(
                                                                      blogListItem,
                                                                      r'''$._embedded''',
                                                                    ) !=
                                                                    null))
                                                              Expanded(
                                                                child: Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          8.0),
                                                                  child:
                                                                      ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            12.0),
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
                                                                        blogListItem,
                                                                        r'''$._embedded['wp:featuredmedia'][0]['source_url']''',
                                                                      ).toString(),
                                                                      width: double
                                                                          .infinity,
                                                                      height: double
                                                                          .infinity,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                      errorWidget: (context,
                                                                              error,
                                                                              stackTrace) =>
                                                                          Image
                                                                              .asset(
                                                                        'assets/images/error_image.png',
                                                                        width: double
                                                                            .infinity,
                                                                        height:
                                                                            double.infinity,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  getJsonField(
                                                                    blogListItem,
                                                                    r'''$.title.rendered''',
                                                                  ).toString(),
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
                                                                            15.0,
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
                                                                Text(
                                                                  (String
                                                                      var1) {
                                                                    return var1
                                                                        .replaceAll(
                                                                            RegExp(r'<[^>]*>'),
                                                                            '');
                                                                  }(getJsonField(
                                                                    blogListItem,
                                                                    r'''$.excerpt.rendered''',
                                                                  ).toString()),
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
                                                                Text(
                                                                  functions
                                                                      .formatBlogDateTime(
                                                                          getJsonField(
                                                                    blogListItem,
                                                                    r'''$.date''',
                                                                  ).toString()),
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
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryText,
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
                                                                  height: 4.0)),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ).animateOnPageLoad(
                                                    animationsMap[
                                                        'containerOnPageLoadAnimation']!,
                                                    effects: [
                                                      FadeEffect(
                                                        curve: Curves.easeInOut,
                                                        delay: valueOrDefault<
                                                            double>(
                                                          blogListIndex + 50,
                                                          0.0,
                                                        ).ms,
                                                        duration: 600.0.ms,
                                                        begin: 0.0,
                                                        end: 1.0,
                                                      ),
                                                    ],
                                                  );
                                                }),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
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
