import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import 'feedbackage_widget.dart' show FeedbackageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackageModel extends FlutterFlowModel<FeedbackageWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // Model for MainAppbar component.
  late MainAppbarModel mainAppbarModel;
  // State field(s) for RatingBar widget.
  double? _ratingBarValue;
  set ratingBarValue(double? value) {
    _ratingBarValue = value;
    debugLogWidgetClass(this);
  }

  double? get ratingBarValue => _ratingBarValue;

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  String? _textControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'pxjxwmmh' /* Please enter sum thoughts */,
      );
    }

    return null;
  }

  // Model for responseComponent component.
  late ResponseComponentModel responseComponentModel;

   
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    mainAppbarModel = createModel(context, () => MainAppbarModel());
    textControllerValidator = _textControllerValidator;
    responseComponentModel =
        createModel(context, () => ResponseComponentModel());

    debugLogWidgetClass(this);
  }

  @override
  void dispose() {
    mainAppbarModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();

    responseComponentModel.dispose();
  }

}
