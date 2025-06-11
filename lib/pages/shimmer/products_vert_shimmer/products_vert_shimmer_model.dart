import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/shimmer/main_component_shimmer/main_component_shimmer_widget.dart';
import '/flutter_flow/random_data_util.dart' as random_data;
import 'products_vert_shimmer_widget.dart' show ProductsVertShimmerWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProductsVertShimmerModel
    extends FlutterFlowModel<ProductsVertShimmerWidget> {
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=ProductsVertShimmer',
        searchReference:
            'reference=OhNQcm9kdWN0c1ZlcnRTaGltbWVyUABaE1Byb2R1Y3RzVmVydFNoaW1tZXI=',
        widgetClassName: 'ProductsVertShimmer',
      );
}
