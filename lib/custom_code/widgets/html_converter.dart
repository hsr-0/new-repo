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

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';

class HtmlConverter extends StatefulWidget {
  const HtmlConverter({
    super.key,
    this.width,
    this.height,
    required this.text,
  });

  final double? width;
  final double? height;
  final String text;

  @override
  State<HtmlConverter> createState() => _HtmlConverterState();
}

class _HtmlConverterState extends State<HtmlConverter> {
  @override
  Widget build(BuildContext context) {
    return HtmlWidget(
      widget.text.replaceAll('\n', '<br>'),

      // Apply custom styles
      customStylesBuilder: (element) {
        switch (element.localName) {
          case 'body':
            return {
              'font-size': '20px',
              'color': FlutterFlowTheme.of(context).primaryText.toString(),
              'font-family': 'SF Pro Display',
              'letter-spacing': '0.17px',
              'font-weight': '700',
            };
          case 'p':
          case 'li':
            return {
              'font-size': '16px',
              'color': FlutterFlowTheme.of(context).primaryText.toString(),
              'font-family': 'SF Pro Display',
              'letter-spacing': '0.17px',
              'font-weight': '400',
            };
        }
        return null;
      },

      // Handle link taps
      onTapUrl: (url) async {
        if (url != null) {
          final Uri uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            return await launchUrl(uri);
          }
        }
        return false; // Return false if URL is null or cannot be launched
      },

      // Render HTML as a column
      renderMode: RenderMode.column,

      // Default text styling
      textStyle: TextStyle(
        fontSize: 16,
        color: FlutterFlowTheme.of(context).primaryText,
        fontFamily: 'SF Pro Display',
        letterSpacing: 0.17,
      ),
    );
  }
}

// Future<void> handleURLTap(String? url) async {
//   if (url != null) {
//     if (await canLaunch(url)) {
//       await launch(url);
//     } else {
//       throw 'Could not launch $url';
//     }
//   }
// }
