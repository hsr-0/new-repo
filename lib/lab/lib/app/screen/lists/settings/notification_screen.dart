import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/data/data_file.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../../base/color_data.dart';
import '../../../../base/constant.dart';
import '../../../models/model_notification.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _NotificationScreenState();
  }
}

class _NotificationScreenState extends State<NotificationScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  List<NotificationCat> notificationCatList = DataFile.notificationCatList;
  List<ModelNotification> notificationList = DataFile.notificationList;

  @override
  Widget build(BuildContext context) {
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
              }, 'Notifications'),
              getVerSpace(20.h),
              Expanded(
                child: (notificationCatList.isEmpty)
                    ? buildNoDataWidget(context)
                    : buildNotificationList(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildNotificationList() {
    return ListView.builder(
      itemCount: notificationCatList.length,
      itemBuilder: (context, index) {
        NotificationCat cat = notificationCatList[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            getCustomFont(cat.title, 15.sp, Colors.black, 1,
                fontWeight: FontWeight.w500),
            getVerSpace(16.h),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: 3,
              itemBuilder: (context, index) {
                ModelNotification notification = notificationList[index];
                return Row(
                  children: [
                    getCircularImage(
                        context, 60.h, 60.h, 22.h, notification.img,
                        boxFit: BoxFit.cover),
                    getHorSpace(10.h),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          getCustomFont(
                              notification.title, 16.sp, Colors.black, 1,
                              fontWeight: FontWeight.w700),
                          getVerSpace(4.h),
                          getCustomFont(
                              notification.subtitle, 15.sp, greyFontColor, 1,
                              fontWeight: FontWeight.w500),
                        ],
                      ),
                    ),
                    getCustomFont(notification.time, 15.sp, greyFontColor, 1,
                        fontWeight: FontWeight.w500)
                  ],
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return getDivider().marginSymmetric(vertical: 20.h);
              },
            ),
            getVerSpace(20.h)
          ],
        );
      },
    ).marginSymmetric(horizontal: 20.h);
  }

  Column buildNoDataWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        getNoDataWidget(
            context,
            'No Notifications Yet!',
            'We’ll notify you when something arrives.',
            'no_notification_icon.svg'),
        getVerSpace(100.h),
      ],
    );
  }
}
