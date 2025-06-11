import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'delete_account_component_widget.dart' show DeleteAccountComponentWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DeleteAccountComponentModel
    extends FlutterFlowModel<DeleteAccountComponentWidget> {
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
          'isDeleteTap': debugSerializeParam(
            widget?.isDeleteTap,
            ParamType.Action,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=DeleteAccountComponent',
            searchReference:
                'reference=Sh0KFQoLaXNEZWxldGVUYXASBjdkanQxMHIECBUgAVAAWgtpc0RlbGV0ZVRhcA==',
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=DeleteAccountComponent',
        searchReference:
            'reference=OhZEZWxldGVBY2NvdW50Q29tcG9uZW50UABaFkRlbGV0ZUFjY291bnRDb21wb25lbnQ=',
        widgetClassName: 'DeleteAccountComponent',
      );
}
