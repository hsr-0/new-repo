import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../base/constant.dart';
import '../../../base/widget_utils.dart';
import '../../controller/controller.dart';
import '../../models/model_country.dart';

class SelectCountryScreen extends StatefulWidget {
  const SelectCountryScreen({Key? key}) : super(key: key);

  @override
  State<SelectCountryScreen> createState() => _SelectCountryScreenState();
}

class _SelectCountryScreenState extends State<SelectCountryScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  ForgotController controller = Get.put(ForgotController());

  @override
  Widget build(BuildContext context) {
    getColorStatusBar(Colors.white);
    return WillPopScope(
      onWillPop: () async {
        backClick();
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              getVerSpace(20.h),
              getBackAppBar(context, () {
                backClick();
              }, 'Select Country'),
              getVerSpace(37.h),
              buildSearchTextFieldWidget(context),
              getVerSpace(30.h),
              buildCountryListWidget()
            ],
          ),
        ),
      ),
    );
  }

  Expanded buildCountryListWidget() {
    return Expanded(
        flex: 1,
        child: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: GetBuilder<ForgotController>(
            init: ForgotController(),
            builder: (controller) => ListView.separated(
              separatorBuilder: (context, index) {
                return getDivider();
              },
              padding: EdgeInsets.symmetric(horizontal: 20.h),
              primary: true,
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: controller.newCountryLists.length,
              itemBuilder: (context, index) {
                ModelCountry modelCountry = controller.newCountryLists[index];
                return GestureDetector(
                  onTap: () {
                    controller.getImage(
                        modelCountry.image ?? "", modelCountry.code ?? "");
                    backClick();
                  },
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            getAssetImage(modelCountry.image ?? "",
                                height: 24.h, width: 40.h),
                            getHorSpace(10.h),
                            getCustomFont(
                                modelCountry.name ?? "", 15.sp, Colors.black, 1,
                                fontWeight: FontWeight.w700)
                          ],
                        ),
                        getCustomFont(
                            modelCountry.code ?? '', 20.sp, Colors.black, 1,
                            fontWeight: FontWeight.w700)
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ));
  }

  Padding buildSearchTextFieldWidget(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.h),
      // child:getSearchWidget(context, "Search", controller.searchController,
      //     isEnable: false,
      //     isprefix: true,
      //     prefix: Row(
      //       children: [
      //         getHorSpace(18.h),
      //         getSvgImage("search.svg", height: 24.h, width: 24.h),
      //       ],
      //     ),
      //     constraint: BoxConstraints(maxHeight: 24.h, maxWidth: 55.h),
      //     onChanged: controller.onItemChanged),
      child: getDefaultTextFiledWithLabel(
        context,
        'search...',
        controller.searchController,
        isprefix: true,
        height: 60.h,
        prefix: Row(
          children: [
            getHorSpace(16.h),
            getSvgImage(
              'search.svg',
              height: 24.h,
              width: 24.h,
            ),
            getHorSpace(13.h),
          ],
        ),
        constraint: BoxConstraints(maxHeight: 24.h, maxWidth: 55.h),
        onChanged: controller.onItemChanged,
      ),
    );
  }
}
