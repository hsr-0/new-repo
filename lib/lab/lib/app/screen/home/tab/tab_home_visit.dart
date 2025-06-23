import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/base/color_data.dart';

import '../../../../base/constant.dart';
import '../../../../base/widget_utils.dart';
import '../../../routes/app_routes.dart';

class TabHomeVisit extends StatefulWidget {
  const TabHomeVisit({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TabHomeVisitState();
  }
}

class _TabHomeVisitState extends State<TabHomeVisit> {
  void backClick() {
    Constant.backToPrev(context);
  }

  TextEditingController searchController = TextEditingController();

  RxBool isVisible = false.obs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        getVerSpace(20.h),
        getBackAppBar(context, () {}, 'Home Visit', withLeading: false),
        getVerSpace(20.h),
        Expanded(
            child: ObxValue(
                (p0) => (isVisible.value)
                    ? Column(
                        children: [
                          getSearchTextFieldWidget(context, 56.h,
                              'Search your Location', searchController),
                          getVerSpace(17.75.h),
                          Expanded(
                            child: buildBottomContainerWidget(context),
                          ),
                        ],
                      )
                    : buildNoDataWidget(context),
                isVisible))
      ],
    );
  }

  Container buildBottomContainerWidget(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(22.h), topRight: Radius.circular(22.h)),
        image: DecorationImage(
          image: AssetImage('${Constant.assetImagePath}location_img.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          buildLocNavBtn(),
          getVerSpace(20.h),
          buildConfirmLocBtn(context),
          getVerSpace(80.h),
        ],
      ),
    );
  }

  Align buildLocNavBtn() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        height: 50.h,
        width: 50.h,
        margin: EdgeInsets.only(right: 20.h),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
            child: getSvgImage('situation.svg', height: 24.h, width: 24.h)),
      ),
    );
  }

  Widget buildConfirmLocBtn(BuildContext context) {
    return getButton(
            context, accentColor, 'Confirm Your Location', Colors.white, () {
      Constant.sendToNext(context, Routes.homeVisitScreenRoute);
    }, 18.sp,
            weight: FontWeight.w700,
            buttonHeight: 60.h,
            borderRadius: BorderRadius.all(Radius.circular(22.h)))
        .paddingSymmetric(horizontal: 20.h);
  }

  Column buildNoDataWidget(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        getNoDataWidget(
            context,
            'No Home Visit Yet!',
            'Once you select your location, then \nyou see it listed here.',
            "no_home_visit_icon.svg",
            withButton: true,
            btnText: 'Go To Book Test', btnClick: () {
          isVisible.value = true;
        }),
        getVerSpace(100.h),
      ],
    );
  }
}
