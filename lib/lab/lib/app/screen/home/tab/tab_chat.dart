import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cosmetic_store/lab/lib/app/routes/app_routes.dart';
import 'package:cosmetic_store/lab/lib/base/color_data.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../../base/constant.dart';
import '../../../data/data_file.dart';
import '../../../models/model_profile.dart';

class TabChat extends StatefulWidget {
  const TabChat({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TabChatState();
  }
}

class _TabChatState extends State<TabChat> {
  final List<ModelProfile> allProfileList = DataFile.getAllProfileList();

  void backClick() {
    Constant.backToPrev(context);
  }

  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        getVerSpace(20.h),
        getBackAppBar(context, () {
          backClick();
        }, 'Chats', withLeading: false),
        getVerSpace(20.h),
        getSearchTextFieldWidget(context, 56.h, 'Search...', searchController),
        getVerSpace(20.h),
        buildChatList(context)
      ],
    );
  }

  Expanded buildChatList(BuildContext context) {
    return Expanded(
      child: (allProfileList.isEmpty)
          ? buildNoChatView(context)
          : ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: allProfileList.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                ModelProfile profile = allProfileList[index];
                return InkWell(
                  onTap: () {
                    Constant.sendToNext(context, Routes.chatScreenRoute);
                  },
                  child: Container(
                      height: 70.h,
                      margin: EdgeInsets.symmetric(
                          horizontal: 20.h, vertical: 10.h),
                      child: Row(
                        children: [
                          getCircularImage(
                              context, 60.h, 60.h, 22.h, profile.image,
                              boxFit: BoxFit.cover),
                          getHorSpace(12.h),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                getCustomFont(
                                    profile.name, 16.sp, Colors.black, 1,
                                    fontWeight: FontWeight.w700),
                                getVerSpace(4.h),
                                getCustomFont(
                                    'Lorem ipsum dolor sit amet, con...',
                                    15.sp,
                                    greyFontColor,
                                    1,
                                    fontWeight: FontWeight.w500),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              getCustomFont('11:15 PM', 15.sp, greyFontColor, 1,
                                  fontWeight: FontWeight.w500),
                              getVerSpace(4.h),
                              (profile.currMsg != '0')
                                  ? Container(
                                      height: 24.h,
                                      width: 24.h,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: accentColor,
                                      ),
                                      child: Center(
                                          child: getCustomFont(profile.currMsg,
                                              15.sp, Colors.white, 1,
                                              fontWeight: FontWeight.w500)),
                                    )
                                  : Container(),
                            ],
                          ),
                        ],
                      )),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return getDivider(endIndent: 20.h, indent: 20.h);
              },
            ),
    );
  }

  Column buildNoChatView(BuildContext context) {
    return Column(
      children: [
        getVerSpace(100.h),
        getNoDataWidget(
            context,
            'No Chats Yet!',
            'Once you start a new conversation, \nyou’ll see it listed here.',
            'no_chat_icon.svg'),
      ],
    );
  }
}
