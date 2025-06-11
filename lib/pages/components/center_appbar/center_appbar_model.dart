import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import 'center_appbar_widget.dart' show CenterAppbarWidget;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CenterAppbarModel extends FlutterFlowModel<CenterAppbarWidget> {
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
          'title': debugSerializeParam(
            widget?.title,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CenterAppbar',
            searchReference:
                'reference=ShcKDwoFdGl0bGUSBjJqMHFpb3IECAMgAVAAWgV0aXRsZQ==',
            name: 'String',
            nullable: true,
          ),
          'isBack': debugSerializeParam(
            widget?.isBack,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CenterAppbar',
            searchReference:
                'reference=SiEKEAoGaXNCYWNrEgY2dTR4c3gqBxIFZmFsc2VyBAgFIAFQAFoGaXNCYWNr',
            name: 'bool',
            nullable: false,
          ),
          'backAction': debugSerializeParam(
            widget?.backAction,
            ParamType.Action,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CenterAppbar',
            searchReference:
                'reference=ShwKFAoKYmFja0FjdGlvbhIGaGlsOGRlcgQIFSABUABaCmJhY2tBY3Rpb24=',
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=CenterAppbar',
        searchReference: 'reference=OgxDZW50ZXJBcHBiYXJQAFoMQ2VudGVyQXBwYmFy',
        widgetClassName: 'CenterAppbar',
      );
}
