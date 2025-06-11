// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

Map<String, dynamic>? paymentIntentData;

Future stripeCustom(
  BuildContext context,
  String amount,
  String curency,
  String country,
  Future Function(String transactionId) successAction,
  Future Function(String transactionId) failedAction,
  String secretKey,
  Future Function() showFailedMessAction,
) async {
  // Add your function code here!
  try {
    paymentIntentData = await createPaymentIntent(
        amount, curency, secretKey, showFailedMessAction);
    print("Payment Intent Data ========== $paymentIntentData");

    if (paymentIntentData != null) {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          googlePay: PaymentSheetGooglePay(merchantCountryCode: country),
          merchantDisplayName: 'Prospects',
          customerId: paymentIntentData!['customer'],
          paymentIntentClientSecret: paymentIntentData!['client_secret'],
          customerEphemeralKeySecret: paymentIntentData!['ephemeralKey'],
        ),
      );
      displayPaymentSheet(
          context, successAction, failedAction, showFailedMessAction);
    }
  } catch (e) {
    showFailedMessAction.call();
  }
}

displayPaymentSheet(
    BuildContext context,
    Future Function(String transactionId) successAction,
    Future Function(String transactionId) failedAction,
    Future Function() showFailedMessAction) async {
  try {
    await Stripe.instance.presentPaymentSheet().then(
      (value) {
        print("value--------${value}");
      },
    );
    successAction.call(paymentIntentData!['id']);
  } on StripeException catch (e) {
    print("error--------${e}----- out");
    if (e.error.code.toString() == "FailureCode.Canceled") {
      print("error--------${e}----- 1");
      showFailedMessAction.call();
    } else {
      print("error--------${e}----- 2");
      failedAction.call(paymentIntentData!['id']);
    }
  } catch (e) {
    print("error--------${e}----- 3");
    failedAction.call(paymentIntentData!['id']);
  }
}

createPaymentIntent(String amount, String currency, String secretKey,
    Future Function() showFailedMessAction) async {
  try {
    Map<String, dynamic> body = {
      'amount': calculateAmount(amount),
      'currency': currency,
      'payment_method_types[]': 'card'
    };
    var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        body: body,
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded'
        });
    return jsonDecode(response.body);
  } catch (err) {
    showFailedMessAction.call();
  }
}

calculateAmount(String amount) {
  double a = (double.parse(amount) * 100);
  int s = a.toInt();
  return s.toString();
}
