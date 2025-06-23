import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/models/model_test_panel.dart';
import '../../../base/constant.dart';
import '../../../base/widget_utils.dart';
import '../../data/data_file.dart';

class TestsPanelScreen extends StatefulWidget {
  const TestsPanelScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TestsPanelScreenState();
  }
}

class _TestsPanelScreenState extends State<TestsPanelScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  List<ModelTestPanel> testsPanel = DataFile.testPanelList;

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
                }, 'Tests panel'),
                getVerSpace(20.h),
                buildTestsPanelListView()
              ],
            ),
          )),
    );
  }

  Expanded buildTestsPanelListView() {
    return Expanded(
        flex: 1,
        child: ListView.builder(
          itemCount: testsPanel.length,
          itemBuilder: (context, index) {
            ModelTestPanel tests = testsPanel[index];
            return GestureDetector(
              onTap: () {
                // Constant.sendToNext(context, Routes.labDetailScreenRoute);
              },
              child: getShadowDefaultContainer(
                height: 130.h,
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 20.h, vertical: 10.h),
                color: Colors.white,
                child: Row(
                  children: [
                    getCircularImage(context, 106.h, 106.h, 22.h, tests.img,
                            boxFit: BoxFit.cover)
                        .marginSymmetric(horizontal: 12.h),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          getCustomFont(tests.title, 18.sp, Colors.black, 1,
                              fontWeight: FontWeight.w700),
                          getVerSpace(5.h),
                          getCustomFont(tests.test, 16.sp, Colors.black, 1,
                              fontWeight: FontWeight.w500),
                        ],
                      ).marginSymmetric(horizontal: 4.h),
                    )
                  ],
                ),
              ),
            );
          },
        ));
  }
}
