import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import 'no_payment_methodes_component_widget.dart'
    show NoPaymentMethodesComponentWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class NoPaymentMethodesComponentModel
    extends FlutterFlowModel<NoPaymentMethodesComponentWidget> {
  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}

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
        link:
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=NoPaymentMethodesComponent',
        searchReference:
            'reference=OhpOb1BheW1lbnRNZXRob2Rlc0NvbXBvbmVudFAAWhpOb1BheW1lbnRNZXRob2Rlc0NvbXBvbmVudA==',
        widgetClassName: 'NoPaymentMethodesComponent',
      );
}
