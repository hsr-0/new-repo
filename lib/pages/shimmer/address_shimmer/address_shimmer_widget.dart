import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'address_shimmer_model.dart';
export 'address_shimmer_model.dart';

class AddressShimmerWidget extends StatefulWidget {
  const AddressShimmerWidget({super.key});

  @override
  State<AddressShimmerWidget> createState() => _AddressShimmerWidgetState();
}

class _AddressShimmerWidgetState extends State<AddressShimmerWidget>
    with TickerProviderStateMixin, RouteAware {
  late AddressShimmerModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddressShimmerModel());

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
      'containerOnPageLoadAnimation5': AnimationInfo(
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
      'containerOnPageLoadAnimation6': AnimationInfo(
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
      'containerOnPageLoadAnimation7': AnimationInfo(
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
      'containerOnPageLoadAnimation8': AnimationInfo(
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
      'containerOnPageLoadAnimation9': AnimationInfo(
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
      'containerOnPageLoadAnimation10': AnimationInfo(
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
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          0,
          22.0,
          0,
          22.0,
        ),
        primary: false,
        scrollDirection: Axis.vertical,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
            child: Container(
              width: double.infinity,
              height: 54.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).black10,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ).animateOnPageLoad(
                animationsMap['containerOnPageLoadAnimation1']!),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(12.0, 29.0, 12.0, 0.0),
            child: Container(
              width: double.infinity,
              height: 54.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).black10,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ).animateOnPageLoad(
                animationsMap['containerOnPageLoadAnimation2']!),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(12.0, 29.0, 12.0, 0.0),
            child: Container(
              width: double.infinity,
              height: 54.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).black10,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ).animateOnPageLoad(
                animationsMap['containerOnPageLoadAnimation3']!),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(12.0, 29.0, 12.0, 0.0),
            child: Container(
              width: double.infinity,
              height: 54.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).black10,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ).animateOnPageLoad(
                animationsMap['containerOnPageLoadAnimation4']!),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(12.0, 29.0, 12.0, 10.0),
            child: Container(
              width: double.infinity,
              height: 54.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).black10,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ).animateOnPageLoad(
                animationsMap['containerOnPageLoadAnimation5']!),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(12.0, 19.0, 12.0, 19.0),
            child: Container(
              width: double.infinity,
              height: 54.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).black10,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ).animateOnPageLoad(
                animationsMap['containerOnPageLoadAnimation6']!),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 19.0),
            child: Container(
              width: double.infinity,
              height: 54.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).black10,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ).animateOnPageLoad(
                animationsMap['containerOnPageLoadAnimation7']!),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 19.0),
            child: Container(
              width: double.infinity,
              height: 54.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).black10,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ).animateOnPageLoad(
                animationsMap['containerOnPageLoadAnimation8']!),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 19.0),
            child: Container(
              width: double.infinity,
              height: 54.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).black10,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ).animateOnPageLoad(
                animationsMap['containerOnPageLoadAnimation9']!),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
            child: Container(
              width: double.infinity,
              height: 54.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).black10,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ).animateOnPageLoad(
                animationsMap['containerOnPageLoadAnimation10']!),
          ),
        ],
      ),
    );
  }
}
