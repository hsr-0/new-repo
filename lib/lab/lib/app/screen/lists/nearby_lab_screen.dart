import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/routes/app_routes.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../base/constant.dart';
import '../../data/data_file.dart';
import '../../models/model_nearby_lab.dart';

class NearbyLabScreen extends StatefulWidget {
  const NearbyLabScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _NearbyLabScreenState();
  }
}

class _NearbyLabScreenState extends State<NearbyLabScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  List<ModelNearbyLab> nearbyLabList = DataFile.nearbyLabList;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                getVerSpace(20.h),
                getBackAppBar(context, () {
                  backClick();
                }, 'Nearby Laboratories'),
                getVerSpace(20.h),
                buildLabListView()
              ],
            ),
          )),
    );
  }

  Expanded buildLabListView() {
    return Expanded(
      child: ListView.builder(
        itemCount: nearbyLabList.length,
        itemBuilder: (context, index) {
          ModelNearbyLab lab = nearbyLabList[index];
          return GestureDetector(
            onTap: () {
              Constant.sendToNext(context, Routes.labDetailScreenRoute);
            },
            child: getShadowDefaultContainer(
              height: 130.h,
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 20.h, vertical: 10.h),
              color: Colors.white,
              child: Row(
                children: [
                  getCircularImage(context, 106.h, 106.h, 22.h, lab.img,
                          boxFit: BoxFit.cover)
                      .marginSymmetric(horizontal: 12.h),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        getCustomFont(lab.title, 18.sp, Colors.black, 1,
                            fontWeight: FontWeight.w700),
                        getVerSpace(5.h),
                        buildLocationRow(lab.location),
                      ],
                    ).marginSymmetric(horizontal: 4.h),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
