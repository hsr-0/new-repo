import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'logo_component_widget.dart' show LogoComponentWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LogoComponentModel extends FlutterFlowModel<LogoComponentWidget> {
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
          'height': debugSerializeParam(
            widget?.height,
            ParamType.double,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=LogoComponent',
            searchReference:
                'reference=ShgKEAoGaGVpZ2h0EgZmenA4cGxyBAgCIAFQAFoGaGVpZ2h0',
            name: 'double',
            nullable: true,
          ),
          'width': debugSerializeParam(
            widget?.width,
            ParamType.double,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=LogoComponent',
            searchReference:
                'reference=ShcKDwoFd2lkdGgSBjBwbGdzcXIECAIgAVAAWgV3aWR0aA==',
            name: 'double',
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=LogoComponent',
        searchReference:
            'reference=Og1Mb2dvQ29tcG9uZW50UABaDUxvZ29Db21wb25lbnQ=',
        widgetClassName: 'LogoComponent',
      );
}
