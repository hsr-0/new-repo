import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/main_component/main_component_widget.dart';
import '/pages/components/review_component/review_component_widget.dart';
import '/pages/shimmer/main_component_shimmer/main_component_shimmer_widget.dart';
import '/pages/shimmer/reviews_shimmer/reviews_shimmer_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'detail_component_widget.dart' show DetailComponentWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DetailComponentModel extends FlutterFlowModel<DetailComponentWidget> {
  ///  Local state fields for this component.

  int _dataTapIndex = 0;
  set dataTapIndex(int value) {
    _dataTapIndex = value;
    debugLogWidgetClass(this);
  }

  int get dataTapIndex => _dataTapIndex;

  ///  State fields for stateful widgets in this component.

  // Models for ReviewComponent dynamic component.
  late FlutterFlowDynamicModels<ReviewComponentModel> reviewComponentModels;
  // Models for MainComponent dynamic component.
  late FlutterFlowDynamicModels<MainComponentModel> mainComponentModels1;
  // Models for MainComponent dynamic component.
  late FlutterFlowDynamicModels<MainComponentModel> mainComponentModels2;

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    reviewComponentModels =
        FlutterFlowDynamicModels(() => ReviewComponentModel());
    mainComponentModels1 = FlutterFlowDynamicModels(() => MainComponentModel());
    mainComponentModels2 = FlutterFlowDynamicModels(() => MainComponentModel());
  }

  @override
  void dispose() {
    reviewComponentModels.dispose();
    mainComponentModels1.dispose();
    mainComponentModels2.dispose();
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        widgetParameters: {
          'productDetail': debugSerializeParam(
            widget?.productDetail,
            ParamType.JSON,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=DetailComponent',
            searchReference:
                'reference=Sh8KFwoNcHJvZHVjdERldGFpbBIGcjduaXB0cgQICSABUABaDXByb2R1Y3REZXRhaWw=',
            name: 'dynamic',
            nullable: true,
          ),
          'upsellIdsList': debugSerializeParam(
            widget?.upsellIdsList,
            ParamType.String,
            isList: true,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=DetailComponent',
            searchReference:
                'reference=SiEKFwoNdXBzZWxsSWRzTGlzdBIGMjV2OWw5cgYSAggDIAFQAFoNdXBzZWxsSWRzTGlzdA==',
            name: 'String',
            nullable: true,
          ),
          'relatedIdsList': debugSerializeParam(
            widget?.relatedIdsList,
            ParamType.String,
            isList: true,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=DetailComponent',
            searchReference:
                'reference=SiIKGAoOcmVsYXRlZElkc0xpc3QSBmVueXprZ3IGEgIIAyABUABaDnJlbGF0ZWRJZHNMaXN0',
            name: 'String',
            nullable: true,
          ),
          'variationsList': debugSerializeParam(
            widget?.variationsList,
            ParamType.JSON,
            isList: true,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=DetailComponent',
            searchReference:
                'reference=SiIKGAoOdmFyaWF0aW9uc0xpc3QSBjAwYmJtaXIGEgIICSABUABaDnZhcmlhdGlvbnNMaXN0',
            name: 'dynamic',
            nullable: true,
          ),
          'priceList': debugSerializeParam(
            widget?.priceList,
            ParamType.String,
            isList: true,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=DetailComponent',
            searchReference:
                'reference=Sh0KEwoJcHJpY2VMaXN0EgZjOWI2Z3RyBhICCAMgAFAAWglwcmljZUxpc3Q=',
            name: 'String',
            nullable: true,
          )
        }.withoutNulls,
        localStates: {
          'dataTapIndex': debugSerializeParam(
            dataTapIndex,
            ParamType.int,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=DetailComponent',
            searchReference:
                'reference=Qh0KFQoMZGF0YVRhcEluZGV4EgV2bXhld3IECAEgAVAAWgxkYXRhVGFwSW5kZXhiD0RldGFpbENvbXBvbmVudA==',
            name: 'int',
            nullable: false,
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
        dynamicComponentStates: {
          'reviewComponentModels (List<ReviewComponent>)':
              reviewComponentModels?.toDynamicWidgetClassDebugData(),
          'mainComponentModels1 (List<MainComponent>)':
              mainComponentModels1?.toDynamicWidgetClassDebugData(),
          'mainComponentModels2 (List<MainComponent>)':
              mainComponentModels2?.toDynamicWidgetClassDebugData(),
        }.withoutNulls,
        link:
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=DetailComponent',
        searchReference:
            'reference=Og9EZXRhaWxDb21wb25lbnRQAFoPRGV0YWlsQ29tcG9uZW50',
        widgetClassName: 'DetailComponent',
      );
}
