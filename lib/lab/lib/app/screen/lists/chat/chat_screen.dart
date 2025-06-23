import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/lab/lib/base/color_data.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../../base/constant.dart';
import '../../../data/data_file.dart';
import '../../../models/model_chat.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChatScreenState();
  }
}

class _ChatScreenState extends State<ChatScreen> {
  List<ModelChat> chattingList = DataFile.getChattingList();
  TextEditingController messageController = TextEditingController();

  void backClick() {
    Constant.backToPrev(context);
  }

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
              buildTopProfileView(context),
              buildChatWidget(context)
            ],
          ),
        ),
      ),
    );
  }

  Expanded buildChatWidget(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Expanded(
          flex: 1,
          child: ListView.builder(
              itemBuilder: (context, index) {
                ModelChat modelChat = chattingList[index];
                Radius radius = Radius.circular(22.h);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: (modelChat.isSender)
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    getVerSpace(12.h),
                    Container(
                      padding: EdgeInsets.all(18.h),
                      margin: (modelChat.isReceive)
                          ? EdgeInsets.only(left: 39.h)
                          : EdgeInsets.only(right: 39.h),
                      decoration: BoxDecoration(
                        color: (modelChat.isSender)
                            ? '#F3EEFF'.toColor()
                            : Colors.white,
                        borderRadius: BorderRadius.only(
                            topLeft: radius,
                            topRight: radius,
                            bottomRight:
                                (!modelChat.isSender) ? radius : Radius.zero,
                            bottomLeft:
                                (modelChat.isSender) ? radius : Radius.zero),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x289a90b8),
                            blurRadius: 32.h,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: getMultilineCustomFont(
                          modelChat.msg, 17.sp, Colors.black,
                          fontWeight: FontWeight.w500, txtHeight: 1.7.h),
                    ),
                    getVerSpace(10.h),
                    buildSeenRow(modelChat),
                  ],
                );
              },
              itemCount: chattingList.length,
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(
                vertical: 18.h,
              )),
        ),
        buildMessageTextField(context),
        getVerSpace(20.h),
      ]).marginSymmetric(horizontal: 20.h),
    );
  }

  Row buildSeenRow(ModelChat modelChat) {
    return Row(
      mainAxisAlignment: (modelChat.isSender)
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        getCustomFont(modelChat.time, 15.sp, greyFontColor, 1,
            fontWeight: FontWeight.w500),
        (modelChat.isSender)
            ? getSvgImage("seen.svg",
                height: 20.h, width: 20.h, boxFit: BoxFit.fill)
            : getHorSpace(0.h),
      ],
    );
  }

  Widget buildMessageTextField(BuildContext context) {
    return getDefaultTextFiledWithLabel(
        context, 'Type a message', messageController,
        height: 60.h,
        isprefix: true,
        prefix: Row(
          children: [
            getHorSpace(18.h),
            getSvgImage('camera.svg', height: 24.h, width: 24.h),
            getSvgImage('attach.svg', height: 24.h, width: 24.h)
                .paddingSymmetric(horizontal: 14.h),
          ],
        ),
        constraint: BoxConstraints(
          maxWidth: 100.h,
        ),
        withSufix: true,
        suffiximage: 'send_btn.svg',
        imagefunction: () {},
        suffixHeight: 52,
        suffixWidth: 52,
        suffixRightPad: 6);
  }

  Row buildTopProfileView(BuildContext context) {
    return Row(
      children: [
        getBackIcon(() {
          backClick();
        }),
        getCircularImage(context, 54.h, 54.h, 22.h, 'lab1.png',
            boxFit: BoxFit.cover),
        getHorSpace(10.h),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              getCustomFont('Genelia Laboratory', 16.sp, Colors.black, 1,
                  fontWeight: FontWeight.w700),
              getVerSpace(1.h),
              getCustomFont('Online', 15.sp, greyFontColor, 1,
                  fontWeight: FontWeight.w500),
            ],
          ),
        ),
        getSvgImage('video.svg', height: 24.h, width: 24.h),
        getSvgImage('menu.svg', height: 24.h, width: 24.h)
            .paddingSymmetric(horizontal: 20.h),
      ],
    );
  }
}
