import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/shimmer/main_component_shimmer/main_component_shimmer_widget.dart';
import 'dart:ui';
import '/flutter_flow/random_data_util.dart' as random_data;
import 'big_saving_shimmer_widget.dart' show BigSavingShimmerWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BigSavingShimmerModel extends FlutterFlowModel<BigSavingShimmerWidget> {
  ///  State fields for stateful widgets in this component.

  // Models for MainComponentShimmer dynamic component.
  late FlutterFlowDynamicModels<MainComponentShimmerModel>
      mainComponentShimmerModels;

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    mainComponentShimmerModels =
        FlutterFlowDynamicModels(() => MainComponentShimmerModel());
  }

  @override
  void dispose() {
    mainComponentShimmerModels.dispose();
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        generatorVariables: debugGeneratorVariables,
        backendQueries: debugBackendQueries,
        componentStates: {
          ...widgetBuilderComponents.map(
            (key, value) => MapEntry(
              key,
              value.toWidgetClassDebugData(),
            ),
          ),
        }.withoutNulls,
        dynamicComponentStates: {
          'mainComponentShimmerModels (List<MainComponentShimmer>)':
              mainComponentShimmerModels?.toDynamicWidgetClassDebugData(),
        }.withoutNulls,
        link:
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=BigSavingShimmer',
        searchReference:
            'reference=OhBCaWdTYXZpbmdTaGltbWVyUABaEEJpZ1NhdmluZ1NoaW1tZXI=',
        widgetClassName: 'BigSavingShimmer',
      );
}
