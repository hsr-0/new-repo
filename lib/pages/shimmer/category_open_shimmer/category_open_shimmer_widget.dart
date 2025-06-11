import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/empty_components/no_products_component/no_products_component_widget.dart';
import '/pages/shimmer/main_component_shimmer/main_component_shimmer_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/flutter_flow/random_data_util.dart' as random_data;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'category_open_shimmer_model.dart';
export 'category_open_shimmer_model.dart';

class CategoryOpenShimmerWidget extends StatefulWidget {
  const CategoryOpenShimmerWidget({super.key});

  @override
  State<CategoryOpenShimmerWidget> createState() =>
      _CategoryOpenShimmerWidgetState();
}

class _CategoryOpenShimmerWidgetState extends State<CategoryOpenShimmerWidget>
    with TickerProviderStateMixin, RouteAware {
  late CategoryOpenShimmerModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CategoryOpenShimmerModel());

    animationsMap.addAll({
      'containerOnPageLoadAnimation1': AnimationInfo(
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
      'containerOnPageLoadAnimation2': AnimationInfo(
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
      'containerOnPageLoadAnimation3': AnimationInfo(
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
      'containerOnPageLoadAnimation4': AnimationInfo(
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

    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
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
                  color: FlutterFlowTheme.of(context).lightGray,
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(8.0, 10.0, 8.0, 10.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48.0,
                          height: 48.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).black10,
                            shape: BoxShape.circle,
                          ),
                        ).animateOnPageLoad(
                            animationsMap['containerOnPageLoadAnimation1']!),
                        Container(
                          width: MediaQuery.sizeOf(context).width * 0.2,
                          height: 18.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).black10,
                          ),
                        ).animateOnPageLoad(
                            animationsMap['containerOnPageLoadAnimation2']!),
                      ].divide(SizedBox(height: 8.0)),
                    ),
                  ),
                ),
              ),
              Builder(
                builder: (context) {
                  final categoryRelatedList = List.generate(
                      random_data.randomInteger(4, 4),
                      (index) => random_data.randomName(true, false)).toList();
                  _model.debugGeneratorVariables[
                          'categoryRelatedList${categoryRelatedList.length > 100 ? ' (first 100)' : ''}'] =
                      debugSerializeParam(
                    categoryRelatedList.take(100),
                    ParamType.String,
                    isList: true,
                    link:
                        'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryOpenShimmer',
                    name: 'String',
                    nullable: false,
                  );
                  debugLogWidgetClass(_model);

                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    children: List.generate(categoryRelatedList.length,
                        (categoryRelatedListIndex) {
                      final categoryRelatedListItem =
                          categoryRelatedList[categoryRelatedListIndex];
                      return Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                8.0, 10.0, 8.0, 10.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 48.0,
                                  height: 48.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context).black10,
                                    shape: BoxShape.circle,
                                  ),
                                ).animateOnPageLoad(animationsMap[
                                    'containerOnPageLoadAnimation3']!),
                                Container(
                                  width: MediaQuery.sizeOf(context).width * 0.2,
                                  height: 18.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context).black10,
                                  ),
                                ).animateOnPageLoad(animationsMap[
                                    'containerOnPageLoadAnimation4']!),
                              ].divide(SizedBox(height: 8.0)),
                            ),
                          ),
                        ),
                      );
                    }).divide(SizedBox(height: 12.0)),
                  );
                },
              ),
            ].divide(SizedBox(height: 12.0)),
          ),
        ),
        Expanded(
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
                  color: FlutterFlowTheme.of(context).lightGray,
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                child: Builder(
                  builder: (context) {
                    final categoryOpenList = List.generate(
                            random_data.randomInteger(6, 6),
                            (index) => random_data.randomName(true, false))
                        .toList();
                    if (categoryOpenList.isEmpty) {
                      return Center(
                        child: Container(
                          width: double.infinity,
                          height: MediaQuery.sizeOf(context).height * 0.8,
                          child: NoProductsComponentWidget(),
                        ),
                      );
                    }
                    _model.debugGeneratorVariables[
                            'categoryOpenList${categoryOpenList.length > 100 ? ' (first 100)' : ''}'] =
                        debugSerializeParam(
                      categoryOpenList.take(100),
                      ParamType.String,
                      isList: true,
                      link:
                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryOpenShimmer',
                      name: 'String',
                      nullable: false,
                    );
                    debugLogWidgetClass(_model);

                    return Wrap(
                      spacing: 12.0,
                      runSpacing: 12.0,
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      direction: Axis.horizontal,
                      runAlignment: WrapAlignment.start,
                      verticalDirection: VerticalDirection.down,
                      clipBehavior: Clip.none,
                      children: List.generate(categoryOpenList.length,
                          (categoryOpenListIndex) {
                        final categoryOpenListItem =
                            categoryOpenList[categoryOpenListIndex];
                        return wrapWithModel(
                          model: _model.mainComponentShimmerModels.getModel(
                            categoryOpenListItem,
                            categoryOpenListIndex,
                          ),
                          updateCallback: () => safeSetState(() {}),
                          child: Builder(builder: (_) {
                            return DebugFlutterFlowModelContext(
                              rootModel: _model.rootModel,
                              child: MainComponentShimmerWidget(
                                key: Key(
                                  'Keyv2q_${categoryOpenListItem}',
                                ),
                                isBig: false,
                                width: () {
                                  if (MediaQuery.sizeOf(context).width <
                                      810.0) {
                                    return ((MediaQuery.sizeOf(context).width -
                                            116) *
                                        1 /
                                        2);
                                  } else if ((MediaQuery.sizeOf(context)
                                              .width >=
                                          810.0) &&
                                      (MediaQuery.sizeOf(context).width <
                                          1280.0)) {
                                    return ((MediaQuery.sizeOf(context).width -
                                            140) *
                                        1 /
                                        4);
                                  } else if (MediaQuery.sizeOf(context).width >=
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
                                height: 250.0,
                              ),
                            );
                          }),
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
