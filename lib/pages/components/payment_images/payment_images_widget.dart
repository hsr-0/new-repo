import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'payment_images_model.dart';
export 'payment_images_model.dart';

class PaymentImagesWidget extends StatefulWidget {
  const PaymentImagesWidget({
    super.key,
    required this.id,
  });

  final String? id;

  @override
  State<PaymentImagesWidget> createState() => _PaymentImagesWidgetState();
}

class _PaymentImagesWidgetState extends State<PaymentImagesWidget>
    with RouteAware {
  late PaymentImagesModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PaymentImagesModel());
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);

    _model.maybeDispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = DebugModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
    debugLogGlobalProperty(context);
  }

  @override
  void didPopNext() {
    if (mounted && DebugFlutterFlowModelContext.maybeOf(context) == null) {
      setState(() => _model.isRouteVisible = true);
      debugLogWidgetClass(_model);
    }
  }

  @override
  void didPush() {
    if (mounted && DebugFlutterFlowModelContext.maybeOf(context) == null) {
      setState(() => _model.isRouteVisible = true);
      debugLogWidgetClass(_model);
    }
  }

  @override
  void didPop() {
    _model.isRouteVisible = false;
  }

  @override
  void didPushNext() {
    _model.isRouteVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    DebugFlutterFlowModelContext.maybeOf(context)
        ?.parentModelCallback
        ?.call(_model);

    return Builder(
      builder: (context) {
        if (widget!.id == 'cod') {
          return Image.asset(
            'assets/images/money_1.png',
            width: 28.0,
            height: 28.0,
            fit: BoxFit.contain,
            alignment: Alignment(0.0, 0.0),
          );
        } else if (widget!.id == 'razorpay') {
          return Image.asset(
            'assets/images/razorPay.png',
            width: 28.0,
            height: 28.0,
            fit: BoxFit.contain,
            alignment: Alignment(0.0, 0.0),
          );
        } else if (widget!.id == 'stripe') {
          return Image.asset(
            'assets/images/stripe.png',
            width: 28.0,
            height: 28.0,
            fit: BoxFit.contain,
            alignment: Alignment(0.0, 0.0),
          );
        } else if (widget!.id == 'ppcp-gateway') {
          return Image.asset(
            'assets/images/paypal.png',
            width: 28.0,
            height: 28.0,
            fit: BoxFit.contain,
            alignment: Alignment(0.0, 0.0),
          );
        } else {
          return Image.asset(
            'assets/images/webview_logo.png',
            width: 28.0,
            height: 28.0,
            fit: BoxFit.contain,
            alignment: Alignment(0.0, 0.0),
          );
        }
      },
    );
  }
}
