import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'cart_item_delete_component_widget.dart'
    show CartItemDeleteComponentWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CartItemDeleteComponentModel
    extends FlutterFlowModel<CartItemDeleteComponentWidget> {
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
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartItemDeleteComponent',
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=CartItemDeleteComponent',
        searchReference:
            'reference=OhdDYXJ0SXRlbURlbGV0ZUNvbXBvbmVudFAAWhdDYXJ0SXRlbURlbGV0ZUNvbXBvbmVudA==',
        widgetClassName: 'CartItemDeleteComponent',
      );
}
