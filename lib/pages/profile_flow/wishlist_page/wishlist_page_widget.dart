import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/main_component/main_component_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/empty_components/no_favourite_component/no_favourite_component_widget.dart';
import '/pages/shimmer/main_component_shimmer/main_component_shimmer_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'wishlist_page_model.dart';
export 'wishlist_page_model.dart';

class WishlistPageWidget extends StatefulWidget {
  const WishlistPageWidget({super.key});

  static String routeName = 'WishlistPage';
  static String routePath = '/wishlistPage';

  @override
  State<WishlistPageWidget> createState() => _WishlistPageWidgetState();
}

class _WishlistPageWidgetState extends State<WishlistPageWidget>
    with TickerProviderStateMixin, RouteAware {
  late WishlistPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WishlistPageModel());

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
                        title: 'Wishlist',
                        isBack: false,
                        isEdit: false,
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
                              return Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    6.0, 0.0, 6.0, 0.0),
                                child: Builder(
                                  builder: (context) {
                                    final wishList =
                                        FFAppState().wishList.toList();
                                    if (wishList.isEmpty) {
                                      return NoFavouriteComponentWidget();
                                    }
                                    _model.debugGeneratorVariables[
                                            'wishList${wishList.length > 100 ? ' (first 100)' : ''}'] =
                                        debugSerializeParam(
                                      wishList.take(100),
                                      ParamType.String,
                                      isList: true,
                                      link:
                                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=WishlistPage',
                                      name: 'String',
                                      nullable: false,
                                    );
                                    debugLogWidgetClass(_model);

                                    return GridView.builder(
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
                                              (MediaQuery.sizeOf(context)
                                                      .width <
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
                                      itemCount: wishList.length,
                                      itemBuilder: (context, wishListIndex) {
                                        final wishListItem =
                                            wishList[wishListIndex];
                                        return Padding(
                                          padding: EdgeInsets.all(6.0),
                                          child: FutureBuilder<ApiCallResponse>(
                                            future: FFAppState().productDdetail(
                                              uniqueQueryKey: wishListItem,
                                              requestFn: () => PlantShopGroup
                                                  .productDetailCall
                                                  .call(
                                                productId: wishListItem,
                                              ),
                                            ),
                                            builder: (context, snapshot) {
                                              // Customize what your widget looks like when it's loading.
                                              if (!snapshot.hasData) {
                                                return MainComponentShimmerWidget(
                                                  isBig: true,
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
                                                  height: 298.0,
                                                );
                                              }
                                              final containerProductDetailResponse =
                                                  snapshot.data!;
                                              _model.debugBackendQueries[
                                                      'PlantShopGroup.productDetailCall_statusCode_Container_tfnjul4a'] =
                                                  debugSerializeParam(
                                                containerProductDetailResponse
                                                    .statusCode,
                                                ParamType.int,
                                                link:
                                                    'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=WishlistPage',
                                                name: 'int',
                                                nullable: false,
                                              );
                                              _model.debugBackendQueries[
                                                      'PlantShopGroup.productDetailCall_responseBody_Container_tfnjul4a'] =
                                                  debugSerializeParam(
                                                containerProductDetailResponse
                                                    .bodyText,
                                                ParamType.String,
                                                link:
                                                    'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=WishlistPage',
                                                name: 'String',
                                                nullable: false,
                                              );
                                              debugLogWidgetClass(_model);

                                              return Container(
                                                decoration: BoxDecoration(),
                                                child: wrapWithModel(
                                                  model: _model
                                                      .mainComponentModels
                                                      .getModel(
                                                    getJsonField(
                                                      PlantShopGroup
                                                          .productDetailCall
                                                          .productDetail(
                                                        containerProductDetailResponse
                                                            .jsonBody,
                                                      ),
                                                      r'''$.id''',
                                                    ).toString(),
                                                    wishListIndex,
                                                  ),
                                                  updateCallback: () =>
                                                      safeSetState(() {}),
                                                  child: Builder(builder: (_) {
                                                    return DebugFlutterFlowModelContext(
                                                      rootModel:
                                                          _model.rootModel,
                                                      child:
                                                          MainComponentWidget(
                                                        key: Key(
                                                          'Key8ne_${getJsonField(
                                                            PlantShopGroup
                                                                .productDetailCall
                                                                .productDetail(
                                                              containerProductDetailResponse
                                                                  .jsonBody,
                                                            ),
                                                            r'''$.id''',
                                                          ).toString()}',
                                                        ),
                                                        image: getJsonField(
                                                          PlantShopGroup
                                                              .productDetailCall
                                                              .imagesList(
                                                                containerProductDetailResponse
                                                                    .jsonBody,
                                                              )!
                                                              .firstOrNull,
                                                          r'''$.src''',
                                                        ).toString(),
                                                        name: getJsonField(
                                                          PlantShopGroup
                                                              .productDetailCall
                                                              .productDetail(
                                                            containerProductDetailResponse
                                                                .jsonBody,
                                                          ),
                                                          r'''$.name''',
                                                        ).toString(),
                                                        isLike: FFAppState()
                                                            .wishList
                                                            .contains(
                                                                getJsonField(
                                                              PlantShopGroup
                                                                  .productDetailCall
                                                                  .productDetail(
                                                                containerProductDetailResponse
                                                                    .jsonBody,
                                                              ),
                                                              r'''$.id''',
                                                            ).toString()),
                                                        regularPrice:
                                                            PlantShopGroup
                                                                .productDetailCall
                                                                .regularPrice(
                                                          containerProductDetailResponse
                                                              .jsonBody,
                                                        )!,
                                                        price: PlantShopGroup
                                                            .productDetailCall
                                                            .price(
                                                          containerProductDetailResponse
                                                              .jsonBody,
                                                        )!,
                                                        review: PlantShopGroup
                                                            .productDetailCall
                                                            .ratingCount(
                                                              containerProductDetailResponse
                                                                  .jsonBody,
                                                            )!
                                                            .toString(),
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
                                                        onSale: PlantShopGroup
                                                            .productDetailCall
                                                            .onSale(
                                                          containerProductDetailResponse
                                                              .jsonBody,
                                                        )!,
                                                        showImage: true,
                                                        isLikeTap: () async {
                                                          await action_blocks
                                                              .addorRemoveFavourite(
                                                            context,
                                                            id: getJsonField(
                                                              PlantShopGroup
                                                                  .productDetailCall
                                                                  .productDetail(
                                                                containerProductDetailResponse
                                                                    .jsonBody,
                                                              ),
                                                              r'''$.id''',
                                                            ).toString(),
                                                          );
                                                          safeSetState(() {});
                                                        },
                                                        isMainTap: () async {
                                                          context.pushNamed(
                                                            ProductDetailPageWidget
                                                                .routeName,
                                                            queryParameters: {
                                                              'productDetail':
                                                                  serializeParam(
                                                                PlantShopGroup
                                                                    .productDetailCall
                                                                    .productDetail(
                                                                  containerProductDetailResponse
                                                                      .jsonBody,
                                                                ),
                                                                ParamType.JSON,
                                                              ),
                                                              'upsellIdsList':
                                                                  serializeParam(
                                                                (getJsonField(
                                                                  PlantShopGroup
                                                                      .productDetailCall
                                                                      .productDetail(
                                                                    containerProductDetailResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  r'''$.upsell_ids''',
                                                                  true,
                                                                ) as List)
                                                                    .map<String>(
                                                                        (s) => s
                                                                            .toString())
                                                                    .toList(),
                                                                ParamType
                                                                    .String,
                                                                isList: true,
                                                              ),
                                                              'relatedIdsList':
                                                                  serializeParam(
                                                                (getJsonField(
                                                                  PlantShopGroup
                                                                      .productDetailCall
                                                                      .productDetail(
                                                                    containerProductDetailResponse
                                                                        .jsonBody,
                                                                  ),
                                                                  r'''$.related_ids''',
                                                                  true,
                                                                ) as List)
                                                                    .map<String>(
                                                                        (s) => s
                                                                            .toString())
                                                                    .toList(),
                                                                ParamType
                                                                    .String,
                                                                isList: true,
                                                              ),
                                                              'imagesList':
                                                                  serializeParam(
                                                                PlantShopGroup
                                                                    .productDetailCall
                                                                    .imagesList(
                                                                  containerProductDetailResponse
                                                                      .jsonBody,
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
                                        );
                                      },
                                    );
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
