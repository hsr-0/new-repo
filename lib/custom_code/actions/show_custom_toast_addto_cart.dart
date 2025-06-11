// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

Future showCustomToastAddtoCart(
  BuildContext context,
  String text,
  bool success,
  Future Function() navigateAction,
) async {
  // Add your function code here!
  CustomToast.showToast(context, text, success, navigateAction);
}

// String htmlToPlainText(String htmlText) {
//   // Replace line breaks
//   String text = htmlText.replaceAll(RegExp(r'<br\s*/?>'), '\n');

//   // Replace paragraph tags
//   text = text.replaceAll(RegExp(r'<\/?p>'), '\n');

//   // Replace all other HTML tags
//   text = text.replaceAll(RegExp(r'<[^>]*>'), '');

//   text = text.replaceAll('Error:', '');

//   // Decode HTML entities
//   text = text
//       .replaceAll('&nbsp;', ' ')
//       .replaceAll('&lt;', '<')
//       .replaceAll('&gt;', '>')
//       .replaceAll('&amp;', '&')
//       .replaceAll('&quot;', '"')
//       .replaceAll('&apos;', "'");

//   // Trim extra spaces and lines
//   text = text.replaceAll(RegExp(r'\n\s*\n'), '\n').trim();

//   return text;
// }

class CustomToast {
  static OverlayEntry?
      _currentOverlayEntry; // Store the current overlay entry to close it

  static void showToast(BuildContext context, String message, bool success,
      Future Function() navigateAction) {
    // Remove the current toast if it exists to allow showing a new one
    _currentOverlayEntry?.remove();

    // Create a new overlay entry to display the toast
    _currentOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80, // Position from the top of the screen
        left: MediaQuery.of(context).size.width * 0.05,
        right: MediaQuery.of(context).size.width * 0.05,
        child: Material(
          color: Colors.transparent,
          child: _buildToastContent(context, message, success, navigateAction),
        ),
      ),
    );

    // Insert the overlay entry into the Overlay
    Overlay.of(context).insert(_currentOverlayEntry!);

    // Automatically remove the toast after 2 seconds unless closed manually
    Future.delayed(Duration(seconds: 3)).then((_) {
      // Check if the toast still exists before removing
      if (_currentOverlayEntry?.mounted ?? false) {
        _currentOverlayEntry?.remove();
        _currentOverlayEntry = null; // Reset the current overlay entry
      }
    });
  }

  static Widget _buildToastContent(BuildContext context, String message,
      bool success, Future Function() navigateAction) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryText,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            SvgPicture.asset(
              success ? 'assets/images/success.svg' : 'assets/images/error.svg',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
            Container(
              width: 16,
              decoration: BoxDecoration(),
            ),
            Expanded(
              child: Text(
                message,
                textAlign: TextAlign.start,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'SF Pro Display',
                      color: FlutterFlowTheme.of(context).primaryBackground,
                      fontSize: 17,
                      letterSpacing: 0.17,
                      fontWeight: FontWeight.w500,
                      useGoogleFonts: false,
                      lineHeight: 1.5,
                    ),
              ),
            ),
            // InkWell(
            //   splashColor: Colors.transparent,
            //   focusColor: Colors.transparent,
            //   hoverColor: Colors.transparent,
            //   highlightColor: Colors.transparent,
            //   onTap: () async {
            //     navigateAction.call();
            //   },
            //   child: Container(
            //     decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(80),
            //       border: Border.all(
            //         color: FlutterFlowTheme.of(context).primaryBackground,
            //         width: 1,
            //       ),
            //     ),
            //     child: Padding(
            //       padding: EdgeInsetsDirectional.fromSTEB(20, 6, 20, 6),
            //       child: Text(
            //         'VIEW',
            //         textAlign: TextAlign.start,
            //         style: FlutterFlowTheme.of(context).bodyMedium.override(
            //               fontFamily: 'SF Pro Display',
            //               color: FlutterFlowTheme.of(context).primaryBackground,
            //               fontSize: 16,
            //               letterSpacing: 0.0,
            //               fontWeight: FontWeight.normal,
            //               useGoogleFonts: false,
            //               lineHeight: 1.5,
            //             ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
