import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'review_done_component_widget.dart' show ReviewDoneComponentWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ReviewDoneComponentModel
    extends FlutterFlowModel<ReviewDoneComponentWidget> {
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
          'onTapOk': debugSerializeParam(
            widget?.onTapOk,
            ParamType.Action,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ReviewDoneComponent',
            searchReference:
                'reference=ShkKEQoHb25UYXBPaxIGMDc1YWFkcgQIFSABUABaB29uVGFwT2s=',
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=ReviewDoneComponent',
        searchReference:
            'reference=OhNSZXZpZXdEb25lQ29tcG9uZW50UABaE1Jldmlld0RvbmVDb21wb25lbnQ=',
        widgetClassName: 'ReviewDoneComponent',
      );
}
