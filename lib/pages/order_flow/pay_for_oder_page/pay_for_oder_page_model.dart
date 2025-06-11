import '';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/payment_images/payment_images_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'pay_for_oder_page_widget.dart' show PayForOderPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class PayForOderPageModel extends FlutterFlowModel<PayForOderPageWidget> {
  ///  Local state fields for this page.

  String? _select;
  set select(String? value) {
    _select = value;
    debugLogWidgetClass(this);
  }

  String? get select => _select;

  dynamic _selectdMethod;
  set selectdMethod(dynamic value) {
    _selectdMethod = value;
    debugLogWidgetClass(this);
  }

  dynamic get selectdMethod => _selectdMethod;

  bool _process = false;
  set process(bool value) {
    _process = value;
    debugLogWidgetClass(this);
  }

  bool get process => _process;

  bool _isBack = false;
  set isBack(bool value) {
    _isBack = value;
    debugLogWidgetClass(this);
  }

  bool get isBack => _isBack;

  ///  State fields for stateful widgets in this page.

  // Model for MainAppbar component.
  late MainAppbarModel mainAppbarModel;
  // Models for PaymentImages dynamic component.
  late FlutterFlowDynamicModels<PaymentImagesModel> paymentImagesModels;
  // Stores action output result for [Action Block - UpdateStatus] action in Button widget.
  bool? _sucessRazorPay;
  set sucessRazorPay(bool? value) {
    _sucessRazorPay = value;
    debugLogWidgetClass(this);
  }

  bool? get sucessRazorPay => _sucessRazorPay;

  // Stores action output result for [Action Block - UpdateStatus] action in Button widget.
  bool? _sucessStripe;
  set sucessStripe(bool? value) {
    _sucessStripe = value;
    debugLogWidgetClass(this);
  }

  bool? get sucessStripe => _sucessStripe;

  // Stores action output result for [Action Block - UpdateStatus] action in Button widget.
  bool? _sucessPayPal;
  set sucessPayPal(bool? value) {
    _sucessPayPal = value;
    debugLogWidgetClass(this);
  }

  bool? get sucessPayPal => _sucessPayPal;

  // Model for responseComponent component.
  late ResponseComponentModel responseComponentModel;

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    mainAppbarModel = createModel(context, () => MainAppbarModel());
    paymentImagesModels = FlutterFlowDynamicModels(() => PaymentImagesModel());
    responseComponentModel =
        createModel(context, () => ResponseComponentModel());

    debugLogWidgetClass(this);
  }

  @override
  void dispose() {
    mainAppbarModel.dispose();
    paymentImagesModels.dispose();
    responseComponentModel.dispose();
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        widgetParameters: {
          'orderDetail': debugSerializeParam(
            widget?.orderDetail,
            ParamType.JSON,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=PayForOderPage',
            searchReference:
                'reference=Sh0KFQoLb3JkZXJEZXRhaWwSBnJ3MXkxbHIECAkgAVABWgtvcmRlckRldGFpbA==',
            name: 'dynamic',
            nullable: true,
          )
        }.withoutNulls,
        localStates: {
          'select': debugSerializeParam(
            select,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=PayForOderPage',
            searchReference:
                'reference=QhsKDwoGc2VsZWN0EgVybW91MCoCEgByBAgDIABQAVoGc2VsZWN0Yg5QYXlGb3JPZGVyUGFnZQ==',
            name: 'String',
            nullable: true,
          ),
          'selectdMethod': debugSerializeParam(
            selectdMethod,
            ParamType.JSON,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=PayForOderPage',
            searchReference:
                'reference=QhwKFgoNc2VsZWN0ZE1ldGhvZBIFNjBkdjByAggJUAFaDXNlbGVjdGRNZXRob2RiDlBheUZvck9kZXJQYWdl',
            name: 'dynamic',
            nullable: true,
          ),
          'process': debugSerializeParam(
            process,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=PayForOderPage',
            searchReference:
                'reference=QiEKEAoHcHJvY2VzcxIFZHlmaHcqBxIFZmFsc2VyBAgFIAFQAVoHcHJvY2Vzc2IOUGF5Rm9yT2RlclBhZ2U=',
            name: 'bool',
            nullable: false,
          ),
          'isBack': debugSerializeParam(
            isBack,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=PayForOderPage',
            searchReference:
                'reference=QiAKDwoGaXNCYWNrEgV0OWtpZCoHEgVmYWxzZXIECAUgAVABWgZpc0JhY2tiDlBheUZvck9kZXJQYWdl',
            name: 'bool',
            nullable: false,
          )
        },
        actionOutputs: {
          'sucessRazorPay': debugSerializeParam(
            sucessRazorPay,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=PayForOderPage',
            name: 'bool',
            nullable: true,
          ),
          'sucessStripe': debugSerializeParam(
            sucessStripe,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=PayForOderPage',
            name: 'bool',
            nullable: true,
          ),
          'sucessPayPal': debugSerializeParam(
            sucessPayPal,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=PayForOderPage',
            name: 'bool',
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
        dynamicComponentStates: {
          'paymentImagesModels (List<PaymentImages>)':
              paymentImagesModels?.toDynamicWidgetClassDebugData(),
        }.withoutNulls,
        link:
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=PayForOderPage',
        searchReference:
            'reference=Og5QYXlGb3JPZGVyUGFnZVABWg5QYXlGb3JPZGVyUGFnZQ==',
        widgetClassName: 'PayForOderPage',
      );
}
