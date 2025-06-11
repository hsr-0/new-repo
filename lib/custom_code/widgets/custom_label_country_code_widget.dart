// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets

import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomLabelCountryCodeWidget extends StatefulWidget {
  const CustomLabelCountryCodeWidget({
    super.key,
    this.width,
    this.height,
    this.initialValue,
    this.code,
    required this.updateAction,
  });

  final double? width;
  final double? height;
  final String? initialValue;
  final String? code;
  final Future Function(String? countryCode, String? phone) updateAction;

  @override
  State<CustomLabelCountryCodeWidget> createState() =>
      _CustomLabelCountryCodeWidgetState();
}

class _CustomLabelCountryCodeWidgetState
    extends State<CustomLabelCountryCodeWidget> {
  @override
  Widget build(BuildContext context) {
    return IntlPhoneField(
      showCountryFlag: false,
      autofocus: false,
      dropdownIcon: Icon(
        Icons.keyboard_arrow_down,
        size: 12,
        color: FlutterFlowTheme.of(context).primaryText,
      ),
      style: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'SF Pro Display',
            fontSize: 16.0,
            letterSpacing: 0.0,
            useGoogleFonts: false,
          ),
      dropdownIconPosition: IconPosition.trailing,
      dropdownTextStyle: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'SF Pro Display',
            fontSize: 16.0,
            letterSpacing: 0.0,
            useGoogleFonts: false,
          ),
      dropdownDecoration:
          BoxDecoration(borderRadius: BorderRadius.circular(12)),
      initialValue: widget.initialValue ?? "",
      flagsButtonMargin: EdgeInsets.only(left: 16),
      keyboardType: TextInputType.phone,
      cursorColor: FlutterFlowTheme.of(context).primaryText,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9]'))],
      decoration: InputDecoration(
        alignLabelWithHint: true,

        hintText: 'Enter phone number',
        hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
              fontFamily: 'SF Pro Display',
              fontSize: 16.0,
              letterSpacing: 0.0,
              fontWeight: FontWeight.normal,
              useGoogleFonts: false,
            ),
        counterText: '',

        // errorText: 'Please enter valid number ',
        errorStyle: FlutterFlowTheme.of(context).bodyMedium.override(
              fontFamily: 'SF Pro Display',
              color: FlutterFlowTheme.of(context).error,
              fontSize: 14.0,
              letterSpacing: 0.0,
              useGoogleFonts: false,
            ),
        // contentPadding: EdgeInsets.only(top: 16, bottom: 16, left: 16),
        contentPadding: EdgeInsetsDirectional.fromSTEB(20.0, 16.5, 20.0, 16.5),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: FlutterFlowTheme.of(context).error,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: FlutterFlowTheme.of(context).primaryText,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: FlutterFlowTheme.of(context).black20,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: FlutterFlowTheme.of(context).error,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: FlutterFlowTheme.of(context).black20,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: FlutterFlowTheme.of(context).black20,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      initialCountryCode: widget.code ?? "IN",
      validator: (num) {
        return "Please enter phone number";
      },
      invalidNumberMessage: "Please enter valid phone number",
      onChanged: (value) {
        widget.updateAction.call(value.countryCode, value.number);
      },
      autovalidateMode: AutovalidateMode.onUnfocus,
      onCountryChanged: (value) {
        // widget.updateAction.call(value.countryCode, value.number);
      },
    );
  }
}
