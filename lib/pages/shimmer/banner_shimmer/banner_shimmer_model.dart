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

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        widgetParameters: {
          'isBig': debugSerializeParam(
            widget?.isBig,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=BannerShimmer',
            searchReference:
                'reference=SiAKDwoFaXNCaWcSBnRvNmo1dCoHEgVmYWxzZXIECAUgAVAAWgVpc0JpZw==',
            name: 'bool',
            nullable: false,
          ),
          'image': debugSerializeParam(
            widget?.image,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=BannerShimmer',
            searchReference:
                'reference=ShcKDwoFaW1hZ2USBml1eXU4Y3IECAQgAVAAWgVpbWFnZQ==',
            name: 'String',
            nullable: true,
          )
        }.withoutNulls,
        widgetStates: {
          'carouselCurrentIndex': debugSerializeParam(
            carouselCurrentIndex,
            ParamType.int,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=BannerShimmer',
            name: 'int',
            nullable: true,
          )
        },
        generatorVariables: debugGeneratorVariables,
        backendQueries: debugBackendQueries,
        componentStates: {
          ...widgetBuilderComponents.map(
            (key, value) => MapEntry(
              key,
              value.toWidgetClassDebugData(),
            ),
          ),
        }.withoutNulls,
        link:
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=BannerShimmer',
        searchReference:
            'reference=Og1CYW5uZXJTaGltbWVyUABaDUJhbm5lclNoaW1tZXI=',
        widgetClassName: 'BannerShimmer',
      );
}
