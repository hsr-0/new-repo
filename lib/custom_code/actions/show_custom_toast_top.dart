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

Future showCustomToastTop(String text) async {
  // Add your function code here!
  Fluttertoast.showToast(
    msg: htmlToPlainText(text),
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.TOP,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.black,
    textColor: Colors.white,
    fontSize: 16,
  );
}

String htmlToPlainText(String htmlText) {
  // Replace line breaks
  String text = htmlText.replaceAll(RegExp(r'<br\s*/?>'), '\n');

  // Replace paragraph tags
  text = text.replaceAll(RegExp(r'<\/?p>'), '\n');

  // Replace all other HTML tags
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');

  text = text.replaceAll('Error:', '');

  // Decode HTML entities
  text = text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'");

  // Trim extra spaces and lines
  text = text.replaceAll(RegExp(r'\n\s*\n'), '\n').trim();

  return text;
}
