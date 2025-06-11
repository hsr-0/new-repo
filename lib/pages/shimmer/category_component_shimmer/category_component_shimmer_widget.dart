import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:math';
import 'dart:ui';
import '/flutter_flow/random_data_util.dart' as random_data;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'category_component_shimmer_model.dart';
export 'category_component_shimmer_model.dart';

class CategoryComponentShimmerWidget extends StatefulWidget {
  const CategoryComponentShimmerWidget({super.key});

  @override
  State<CategoryComponentShimmerWidget> createState() =>
      _CategoryComponentShimmerWidgetState();
}

class _CategoryComponentShimmerWidgetState
    extends State<CategoryComponentShimmerWidget>
    with TickerProviderStateMixin, RouteAware {
  late CategoryComponentShimmerModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CategoryComponentShimmerModel());

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

    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
      ),
      child: SingleChildScrollView(
        primary: false,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: double.infinity,
              height: 12.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).lightGray,
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(12.0, 16.0, 12.0, 0.0),
              child: Builder(
                builder: (context) {
                  final categoryList = List.generate(
                      random_data.randomInteger(9, 9),
                      (index) => random_data.randomName(true, true)).toList();
                  _model.debugGeneratorVariables[
                          'categoryList${categoryList.length > 100 ? ' (first 100)' : ''}'] =
                      debugSerializeParam(
                    categoryList.take(100),
                    ParamType.String,
                    isList: true,
                    link:
                        'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryComponentShimmer',
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
                    children:
                        List.generate(categoryList.length, (categoryListIndex) {
                      final categoryListItem = categoryList[categoryListIndex];
                      return Container(
                        width: () {
                          if (MediaQuery.sizeOf(context).width < 810.0) {
                            return ((MediaQuery.sizeOf(context).width - 48) *
                                1 /
                                3);
                          } else if ((MediaQuery.sizeOf(context).width >=
                                  810.0) &&
                              (MediaQuery.sizeOf(context).width < 1280.0)) {
                            return ((MediaQuery.sizeOf(context).width - 96) *
                                1 /
                                7);
                          } else if (MediaQuery.sizeOf(context).width >=
                              1280.0) {
                            return ((MediaQuery.sizeOf(context).width - 120) *
                                1 /
                                9);
                          } else {
                            return ((MediaQuery.sizeOf(context).width - 156) *
                                1 /
                                12);
                          }
                        }(),
                        height: 175.0,
                        decoration: BoxDecoration(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 114.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).black10,
                              ),
                            ).animateOnPageLoad(animationsMap[
                                'containerOnPageLoadAnimation1']!),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 8.0, 0.0, 0.0),
                              child: Container(
                                width: MediaQuery.sizeOf(context).width * 0.3,
                                height: 19.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).black10,
                                ),
                              ).animateOnPageLoad(animationsMap[
                                  'containerOnPageLoadAnimation2']!),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 4.0, 0.0, 0.0),
                              child: Container(
                                width: MediaQuery.sizeOf(context).width * 0.3,
                                height: 19.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).black10,
                                ),
                              ).animateOnPageLoad(animationsMap[
                                  'containerOnPageLoadAnimation3']!),
                            ),
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ].addToEnd(SizedBox(height: 16.0)),
        ),
      ),
    );
  }
}
