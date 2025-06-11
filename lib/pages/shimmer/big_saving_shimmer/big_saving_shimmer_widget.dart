import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/shimmer/main_component_shimmer/main_component_shimmer_widget.dart';
import 'dart:ui';
import '/flutter_flow/random_data_util.dart' as random_data;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'big_saving_shimmer_model.dart';
export 'big_saving_shimmer_model.dart';

class BigSavingShimmerWidget extends StatefulWidget {
  const BigSavingShimmerWidget({super.key});

  @override
  State<BigSavingShimmerWidget> createState() => _BigSavingShimmerWidgetState();
}

class _BigSavingShimmerWidgetState extends State<BigSavingShimmerWidget>
    with RouteAware {
  late BigSavingShimmerModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BigSavingShimmerModel());
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

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondary,
          borderRadius: BorderRadius.circular(0.0),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 14.0),
          child: Container(
            width: double.infinity,
            height: 298.0,
            decoration: BoxDecoration(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 12.0, 0.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          FFLocalizations.of(context).getText(
                            '49lffdzb' /* Popular 
products 🔥 */
                            ,
                          ),
                          textAlign: TextAlign.start,
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: 'SF Pro Display',
                                color: FlutterFlowTheme.of(context).primaryText,
                                fontSize: 20.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                                useGoogleFonts: false,
                                lineHeight: 1.5,
                              ),
                        ),
                        Container(
                          width: 100.0,
                          height: 36.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).primary,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Text(
                            FFLocalizations.of(context).getText(
                              '8vd5ihur' /* View all */,
                            ),
                            textAlign: TextAlign.start,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'SF Pro Display',
                                  color: Colors.white,
                                  fontSize: 17.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                  useGoogleFonts: false,
                                ),
                          ),
                        ),
                      ].divide(SizedBox(height: 16.0)),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(),
                    child: Builder(
                      builder: (context) {
                        final newArrivalList = List.generate(
                                random_data.randomInteger(6, 6),
                                (index) => random_data.randomName(true, false))
                            .toList()
                            .take(6)
                            .toList();
                        _model.debugGeneratorVariables[
                                'newArrivalList${newArrivalList.length > 100 ? ' (first 100)' : ''}'] =
                            debugSerializeParam(
                          newArrivalList.take(100),
                          ParamType.String,
                          isList: true,
                          link:
                              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=BigSavingShimmer',
                          name: 'String',
                          nullable: false,
                        );
                        debugLogWidgetClass(_model);

                        return Row(
                          mainAxisSize: MainAxisSize.max,
                          children: List.generate(newArrivalList.length,
                              (newArrivalListIndex) {
                            final newArrivalListItem =
                                newArrivalList[newArrivalListIndex];
                            return wrapWithModel(
                              model: _model.mainComponentShimmerModels.getModel(
                                newArrivalListItem,
                                newArrivalListIndex,
                              ),
                              updateCallback: () => safeSetState(() {}),
                              child: Builder(builder: (_) {
                                return DebugFlutterFlowModelContext(
                                  rootModel: _model.rootModel,
                                  child: MainComponentShimmerWidget(
                                    key: Key(
                                      'Keypw2_${newArrivalListItem}',
                                    ),
                                    isBig: false,
                                    width: 189.0,
                                    height: 298.0,
                                  ),
                                );
                              }),
                            );
                          }).divide(SizedBox(width: 12.0)),
                        );
                      },
                    ),
                  ),
                ]
                    .addToStart(SizedBox(width: 12.0))
                    .addToEnd(SizedBox(width: 12.0)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
