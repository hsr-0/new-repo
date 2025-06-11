import '/backend/api_requests/api_calls.dart';
import '/backend/api_requests/api_manager.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';

Future addorRemoveFavourite(
  BuildContext context, {
  String? id,
}) async {
  if (FFAppState().wishList.contains(id)) {
    FFAppState().removeFromWishList(id!);
    FFAppState().update(() {});
    await actions.showCustomToastAddtoCart(
      context,
      FFLocalizations.of(context).getVariableText(
        enText: 'Product removed from My Wishlist',
        arText: 'تم إزالة المنتج من قائمة ',
      ),
      false,
      () async {
        context.pushNamed(WishlistPageWidget.routeName);
      },
    );
  } else {
    FFAppState().addToWishList(id!);
    FFAppState().update(() {});
    await actions.showCustomToastAddtoCart(
      context,
      FFLocalizations.of(context).getVariableText(
        enText: 'Product is added to My Wishlist',
        arText: 'تمت إضافة المنتج إلى قائمة ',
      ),
      true,
      () async {
        context.pushNamed(WishlistPageWidget.routeName);
      },
    );
  }
}

Future internetTost(BuildContext context) async {
  await actions.showCustomToastTop(
    FFLocalizations.of(context).getVariableText(
      enText: 'Please turn on internet',
      arText: 'الرجاء تشغيل الانترنت',
    ),
  );
}

Future<bool?> getCustomer(BuildContext context) async {
  ApiCallResponse? userDetail;

  userDetail = await PlantShopGroup.getCustomerCall.call(
    userId: getJsonField(
      FFAppState().userDetail,
      r'''$.id''',
    ).toString().toString(),
  );

  if (PlantShopGroup.getCustomerCall.status(
        (userDetail?.jsonBody ?? ''),
      ) ==
      null) {
    FFAppState().userDetail = PlantShopGroup.getCustomerCall.userDetail(
      (userDetail?.jsonBody ?? ''),
    );
    FFAppState().update(() {});
    return true;
  } else {
    FFAppState().isLogin = false;
    FFAppState().update(() {});
    return false;
  }
}

Future listAllCountries(BuildContext context) async {
  ApiCallResponse? allCountrys;

  allCountrys = await PlantShopGroup.listAllCountriesCall.call();

  if (PlantShopGroup.listAllCountriesCall.status(
        (allCountrys?.jsonBody ?? ''),
      ) ==
      null) {
    FFAppState().allCountrysList = PlantShopGroup.listAllCountriesCall
        .countriesList(
          (allCountrys?.jsonBody ?? ''),
        )!
        .toList()
        .cast<dynamic>();
    FFAppState().update(() {});
  } else {
    FFAppState().allCountrysList = [];
    FFAppState().update(() {});
  }
}

Future<bool> addtoCartAction(
  BuildContext context, {
  required int? id,
  required String? quantity,
  required List<dynamic>? variation,
}) async {
  ApiCallResponse? getCart;
  ApiCallResponse? addToCart;

  getCart = await PlantShopGroup.getCartCall.call(
    token: FFAppState().token,
  );

  if (PlantShopGroup.getCartCall.status(
        (getCart?.jsonBody ?? ''),
      ) ==
      null) {
    addToCart = await PlantShopGroup.addToCartCall.call(
      nonce: (getCart?.getHeader('nonce') ?? ''),
      id: id,
      quantity: quantity,
      variationJson: variation,
      token: FFAppState().token,
    );

    if (PlantShopGroup.addToCartCall.status(
          (addToCart?.jsonBody ?? ''),
        ) ==
        null) {
      await action_blocks.cartItemCount(context);
      FFAppState().clearCartCache();
      await actions.showCustomToastAddtoCart(
        context,
        FFLocalizations.of(context).getVariableText(
          enText: 'Product added to cart successfully',
          arText: 'تمت إضافة المنتج إلى سلة التسوق بنجاح',
        ),
        true,
        () async {
          context.pushNamed(CartPageWidget.routeName);
        },
      );
      return true;
    } else {
      await actions.showCustomToastTop(
        PlantShopGroup.addToCartCall.message(
          (addToCart?.jsonBody ?? ''),
        )!,
      );
      return false;
    }
  } else {
    await actions.showCustomToastTop(
      FFLocalizations.of(context).getVariableText(
        enText: 'Please log in first',
        arText: 'الرجاء تسجيل الدخول أولاً',
      ),
    );

    context.pushNamed(
      SignInPageWidget.routeName,
      queryParameters: {
        'isInner': serializeParam(
          true,
          ParamType.bool,
        ),
      }.withoutNulls,
    );

    return false;
  }
}

Future cartItemCount(BuildContext context) async {
  ApiCallResponse? getCart;

  getCart = await PlantShopGroup.getCartCall.call(
    token: FFAppState().token,
  );

  if (PlantShopGroup.getCartCall.status(
        (getCart?.jsonBody ?? ''),
      ) ==
      null) {
    FFAppState().clearCartCache();
    FFAppState().cartCount =
        functions.calculateTotalQuantity(PlantShopGroup.getCartCall
            .itemsList(
              (getCart?.jsonBody ?? ''),
            )!
            .toList());
    FFAppState().update(() {});
  } else {
    FFAppState().cartCount = '0';
    FFAppState().update(() {});
  }
}

