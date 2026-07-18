import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/components/review_component/review_component_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import 'review_page_widget.dart' show ReviewPageWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';

class ReviewPageModel extends FlutterFlowModel<ReviewPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for MainAppbar component.
  late MainAppbarModel mainAppbarModel;
  // Models for ReviewComponent dynamic component.
  late FlutterFlowDynamicModels<ReviewComponentModel> reviewComponentModels;
  // Model for responseComponent component.
  late ResponseComponentModel responseComponentModel;

   
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    mainAppbarModel = createModel(context, () => MainAppbarModel());
    reviewComponentModels =
        FlutterFlowDynamicModels(() => ReviewComponentModel());
    responseComponentModel =
        createModel(context, () => ResponseComponentModel());

    debugLogWidgetClass(this);
  }

  @override
  void dispose() {
    mainAppbarModel.dispose();
    reviewComponentModels.dispose();
    responseComponentModel.dispose();
  }

}
