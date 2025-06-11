import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:math';
import 'dart:ui';
import 'main_component_shimmer_widget.dart' show MainComponentShimmerWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MainComponentShimmerModel
    extends FlutterFlowModel<MainComponentShimmerWidget> {
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
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainComponentShimmer',
            searchReference:
                'reference=SiAKDwoFaXNCaWcSBjhraTNwbioHEgVmYWxzZXIECAUgAVAAWgVpc0JpZw==',
            name: 'bool',
            nullable: false,
          ),
          'width': debugSerializeParam(
            widget?.width,
            ParamType.double,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainComponentShimmer',
            searchReference:
                'reference=ShcKDwoFd2lkdGgSBjVoeHJlaXIECAIgAVAAWgV3aWR0aA==',
            name: 'double',
            nullable: true,
          ),
          'height': debugSerializeParam(
            widget?.height,
            ParamType.double,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainComponentShimmer',
            searchReference:
                'reference=ShgKEAoGaGVpZ2h0EgZ5YzJwejNyBAgCIAFQAFoGaGVpZ2h0',
            name: 'double',
            nullable: true,
          )
        }.withoutNulls,
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=MainComponentShimmer',
        searchReference:
            'reference=OhRNYWluQ29tcG9uZW50U2hpbW1lclAAWhRNYWluQ29tcG9uZW50U2hpbW1lcg==',
        widgetClassName: 'MainComponentShimmer',
      );
}