Future<bool> deleteCartItem(
  BuildContext context, {
  required String? keyId,
  required String? nonce,
}) async {
  ApiCallResponse? deleteCart;

  deleteCart = await PlantShopGroup.deleteCartCall.call(
    nonce: nonce,
    keyId: keyId,
    token: FFAppState().token,
  );

  if (PlantShopGroup.deleteCartCall.status(
        (deleteCart?.jsonBody ?? ''),
      ) ==
      null) {
    await action_blocks.cartItemCount(context);
    return true;
  } else {
    return false;
  }
}

Future<bool?> updateCart(
  BuildContext context, {
  required String? nonce,
  required String? qty,
  required String? keyId,
  required String? id,
}) async {
  ApiCallResponse? updateCart;

  updateCart = await PlantShopGroup.updateCartCall.call(
    nonce: nonce,
    keyId: keyId,
    id: id,
    qty: qty,
    token: FFAppState().token,
  );

  if (PlantShopGroup.updateCartCall.status(
        (updateCart?.jsonBody ?? ''),
      ) ==
      null) {
    await action_blocks.cartItemCount(context);
    return true;
  } else {
    return false;
  }
}

Future responseAction(BuildContext context) async {
  ApiCallResponse? response;

  response = await PlantShopGroup.authorizationCall.call();

  if (PlantShopGroup.authorizationCall.success(
        (response?.jsonBody ?? ''),
      ) ==
      1) {
    FFAppState().response = true;
    FFAppState().update(() {});
  } else {
    FFAppState().response = false;
    FFAppState().update(() {});
  }
}

Future getPaymentGateways(BuildContext context) async {
  ApiCallResponse? paymentGateways;

  paymentGateways = await PlantShopGroup.paymentGatewaysCall.call();

  if (PlantShopGroup.paymentGatewaysCall.status(
        (paymentGateways?.jsonBody ?? ''),
      ) ==
      null) {
    FFAppState().paymentGatewaysList = PlantShopGroup.paymentGatewaysCall
        .paymentGatewaysList(
          (paymentGateways?.jsonBody ?? ''),
        )!
        .toList()
        .cast<dynamic>();
    FFAppState().update(() {});
  } else {
    FFAppState().paymentGatewaysList = [];
    FFAppState().update(() {});
  }
}

Future<dynamic> createOrder(
  BuildContext context, {
  required String? paymentMethod,
  required String? paymentMethodTitle,
  required dynamic billing,
  required dynamic shipping,
  required bool? setPaid,
  required List<dynamic>? shippingLines,
  required List<dynamic>? lineItems,
  required List<dynamic>? couponLines,
  required dynamic taxlines,
  required String? nonce,
}) async {
  ApiCallResponse? createOrder;
  ApiCallResponse? removeCoupon;

  createOrder = await PlantShopGroup.createOrderCall.call(
    paymentMethod: paymentMethod,
    paymentMethodTitle: paymentMethodTitle,
    setPaid: setPaid,
    customerId: getJsonField(
      FFAppState().userDetail,
      r'''$.id''',
    ),
    billingJson: billing,
    shippingJson: shipping,
    lineItemsJson: functions.getLineItems(lineItems!.toList()),
    shippingLinesJson: functions.getShippingLines(shippingLines!
        .where((e) =>
            true ==
            getJsonField(
              e,
              r'''$.selected''',
            ))
        .toList()
        .toList()),
    couponLinesJson: functions.getCouponLines(couponLines!.toList()),
    taxLinesJson: functions.getTaxLines(taxlines),
  );

  if (PlantShopGroup.createOrderCall.status(
        (createOrder?.jsonBody ?? ''),
      ) ==
      null) {
    await actions.deleteCartItem(
      lineItems!.toList(),
      (keyId) async {
        await action_blocks.deleteCartItem(
          context,
          keyId: keyId,
          nonce: nonce,
        );
      },
    );
    await actions.removeCouponCode(
      couponLines!.toList(),
      (code) async {
        removeCoupon = await PlantShopGroup.removeCouponCodeCall.call(
          code: code,
          nonce: nonce,
          token: FFAppState().token,
        );
      },
    );
    FFAppState().clearCartCache();
    await action_blocks.cartItemCount(context);
    return PlantShopGroup.createOrderCall.orderDetail(
      (createOrder?.jsonBody ?? ''),
    );
  } else {
    await actions.showCustomToastTop(
      PlantShopGroup.createOrderCall.message(
        (createOrder?.jsonBody ?? ''),
      )!,
    );
    return <String, bool?>{
      'sucess': false,
    };
  }
}

Future<bool> updateStatus(
  BuildContext context, {
  required dynamic productDetail,
  required String? status,
}) async {
  ApiCallResponse? updateStatus;

  updateStatus = await PlantShopGroup.cancelOrderCall.call(
    orderId: getJsonField(
      productDetail,
      r'''$.id''',
    ),
    status: status,
  );

  if (PlantShopGroup.cancelOrderCall.status(
        (updateStatus?.jsonBody ?? ''),
      ) ==
      null) {
    return true;
  }

  await actions.showCustomToastTop(
    PlantShopGroup.cancelOrderCall.message(
      (updateStatus?.jsonBody ?? ''),
    )!,
  );
  return false;
}
