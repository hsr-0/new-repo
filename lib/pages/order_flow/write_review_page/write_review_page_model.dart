import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/index.dart';
import 'write_review_page_widget.dart' show WriteReviewPageWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class WriteReviewPageModel extends FlutterFlowModel<WriteReviewPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for MainAppbar component.
  late MainAppbarModel mainAppbarModel;
  // State field(s) for RatingBar widget.
  double? _ratingBarValue;
  set ratingBarValue(double? value) {
    _ratingBarValue = value;
    debugLogWidgetClass(this);
  }

  double? get ratingBarValue => _ratingBarValue;

  // Model for responseComponent component.
  late ResponseComponentModel responseComponentModel;

   
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    mainAppbarModel = createModel(context, () => MainAppbarModel());
    responseComponentModel =
        createModel(context, () => ResponseComponentModel());

    debugLogWidgetClass(this);
  }

  @override
  void dispose() {
    mainAppbarModel.dispose();
    responseComponentModel.dispose();
  }


}
