import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'categories_single_home_component_widget.dart'
    show CategoriesSingleHomeComponentWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CategoriesSingleHomeComponentModel
    extends FlutterFlowModel<CategoriesSingleHomeComponentWidget> {
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
          'image': debugSerializeParam(
            widget?.image,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoriesSingleHomeComponent',
            searchReference:
                'reference=ShcKDwoFaW1hZ2USBmQ4NWFiOXIECAQgAVAAWgVpbWFnZQ==',
            name: 'String',
            nullable: true,
          ),
          'name': debugSerializeParam(
            widget?.name,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoriesSingleHomeComponent',
            searchReference:
                'reference=ShYKDgoEbmFtZRIGaWtkZjc5cgQIAyABUABaBG5hbWU=',
            name: 'String',
            nullable: true,
          ),
          'width': debugSerializeParam(
            widget?.width,
            ParamType.double,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoriesSingleHomeComponent',
            searchReference:
                'reference=ShcKDwoFd2lkdGgSBmNrdTV0MnIECAIgAVAAWgV3aWR0aA==',
            name: 'double',
            nullable: true,
          ),
          'isMainTap': debugSerializeParam(
            widget?.isMainTap,
            ParamType.Action,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoriesSingleHomeComponent',
            searchReference:
                'reference=ShsKEwoJaXNNYWluVGFwEgZ1aWVrcjRyBAgVIAFQAFoJaXNNYWluVGFw',
            name: 'Future Function()',
            nullable: true,
          ),
          'showImage': debugSerializeParam(
            widget?.showImage,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoriesSingleHomeComponent',
            searchReference:
                'reference=ShsKEwoJc2hvd0ltYWdlEgY0MzJkbm1yBAgFIAFQAFoJc2hvd0ltYWdl',
            name: 'bool',
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=CategoriesSingleHomeComponent',
        searchReference:
            'reference=Oh1DYXRlZ29yaWVzU2luZ2xlSG9tZUNvbXBvbmVudFAAWh1DYXRlZ29yaWVzU2luZ2xlSG9tZUNvbXBvbmVudA==',
        widgetClassName: 'CategoriesSingleHomeComponent',
      );
}
