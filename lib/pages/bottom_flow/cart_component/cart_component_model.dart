import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/center_appbar/center_appbar_widget.dart';
import '/pages/components/main_component/main_component_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/dialog_components/cart_item_delete_component/cart_item_delete_component_widget.dart';
import '/pages/empty_components/no_cart_component/no_cart_component_widget.dart';
import '/pages/shimmer/cart_shimmer/cart_shimmer_widget.dart';
import '/pages/shimmer/main_component_shimmer/main_component_shimmer_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'cart_component_widget.dart' show CartComponentWidget;
import 'dart:async';
import 'package:styled_divider/styled_divider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class CartComponentModel extends FlutterFlowModel<CartComponentWidget> {
  ///  Local state fields for this component.

  int _shipping = 0;
  set shipping(int value) {
    _shipping = value;
    debugLogWidgetClass(this);
  }

  int get shipping => _shipping;

  bool _process = false;
  set process(bool value) {
    _process = value;
    debugLogWidgetClass(this);
  }

  bool get process => _process;

  String _keyId = '5';
  set keyId(String value) {
    _keyId = value;
    debugLogWidgetClass(this);
  }

  String get keyId => _keyId;

  bool _mainProcess = false;
  set mainProcess(bool value) {
    _mainProcess = value;
    debugLogWidgetClass(this);
  }

  bool get mainProcess => _mainProcess;

  ///  State fields for stateful widgets in this component.

  // Model for CenterAppbar component.
  late CenterAppbarModel centerAppbarModel;
  bool apiRequestCompleted = false;
  String? apiRequestLastUniqueKey;
  // Stores action output result for [Action Block - DeleteCartItem] action in Container widget.
  bool? _success;
  set success(bool? value) {
    _success = value;
    debugLogWidgetClass(this);
  }

  bool? get success => _success;

  // Stores action output result for [Backend Call - API (Remove coupon code)] action in Container widget.
  ApiCallResponse? _removeCouponCopy;
  set removeCouponCopy(ApiCallResponse? value) {
    _removeCouponCopy = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get removeCouponCopy => _removeCouponCopy;

  // Stores action output result for [Action Block - UpdateCart] action in Container widget.
  bool? _successUpdate;
  set successUpdate(bool? value) {
    _successUpdate = value;
    debugLogWidgetClass(this);
  }

  bool? get successUpdate => _successUpdate;

  // Stores action output result for [Action Block - UpdateCart] action in Container widget.
  bool? _successUpdateCopy;
  set successUpdateCopy(bool? value) {
    _successUpdateCopy = value;
    debugLogWidgetClass(this);
  }

  bool? get successUpdateCopy => _successUpdateCopy;

  // Models for MainComponent dynamic component.
  late FlutterFlowDynamicModels<MainComponentModel> mainComponentModels;
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

  // Model for NoCartComponent component.
  late NoCartComponentModel noCartComponentModel;
  // Model for responseComponent component.
  late ResponseComponentModel responseComponentModel;

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    centerAppbarModel = createModel(context, () => CenterAppbarModel());
    mainComponentModels = FlutterFlowDynamicModels(() => MainComponentModel());
    noCartComponentModel = createModel(context, () => NoCartComponentModel());
    responseComponentModel =
        createModel(context, () => ResponseComponentModel());
  }

  @override
  void dispose() {
    centerAppbarModel.dispose();
    mainComponentModels.dispose();
    noCartComponentModel.dispose();
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
        widgetParameters: {
          'isBack': debugSerializeParam(
            widget?.isBack,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
            searchReference:
                'reference=SiEKEAoGaXNCYWNrEgZ4Y2FvcHYqBxIFZmFsc2VyBAgFIAFQAFoGaXNCYWNr',
            name: 'bool',
            nullable: false,
          )
        }.withoutNulls,
        localStates: {
          'shipping': debugSerializeParam(
            shipping,
            ParamType.int,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
            searchReference:
                'reference=QhkKEQoIc2hpcHBpbmcSBTl4OWk5cgQIASABUABaCHNoaXBwaW5nYg1DYXJ0Q29tcG9uZW50',
            name: 'int',
            nullable: false,
          ),
          'process': debugSerializeParam(
            process,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
            searchReference:
                'reference=QhgKEAoHcHJvY2VzcxIFbHh6MWhyBAgFIAFQAFoHcHJvY2Vzc2INQ2FydENvbXBvbmVudA==',
            name: 'bool',
            nullable: false,
          ),
          'keyId': debugSerializeParam(
            keyId,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
            searchReference:
                'reference=QhoKDgoFa2V5SWQSBTk4NGgyKgISAHIECAMgAVAAWgVrZXlJZGINQ2FydENvbXBvbmVudA==',
            name: 'String',
            nullable: false,
          ),
          'mainProcess': debugSerializeParam(
            mainProcess,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
            searchReference:
                'reference=QiUKFAoLbWFpblByb2Nlc3MSBXFzc2JzKgcSBWZhbHNlcgQIBSABUABaC21haW5Qcm9jZXNzYg1DYXJ0Q29tcG9uZW50',
            name: 'bool',
            nullable: false,
          )
        },
        actionOutputs: {
          'success': debugSerializeParam(
            success,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
            name: 'bool',
            nullable: true,
          ),
          'removeCouponCopy': debugSerializeParam(
            removeCouponCopy,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
            name: 'ApiCallResponse',
            nullable: true,
          ),
          'successUpdate': debugSerializeParam(
            successUpdate,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
            name: 'bool',
            nullable: true,
          ),
          'successUpdateCopy': debugSerializeParam(
            successUpdateCopy,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
            name: 'bool',
            nullable: true,
          ),
          'removeCoupon': debugSerializeParam(
            removeCoupon,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
            name: 'ApiCallResponse',
            nullable: true,
          ),
          'updateShipping': debugSerializeParam(
            updateShipping,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartComponent',
            name: 'ApiCallResponse',
            nullable: true,
          )
        },
        generatorVariables: debugGeneratorVariables,
        backendQueries: debugBackendQueries,
        componentStates: {
          'centerAppbarModel (CenterAppbar)':
              centerAppbarModel?.toWidgetClassDebugData(),
          'noCartComponentModel (NoCartComponent)':
              noCartComponentModel?.toWidgetClassDebugData(),
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
          'mainComponentModels (List<MainComponent>)':
              mainComponentModels?.toDynamicWidgetClassDebugData(),
        }.withoutNulls,
        link:
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=CartComponent',
        searchReference:
            'reference=Og1DYXJ0Q29tcG9uZW50UABaDUNhcnRDb21wb25lbnQ=',
        widgetClassName: 'CartComponent',
      );
}
