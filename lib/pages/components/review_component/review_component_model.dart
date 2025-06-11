import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'review_component_widget.dart' show ReviewComponentWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ReviewComponentModel extends FlutterFlowModel<ReviewComponentWidget> {
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
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ReviewComponent',
            searchReference:
                'reference=ShcKDwoFaW1hZ2USBnR3YnJxc3IECAQgAVAAWgVpbWFnZQ==',
            name: 'String',
            nullable: true,
          ),
          'userName': debugSerializeParam(
            widget?.userName,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ReviewComponent',
            searchReference:
                'reference=ShoKEgoIdXNlck5hbWUSBjZzdTBqc3IECAMgAVAAWgh1c2VyTmFtZQ==',
            name: 'String',
            nullable: true,
          ),
          'createAt': debugSerializeParam(
            widget?.createAt,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ReviewComponent',
            searchReference:
                'reference=ShoKEgoIY3JlYXRlQXQSBmxtNGowMHIECAMgAVAAWghjcmVhdGVBdA==',
            name: 'String',
            nullable: true,
          ),
          'rate': debugSerializeParam(
            widget?.rate,
            ParamType.double,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ReviewComponent',
            searchReference:
                'reference=ShYKDgoEcmF0ZRIGemVpODlucgQIAiABUABaBHJhdGU=',
            name: 'double',
            nullable: true,
          ),
          'description': debugSerializeParam(
            widget?.description,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ReviewComponent',
            searchReference:
                'reference=Sh0KFQoLZGVzY3JpcHRpb24SBnQwdjh3cXIECAMgAVAAWgtkZXNjcmlwdGlvbg==',
            name: 'String',
            nullable: true,
          ),
          'isDivider': debugSerializeParam(
            widget?.isDivider,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ReviewComponent',
            searchReference:
                'reference=SiQKEwoJaXNEaXZpZGVyEgY0dWNwYmwqBxIFZmFsc2VyBAgFIAFQAFoJaXNEaXZpZGVy',
            name: 'bool',
            nullable: false,
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=ReviewComponent',
        searchReference:
            'reference=Og9SZXZpZXdDb21wb25lbnRQAFoPUmV2aWV3Q29tcG9uZW50',
        widgetClassName: 'ReviewComponent',
      );
}
