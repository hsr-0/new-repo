import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/dialog_components/variation_bottom_sheet/variation_bottom_sheet_widget.dart';
import '/pages/product_detail_flow/detail_component/detail_component_widget.dart';
import '/pages/product_detail_flow/image_component/image_component_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'product_detail_page_widget.dart' show ProductDetailPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class ProductDetailPageModel extends FlutterFlowModel<ProductDetailPageWidget> {
  ///  Local state fields for this page.

  int? _dataTapIndex = 0;
  set dataTapIndex(int? value) {
    _dataTapIndex = value;
    debugLogWidgetClass(this);
  }

  int? get dataTapIndex => _dataTapIndex;

  int _qty = 1;
  set qty(int value) {
    _qty = value;
    debugLogWidgetClass(this);
  }

  int get qty => _qty;

  bool _process = false;
  set process(bool value) {
    _process = value;
    debugLogWidgetClass(this);
  }

  bool get process => _process;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (Product variations)] action in ProductDetailPage widget.
  ApiCallResponse? _productVariation;
  set productVariation(ApiCallResponse? value) {
    _productVariation = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get productVariation => _productVariation;

  // Model for responseComponent component.
  late ResponseComponentModel responseComponentModel;

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    responseComponentModel =
        createModel(context, () => ResponseComponentModel());

    debugLogWidgetClass(this);
  }

  @override
  void dispose() {
    responseComponentModel.dispose();
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        widgetParameters: {
          'productDetail': debugSerializeParam(
            widget?.productDetail,
            ParamType.JSON,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPage',
            searchReference:
                'reference=Sh8KFwoNcHJvZHVjdERldGFpbBIGdG1wNjU3cgQICSABUAFaDXByb2R1Y3REZXRhaWw=',
            name: 'dynamic',
            nullable: true,
          ),
          'upsellIdsList': debugSerializeParam(
            widget?.upsellIdsList,
            ParamType.String,
            isList: true,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPage',
            searchReference:
                'reference=SiEKFwoNdXBzZWxsSWRzTGlzdBIGZTV3ZnJpcgYSAggDIAFQAVoNdXBzZWxsSWRzTGlzdA==',
            name: 'String',
            nullable: true,
          ),
          'relatedIdsList': debugSerializeParam(
            widget?.relatedIdsList,
            ParamType.String,
            isList: true,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPage',
            searchReference:
                'reference=SiIKGAoOcmVsYXRlZElkc0xpc3QSBnQ0MnNqd3IGEgIIAyABUAFaDnJlbGF0ZWRJZHNMaXN0',
            name: 'String',
            nullable: true,
          ),
          'imagesList': debugSerializeParam(
            widget?.imagesList,
            ParamType.JSON,
            isList: true,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPage',
            searchReference:
                'reference=Sh4KFAoKaW1hZ2VzTGlzdBIGaWowZnA4cgYSAggJIAFQAVoKaW1hZ2VzTGlzdA==',
            name: 'dynamic',
            nullable: true,
          )
        }.withoutNulls,
        localStates: {
          'dataTapIndex': debugSerializeParam(
            dataTapIndex,
            ParamType.int,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPage',
            searchReference:
                'reference=QhsKFQoMZGF0YVRhcEluZGV4EgV4aTl6aHICCAFQAVoMZGF0YVRhcEluZGV4YhFQcm9kdWN0RGV0YWlsUGFnZQ==',
            name: 'int',
            nullable: true,
          ),
          'qty': debugSerializeParam(
            qty,
            ParamType.int,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPage',
            searchReference:
                'reference=QhQKDAoDcXR5EgVqbTJ0dXIECAEgAVABWgNxdHliEVByb2R1Y3REZXRhaWxQYWdl',
            name: 'int',
            nullable: false,
          ),
          'process': debugSerializeParam(
            process,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPage',
            searchReference:
                'reference=QiEKEAoHcHJvY2VzcxIFeDlqeG8qBxIFZmFsc2VyBAgFIAFQAVoHcHJvY2Vzc2IRUHJvZHVjdERldGFpbFBhZ2U=',
            name: 'bool',
            nullable: false,
          )
        },
        actionOutputs: {
          'productVariation': debugSerializeParam(
            productVariation,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPage',
            name: 'ApiCallResponse',
            nullable: true,
          )
        },
        generatorVariables: debugGeneratorVariables,
        backendQueries: debugBackendQueries,
        componentStates: {
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=ProductDetailPage',
        searchReference:
            'reference=OhFQcm9kdWN0RGV0YWlsUGFnZVABWhFQcm9kdWN0RGV0YWlsUGFnZQ==',
        widgetClassName: 'ProductDetailPage',
      );
}
