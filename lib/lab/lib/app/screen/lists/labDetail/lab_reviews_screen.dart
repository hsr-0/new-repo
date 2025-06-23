import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/data/data_file.dart';
import 'package:cosmetic_store/lab/lib/base/color_data.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';
import '../../../../base/constant.dart';
import '../../../models/model_reviews.dart';

class LabReviewsScreen extends StatefulWidget {
  const LabReviewsScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LabReviewsScreenState();
  }
}

class _LabReviewsScreenState extends State<LabReviewsScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  List<ModelReviews> reviewsList = DataFile.reviewsList;

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
              }, 'Reviews'),
              getVerSpace(20.h),
              Expanded(
                child: (reviewsList.isEmpty)
                    ? buildNoReviewView(context)
                    : buildReviewList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildReviewList() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: reviewsList.length,
      itemBuilder: (context, index) {
        ModelReviews review = reviewsList[index];
        return Column(
          children: [
            getVerSpace(20.h),
            Row(
              children: [
                getCircleImage(context, review.img, 44.h),
                getHorSpace(10.h),
                Expanded(
                    child: getCustomFont(review.name, 16.sp, Colors.black, 1,
                        fontWeight: FontWeight.w700)),
                getCustomFont(review.time, 15.sp, greyFontColor, 1,
                    fontWeight: FontWeight.w500),
              ],
            ),
            getVerSpace(6.h),
            getMultilineCustomFont(review.review, 17.sp, Colors.black,
                    fontWeight: FontWeight.w500, txtHeight: 1.7.h)
                .marginOnly(left: 54.h),
            getVerSpace(10.h),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      getSvgImage('comment.svg', height: 20.h, width: 20.h),
                      getHorSpace(14.h),
                      getSvgImage('heart.svg', height: 20.h, width: 20.h),
                    ],
                  ),
                ),
                getSvgImage('share.svg', height: 20.h, width: 20.h),
              ],
            ).marginOnly(left: 54.h),
            getVerSpace(20.h),
            getDivider(),
          ],
        );
      },
    ).marginSymmetric(horizontal: 20.h);
  }

  Column buildNoReviewView(BuildContext context) {
    return Column(
      children: [
        getVerSpace(161.h),
        getNoDataWidget(context, 'No Reviews Yet!',
            'Come on, maybe we still have a \nchance', "no_rating_icon.svg"),
      ],
    );
  }
}
