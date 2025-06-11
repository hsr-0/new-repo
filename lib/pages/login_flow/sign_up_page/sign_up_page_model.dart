import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'sign_up_page_widget.dart' show SignUpPageWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SignUpPageModel extends FlutterFlowModel<SignUpPageWidget> {
  ///  Local state fields for this page.

  bool? _isCheck = false;
  set isCheck(bool? value) {
    _isCheck = value;
    debugLogWidgetClass(this);
  }

  bool? get isCheck => _isCheck;

  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  String? _textController1Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'cagfa4hb' /* Please enter username */,
      );
    }

    return null;
  }

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  String? _textController2Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'c12hy1cn' /* Please enter email address */,
      );
    }

    if (!RegExp(kTextValidatorEmailRegex).hasMatch(val)) {
      return FFLocalizations.of(context).getText(
        'a3bia36h' /* Please enter valid email addre... */,
      );
    }
    return null;
  }

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController3;
  late bool passwordVisibility1;
  String? Function(BuildContext, String?)? textController3Validator;
  String? _textController3Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'l61afd4j' /* Please enter password */,
      );
    }

    return null;
  }

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode4;
  TextEditingController? textController4;
  late bool passwordVisibility2;
  String? Function(BuildContext, String?)? textController4Validator;
  String? _textController4Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'ys6g7k01' /* Please enter confirm password */,
      );
    }

    return null;
  }

  // Stores action output result for [Backend Call - API (sign up)] action in Button widget.
  ApiCallResponse? _signup;
  set signup(ApiCallResponse? value) {
    _signup = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get signup => _signup;

  // Stores action output result for [Backend Call - API (log in)] action in Button widget.
  ApiCallResponse? _login;
  set login(ApiCallResponse? value) {
    _login = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get login => _login;

  // Stores action output result for [Custom Action - tokenDecoder] action in Button widget.
  String? _id;
  set id(String? value) {
    _id = value;
    debugLogWidgetClass(this);
  }

  String? get id => _id;

  // Stores action output result for [Backend Call - API (Get customer)] action in Button widget.
  ApiCallResponse? _customerData;
  set customerData(ApiCallResponse? value) {
    _customerData = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get customerData => _customerData;

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    textController1Validator = _textController1Validator;
    textController2Validator = _textController2Validator;
    passwordVisibility1 = false;
    textController3Validator = _textController3Validator;
    passwordVisibility2 = false;
    textController4Validator = _textController4Validator;

    debugLogWidgetClass(this);
  }

  @override
  void dispose() {
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    textFieldFocusNode3?.dispose();
    textController3?.dispose();

    textFieldFocusNode4?.dispose();
    textController4?.dispose();
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        widgetParameters: {
          'isInner': debugSerializeParam(
            widget?.isInner,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignUpPage',
            searchReference:
                'reference=SiEKEQoHaXNJbm5lchIGNzFnZjUxKgYSBHRydWVyBAgFIAFQAVoHaXNJbm5lcg==',
            name: 'bool',
            nullable: false,
          )
        }.withoutNulls,
        localStates: {
          'isCheck': debugSerializeParam(
            isCheck,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignUpPage',
            searchReference:
                'reference=QiEKEAoHaXNDaGVjaxIFMHp0cmUqBxIFZmFsc2VyBAgFIABQAVoHaXNDaGVja2IKU2lnblVwUGFnZQ==',
            name: 'bool',
            nullable: true,
          )
        },
        widgetStates: {
          'textFieldText1': debugSerializeParam(
            textController1?.text,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignUpPage',
            name: 'String',
            nullable: true,
          ),
          'textFieldText2': debugSerializeParam(
            textController2?.text,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignUpPage',
            name: 'String',
            nullable: true,
          ),
          'textFieldText3': debugSerializeParam(
            textController3?.text,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignUpPage',
            name: 'String',
            nullable: true,
          ),
          'textFieldText4': debugSerializeParam(
            textController4?.text,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignUpPage',
            name: 'String',
            nullable: true,
          )
        },
        actionOutputs: {
          'signup': debugSerializeParam(
            signup,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignUpPage',
            name: 'ApiCallResponse',
            nullable: true,
          ),
          'login': debugSerializeParam(
            login,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignUpPage',
            name: 'ApiCallResponse',
            nullable: true,
          ),
          'id': debugSerializeParam(
            id,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignUpPage',
            name: 'String',
            nullable: true,
          ),
          'customerData': debugSerializeParam(
            customerData,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignUpPage',
            name: 'ApiCallResponse',
            nullable: true,
          )
        },
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=SignUpPage',
        searchReference: 'reference=OgpTaWduVXBQYWdlUAFaClNpZ25VcFBhZ2U=',
        widgetClassName: 'SignUpPage',
      );
}
