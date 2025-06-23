import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/app/data/data_file.dart';
import 'package:cosmetic_store/lab/lib/app/routes/app_routes.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../base/constant.dart';
import '../../models/model_nearby_lab.dart';
import '../../models/model_recent_search.dart';
import '../home/tab/tab_home.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SearchScreenState();
  }
}

class SearchScreenState extends State<SearchScreen> {
  void backClick() {
    Constant.backToPrev(context);
  }

  TextEditingController searchController = TextEditingController();
  List<ModelRecentSearch> recentSearchList = DataFile.recentSearchList;
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
              }, 'Search For Lab'),
              getVerSpace(20.h),
              getSearchTextFieldWidget(
                  context, 60.h, 'search...', searchController),
              getVerSpace(20.h),
              getCustomFont('Recent Searches', 16.sp, Colors.black, 1,
                      fontWeight: FontWeight.w700)
                  .paddingSymmetric(horizontal: 20.h),
              getVerSpace(14.h),
              buildRecentSearchTab(),
              getVerSpace(30.h),
              buildViewAllView(context, 'Nearby Laboratories', () {
                Constant.sendToNext(context, Routes.nearbyLabScreenRoute);
              }),
              buildNearbyLabView(),
            ],
          ),
        ),
      ),
    );
  }

  ListView buildRecentSearchTab() {
    return ListView.separated(
      itemCount: 5,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        ModelRecentSearch recentSearch = recentSearchList[index];
        return SizedBox(
            height: 41.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                getSvgImage('recent.svg', height: 24.h, width: 24.h),
                getHorSpace(6.h),
                Expanded(
                    child: getCustomFont(
                            recentSearch.title, 17.sp, Colors.black, 1,
                            fontWeight: FontWeight.w500)
                        .paddingSymmetric(vertical: 12.h)),
                getSvgImage('close.svg', height: 16.h, width: 16.h),
              ],
            ).marginSymmetric(horizontal: 20.h));
      },
      separatorBuilder: (BuildContext context, int index) {
        return getDivider(endIndent: 20.h, indent: 20.h);
      },
    );
  }
}
