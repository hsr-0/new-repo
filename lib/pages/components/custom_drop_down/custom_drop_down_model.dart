import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'custom_drop_down_widget.dart' show CustomDropDownWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CustomDropDownModel extends FlutterFlowModel<CustomDropDownWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for DropDown widget.
  String? _dropDownValue;
  set dropDownValue(String? value) {
    _dropDownValue = value;
    debugLogWidgetClass(this);
  }

  String? get dropDownValue => _dropDownValue;

  FormFieldController<String>? dropDownValueController;

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
          'options': debugSerializeParam(
            widget?.options,
            ParamType.String,
            isList: true,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CustomDropDown',
            searchReference:
                'reference=ShsKEQoHb3B0aW9ucxIGcTVyMXBmcgYSAggDIAFQAFoHb3B0aW9ucw==',
            name: 'String',
            nullable: true,
          ),
          'hintText': debugSerializeParam(
            widget?.hintText,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CustomDropDown',
            searchReference:
                'reference=ShoKEgoIaGludFRleHQSBmc3eTdobHIECAMgAVAAWghoaW50VGV4dA==',
            name: 'String',
            nullable: true,
          ),
          'selectAction': debugSerializeParam(
            widget?.selectAction,
            ParamType.Action,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CustomDropDown',
            searchReference:
                'reference=SjcKFgoMc2VsZWN0QWN0aW9uEgZuaDEyczRyHQgVIAEyFwoPCgV2YWx1ZRIGOHk1Mmc5cgQIAyABUABaDHNlbGVjdEFjdGlvbg==',
            name: 'Future Function(String value)',
            nullable: true,
          )
        }.withoutNulls,
        widgetStates: {
          'dropDownValue': debugSerializeParam(
            dropDownValue,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CustomDropDown',
            name: 'String',
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
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=CustomDropDown',
        searchReference:
            'reference=Og5DdXN0b21Ecm9wRG93blAAWg5DdXN0b21Ecm9wRG93bg==',
        widgetClassName: 'CustomDropDown',
      );
}
