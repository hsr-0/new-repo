import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_component/main_component_widget.dart';
import '/pages/components/main_search_filter_appbar/main_search_filter_appbar_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/dialog_components/sort_by_bottom_sheet/sort_by_bottom_sheet_widget.dart';
import '/pages/empty_components/no_products_component/no_products_component_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'category_open_page_widget.dart' show CategoryOpenPageWidget;
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class CategoryOpenPageModel extends FlutterFlowModel<CategoryOpenPageWidget> {
  ///  Local state fields for this page.

  String _categorySelected = '0';
  set categorySelected(String value) {
    _categorySelected = value;
    debugLogWidgetClass(this);
  }

  String get categorySelected => _categorySelected;

  bool _process = false;
  set process(bool value) {
    _process = value;
    debugLogWidgetClass(this);
  }

  bool get process => _process;

  String _filter = 'null';
  set filter(String value) {
    _filter = value;
    debugLogWidgetClass(this);
  }

  String get filter => _filter;

  ///  State fields for stateful widgets in this page.

  // Model for MainSearchFilterAppbar component.
  late MainSearchFilterAppbarModel mainSearchFilterAppbarModel;
  // Stores action output result for [Backend Call - API (Category open sub)] action in Container widget.
  ApiCallResponse? _catOpenSub;
  set catOpenSub(ApiCallResponse? value) {
    _catOpenSub = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get catOpenSub => _catOpenSub;

  // State field(s) for GridView widget.

  PagingController<ApiPagingParams, dynamic>? gridViewPagingController;
  Function(ApiPagingParams nextPageMarker)? gridViewApiCall;

  // Models for MainComponent dynamic component.
  late FlutterFlowDynamicModels<MainComponentModel> mainComponentModels;
  // Model for responseComponent component.
  late ResponseComponentModel responseComponentModel;

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    mainSearchFilterAppbarModel =
        createModel(context, () => MainSearchFilterAppbarModel());
    mainComponentModels = FlutterFlowDynamicModels(() => MainComponentModel());
    responseComponentModel =
        createModel(context, () => ResponseComponentModel());

    debugLogWidgetClass(this);
  }

  @override
  void dispose() {
    mainSearchFilterAppbarModel.dispose();
    gridViewPagingController?.dispose();
    mainComponentModels.dispose();
    responseComponentModel.dispose();
  }

  /// Additional helper methods.
  Future waitForOnePageForGridView({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete =
          (gridViewPagingController?.nextPageKey?.nextPageNumber ?? 0) > 0;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  PagingController<ApiPagingParams, dynamic> setGridViewController(
    Function(ApiPagingParams) apiCall,
  ) {
    gridViewApiCall = apiCall;
    return gridViewPagingController ??= _createGridViewController(apiCall);
  }

  PagingController<ApiPagingParams, dynamic> _createGridViewController(
    Function(ApiPagingParams) query,
  ) {
    final controller = PagingController<ApiPagingParams, dynamic>(
      firstPageKey: ApiPagingParams(
        nextPageNumber: 0,
        numItems: 0,
        lastResponse: null,
      ),
    );
    return controller..addPageRequestListener(gridViewCategoryOpenPage);
  }

  void gridViewCategoryOpenPage(ApiPagingParams nextPageMarker) =>
      gridViewApiCall!(nextPageMarker).then((gridViewCategoryOpenResponse) {
        final pageItems = (PlantShopGroup.categoryOpenCall.categoryOpenList(
                  gridViewCategoryOpenResponse.jsonBody,
                )! ??
                [])
            .toList() as List;
        final newNumItems = nextPageMarker.numItems + pageItems.length;
        gridViewPagingController?.appendPage(
          pageItems,
          (pageItems.length > 0)
              ? ApiPagingParams(
                  nextPageNumber: nextPageMarker.nextPageNumber + 1,
                  numItems: newNumItems,
                  lastResponse: gridViewCategoryOpenResponse,
                )
              : null,
        );
      });

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        widgetParameters: {
          'title': debugSerializeParam(
            widget?.title,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryOpenPage',
            searchReference:
                'reference=ShcKDwoFdGl0bGUSBjU0djB3MHIECAMgAVABWgV0aXRsZQ==',
            name: 'String',
            nullable: true,
          ),
          'catId': debugSerializeParam(
            widget?.catId,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryOpenPage',
            searchReference:
                'reference=ShcKDwoFY2F0SWQSBnR5cHFmc3IECAMgAVABWgVjYXRJZA==',
            name: 'String',
            nullable: true,
          ),
          'cateImage': debugSerializeParam(
            widget?.cateImage,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryOpenPage',
            searchReference:
                'reference=ShsKEwoJY2F0ZUltYWdlEgY5Y2wyMGRyBAgEIAFQAVoJY2F0ZUltYWdl',
            name: 'String',
            nullable: true,
          )
        }.withoutNulls,
        localStates: {
          'categorySelected': debugSerializeParam(
            categorySelected,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryOpenPage',
            searchReference:
                'reference=QiUKGQoQY2F0ZWdvcnlTZWxlY3RlZBIFZ2gzM2YqAhIAcgQIAyABUAFaEGNhdGVnb3J5U2VsZWN0ZWRiEENhdGVnb3J5T3BlblBhZ2U=',
            name: 'String',
            nullable: false,
          ),
          'process': debugSerializeParam(
            process,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryOpenPage',
            searchReference:
                'reference=QiEKEAoHcHJvY2VzcxIFbmk0M3YqBxIFZmFsc2VyBAgFIAFQAVoHcHJvY2Vzc2IQQ2F0ZWdvcnlPcGVuUGFnZQ==',
            name: 'bool',
            nullable: false,
          ),
          'filter': debugSerializeParam(
            filter,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryOpenPage',
            searchReference:
                'reference=QhsKDwoGZmlsdGVyEgU4emd4ZCoCEgByBAgDIAFQAVoGZmlsdGVyYhBDYXRlZ29yeU9wZW5QYWdl',
            name: 'String',
            nullable: false,
          )
        },
        actionOutputs: {
          'catOpenSub': debugSerializeParam(
            catOpenSub,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoryOpenPage',
            name: 'ApiCallResponse',
            nullable: true,
          )
        },
        generatorVariables: debugGeneratorVariables,
        backendQueries: debugBackendQueries,
        componentStates: {
          'mainSearchFilterAppbarModel (MainSearchFilterAppbar)':
              mainSearchFilterAppbarModel?.toWidgetClassDebugData(),
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=CategoryOpenPage',
        searchReference:
            'reference=OhBDYXRlZ29yeU9wZW5QYWdlUAFaEENhdGVnb3J5T3BlblBhZ2U=',
        widgetClassName: 'CategoryOpenPage',
      );
}
