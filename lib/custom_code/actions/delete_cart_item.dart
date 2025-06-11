// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future deleteCartItem(
  List<dynamic> dataList,
  Future Function(String keyId) callAction,
) async {
  // Add your function code here!
  for (int i = 0; i < dataList.length; i++) {
    await callAction.call(dataList[i]['key']);
  }
}
