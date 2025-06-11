import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import 'main_appbar_widget.dart' show MainAppbarWidget;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MainAppbarModel extends FlutterFlowModel<MainAppbarWidget> {
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
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainAppbar',
            searchReference:
                'reference=ShcKDwoFdGl0bGUSBjJqMHFpb3IECAMgAVAAWgV0aXRsZQ==',
            name: 'String',
            nullable: true,
          ),
          'isBack': debugSerializeParam(
            widget?.isBack,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainAppbar',
            searchReference:
                'reference=SiEKEAoGaXNCYWNrEgYzbW5nNXMqBxIFZmFsc2VyBAgFIAFQAFoGaXNCYWNr',
            name: 'bool',
            nullable: false,
          ),
          'backAction': debugSerializeParam(
            widget?.backAction,
            ParamType.Action,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainAppbar',
            searchReference:
                'reference=ShwKFAoKYmFja0FjdGlvbhIGcGFsNnd1cgQIFSABUABaCmJhY2tBY3Rpb24=',
            name: 'Future Function()',
            nullable: true,
          ),
          'isEdit': debugSerializeParam(
            widget?.isEdit,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainAppbar',
            searchReference:
                'reference=SiEKEAoGaXNFZGl0EgZ0dXpheDQqBxIFZmFsc2VyBAgFIAFQAFoGaXNFZGl0',
            name: 'bool',
            nullable: false,
          ),
          'editAction': debugSerializeParam(
            widget?.editAction,
            ParamType.Action,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainAppbar',
            searchReference:
                'reference=ShwKFAoKZWRpdEFjdGlvbhIGaDFrZnFmcgQIFSABUABaCmVkaXRBY3Rpb24=',
            name: 'Future Function()',
            nullable: true,
          ),
          'isShare': debugSerializeParam(
            widget?.isShare,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainAppbar',
            searchReference:
                'reference=SiIKEQoHaXNTaGFyZRIGdXRxZHY0KgcSBWZhbHNlcgQIBSABUABaB2lzU2hhcmU=',
            name: 'bool',
            nullable: false,
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=MainAppbar',
        searchReference: 'reference=OgpNYWluQXBwYmFyUABaCk1haW5BcHBiYXI=',
        widgetClassName: 'MainAppbar',
      );
}
