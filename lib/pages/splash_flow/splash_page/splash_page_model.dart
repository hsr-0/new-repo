import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/logo_component/logo_component_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'splash_page_widget.dart' show SplashPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SplashPageModel extends FlutterFlowModel<SplashPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - tokenValidater] action in SplashPage widget.
  bool? _isTokenExpired;
  set isTokenExpired(bool? value) {
    _isTokenExpired = value;
    debugLogWidgetClass(this);
  }

  bool? get isTokenExpired => _isTokenExpired;

  // Stores action output result for [Backend Call - API (Current currency)] action in SplashPage widget.
  ApiCallResponse? _currency;
  set currency(ApiCallResponse? value) {
    _currency = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get currency => _currency;

  // Stores action output result for [Custom Action - currencyConverter] action in SplashPage widget.
  String? _currencySymbol;
  set currencySymbol(String? value) {
    _currencySymbol = value;
    debugLogWidgetClass(this);
  }

  String? get currencySymbol => _currencySymbol;

  // Stores action output result for [Backend Call - API (Currency position)] action in SplashPage widget.
  ApiCallResponse? _currencyPosition;
  set currencyPosition(ApiCallResponse? value) {
    _currencyPosition = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get currencyPosition => _currencyPosition;

  // Stores action output result for [Backend Call - API (Thousand separator)] action in SplashPage widget.
  ApiCallResponse? _thousandSeparator;
  set thousandSeparator(ApiCallResponse? value) {
    _thousandSeparator = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get thousandSeparator => _thousandSeparator;

  // Stores action output result for [Backend Call - API (Decimal separator)] action in SplashPage widget.
  ApiCallResponse? _decimalSeparator;
  set decimalSeparator(ApiCallResponse? value) {
    _decimalSeparator = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get decimalSeparator => _decimalSeparator;

  // Stores action output result for [Backend Call - API (Number of Decimals)] action in SplashPage widget.
  ApiCallResponse? _numberofDecimals;
  set numberofDecimals(ApiCallResponse? value) {
    _numberofDecimals = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get numberofDecimals => _numberofDecimals;

  // Stores action output result for [Action Block - GetCustomer] action in SplashPage widget.
  bool? _success;
  set success(bool? value) {
    _success = value;
    debugLogWidgetClass(this);
  }

  bool? get success => _success;

  // Stores action output result for [Backend Call - API (All Intro)] action in SplashPage widget.
  ApiCallResponse? _allIntro;
  set allIntro(ApiCallResponse? value) {
    _allIntro = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get allIntro => _allIntro;

  // Model for LogoComponent component.
  late LogoComponentModel logoComponentModel;

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    logoComponentModel = createModel(context, () => LogoComponentModel());

    debugLogWidgetClass(this);
  }

  @override
  void dispose() {
    logoComponentModel.dispose();
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        actionOutputs: {
          'isTokenExpired': debugSerializeParam(
            isTokenExpired,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SplashPage',
            name: 'bool',
            nullable: true,
          ),
          'currency': debugSerializeParam(
            currency,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SplashPage',
            name: 'ApiCallResponse',
            nullable: true,
          ),
          'currencySymbol': debugSerializeParam(
            currencySymbol,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SplashPage',
            name: 'String',
            nullable: true,
          ),
          'currencyPosition': debugSerializeParam(
            currencyPosition,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SplashPage',
            name: 'ApiCallResponse',
            nullable: true,
          ),
          'thousandSeparator': debugSerializeParam(
            thousandSeparator,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SplashPage',
            name: 'ApiCallResponse',
            nullable: true,
          ),
          'decimalSeparator': debugSerializeParam(
            decimalSeparator,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SplashPage',
            name: 'ApiCallResponse',
            nullable: true,
          ),
          'numberofDecimals': debugSerializeParam(
            numberofDecimals,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SplashPage',
            name: 'ApiCallResponse',
            nullable: true,
          ),
          'success': debugSerializeParam(
            success,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SplashPage',
            name: 'bool',
            nullable: true,
          ),
          'allIntro': debugSerializeParam(
            allIntro,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SplashPage',
            name: 'ApiCallResponse',
            nullable: true,
          )
        },
        generatorVariables: debugGeneratorVariables,
        backendQueries: debugBackendQueries,
        componentStates: {
          'logoComponentModel (LogoComponent)':
              logoComponentModel?.toWidgetClassDebugData(),
          ...widgetBuilderComponents.map(
            (key, value) => MapEntry(
              key,
              value.toWidgetClassDebugData(),
            ),
          ),
        }.withoutNulls,
        link:
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=SplashPage',
        searchReference: 'reference=OgpTcGxhc2hQYWdlUAFaClNwbGFzaFBhZ2U=',
        widgetClassName: 'SplashPage',
      );
}
