import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/empty_components/no_products_component/no_products_component_widget.dart';
import '/pages/shimmer/main_component_shimmer/main_component_shimmer_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/flutter_flow/random_data_util.dart' as random_data;
import 'category_open_shimmer_widget.dart' show CategoryOpenShimmerWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CategoryOpenShimmerModel
    extends FlutterFlowModel<CategoryOpenShimmerWidget> {
  ///  State fields for stateful widgets in this component.

  // Models for MainComponentShimmer dynamic component.
  late FlutterFlowDynamicModels<MainComponentShimmerModel>
      mainComponentShimmerModels;

   
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    mainComponentShimmerModels =
        FlutterFlowDynamicModels(() => MainComponentShimmerModel());
  }

  @override
  void dispose() {
    mainComponentShimmerModels.dispose();
  }

}
