import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'add_address_page_widget.dart' show AddAddressPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class AddAddressPageModel extends FlutterFlowModel<AddAddressPageWidget> {
  ///  Local state fields for this page.

  String? _code;
  set code(String? value) {
    _code = value;
    debugLogWidgetClass(this);
  }

  String? get code => _code;

  String? _phone;
  set phone(String? value) {
    _phone = value;
    debugLogWidgetClass(this);
  }

  String? get phone => _phone;

  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // Model for MainAppbar component.
  late MainAppbarModel mainAppbarModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  String? _textController1Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        '0pg7scg9' /* Please enter first name */,
      );
    }

    return null;
  }

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  String? _textController2Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'iff82xf7' /* Please enter last name */,
      );
    }

    return null;
  }

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController3;
  String? Function(BuildContext, String?)? textController3Validator;
  String? _textController3Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'ufe728y0' /* Please enter email address */,
      );
    }

    if (!RegExp(kTextValidatorEmailRegex).hasMatch(val)) {
      return FFLocalizations.of(context).getText(
        'jhmbdo3f' /* Please enter valid email addre... */,
      );
    }
    return null;
  }

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode4;
  TextEditingController? textController4;
  String? Function(BuildContext, String?)? textController4Validator;
  String? _textController4Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'dy0xuad4' /* Please enter address line 1 */,
      );
    }

    return null;
  }

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode5;
  TextEditingController? textController5;
  String? Function(BuildContext, String?)? textController5Validator;
  // State field(s) for DropDown widget.
  String? _dropDownValue1;
  set dropDownValue1(String? value) {
    _dropDownValue1 = value;
    debugLogWidgetClass(this);
  }

  String? get dropDownValue1 => _dropDownValue1;

  FormFieldController<String>? dropDownValueController1;
  // State field(s) for DropDown widget.
  String? _dropDownValue2;
  set dropDownValue2(String? value) {
    _dropDownValue2 = value;
    debugLogWidgetClass(this);
  }

  String? get dropDownValue2 => _dropDownValue2;

  FormFieldController<String>? dropDownValueController2;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode6;
  TextEditingController? textController6;
  String? Function(BuildContext, String?)? textController6Validator;
  String? _textController6Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'n6prf892' /* Please enter city */,
      );
    }

    return null;
  }

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode7;
  TextEditingController? textController7;
  String? Function(BuildContext, String?)? textController7Validator;
  String? _textController7Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'k21cwl9i' /* Please enter pincode */,
      );
    }

    return null;
  }

  // Stores action output result for [Backend Call - API (Edit shipping address)] action in Button widget.
  ApiCallResponse? _shippingAddress;
  set shippingAddress(ApiCallResponse? value) {
    _shippingAddress = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get shippingAddress => _shippingAddress;

  // Stores action output result for [Action Block - GetCustomer] action in Button widget.
  bool? _success;
  set success(bool? value) {
    _success = value;
    debugLogWidgetClass(this);
  }

  bool? get success => _success;

  // Stores action output result for [Backend Call - API (Edit shipping address)] action in Button widget.
  ApiCallResponse? _shippingAddressEdit;
  set shippingAddressEdit(ApiCallResponse? value) {
    _shippingAddressEdit = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get shippingAddressEdit => _shippingAddressEdit;

  // Stores action output result for [Action Block - GetCustomer] action in Button widget.
  bool? _successShippingEdit;
  set successShippingEdit(bool? value) {
    _successShippingEdit = value;
    debugLogWidgetClass(this);
  }

  bool? get successShippingEdit => _successShippingEdit;

  // Stores action output result for [Backend Call - API (Edit billing address)] action in Button widget.
  ApiCallResponse? _billingAddressEdit;
  set billingAddressEdit(ApiCallResponse? value) {
    _billingAddressEdit = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get billingAddressEdit => _billingAddressEdit;

  // Stores action output result for [Action Block - GetCustomer] action in Button widget.
  bool? _successBillingEdit;
  set successBillingEdit(bool? value) {
    _successBillingEdit = value;
    debugLogWidgetClass(this);
  }

  bool? get successBillingEdit => _successBillingEdit;

  // Stores action output result for [Backend Call - API (Edit billing address)] action in Button widget.
  ApiCallResponse? _billingAddress;
  set billingAddress(ApiCallResponse? value) {
    _billingAddress = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get billingAddress => _billingAddress;

  // Stores action output result for [Backend Call - API (Edit shipping address)] action in Button widget.
  ApiCallResponse? _shippingAddressAdd;
  set shippingAddressAdd(ApiCallResponse? value) {
    _shippingAddressAdd = value;
    debugLogWidgetClass(this);
  }

  ApiCallResponse? get shippingAddressAdd => _shippingAddressAdd;

  // Stores action output result for [Action Block - GetCustomer] action in Button widget.
  bool? _successAdd;
  set successAdd(bool? value) {
    _successAdd = value;
    debugLogWidgetClass(this);
  }

  bool? get successAdd => _successAdd;

  // Model for responseComponent component.
  late ResponseComponentModel responseComponentModel;

   
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    mainAppbarModel = createModel(context, () => MainAppbarModel());
    textController1Validator = _textController1Validator;
    textController2Validator = _textController2Validator;
    textController3Validator = _textController3Validator;
    textController4Validator = _textController4Validator;
    textController6Validator = _textController6Validator;
    textController7Validator = _textController7Validator;
    responseComponentModel =
        createModel(context, () => ResponseComponentModel());

    debugLogWidgetClass(this);
  }

  @override
  void dispose() {
    mainAppbarModel.dispose();
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    textFieldFocusNode3?.dispose();
    textController3?.dispose();

    textFieldFocusNode4?.dispose();
    textController4?.dispose();

    textFieldFocusNode5?.dispose();
    textController5?.dispose();

    textFieldFocusNode6?.dispose();
    textController6?.dispose();

    textFieldFocusNode7?.dispose();
    textController7?.dispose();

    responseComponentModel.dispose();
  }


}
