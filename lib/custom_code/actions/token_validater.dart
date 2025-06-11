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

Future<bool> tokenValidater(String token) async {
  // Add your function code here!
  bool isTokenExpired = token == "" ? false : JwtDecoder.isExpired(token);

  print("is token expired ===========${isTokenExpired}");

  if (isTokenExpired == true) {
    /* getExpirationDate() - this method returns the expiration date of the token */
    DateTime expirationDate = JwtDecoder.getExpirationDate(token);

    // 2025-01-13 13:04:18.000
    print(expirationDate);

    /* getTokenTime() - You can use this method to know how old your token is */
    Duration tokenTime = JwtDecoder.getTokenTime(token);

    // 15
    print(tokenTime.inDays);
    return true;
  }
  return false;
}
