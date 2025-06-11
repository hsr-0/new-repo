import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/payment_images/payment_images_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/empty_components/no_payment_methodes_component/no_payment_methodes_component_widget.dart';
import '/pages/shimmer/cart_shimmer/cart_shimmer_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'checkout_page_widget.dart' show CheckoutPageWidget;
import 'dart:async';
import 'package:styled_divider/styled_divider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class CheckoutPageModel extends FlutterFlowModel<CheckoutPageWidget> {
  ///  Local state fields for this page.

  bool _differentShip = true;
  set differentShip(bool value) {
    _differentShip = value;
    debugLogWidgetClass(this);
  }

  bool get differentShip => _differentShip;

  bool _process = false;
  set process(bool value) {
    _process = value;
    debugLogWidgetClass(this);
  }

  bool get process => _process;

  String? _select;
  set select(String? value) {
    _select = value;
    debugLogWidgetClass(this);
  }

  String? get select => _select;

  dynamic _selectedMethode;
  set selectedMethode(dynamic value) {
    _selectedMethode = value;
    debugLogWidgetClass(this);
  }

  dynamic get selectedMethode => _selectedMethode;

  ///  State fields for stateful widgets in this page.

  // Model for MainAppbar component.
  late MainAppbarModel mainAppbarModel;
  bool apiRequestCompleted = false;
  String? apiRequestLastUniqueKey;
  // Stores action output result for [Backend Call - API (Edit shipping address)] action in Row widget.
  ApiCallResponse? _shippingAddress;
  set shippingAddress(ApiCallResponse? value) {
    _shippingAddress = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get shippingAddress => _shippingAddress;

  // Stores action output result for [Action Block - GetCustomer] action in Row widget.
  bool? _success;
  set success(bool? value) {
    _success = value;
    debugLogWidgetClass(this);
  }

  bool? get success => _success;

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Backend Call - API (Apply coupon code)] action in Button widget.
  ApiCallResponse? _applyCode;
  set applyCode(ApiCallResponse? value) {
    _applyCode = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get applyCode => _applyCode;

  // Stores action output result for [Backend Call - API (Remove coupon code)] action in Text widget.
  ApiCallResponse? _removeCoupon;
  set removeCoupon(ApiCallResponse? value) {
    _removeCoupon = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get removeCoupon => _removeCoupon;

  // Stores action output result for [Backend Call - API (Update shipping)] action in Container widget.
  ApiCallResponse? _updateShipping;
  set updateShipping(ApiCallResponse? value) {
    _updateShipping = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get updateShipping => _updateShipping;

  // Models for PaymentImages dynamic component.
  late FlutterFlowDynamicModels<PaymentImagesModel> paymentImagesModels;
  // Stores action output result for [Action Block - CreateOrder] action in Button widget.
  dynamic? _orderDetailCod;
  set orderDetailCod(dynamic? value) {
    _orderDetailCod = value;
    debugLogWidgetClass(this);
  }

  dynamic? get orderDetailCod => _orderDetailCod;

  // Stores action output result for [Action Block - CreateOrder] action in Button widget.
  dynamic? _orderDetailRazorpay;
  set orderDetailRazorpay(dynamic? value) {
    _orderDetailRazorpay = value;
    debugLogWidgetClass(this);
  }

  dynamic? get orderDetailRazorpay => _orderDetailRazorpay;

  // Stores action output result for [Action Block - CreateOrder] action in Button widget.
  dynamic? _orderDetailStripe;
  set orderDetailStripe(dynamic? value) {
    _orderDetailStripe = value;
    debugLogWidgetClass(this);
  }

  dynamic? get orderDetailStripe => _orderDetailStripe;

  // Stores action output result for [Action Block - CreateOrder] action in Button widget.
  dynamic? _orderDetailPayPal;
  set orderDetailPayPal(dynamic? value) {
    _orderDetailPayPal = value;
    debugLogWidgetClass(this);
  }

  dynamic? get orderDetailPayPal => _orderDetailPayPal;

  // Stores action output result for [Action Block - CreateOrder] action in Button widget.
  dynamic? _orderDetailWebview;
  set orderDetailWebview(dynamic? value) {
    _orderDetailWebview = value;
    debugLogWidgetClass(this);
  }

  dynamic? get orderDetailWebview => _orderDetailWebview;

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
    textFieldFocusNode?.dispose();
    textController?.dispose();

    paymentImagesModels.dispose();
    responseComponentModel.dispose();
  }

  /// Additional helper methods.
  Future waitForApiRequestCompleted({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleted;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        localStates: {
          'differentShip': debugSerializeParam(
            differentShip,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
            searchReference:
                'reference=QicKFgoNZGlmZmVyZW50U2hpcBIFbW84OXMqBxIFZmFsc2VyBAgFIAFQAVoNZGlmZmVyZW50U2hpcGIMQ2hlY2tvdXRQYWdl',
            name: 'bool',
            nullable: false,
          ),
          'process': debugSerializeParam(
            process,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
            searchReference:
                'reference=QiEKEAoHcHJvY2VzcxIFODlmMTMqBxIFZmFsc2VyBAgFIAFQAVoHcHJvY2Vzc2IMQ2hlY2tvdXRQYWdl',
            name: 'bool',
            nullable: false,
          ),
          'select': debugSerializeParam(
            select,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
            searchReference:
                'reference=QhsKDwoGc2VsZWN0EgVmaXFuZSoCEgByBAgDIABQAVoGc2VsZWN0YgxDaGVja291dFBhZ2U=',
            name: 'String',
            nullable: true,
          ),
          'selectedMethode': debugSerializeParam(
            selectedMethode,
            ParamType.JSON,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
            searchReference:
                'reference=Qh4KGAoPc2VsZWN0ZWRNZXRob2RlEgVwYW9scHICCAlQAVoPc2VsZWN0ZWRNZXRob2RlYgxDaGVja291dFBhZ2U=',
            name: 'dynamic',
            nullable: true,
          )
        },
        widgetStates: {
          'textFieldText': debugSerializeParam(
            textController?.text,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
            name: 'String',
            nullable: true,
          )
        },
        actionOutputs: {
          'shippingAddress': debugSerializeParam(
            shippingAddress,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
            name: 'ApiCallResponse',
            nullable: true,
          ),
          'success': debugSerializeParam(
            success,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
            name: 'bool',
            nullable: true,
          ),
          'applyCode': debugSerializeParam(
            applyCode,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
            name: 'ApiCallResponse',
            nullable: true,
          ),
          'removeCoupon': debugSerializeParam(
            removeCoupon,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
            name: 'ApiCallResponse',
            nullable: true,
          ),
          'updateShipping': debugSerializeParam(
            updateShipping,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
            name: 'ApiCallResponse',
            nullable: true,
          ),
          'orderDetailCod': debugSerializeParam(
            orderDetailCod,
            ParamType.JSON,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
            name: 'dynamic',
            nullable: true,
          ),
          'orderDetailRazorpay': debugSerializeParam(
            orderDetailRazorpay,
            ParamType.JSON,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
            name: 'dynamic',
            nullable: true,
          ),
          'orderDetailStripe': debugSerializeParam(
            orderDetailStripe,
            ParamType.JSON,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
            name: 'dynamic',
            nullable: true,
          ),
          'orderDetailPayPal': debugSerializeParam(
            orderDetailPayPal,
            ParamType.JSON,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
            name: 'dynamic',
            nullable: true,
          ),
          'orderDetailWebview': debugSerializeParam(
            orderDetailWebview,
            ParamType.JSON,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CheckoutPage',
            name: 'dynamic',
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=CheckoutPage',
        searchReference: 'reference=OgxDaGVja291dFBhZ2VQAVoMQ2hlY2tvdXRQYWdl',
        widgetClassName: 'CheckoutPage',
      );
}
