import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_expanded_image_view.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_component/main_component_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/components/review_component/review_component_widget.dart';
import '/pages/dialog_components/variation_bottom_sheet/variation_bottom_sheet_widget.dart';
import '/pages/shimmer/main_component_shimmer/main_component_shimmer_widget.dart';
import '/pages/shimmer/reviews_shimmer/reviews_shimmer_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'product_detail_page_copy_widget.dart' show ProductDetailPageCopyWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

class ProductDetailPageCopyModel
    extends FlutterFlowModel<ProductDetailPageCopyWidget> {
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

  late LoggableList<String> _list =
      LoggableList(['Hello World', 'Hello World']);
  set list(List<String> value) {
    if (value != null) {
      _list = LoggableList(value);
    }

    debugLogWidgetClass(this);
  }

  List<String> get list => _list?..logger = () => debugLogWidgetClass(this);
  void addToList(String item) => list.add(item);
  void removeFromList(String item) => list.remove(item);
  void removeAtIndexFromList(int index) => list.removeAt(index);
  void insertAtIndexInList(int index, String item) => list.insert(index, item);
  void updateListAtIndex(int index, Function(String) updateFn) =>
      list[index] = updateFn(list[index]);

  bool _process = false;
  set process(bool value) {
    _process = value;
    debugLogWidgetClass(this);
  }

  bool get process => _process;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (Product variations)] action in ProductDetailPageCopy widget.
  ApiCallResponse? _productVariation;
  set productVariation(ApiCallResponse? value) {
    _productVariation = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get productVariation => _productVariation;

  // State field(s) for PageView widget.
  PageController? pageViewController;

  int get pageViewCurrentIndex => pageViewController != null &&
          pageViewController!.hasClients &&
          pageViewController!.page != null
      ? pageViewController!.page!.round()
      : 0;
  // Models for ReviewComponent dynamic component.
  late FlutterFlowDynamicModels<ReviewComponentModel> reviewComponentModels;
  // Models for MainComponent dynamic component.
  late FlutterFlowDynamicModels<MainComponentModel> mainComponentModels1;
  // Models for MainComponent dynamic component.
  late FlutterFlowDynamicModels<MainComponentModel> mainComponentModels2;
  // Model for responseComponent component.
  late ResponseComponentModel responseComponentModel;

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    reviewComponentModels =
        FlutterFlowDynamicModels(() => ReviewComponentModel());
    mainComponentModels1 = FlutterFlowDynamicModels(() => MainComponentModel());
    mainComponentModels2 = FlutterFlowDynamicModels(() => MainComponentModel());
    responseComponentModel =
        createModel(context, () => ResponseComponentModel());

    debugLogWidgetClass(this);
  }

  @override
  void dispose() {
    reviewComponentModels.dispose();
    mainComponentModels1.dispose();
    mainComponentModels2.dispose();
    responseComponentModel.dispose();
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        widgetParameters: {
          'productDetail': debugSerializeParam(
            widget?.productDetail,
            ParamType.JSON,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
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
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
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
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
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
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
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
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
            searchReference:
                'reference=QhsKFQoMZGF0YVRhcEluZGV4EgV4aTl6aHICCAFQAVoMZGF0YVRhcEluZGV4YhVQcm9kdWN0RGV0YWlsUGFnZUNvcHk=',
            name: 'int',
            nullable: true,
          ),
          'qty': debugSerializeParam(
            qty,
            ParamType.int,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
            searchReference:
                'reference=QhQKDAoDcXR5EgVqbTJ0dXIECAEgAVABWgNxdHliFVByb2R1Y3REZXRhaWxQYWdlQ29weQ==',
            name: 'int',
            nullable: false,
          ),
          'list': debugSerializeParam(
            list,
            ParamType.String,
            isList: true,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
            searchReference:
                'reference=QhcKDQoEbGlzdBIFdW5vZ2dyBhICCAMgAVABWgRsaXN0YhVQcm9kdWN0RGV0YWlsUGFnZUNvcHk=',
            name: 'String',
            nullable: false,
          ),
          'process': debugSerializeParam(
            process,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
            searchReference:
                'reference=QiEKEAoHcHJvY2VzcxIFeDlqeG8qBxIFZmFsc2VyBAgFIAFQAVoHcHJvY2Vzc2IVUHJvZHVjdERldGFpbFBhZ2VDb3B5',
            name: 'bool',
            nullable: false,
          )
        },
        widgetStates: {
          'pageViewCurrentIndex': debugSerializeParam(
            pageViewCurrentIndex,
            ParamType.int,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
            name: 'int',
            nullable: true,
          )
        },
        actionOutputs: {
          'productVariation': debugSerializeParam(
            productVariation,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductDetailPageCopy',
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
        dynamicComponentStates: {
          'reviewComponentModels (List<ReviewComponent>)':
              reviewComponentModels?.toDynamicWidgetClassDebugData(),
          'mainComponentModels1 (List<MainComponent>)':
              mainComponentModels1?.toDynamicWidgetClassDebugData(),
          'mainComponentModels2 (List<MainComponent>)':
              mainComponentModels2?.toDynamicWidgetClassDebugData(),
        }.withoutNulls,
        link:
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=ProductDetailPageCopy',
        searchReference:
            'reference=OhVQcm9kdWN0RGV0YWlsUGFnZUNvcHlQAVoVUHJvZHVjdERldGFpbFBhZ2VDb3B5',
        widgetClassName: 'ProductDetailPageCopy',
      );
}
