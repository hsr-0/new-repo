import '';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/custom_drop_down/custom_drop_down_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'variation_bottom_sheet_widget.dart' show VariationBottomSheetWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VariationBottomSheetModel
    extends FlutterFlowModel<VariationBottomSheetWidget> {
  ///  Local state fields for this component.

  int _qty = 1;
  set qty(int value) {
    _qty = value;
    debugLogWidgetClass(this);
  }

  int get qty => _qty;

  late LoggableList<String> _selectedValuesList = LoggableList([]);
  set selectedValuesList(List<String> value) {
    if (value != null) {
      _selectedValuesList = LoggableList(value);
    }

    debugLogWidgetClass(this);
  }

  List<String> get selectedValuesList =>
      _selectedValuesList?..logger = () => debugLogWidgetClass(this);
  void addToSelectedValuesList(String item) => selectedValuesList.add(item);
  void removeFromSelectedValuesList(String item) =>
      selectedValuesList.remove(item);
  void removeAtIndexFromSelectedValuesList(int index) =>
      selectedValuesList.removeAt(index);
  void insertAtIndexInSelectedValuesList(int index, String item) =>
      selectedValuesList.insert(index, item);
  void updateSelectedValuesListAtIndex(int index, Function(String) updateFn) =>
      selectedValuesList[index] = updateFn(selectedValuesList[index]);

  int _index = 0;
  set index(int value) {
    _index = value;
    debugLogWidgetClass(this);
  }

  int get index => _index;

  dynamic _productDetail;
  set productDetail(dynamic value) {
    _productDetail = value;
    debugLogWidgetClass(this);
  }

  dynamic get productDetail => _productDetail;

  bool _process = false;
  set process(bool value) {
    _process = value;
    debugLogWidgetClass(this);
  }

  bool get process => _process;

  ///  State fields for stateful widgets in this component.

  // Models for CustomDropDown dynamic component.
  late FlutterFlowDynamicModels<CustomDropDownModel> customDropDownModels;
  // Stores action output result for [Action Block - AddtoCartAction] action in Button widget.
  bool? _success;
  set success(bool? value) {
    _success = value;
    debugLogWidgetClass(this);
  }

  bool? get success => _success;

   
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    customDropDownModels =
        FlutterFlowDynamicModels(() => CustomDropDownModel());
  }

  @override
  void dispose() {
    customDropDownModels.dispose();
  }


}
