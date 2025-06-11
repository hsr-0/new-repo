import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'main_search_filter_appbar_widget.dart'
    show MainSearchFilterAppbarWidget;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MainSearchFilterAppbarModel
    extends FlutterFlowModel<MainSearchFilterAppbarWidget> {
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
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainSearchFilterAppbar',
            searchReference:
                'reference=ShcKDwoFdGl0bGUSBjJqMHFpb3IECAMgAVAAWgV0aXRsZQ==',
            name: 'String',
            nullable: true,
          ),
          'isBack': debugSerializeParam(
            widget?.isBack,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainSearchFilterAppbar',
            searchReference:
                'reference=SiEKEAoGaXNCYWNrEgYzbW5nNXMqBxIFZmFsc2VyBAgFIAFQAFoGaXNCYWNr',
            name: 'bool',
            nullable: false,
          ),
          'backAction': debugSerializeParam(
            widget?.backAction,
            ParamType.Action,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainSearchFilterAppbar',
            searchReference:
                'reference=ShwKFAoKYmFja0FjdGlvbhIGcGFsNnd1cgQIFSABUABaCmJhY2tBY3Rpb24=',
            name: 'Future Function()',
            nullable: true,
          ),
          'searchAction': debugSerializeParam(
            widget?.searchAction,
            ParamType.Action,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainSearchFilterAppbar',
            searchReference:
                'reference=Sh4KFgoMc2VhcmNoQWN0aW9uEgZoMWtmcWZyBAgVIAFQAFoMc2VhcmNoQWN0aW9u',
            name: 'Future Function()',
            nullable: true,
          ),
          'filterAction': debugSerializeParam(
            widget?.filterAction,
            ParamType.Action,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainSearchFilterAppbar',
            searchReference:
                'reference=Sh4KFgoMZmlsdGVyQWN0aW9uEgZmM2F4MDVyBAgVIAFQAFoMZmlsdGVyQWN0aW9u',
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=MainSearchFilterAppbar',
        searchReference:
            'reference=OhZNYWluU2VhcmNoRmlsdGVyQXBwYmFyUABaFk1haW5TZWFyY2hGaWx0ZXJBcHBiYXI=',
        widgetClassName: 'MainSearchFilterAppbar',
      );
}
