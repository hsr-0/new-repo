import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import 'category_appbar_widget.dart' show CategoryAppbarWidget;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CategoryAppbarModel extends FlutterFlowModel<CategoryAppbarWidget> {
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
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryAppbar',
            searchReference:
                'reference=ShcKDwoFdGl0bGUSBjJqMHFpb3IECAMgAVAAWgV0aXRsZQ==',
            name: 'String',
            nullable: true,
          ),
          'isBack': debugSerializeParam(
            widget?.isBack,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryAppbar',
            searchReference:
                'reference=SiEKEAoGaXNCYWNrEgYzbW5nNXMqBxIFZmFsc2VyBAgFIAFQAFoGaXNCYWNr',
            name: 'bool',
            nullable: false,
          ),
          'searchAction': debugSerializeParam(
            widget?.searchAction,
            ParamType.Action,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryAppbar',
            searchReference:
                'reference=Sh4KFgoMc2VhcmNoQWN0aW9uEgZoMWtmcWZyBAgVIAFQAFoMc2VhcmNoQWN0aW9u',
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=CategoryAppbar',
        searchReference:
            'reference=Og5DYXRlZ29yeUFwcGJhclAAWg5DYXRlZ29yeUFwcGJhcg==',
        widgetClassName: 'CategoryAppbar',
      );
}
