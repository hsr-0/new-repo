// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:flutter_paypal/flutter_paypal.dart';

Future paypalCustom(
  BuildContext context,
  String clientId,
  String secretKey,
  String total,
  String currency,
  String description,
  Future Function(String transactionId) successAction,
  Future Function(String transactionId) failedAction,
  Future Function() showFailedMessAction,
) async {
  // Add your function code here!
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (BuildContext context) => UsePaypal(
          sandboxMode: true,
          clientId: clientId,
          secretKey: secretKey,
          returnURL: "https://samplesite.com/return",
          cancelURL: "https://samplesite.com/cancel",
          transactions: [
            {
              "amount": {
                "total": total,
                "currency": currency,
              },
              "description": description,
            }
          ],
          note: "Contact us for any questions on your order.",
          onSuccess: (Map params) async {
            print("onSuccess: $params");
            successAction.call(params["paymentId"].toString());
          },
          onError: (error) {
            print("onError: $error");
            showFailedMessAction.call();
          },
          onCancel: (params) {
            print('cancelled: $params');
            failedAction.call(params["paymentId"].toString());
          }),
    ),
  );
}
