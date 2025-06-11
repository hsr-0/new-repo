import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'sucessfully_page_widget.dart' show SucessfullyPageWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class SucessfullyPageModel extends FlutterFlowModel<SucessfullyPageWidget> {
  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    debugLogWidgetClass(this);
  }

  @override
  void dispose() {}

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        widgetParameters: {
          'orderDetail': debugSerializeParam(
            widget?.orderDetail,
            ParamType.JSON,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SucessfullyPage',
            searchReference:
                'reference=Sh0KFQoLb3JkZXJEZXRhaWwSBjNjbTQwdHIECAkgAVABWgtvcmRlckRldGFpbA==',
            name: 'dynamic',
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=SucessfullyPage',
        searchReference:
            'reference=Og9TdWNlc3NmdWxseVBhZ2VQAVoPU3VjZXNzZnVsbHlQYWdl',
        widgetClassName: 'SucessfullyPage',
      );
}
