import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/dialog_components/review_done_component/review_done_component_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'write_review_submit_page_widget.dart' show WriteReviewSubmitPageWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class WriteReviewSubmitPageModel
    extends FlutterFlowModel<WriteReviewSubmitPageWidget> {
  ///  Local state fields for this page.

  bool _process = false;
  set process(bool value) {
    _process = value;
    debugLogWidgetClass(this);
  }

  bool get process => _process;

  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // Model for MainAppbar component.
  late MainAppbarModel mainAppbarModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  String? _textControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'tway3uju' /* Please enter write a review */,
      );
    }

    return null;
  }

  // Stores action output result for [Backend Call - API (Add review)] action in Button widget.
  ApiCallResponse? _review;
  set review(ApiCallResponse? value) {
    _review = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get review => _review;

  // Model for responseComponent component.
  late ResponseComponentModel responseComponentModel;

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
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

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        widgetParameters: {
          'productDetail': debugSerializeParam(
            widget?.productDetail,
            ParamType.JSON,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=WriteReviewSubmitPage',
            searchReference:
                'reference=Sh8KFwoNcHJvZHVjdERldGFpbBIGODFmbGZicgQICSABUAFaDXByb2R1Y3REZXRhaWw=',
            name: 'dynamic',
            nullable: true,
          ),
          'rating': debugSerializeParam(
            widget?.rating,
            ParamType.double,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=WriteReviewSubmitPage',
            searchReference:
                'reference=ShgKEAoGcmF0aW5nEgY0dGY5Ym1yBAgCIAFQAVoGcmF0aW5n',
            name: 'double',
            nullable: true,
          )
        }.withoutNulls,
        localStates: {
          'process': debugSerializeParam(
            process,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=WriteReviewSubmitPage',
            searchReference:
                'reference=QiEKEAoHcHJvY2VzcxIFc3JzYmgqBxIFZmFsc2VyBAgFIAFQAVoHcHJvY2Vzc2IVV3JpdGVSZXZpZXdTdWJtaXRQYWdl',
            name: 'bool',
            nullable: false,
          )
        },
        widgetStates: {
          'textFieldText': debugSerializeParam(
            textController?.text,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=WriteReviewSubmitPage',
            name: 'String',
            nullable: true,
          )
        },
        actionOutputs: {
          'review': debugSerializeParam(
            review,
            ParamType.ApiResponse,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=WriteReviewSubmitPage',
            name: 'ApiCallResponse',
            nullable: true,
          )
        },
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
        link:
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=WriteReviewSubmitPage',
        searchReference:
            'reference=OhVXcml0ZVJldmlld1N1Ym1pdFBhZ2VQAVoVV3JpdGVSZXZpZXdTdWJtaXRQYWdl',
        widgetClassName: 'WriteReviewSubmitPage',
      );
}
