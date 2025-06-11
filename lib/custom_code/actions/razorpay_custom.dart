// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:razorpay_flutter/razorpay_flutter.dart';

Future razorpayCustom(
  BuildContext context,
  String keyId,
  String amount,
  String currency,
  String name,
  String description,
  String userContect,
  String userEmail,
  Future Function(String transactionId) successAction,
  Future Function(String transactionId) failedAction,
  Future Function() showFailedMessAction,
) async {
  // Add your function code here!
  Razorpay razorpay = Razorpay();
  var options = {
    'key': keyId,
    'amount': calculateAmount(amount),
    'currency': currency,
    'name': name,
    'description': description,
    'retry': {'enabled': true, 'max_count': 1},
    'send_sms_hash': true,
    'prefill': {'contact': userContect, 'email': userEmail},
    // 'external': {
    //   'wallets': ['paytm']
    // }
    'method': ['upi', 'netbanking', 'debit_card', 'credit_card']
  };
  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
    print(
        "Payment Failed 655555 ====================${response.code.toString()}");
    showFailedMessAction.call();
  });
  razorpay.on(Razorpay.PAYMENT_CANCELLED.toString(),
      (PaymentSuccessResponse response) {
    handlePaymentErrorResponse(response, failedAction);
  });
  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
      (PaymentSuccessResponse response) {
    handlePaymentSuccessResponse(response, successAction);
  });
  razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET,
      (ExternalWalletResponse response) {
    handleExternalWalletSelected(response, context);
  });
  razorpay.open(options);
}

void handlePaymentErrorResponse(
  PaymentSuccessResponse response,
  Future Function(String transactionId) failedAction,
) {
  /*
    * PaymentFailureResponse contains three values:
    * 1. Error Code
    * 2. Error Description
    * 3. Metadata
    * */
  print("Payment Failed====================${response.paymentId.toString()}");
  failedAction.call(response.paymentId.toString());

  // showAlertDialog(context, "Payment Failed",
  //     "Code: ${response.code}\nDescription: ${response.message}\nMetadata:${response.error.toString()}");
}

void handlePaymentSuccessResponse(PaymentSuccessResponse response,
    Future Function(String transactionId) successAction) {
  /*
    * Payment Success Response contains three values:
    * 1. Order ID
    * 2. Payment ID
    * 3. Signature
    * */
  // print(response.data.toString());
  print("Payment Successful====================");
  successAction.call(response.paymentId.toString());
  // showAlertDialog(
  //     context, "Payment Successful", "Payment ID: ${response.paymentId}");
}

void handleExternalWalletSelected(
    ExternalWalletResponse response, BuildContext context) {
  print("External Wallet Selected====================");
  showAlertDialog(
      context, "External Wallet Selected", "${response.walletName}");
}

void showAlertDialog(BuildContext context, String title, String message) {
  Widget continueButton = ElevatedButton(
    child: const Text("Continue"),
    onPressed: () {},
  );
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(message),
  );
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

calculateAmount(String amount) {
  double a = (double.parse(amount) * 100);
  int s = a.toInt();
  return s;
}
