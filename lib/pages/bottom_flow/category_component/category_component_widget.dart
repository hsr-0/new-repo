import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/categories_single_component/categories_single_component_widget.dart';
import '/pages/components/category_appbar/category_appbar_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/empty_components/no_products_component/no_products_component_widget.dart';
import '/pages/shimmer/category_component_shimmer/category_component_shimmer_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/index.dart';
import 'dart:async';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'category_component_model.dart';
export 'category_component_model.dart';

class CategoryComponentWidget extends StatefulWidget {
  const CategoryComponentWidget({super.key});

  @override
  State<CategoryComponentWidget> createState() =>
      _CategoryComponentWidgetState();
}

class _CategoryComponentWidgetState extends State<CategoryComponentWidget>
    with TickerProviderStateMixin, RouteAware {
  late CategoryComponentModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CategoryComponentModel());

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await action_blocks.responseAction(context);
      safeSetState(() {});
      _model.search = false;
      safeSetState(() {});
    });

    _model.textController ??= TextEditingController()
      ..addListener(() {
        debugLogWidgetClass(_model);
      });
    _model.textFieldFocusNode ??= FocusNode();

    animationsMap.addAll({
      'categoriesSingleComponentOnPageLoadAnimation': AnimationInfo(
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

    _model.maybeDispose();

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

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).lightGray,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (context) {
              if (!_model.search) {
                return wrapWithModel(
                  model: _model.categoryAppbarModel,
                  updateCallback: () => safeSetState(() {}),
                  child: Builder(builder: (_) {
                    return DebugFlutterFlowModelContext(
                      rootModel: _model.rootModel,
                      child: CategoryAppbarWidget(
                        title: FFLocalizations.of(context).getText(
                          'sxygd232' /* Categories */,
                        ),
                        isBack: false,
                        searchAction: () async {
                          _model.search = true;
                          safeSetState(() {});
                        },
                      ),
                    );
                  }),
                );
              } else {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                  ),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(12.0, 8.0, 12.0, 8.0),
                    child: Container(
                      width: double.infinity,
                      height: 56.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).lightGray,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 0.0, 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(0.0),
                              child: SvgPicture.asset(
                                'assets/images/search.svg',
                                width: 24.0,
                                height: 24.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                child: TextFormField(
                                  controller: _model.textController,
                                  focusNode: _model.textFieldFocusNode,
                                  onChanged: (_) => EasyDebounce.debounce(
                                    '_model.textController',
                                    Duration(milliseconds: 100),
                                    () async {
                                      if (_model.textController.text != null &&
                                          _model.textController.text != '') {
                                        _model.search = true;
                                        safeSetState(() {});
                                      } else {
                                        _model.search = false;
                                        safeSetState(() {});
                                        safeSetState(() {
                                          FFAppState().clearCategoriesCache();
                                          _model.apiRequestCompleted = false;
                                        });
                                        await _model
                                            .waitForApiRequestCompleted();
                                      }
                                    },
                                  ),
                                  onFieldSubmitted: (_) async {
                                    _model.search = false;
                                    safeSetState(() {});
                                    safeSetState(() {
                                      FFAppState().clearCategoriesCache();
                                      _model.apiRequestCompleted = false;
                                    });
                                    await _model.waitForApiRequestCompleted();
                                  },
                                  autofocus: false,
                                  textInputAction: TextInputAction.search,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText:
                                        FFLocalizations.of(context).getText(
                                      'knst3phz' /* Search */,
                                    ),
                                    hintStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          fontFamily: 'SF Pro Display',
                                          fontSize: 16.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          useGoogleFonts: false,
                                        ),
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    contentPadding:
                                        EdgeInsetsDirectional.fromSTEB(
                                            12.0, 16.5, 20.0, 16.5),
                                    suffixIcon: _model
                                            .textController!.text.isNotEmpty
                                        ? InkWell(
                                            onTap: () async {
                                              _model.textController?.clear();
                                              if (_model.textController.text !=
                                                      null &&
                                                  _model.textController.text !=
                                                      '') {
                                                _model.search = true;
                                                safeSetState(() {});
                                              } else {
                                                _model.search = false;
                                                safeSetState(() {});
                                                safeSetState(() {
                                                  FFAppState()
                                                      .clearCategoriesCache();
                                                  _model.apiRequestCompleted =
                                                      false;
                                                });
                                                await _model
                                                    .waitForApiRequestCompleted();
                                              }

                                              safeSetState(() {});
                                            },
                                            child: Icon(
                                              Icons.clear,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              size: 24.0,
                                            ),
                                          )
                                        : null,
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
                                      FlutterFlowTheme.of(context).primaryText,
                                  validator: _model.textControllerValidator
                                      .asValidator(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (FFAppState().connected) {
                  return Builder(
                    builder: (context) {
                      if (FFAppState().response) {
                        return FutureBuilder<ApiCallResponse>(
                          future: FFAppState()
                              .categories(
                            requestFn: () => PlantShopGroup.categoriesCall.call(
                              search: _model.textController.text,
                            ),
                          )
                              .then((result) {
                            _model.apiRequestCompleted = true;
                            return result;
                          }),
                          builder: (context, snapshot) {
                            // Customize what your widget looks like when it's loading.
                            if (!snapshot.hasData) {
                              return CategoryComponentShimmerWidget();
                            }
                            final containerCategoriesResponse = snapshot.data!;
                            _model.debugBackendQueries[
                                    'PlantShopGroup.categoriesCall_statusCode_Container_kkg2mrsk'] =
                                debugSerializeParam(
                              containerCategoriesResponse.statusCode,
                              ParamType.int,
                              link:
                                  'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryComponent',
                              name: 'int',
                              nullable: false,
                            );
                            _model.debugBackendQueries[
                                    'PlantShopGroup.categoriesCall_responseBody_Container_kkg2mrsk'] =
                                debugSerializeParam(
                              containerCategoriesResponse.bodyText,
                              ParamType.String,
                              link:
                                  'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryComponent',
                              name: 'String',
                              nullable: false,
                            );
                            debugLogWidgetClass(_model);

                            return Container(
                              width: double.infinity,
                              decoration: BoxDecoration(),
                              child: Builder(
                                builder: (context) {
                                  if (!_model.search) {
                                    return Builder(
                                      builder: (context) {
                                        if ((PlantShopGroup.categoriesCall
                                                    .status(
                                                  containerCategoriesResponse
                                                      .jsonBody,
                                                ) ==
                                                null) &&
                                            (PlantShopGroup.categoriesCall
                                                        .categoriesList(
                                                      containerCategoriesResponse
                                                          .jsonBody,
                                                    ) !=
                                                    null &&
                                                (PlantShopGroup.categoriesCall
                                                        .categoriesList(
                                                  containerCategoriesResponse
                                                      .jsonBody,
                                                ))!
                                                    .isNotEmpty)) {
                                          return RefreshIndicator(
                                            key: Key(
                                                'RefreshIndicator_7san0a1s'),
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            onRefresh: () async {
                                              safeSetState(() {
                                                FFAppState()
                                                    .clearCategoriesCache();
                                                _model.apiRequestCompleted =
                                                    false;
                                              });
                                              await _model
                                                  .waitForApiRequestCompleted();
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
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryBackground,
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                                12.0,
                                                                16.0,
                                                                12.0,
                                                                16.0),
                                                    child: Builder(
                                                      builder: (context) {
                                                        final categoryList =
                                                            PlantShopGroup
                                                                    .categoriesCall
                                                                    .categoriesList(
                                                                      containerCategoriesResponse
                                                                          .jsonBody,
                                                                    )
                                                                    ?.toList() ??
                                                                [];
                                                        _model.debugGeneratorVariables[
                                                                'categoryList${categoryList.length > 100 ? ' (first 100)' : ''}'] =
                                                            debugSerializeParam(
                                                          categoryList
                                                              .take(100),
                                                          ParamType.JSON,
                                                          isList: true,
                                                          link:
                                                              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryComponent',
                                                          name: 'dynamic',
                                                          nullable: false,
                                                        );
                                                        debugLogWidgetClass(
                                                            _model);

                                                        return Wrap(
                                                          spacing: 12.0,
                                                          runSpacing: 12.0,
                                                          alignment:
                                                              WrapAlignment
                                                                  .start,
                                                          crossAxisAlignment:
                                                              WrapCrossAlignment
                                                                  .start,
                                                          direction:
                                                              Axis.horizontal,
                                                          runAlignment:
                                                              WrapAlignment
                                                                  .start,
                                                          verticalDirection:
                                                              VerticalDirection
                                                                  .down,
                                                          clipBehavior:
                                                              Clip.none,
                                                          children: List.generate(
                                                              categoryList
                                                                  .length,
                                                              (categoryListIndex) {
                                                            final categoryListItem =
                                                                categoryList[
                                                                    categoryListIndex];
                                                            return wrapWithModel(
                                                              model: _model
                                                                  .categoriesSingleComponentModels
                                                                  .getModel(
                                                                getJsonField(
                                                                  categoryListItem,
                                                                  r'''$.id''',
                                                                ).toString(),
                                                                categoryListIndex,
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
                                                                      CategoriesSingleComponentWidget(
                                                                    key: Key(
                                                                      'Key2ok_${getJsonField(
                                                                        categoryListItem,
                                                                        r'''$.id''',
                                                                      ).toString()}',
                                                                    ),
                                                                    image:
                                                                        getJsonField(
                                                                      categoryListItem,
                                                                      r'''$.image.src''',
                                                                    ).toString(),
                                                                    name:
                                                                        getJsonField(
                                                                      categoryListItem,
                                                                      r'''$.name''',
                                                                    ).toString(),
                                                                    width: () {
                                                                      if (MediaQuery.sizeOf(context)
                                                                              .width <
                                                                          810.0) {
                                                                        return ((MediaQuery.sizeOf(context).width -
                                                                                48) *
                                                                            1 /
                                                                            3);
                                                                      } else if ((MediaQuery.sizeOf(context).width >=
                                                                              810.0) &&
                                                                          (MediaQuery.sizeOf(context).width <
                                                                              1280.0)) {
                                                                        return ((MediaQuery.sizeOf(context).width -
                                                                                96) *
                                                                            1 /
                                                                            7);
                                                                      } else if (MediaQuery.sizeOf(context)
                                                                              .width >=
                                                                          1280.0) {
                                                                        return ((MediaQuery.sizeOf(context).width -
                                                                                120) *
                                                                            1 /
                                                                            9);
                                                                      } else {
                                                                        return ((MediaQuery.sizeOf(context).width -
                                                                                156) *
                                                                            1 /
                                                                            12);
                                                                      }
                                                                    }(),
                                                                    showImage: ('' !=
                                                                            getJsonField(
                                                                              categoryListItem,
                                                                              r'''$.image.src''',
                                                                            ).toString()) &&
                                                                        (getJsonField(
                                                                              categoryListItem,
                                                                              r'''$.image.src''',
                                                                            ) !=
                                                                            null) &&
                                                                        (getJsonField(
                                                                              categoryListItem,
                                                                              r'''$.image''',
                                                                            ) !=
                                                                            null),
                                                                    isMainTap:
                                                                        () async {
                                                                      context
                                                                          .pushNamed(
                                                                        CategoryOpenPageWidget
                                                                            .routeName,
                                                                        queryParameters:
                                                                            {
                                                                          'title':
                                                                              serializeParam(
                                                                            getJsonField(
                                                                              categoryListItem,
                                                                              r'''$.name''',
                                                                            ).toString(),
                                                                            ParamType.String,
                                                                          ),
                                                                          'catId':
                                                                              serializeParam(
                                                                            getJsonField(
                                                                              categoryListItem,
                                                                              r'''$.id''',
                                                                            ).toString(),
                                                                            ParamType.String,
                                                                          ),
                                                                          'cateImage':
                                                                              serializeParam(
                                                                            getJsonField(
                                                                              categoryListItem,
                                                                              r'''$.image.src''',
                                                                            ).toString(),
                                                                            ParamType.String,
                                                                          ),
                                                                        }.withoutNulls,
                                                                      );
                                                                    },
                                                                  ),
                                                                );
                                                              }),
                                                            ).animateOnPageLoad(
                                                                animationsMap[
                                                                    'categoriesSingleComponentOnPageLoadAnimation']!);
                                                          }),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        } else {
                                          return wrapWithModel(
                                            model:
                                                _model.noProductsComponentModel,
                                            updateCallback: () =>
                                                safeSetState(() {}),
                                            child: Builder(builder: (_) {
                                              return DebugFlutterFlowModelContext(
                                                rootModel: _model.rootModel,
                                                child:
                                                    NoProductsComponentWidget(),
                                              );
                                            }),
                                          );
                                        }
                                      },
                                    );
                                  } else {
                                    return Align(
                                      alignment:
                                          AlignmentDirectional(0.0, -1.0),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            60.0, 40.0, 60.0, 0.0),
                                        child: FFButtonWidget(
                                          onPressed: () async {
                                            _model.search = false;
                                            safeSetState(() {});
                                            safeSetState(() {
                                              FFAppState()
                                                  .clearCategoriesCache();
                                              _model.apiRequestCompleted =
                                                  false;
                                            });
                                            await _model
                                                .waitForApiRequestCompleted();
                                          },
                                          text: FFLocalizations.of(context)
                                              .getText(
                                            'rggadksb' /* Search */,
                                          ),
                                          icon: Icon(
                                            Icons.search_sharp,
                                            color: Colors.white,
                                            size: 24.0,
                                          ),
                                          options: FFButtonOptions(
                                            width: double.infinity,
                                            height: 56.0,
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    24.0, 0.0, 24.0, 0.0),
                                            iconPadding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 0.0, 0.0, 0.0),
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            textStyle: FlutterFlowTheme.of(
                                                    context)
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
                                            borderSide: BorderSide(
                                              color: Colors.transparent,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
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
    );
  }
}
