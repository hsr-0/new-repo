import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'categories_single_component_widget.dart'
    show CategoriesSingleComponentWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CategoriesSingleComponentModel
    extends FlutterFlowModel<CategoriesSingleComponentWidget> {
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
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoriesSingleComponent',
            searchReference:
                'reference=ShcKDwoFaW1hZ2USBmQ4NWFiOXIECAQgAVAAWgVpbWFnZQ==',
            name: 'String',
            nullable: true,
          ),
          'name': debugSerializeParam(
            widget?.name,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoriesSingleComponent',
            searchReference:
                'reference=ShYKDgoEbmFtZRIGaWtkZjc5cgQIAyABUABaBG5hbWU=',
            name: 'String',
            nullable: true,
          ),
          'width': debugSerializeParam(
            widget?.width,
            ParamType.double,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoriesSingleComponent',
            searchReference:
                'reference=ShcKDwoFd2lkdGgSBmNrdTV0MnIECAIgAVAAWgV3aWR0aA==',
            name: 'double',
            nullable: true,
          ),
          'isMainTap': debugSerializeParam(
            widget?.isMainTap,
            ParamType.Action,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoriesSingleComponent',
            searchReference:
                'reference=ShsKEwoJaXNNYWluVGFwEgY4MTl0eGlyBAgVIAFQAFoJaXNNYWluVGFw',
            name: 'Future Function()',
            nullable: true,
          ),
          'showImage': debugSerializeParam(
            widget?.showImage,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CategoriesSingleComponent',
            searchReference:
                'reference=ShsKEwoJc2hvd0ltYWdlEgZtNHllcjlyBAgFIAFQAFoJc2hvd0ltYWdl',
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=CategoriesSingleComponent',
        searchReference:
            'reference=OhlDYXRlZ29yaWVzU2luZ2xlQ29tcG9uZW50UABaGUNhdGVnb3JpZXNTaW5nbGVDb21wb25lbnQ=',
        widgetClassName: 'CategoriesSingleComponent',
      );
}
