import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/categories_single_component/categories_single_component_widget.dart';
import '/pages/components/category_appbar/category_appbar_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/empty_components/no_products_component/no_products_component_widget.dart';
import '/pages/shimmer/category_component_shimmer/category_component_shimmer_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/index.dart';
import 'category_component_widget.dart' show CategoryComponentWidget;
import 'dart:async';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class CategoryComponentModel extends FlutterFlowModel<CategoryComponentWidget> {
  ///  Local state fields for this component.

  bool _search = false;
  set search(bool value) {
    _search = value;
    debugLogWidgetClass(this);
  }

  bool get search => _search;

  ///  State fields for stateful widgets in this component.

  // Model for CategoryAppbar component.
  late CategoryAppbarModel categoryAppbarModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  bool apiRequestCompleted = false;
  String? apiRequestLastUniqueKey;
  // Models for CategoriesSingleComponent dynamic component.
  late FlutterFlowDynamicModels<CategoriesSingleComponentModel>
      categoriesSingleComponentModels;
  // Model for NoProductsComponent component.
  late NoProductsComponentModel noProductsComponentModel;
  // Model for responseComponent component.
  late ResponseComponentModel responseComponentModel;

   
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    categoryAppbarModel = createModel(context, () => CategoryAppbarModel());
    categoriesSingleComponentModels =
        FlutterFlowDynamicModels(() => CategoriesSingleComponentModel());
    noProductsComponentModel =
        createModel(context, () => NoProductsComponentModel());
    responseComponentModel =
        createModel(context, () => ResponseComponentModel());
  }

  @override
  void dispose() {
    categoryAppbarModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();

    categoriesSingleComponentModels.dispose();
    noProductsComponentModel.dispose();
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

}
