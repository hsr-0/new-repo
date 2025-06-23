import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/data/data_file.dart';
import 'package:cosmetic_store/lab/lib/base/color_data.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../../base/constant.dart';
import '../../../models/model_reminder.dart';
import '../../../routes/app_routes.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ReminderScreenState();
  }
}

class _ReminderScreenState extends State<ReminderScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  List<ModelReminder> reminderList = DataFile.reminderList;

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
              }, 'Reminder', withAction: true, actionIcon: 'add.svg'),
              getVerSpace(20.h),
              Expanded(
                child: (reminderList.isEmpty)
                    ? buildNoReminderWidget(context)
                    : buildReminderListView(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Column buildReminderListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        getCustomFont('Reminder me to', 17.sp, Colors.black, 1,
                fontWeight: FontWeight.w500)
            .marginSymmetric(horizontal: 20.h),
        getVerSpace(10.h),
        buildReminderList()
      ],
    );
  }

  Expanded buildReminderList() {
    return Expanded(
        child: ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        ModelReminder reminder = reminderList[index];
        return getShadowDefaultContainer(
            color: Colors.white,
            margin: EdgeInsets.symmetric(horizontal: 20.h, vertical: 10.h),
            padding: EdgeInsets.all(18.h),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    getCustomFont(reminder.title, 16.sp, Colors.black, 1,
                        fontWeight: FontWeight.w700),
                    buildPopupMenuButton((value) {
                      handleClick(value);
                    }),
                  ],
                ),
                getVerSpace(18.h),
                buildDateRow(reminder)
              ],
            ));
      },
    ));
  }

  Row buildDateRow(ModelReminder reminder) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(22.h)),
              color: fillColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                getSvgImage('calender.svg', height: 20.h, width: 20.h),
                getHorSpace(4.h),
                getCustomFont(reminder.date, 15.sp, Colors.black, 1,
                    fontWeight: FontWeight.w500),
              ],
            ),
          ),
        ),
        getHorSpace(20.h),
        Expanded(
          flex: 1,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(22.h)),
              color: fillColor,
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  getSvgImage('time.svg', height: 20.h, width: 20.h),
                  getHorSpace(4.h),
                  getCustomFont(reminder.time, 15.sp, Colors.black, 1,
                      fontWeight: FontWeight.w500),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Column buildNoReminderWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        getNoDataWidget(context, 'No Reminder Yet!',
            'Come on, maybe we still have a \nchance', 'no_reminder_icon.svg'),
        getVerSpace(100.h),
      ],
    );
  }

  void handleClick(String value) {
    switch (value) {
      case 'Edit':
        Constant.sendToNext(context, Routes.editReminderScreenRoute);
        break;
      case 'Delete':
        break;
    }
  }
}
