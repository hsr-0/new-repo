import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/components/categories_single_home_component/categories_single_home_component_widget.dart';
import '/pages/components/logo_component/logo_component_widget.dart';
import '/pages/components/main_component/main_component_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/shimmer/banner_shimmer/banner_shimmer_widget.dart';
import '/pages/shimmer/big_saving_shimmer/big_saving_shimmer_widget.dart';
import '/pages/shimmer/blog_shimmer/blog_shimmer_widget.dart';
import '/pages/shimmer/category_shimmer/category_shimmer_widget.dart';
import '/pages/shimmer/products_hore_shimmer/products_hore_shimmer_widget.dart';
import '/pages/shimmer/sale_products_shimmer/sale_products_shimmer_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'home_component_widget.dart' show HomeComponentWidget;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class HomeComponentModel extends FlutterFlowModel<HomeComponentWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for LogoComponent component.
  late LogoComponentModel logoComponentModel;
  bool apiRequestCompleted7 = false;
  String? apiRequestLastUniqueKey7;
  bool apiRequestCompleted1 = false;
  String? apiRequestLastUniqueKey1;
  bool apiRequestCompleted9 = false;
  String? apiRequestLastUniqueKey9;
  bool apiRequestCompleted5 = false;
  String? apiRequestLastUniqueKey5;
  bool apiRequestCompleted3 = false;
  String? apiRequestLastUniqueKey3;
  bool apiRequestCompleted6 = false;
  String? apiRequestLastUniqueKey6;
  bool apiRequestCompleted4 = false;
  String? apiRequestLastUniqueKey4;
  bool apiRequestCompleted2 = false;
  String? apiRequestLastUniqueKey2;
  bool apiRequestCompleted10 = false;
  String? apiRequestLastUniqueKey10;
  bool apiRequestCompleted8 = false;
  String? apiRequestLastUniqueKey8;
  // State field(s) for Carousel widget.
  CarouselSliderController? carouselController1;
  int _carouselCurrentIndex1 = 1;
  set carouselCurrentIndex1(int value) {
    _carouselCurrentIndex1 = value;
    debugLogWidgetClass(this);
  }

  int get carouselCurrentIndex1 => _carouselCurrentIndex1;

  // Models for CategoriesSingleHomeComponent dynamic component.
  late FlutterFlowDynamicModels<CategoriesSingleHomeComponentModel>
      categoriesSingleHomeComponentModels;
  // Models for MainComponent dynamic component.
  late FlutterFlowDynamicModels<MainComponentModel> mainComponentModels1;
  // Models for MainComponent dynamic component.
  late FlutterFlowDynamicModels<MainComponentModel> mainComponentModels2;
  // State field(s) for Carousel widget.
  CarouselSliderController? carouselController2;
  int _carouselCurrentIndex2 = 1;
  set carouselCurrentIndex2(int value) {
    _carouselCurrentIndex2 = value;
    debugLogWidgetClass(this);
  }

  int get carouselCurrentIndex2 => _carouselCurrentIndex2;

  // Models for MainComponent dynamic component.
  late FlutterFlowDynamicModels<MainComponentModel> mainComponentModels3;
  // Models for MainComponent dynamic component.
  late FlutterFlowDynamicModels<MainComponentModel> mainComponentModels4;
  // State field(s) for Carousel widget.
  CarouselSliderController? carouselController3;
  int _carouselCurrentIndex3 = 1;
  set carouselCurrentIndex3(int value) {
    _carouselCurrentIndex3 = value;
    debugLogWidgetClass(this);
  }

  int get carouselCurrentIndex3 => _carouselCurrentIndex3;

  // Models for MainComponent dynamic component.
  late FlutterFlowDynamicModels<MainComponentModel> mainComponentModels5;
  // Model for responseComponent component.
  late ResponseComponentModel responseComponentModel;

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    logoComponentModel = createModel(context, () => LogoComponentModel());
    categoriesSingleHomeComponentModels =
        FlutterFlowDynamicModels(() => CategoriesSingleHomeComponentModel());
    mainComponentModels1 = FlutterFlowDynamicModels(() => MainComponentModel());
    mainComponentModels2 = FlutterFlowDynamicModels(() => MainComponentModel());
    mainComponentModels3 = FlutterFlowDynamicModels(() => MainComponentModel());
    mainComponentModels4 = FlutterFlowDynamicModels(() => MainComponentModel());
    mainComponentModels5 = FlutterFlowDynamicModels(() => MainComponentModel());
    responseComponentModel =
        createModel(context, () => ResponseComponentModel());
  }

  @override
  void dispose() {
    logoComponentModel.dispose();
    categoriesSingleHomeComponentModels.dispose();
    mainComponentModels1.dispose();
    mainComponentModels2.dispose();
    mainComponentModels3.dispose();
    mainComponentModels4.dispose();
    mainComponentModels5.dispose();
    responseComponentModel.dispose();
  }

  /// Additional helper methods.
  Future waitForApiRequestCompleted7({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleted7;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  Future waitForApiRequestCompleted1({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleted1;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  Future waitForApiRequestCompleted9({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleted9;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  Future waitForApiRequestCompleted5({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleted5;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  Future waitForApiRequestCompleted3({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleted3;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  Future waitForApiRequestCompleted6({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleted6;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  Future waitForApiRequestCompleted4({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleted4;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  Future waitForApiRequestCompleted2({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleted2;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  Future waitForApiRequestCompleted10({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleted10;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  Future waitForApiRequestCompleted8({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleted8;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        widgetStates: {
          'carouselCurrentIndex1': debugSerializeParam(
            carouselCurrentIndex1,
            ParamType.int,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
            name: 'int',
            nullable: true,
          ),
          'carouselCurrentIndex2': debugSerializeParam(
            carouselCurrentIndex2,
            ParamType.int,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
            name: 'int',
            nullable: true,
          ),
          'carouselCurrentIndex3': debugSerializeParam(
            carouselCurrentIndex3,
            ParamType.int,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=HomeComponent',
            name: 'int',
            nullable: true,
          )
        },
        generatorVariables: debugGeneratorVariables,
        backendQueries: debugBackendQueries,
        componentStates: {
          'logoComponentModel (LogoComponent)':
              logoComponentModel?.toWidgetClassDebugData(),
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
          'categoriesSingleHomeComponentModels (List<CategoriesSingleHomeComponent>)':
              categoriesSingleHomeComponentModels
                  ?.toDynamicWidgetClassDebugData(),
          'mainComponentModels1 (List<MainComponent>)':
              mainComponentModels1?.toDynamicWidgetClassDebugData(),
          'mainComponentModels2 (List<MainComponent>)':
              mainComponentModels2?.toDynamicWidgetClassDebugData(),
          'mainComponentModels3 (List<MainComponent>)':
              mainComponentModels3?.toDynamicWidgetClassDebugData(),
          'mainComponentModels4 (List<MainComponent>)':
              mainComponentModels4?.toDynamicWidgetClassDebugData(),
          'mainComponentModels5 (List<MainComponent>)':
              mainComponentModels5?.toDynamicWidgetClassDebugData(),
        }.withoutNulls,
        link:
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=HomeComponent',
        searchReference:
            'reference=Og1Ib21lQ29tcG9uZW50UABaDUhvbWVDb21wb25lbnQ=',
        widgetClassName: 'HomeComponent',
      );
}
