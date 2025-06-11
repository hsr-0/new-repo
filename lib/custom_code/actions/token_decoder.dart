// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:jwt_decoder/jwt_decoder.dart';

Future<String> tokenDecoder(String token) async {
  // Add your function code here!
  Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
  // Now you can use your decoded token
  print("sfadsgfadsgd${decodedToken['data']['user']['id']}");

  return decodedToken['data']['user']['id'];
}
