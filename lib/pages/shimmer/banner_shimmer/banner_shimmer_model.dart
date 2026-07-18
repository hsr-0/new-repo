import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:math';
import 'dart:ui';
import '/flutter_flow/random_data_util.dart' as random_data;
import 'banner_shimmer_widget.dart' show BannerShimmerWidget;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BannerShimmerModel extends FlutterFlowModel<BannerShimmerWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Carousel widget.
  CarouselSliderController? carouselController;
  int _carouselCurrentIndex = 1;
  set carouselCurrentIndex(int value) {
    _carouselCurrentIndex = value;
    debugLogWidgetClass(this);
  }

  int get carouselCurrentIndex => _carouselCurrentIndex;

   
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}


}
