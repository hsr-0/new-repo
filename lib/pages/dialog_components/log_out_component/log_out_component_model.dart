import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'log_out_component_widget.dart' show LogOutComponentWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LogOutComponentModel extends FlutterFlowModel<LogOutComponentWidget> {
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
          'isLogOutTap': debugSerializeParam(
            widget?.isLogOutTap,
            ParamType.Action,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=LogOutComponent',
            searchReference:
                'reference=Sh0KFQoLaXNMb2dPdXRUYXASBmM5YmNiYXIECBUgAVAAWgtpc0xvZ091dFRhcA==',
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=LogOutComponent',
        searchReference:
            'reference=Og9Mb2dPdXRDb21wb25lbnRQAFoPTG9nT3V0Q29tcG9uZW50',
        widgetClassName: 'LogOutComponent',
      );
}
