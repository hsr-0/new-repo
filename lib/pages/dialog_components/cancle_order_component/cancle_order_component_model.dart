import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'cancle_order_component_widget.dart' show CancleOrderComponentWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CancleOrderComponentModel
    extends FlutterFlowModel<CancleOrderComponentWidget> {
  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        widgetParameters: {
          'onTapYes': debugSerializeParam(
            widget?.onTapYes,
            ParamType.Action,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CancleOrderComponent',
            searchReference:
                'reference=ShoKEgoIb25UYXBZZXMSBjA3NWFhZHIECBUgAVAAWghvblRhcFllcw==',
            name: 'Future Function()',
            nullable: true,
          )
        }.withoutNulls,
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=CancleOrderComponent',
        searchReference:
            'reference=OhRDYW5jbGVPcmRlckNvbXBvbmVudFAAWhRDYW5jbGVPcmRlckNvbXBvbmVudA==',
        widgetClassName: 'CancleOrderComponent',
      );
}
