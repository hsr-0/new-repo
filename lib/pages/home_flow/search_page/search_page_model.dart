import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/empty_components/no_search_component/no_search_component_widget.dart';
import '/pages/shimmer/search_shimmer/search_shimmer_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'search_page_widget.dart' show SearchPageWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class SearchPageModel extends FlutterFlowModel<SearchPageWidget> {
  ///  Local state fields for this page.

  bool _isSearch = false;
  set isSearch(bool value) {
    _isSearch = value;
    debugLogWidgetClass(this);
  }

  bool get isSearch => _isSearch;

  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  Completer<ApiCallResponse>? apiRequestCompleter;
  // Model for NoSearchComponent component.
  late NoSearchComponentModel noSearchComponentModel;
  // Model for responseComponent component.
  late ResponseComponentModel responseComponentModel;

   
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    noSearchComponentModel =
        createModel(context, () => NoSearchComponentModel());
    responseComponentModel =
        createModel(context, () => ResponseComponentModel());

    debugLogWidgetClass(this);
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();

    noSearchComponentModel.dispose();
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
      final requestComplete = apiRequestCompleter?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }


}
