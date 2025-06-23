import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cosmetic_store/lab/lib/base/color_data.dart';
import 'package:cosmetic_store/lab/lib/base/pref_data.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../base/constant.dart';
import '../routes/app_routes.dart';

class AccountCreatedDialog extends StatefulWidget {
  const AccountCreatedDialog({Key? key}) : super(key: key);

  @override
  State<AccountCreatedDialog> createState() => _AccountCreatedDialogState();
}

class _AccountCreatedDialogState extends State<AccountCreatedDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20.h),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35.h)),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 30.h),
        height: 456.h,
        width: 374.h,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            getVerSpace(30.h),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                // height: 171.h,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35.h),
                    gradient: RadialGradient(
                        colors: [gradientFirst, gradientSecond, gradientFirst],
                        stops: const [0.0, 0.49, 1.0])),
                child: getSvgImage("account_created.svg",
                    width: 104.h, height: 104.h),
              ),
            ),
            getVerSpace(31.h),
            loginHeader("Account Created",
                "Your account has been successfully \ncreated!"),
            getVerSpace(40.h),
            getButton(context, accentColor, "Ok", Colors.white, () {
              PrefData.setIsSignIn(true);
              Constant.sendToNext(context, Routes.homeScreenRoute);
            }, 18.sp,
                weight: FontWeight.w700,
                buttonHeight: 60.h,
                borderRadius: BorderRadius.circular(22.h)),
            getVerSpace(30.h)
          ],
        ),
      ),
    );
  }
}
