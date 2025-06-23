import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/data/data_file.dart';
import 'package:cosmetic_store/lab/lib/app/routes/app_routes.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../base/color_data.dart';
import '../../../base/constant.dart';
import '../../models/model_top_specialist.dart';

class TopSpecialistScreen extends StatefulWidget {
  const TopSpecialistScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TopSpecialistScreenState();
  }
}

class _TopSpecialistScreenState extends State<TopSpecialistScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  List<ModelTopSpecialist> topSpecialist = DataFile.topSpecialistList;

  @override
  Widget build(BuildContext context) {
    initializeScreenSize(context);
    return WillPopScope(
      onWillPop: () async {
        backClick();
        return false;
      },
      child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                getVerSpace(20.h),
                getBackAppBar(context, () {
                  backClick();
                }, 'Top Specialists'),
                getVerSpace(20.h),
                buildSpecialistListView(context)
              ],
            ),
          )),
    );
  }

  Expanded buildSpecialistListView(BuildContext context) {
    double margin = 20.h;
    int crossCount = 2;
    // if (context.isTablet) {
    //   crossCount = 3;
    // }
    double width = (MediaQuery.of(context).size.width - (margin * crossCount)) / crossCount;
    double height = 208.h;

    return Expanded(
        child: GridView.count(
          crossAxisCount: crossCount,
          crossAxisSpacing: margin,
          mainAxisSpacing: margin,
          childAspectRatio: width / height,
          children: List.generate(topSpecialist.length, (index) {
            ModelTopSpecialist specialist = topSpecialist[index];
            return InkWell(
              onTap: () {
                Constant.sendToNext(context, Routes.specialistDetailScreenRoute);
              },
              child: getShadowDefaultContainer(
                margin: EdgeInsets.only(left: (index.isEven)?margin:0.h,right: (index.isOdd)?margin:0),
                height: height,
                color: Colors.white,
                child: Column(
                  children: [
                    Expanded(
                        child: getCircleImage(
                            context, specialist.img, double.infinity)),
                    getVerSpace(16.h),
                    getCustomFont(specialist.name, 16.sp, Colors.black, 1,
                        fontWeight: FontWeight.w700, txtHeight: 1.4.h),
                    getVerSpace(4.h),
                    getCustomFont(specialist.category, 15.sp, greyFontColor, 1,
                        fontWeight: FontWeight.w500, txtHeight: 1.4.h),
                  ],
                ).paddingSymmetric(vertical: 16.h),
              ),
            );
          }),
        ));
  }
}
