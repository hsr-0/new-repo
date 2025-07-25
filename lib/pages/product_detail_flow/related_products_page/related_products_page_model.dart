import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/main_component/main_component_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/empty_components/no_products_component/no_products_component_widget.dart';
import '/pages/shimmer/main_component_shimmer/main_component_shimmer_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/index.dart';
import 'related_products_page_widget.dart' show RelatedProductsPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class RelatedProductsPageModel
    extends FlutterFlowModel<RelatedProductsPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for MainAppbar component.
  late MainAppbarModel mainAppbarModel;
  // Models for MainComponent dynamic component.
  late FlutterFlowDynamicModels<MainComponentModel> mainComponentModels;
  // Model for responseComponent component.
  late ResponseComponentModel responseComponentModel;

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    mainAppbarModel = createModel(context, () => MainAppbarModel());
    mainComponentModels = FlutterFlowDynamicModels(() => MainComponentModel());
    responseComponentModel =
        createModel(context, () => ResponseComponentModel());

    debugLogWidgetClass(this);
  }

  @override
  void dispose() {
    mainAppbarModel.dispose();
    mainComponentModels.dispose();
    responseComponentModel.dispose();
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        widgetParameters: {
          'relatedProductList': debugSerializeParam(
            widget?.relatedProductList,
            ParamType.String,
            isList: true,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=RelatedProductsPage',
            searchReference:
                'reference=SiYKHAoScmVsYXRlZFByb2R1Y3RMaXN0EgYxZnNkczVyBhICCAMgAVABWhJyZWxhdGVkUHJvZHVjdExpc3Q=',
            name: 'String',
            nullable: true,
          )
        }.withoutNulls,
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
          'mainComponentModels (List<MainComponent>)':
              mainComponentModels?.toDynamicWidgetClassDebugData(),
        }.withoutNulls,
        link:
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=RelatedProductsPage',
        searchReference:
            'reference=OhNSZWxhdGVkUHJvZHVjdHNQYWdlUAFaE1JlbGF0ZWRQcm9kdWN0c1BhZ2U=',
        widgetClassName: 'RelatedProductsPage',
      );
}
