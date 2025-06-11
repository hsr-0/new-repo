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
import '/index.dart';
import 'dart:async';
import 'sale_products_page_widget.dart' show SaleProductsPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class SaleProductsPageModel extends FlutterFlowModel<SaleProductsPageWidget> {
  ///  Local state fields for this page.

  String _filter = 'null';
  set filter(String value) {
    _filter = value;
    debugLogWidgetClass(this);
  }

  String get filter => _filter;

  ///  State fields for stateful widgets in this page.

  // Model for MainSearchFilterAppbar component.
  late MainSearchFilterAppbarModel mainSearchFilterAppbarModel;
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
    return controller..addPageRequestListener(gridViewSellProductsPage);
  }

  void gridViewSellProductsPage(ApiPagingParams nextPageMarker) =>
      gridViewApiCall!(nextPageMarker).then((gridViewSellProductsResponse) {
        final pageItems = (PlantShopGroup.sellProductsCall.sellProductsList(
                  gridViewSellProductsResponse.jsonBody,
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
                  lastResponse: gridViewSellProductsResponse,
                )
              : null,
        );
      });

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        localStates: {
          'filter': debugSerializeParam(
            filter,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SaleProductsPage',
            searchReference:
                'reference=QhsKDwoGZmlsdGVyEgVxZTc0NSoCEgByBAgDIAFQAVoGZmlsdGVyYhBTYWxlUHJvZHVjdHNQYWdl',
            name: 'String',
            nullable: false,
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=SaleProductsPage',
        searchReference:
            'reference=OhBTYWxlUHJvZHVjdHNQYWdlUAFaEFNhbGVQcm9kdWN0c1BhZ2U=',
        widgetClassName: 'SaleProductsPage',
      );
}
