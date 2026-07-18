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

   
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}


}
