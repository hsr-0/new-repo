import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'main_component_widget.dart' show MainComponentWidget;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MainComponentModel extends FlutterFlowModel<MainComponentWidget> {
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
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainComponent',
            searchReference:
                'reference=ShcKDwoFaW1hZ2USBmQ4NWFiOXIECAQgAVAAWgVpbWFnZQ==',
            name: 'String',
            nullable: true,
          ),
          'name': debugSerializeParam(
            widget?.name,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainComponent',
            searchReference:
                'reference=ShYKDgoEbmFtZRIGaWtkZjc5cgQIAyABUABaBG5hbWU=',
            name: 'String',
            nullable: true,
          ),
          'isLike': debugSerializeParam(
            widget?.isLike,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainComponent',
            searchReference:
                'reference=SiEKEAoGaXNMaWtlEgZnNTF4ZWMqBxIFZmFsc2VyBAgFIAFQAFoGaXNMaWtl',
            name: 'bool',
            nullable: false,
          ),
          'regularPrice': debugSerializeParam(
            widget?.regularPrice,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainComponent',
            searchReference:
                'reference=Sh4KFgoMcmVndWxhclByaWNlEgY4bmN3ZHhyBAgDIAFQAFoMcmVndWxhclByaWNl',
            name: 'String',
            nullable: true,
          ),
          'price': debugSerializeParam(
            widget?.price,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainComponent',
            searchReference:
                'reference=ShcKDwoFcHJpY2USBjZjMG16ZHIECAMgAVAAWgVwcmljZQ==',
            name: 'String',
            nullable: true,
          ),
          'isLikeTap': debugSerializeParam(
            widget?.isLikeTap,
            ParamType.Action,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainComponent',
            searchReference:
                'reference=ShsKEwoJaXNMaWtlVGFwEgZlanUzejhyBAgVIAFQAFoJaXNMaWtlVGFw',
            name: 'Future Function()',
            nullable: true,
          ),
          'isMainTap': debugSerializeParam(
            widget?.isMainTap,
            ParamType.Action,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainComponent',
            searchReference:
                'reference=ShsKEwoJaXNNYWluVGFwEgZrbjE0cmpyBAgVIAFQAFoJaXNNYWluVGFw',
            name: 'Future Function()',
            nullable: true,
          ),
          'review': debugSerializeParam(
            widget?.review,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainComponent',
            searchReference:
                'reference=ShgKEAoGcmV2aWV3EgZpdTFxcXFyBAgDIAFQAFoGcmV2aWV3',
            name: 'String',
            nullable: true,
          ),
          'isBigContainer': debugSerializeParam(
            widget?.isBigContainer,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainComponent',
            searchReference:
                'reference=SikKGAoOaXNCaWdDb250YWluZXISBmthYzhwYyoHEgVmYWxzZXIECAUgAVAAWg5pc0JpZ0NvbnRhaW5lcg==',
            name: 'bool',
            nullable: false,
          ),
          'height': debugSerializeParam(
            widget?.height,
            ParamType.double,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainComponent',
            searchReference:
                'reference=ShgKEAoGaGVpZ2h0EgZ6a3RsZ3VyBAgCIAFQAFoGaGVpZ2h0',
            name: 'double',
            nullable: true,
          ),
          'width': debugSerializeParam(
            widget?.width,
            ParamType.double,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainComponent',
            searchReference:
                'reference=ShcKDwoFd2lkdGgSBjE5aDNkNXIECAIgAVAAWgV3aWR0aA==',
            name: 'double',
            nullable: true,
          ),
          'onSale': debugSerializeParam(
            widget?.onSale,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainComponent',
            searchReference:
                'reference=SiEKEAoGb25TYWxlEgZxYmt5MHYqBxIFZmFsc2VyBAgFIAFQAFoGb25TYWxl',
            name: 'bool',
            nullable: false,
          ),
          'showImage': debugSerializeParam(
            widget?.showImage,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainComponent',
            searchReference:
                'reference=ShsKEwoJc2hvd0ltYWdlEgZ2ZzloNW5yBAgFIAFQAFoJc2hvd0ltYWdl',
            name: 'bool',
            nullable: true,
          ),
          'isNotBorder': debugSerializeParam(
            widget?.isNotBorder,
            ParamType.bool,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=MainComponent',
            searchReference:
                'reference=SiYKFQoLaXNOb3RCb3JkZXISBmVxNHFobSoHEgVmYWxzZXIECAUgAVAAWgtpc05vdEJvcmRlcg==',
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=MainComponent',
        searchReference:
            'reference=Og1NYWluQ29tcG9uZW50UABaDU1haW5Db21wb25lbnQ=',
        widgetClassName: 'MainComponent',
      );
}
