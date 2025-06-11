import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'sign_in_page_widget.dart' show SignInPageWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInPageModel extends FlutterFlowModel<SignInPageWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  String? _textController1Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'u8loqg6n' /* Please enter username or email */,
      );
    }
    return null;
  }

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? textController2Validator;
  String? _textController2Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'pawk42w6' /* Please enter password */,
      );
    }
    return null;
  }

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

  // New fields for social login
  UserCredential? _googleUser;
  set googleUser(UserCredential? value) {
    _googleUser = value;
    debugLogWidgetClass(this);
  }
  UserCredential? get googleUser => _googleUser;

  UserCredential? _appleUser;
  set appleUser(UserCredential? value) {
    _appleUser = value;
    debugLogWidgetClass(this);
  }
  UserCredential? get appleUser => _appleUser;

  ApiCallResponse? _socialLogin;
  set socialLogin(ApiCallResponse? value) {
    _socialLogin = value;
    debugLogWidgetClass(this);
  }
  ApiCallResponse? get socialLogin => _socialLogin;

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};

  @override
  void initState(BuildContext context) {
    textController1Validator = _textController1Validator;
    passwordVisibility = false;
    textController2Validator = _textController2Validator;
    debugLogWidgetClass(this);
  }

  @override
  void dispose() {
    textFieldFocusNode1?.dispose();
    textController1?.dispose();
    textFieldFocusNode2?.dispose();
    textController2?.dispose();
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
    widgetParameters: {
      'isInner': debugSerializeParam(
        widget?.isInner,
        ParamType.bool,
        link: 'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignInPage',
        searchReference: 'reference=SiEKEQoHaXNJbm5lchIGZHoxa2UwKgYSBHRydWVyBAgFIAFQAVoHaXNJbm5lcg==',
        name: 'bool',
        nullable: false,
      )
    }.withoutNulls,
    widgetStates: {
      'textFieldText1': debugSerializeParam(
        textController1?.text,
        ParamType.String,
        link: 'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignInPage',
        name: 'String',
        nullable: true,
      ),
      'textFieldText2': debugSerializeParam(
        textController2?.text,
        ParamType.String,
        link: 'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignInPage',
        name: 'String',
        nullable: true,
      )
    },
    actionOutputs: {
      'login': debugSerializeParam(
        login,
        ParamType.ApiResponse,
        link: 'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignInPage',
        name: 'ApiCallResponse',
        nullable: true,
      ),
      'id': debugSerializeParam(
        id,
        ParamType.String,
        link: 'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignInPage',
        name: 'String',
        nullable: true,
      ),
      'customerData': debugSerializeParam(
        customerData,
        ParamType.ApiResponse,
        link: 'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignInPage',
        name: 'ApiCallResponse',
        nullable: true,
      ),
      // New debug outputs for social login
      'googleUser': debugSerializeParam(
        googleUser,
        ParamType.Object,
        link: 'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignInPage',
        name: 'UserCredential',
        nullable: true,
      ),
      'appleUser': debugSerializeParam(
        appleUser,
        ParamType.Object,
        link: 'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignInPage',
        name: 'UserCredential',
        nullable: true,
      ),
      'socialLogin': debugSerializeParam(
        socialLogin,
        ParamType.ApiResponse,
        link: 'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SignInPage',
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
    link: 'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=SignInPage',
    searchReference: 'reference=OgpTaWduSW5QYWdlUAFaClNpZ25JblBhZ2U=',
    widgetClassName: 'SignInPage',
  );
}
