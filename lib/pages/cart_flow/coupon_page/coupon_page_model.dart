import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/empty_components/no_coupon_component/no_coupon_component_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/random_data_util.dart' as random_data;
import 'coupon_page_widget.dart' show CouponPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class CouponPageModel extends FlutterFlowModel<CouponPageWidget> {
  ///  Local state fields for this page.

  bool _process = false;
  set process(bool value) {
    _process = value;
    debugLogWidgetClass(this);
  }

  bool get process => _process;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (Coupon code)] action in CouponPage widget.
  ApiCallResponse? _coupons;
  set coupons(ApiCallResponse? value) {
    _coupons = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get coupons => _coupons;

  // Model for MainAppbar component.
  late MainAppbarModel mainAppbarModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Backend Call - API (Apply coupon code)] action in Button widget.
  ApiCallResponse? _apply;
  set apply(ApiCallResponse? value) {
    _apply = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get apply => _apply;

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
    textFieldFocusNode?.dispose();
    textController?.dispose();

    responseComponentModel.dispose();
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        widgetParameters: {
          'nonce': debugSerializeParam(
            widget?.nonce,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CouponPage',
            searchReference:
                'reference=ShcKDwoFbm9uY2USBjVhZmdiaXIECAMgAVABWgVub25jZQ==',
            name: 'String',
            nullable: true,
          )
        }.withoutNulls,
        localStates: {
          'process': debugSerializeParam(
            process,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CouponPage',
            searchReference:
                'reference=QiEKEAoHcHJvY2VzcxIFeGY5ZnQqBxIFZmFsc2VyBAgFIAFQAVoHcHJvY2Vzc2IKQ291cG9uUGFnZQ==',
            name: 'bool',
            nullable: false,
          )
        },
        widgetStates: {
          'textFieldText': debugSerializeParam(
            textController?.text,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CouponPage',
            name: 'String',
            nullable: true,
          )
        },
        actionOutputs: {
          'coupons': debugSerializeParam(
            coupons,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CouponPage',
            name: 'ApiCallResponse',
            nullable: true,
          ),
          'apply': debugSerializeParam(
            apply,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CouponPage',
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=CouponPage',
        searchReference: 'reference=OgpDb3Vwb25QYWdlUAFaCkNvdXBvblBhZ2U=',
        widgetClassName: 'CouponPage',
      );
}
