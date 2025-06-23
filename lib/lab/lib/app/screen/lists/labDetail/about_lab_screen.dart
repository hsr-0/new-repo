import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cosmetic_store/lab/lib/base/widget_utils.dart';

import '../../../../base/constant.dart';

class AboutLabScreen extends StatefulWidget {
  const AboutLabScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AboutLabScreenState();
  }
}

class _AboutLabScreenState extends State<AboutLabScreen> {
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
              getBackAppBar(context, () {
                backClick();
              }, 'About Lab'),
              // getVerSpace(20.h),
              buildAboutView(context),
              // getVerSpace(21.h),
            ],
          ),
        ),
      ),
    );
  }

  Expanded buildAboutView(BuildContext context) {
    return Expanded(
        child: getShadowDefaultContainer(
            height: double.infinity,
            width: double.infinity,
            color: Colors.white,
            margin: EdgeInsets.symmetric(horizontal: 20.h, vertical: 20.h),
            padding: EdgeInsets.all(20.h),
            child: Column(
              children: [
                getCircularImage(
                    context, double.infinity, 214.h, 22.h, 'lab1.png',
                    boxFit: BoxFit.cover),
                getVerSpace(20.h),
                Expanded(child: buildDescriptionView())
              ],
            )));
  }

  Widget buildDescriptionView() {
    return getMultilineCustomFont(
        'Scientific laboratories can be found as research '
        'room and learning spaces in schools and universities, '
        'industry, government, or military facilities, and even '
        'aboard ships and spacecraft.\n\nDespite the underlying notion of the lab '
        'as a confined space for experts,[2] the '
        'term "laboratory" is also increasingly applied to workshop spaces '
        'such as Living Labs, Fab Labs, or Hackerspaces, in which people meet to work '
        'on societal problems or make prototypes, '
        'working collaboratively or sharing resources.\n\nThis development is inspired '
        'by new, participatory approaches to science'
        ' and innovation and relies on user-centred design methods.',
        17.sp,
        Colors.black,
        txtHeight: 1.8.h);
  }
}
