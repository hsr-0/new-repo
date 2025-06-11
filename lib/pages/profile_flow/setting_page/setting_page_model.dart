import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/dialog_components/delete_account_component/delete_account_component_widget.dart';
import '/pages/dialog_components/log_out_component/log_out_component_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'setting_page_widget.dart' show SettingPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class SettingPageModel extends FlutterFlowModel<SettingPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for MainAppbar component.
  late MainAppbarModel mainAppbarModel;
  // Stores action output result for [Backend Call - API (Delete account)] action in Container widget.
  ApiCallResponse? _deleteAccountApi;
  set deleteAccountApi(ApiCallResponse? value) {
    _deleteAccountApi = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get deleteAccountApi => _deleteAccountApi;

  // Stores action output result for [Backend Call - API (Log out)] action in Button widget.
  ApiCallResponse? _logOutApi;
  set logOutApi(ApiCallResponse? value) {
    _logOutApi = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get logOutApi => _logOutApi;

  // Model for responseComponent component.
  late ResponseComponentModel responseComponentModel;

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    mainAppbarModel = createModel(context, () => MainAppbarModel());
    responseComponentModel =
        createModel(context, () => ResponseComponentModel());

    debugLogWidgetClass(this);
  }

  @override
  void dispose() {
    mainAppbarModel.dispose();
    responseComponentModel.dispose();
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        actionOutputs: {
          'deleteAccountApi': debugSerializeParam(
            deleteAccountApi,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SettingPage',
            name: 'ApiCallResponse',
            nullable: true,
          ),
          'logOutApi': debugSerializeParam(
            logOutApi,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SettingPage',
            name: 'ApiCallResponse',
            nullable: true,
          )
        },
        generatorVariables: debugGeneratorVariables,
        backendQueries: debugBackendQueries,
        componentStates: {
          'mainAppbarModel (MainAppbar)':
              mainAppbarModel?.toWidgetClassDebugData(),
          'responseComponentModel (responseComponent)':
              responseComponentModel?.toWidgetClassDebugData(),
          ...widgetBuilderComponents.map(
            (key, value) => MapEntry(
              key,
              value.toWidgetClassDebugData(),
            ),
          ),
        }.withoutNulls,
        link:
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=SettingPage',
        searchReference: 'reference=OgtTZXR0aW5nUGFnZVABWgtTZXR0aW5nUGFnZQ==',
        widgetClassName: 'SettingPage',
      );
}
