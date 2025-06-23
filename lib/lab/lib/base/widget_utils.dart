import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'color_data.dart';
import 'constant.dart';

Widget getVerSpace(double verSpace) {
  return SizedBox(
    height: verSpace,
  );
}

Widget getAssetImage(String image,
    {double? width,
    double? height,
    Color? color,
    BoxFit boxFit = BoxFit.contain}) {
  return Image.asset(
    Constant.assetImagePath + image,
    color: color,
    width: width,
    height: height,
    fit: boxFit,
  );
}

initializeScreenSize(BuildContext context,
    {double width = 414, double height = 896}) {
  ScreenUtil.init(context, designSize: Size(width, height), minTextAdapt: true);
}

getColorStatusBar(Color? color) {
  return AppBar(
    backgroundColor: color,
    toolbarHeight: 0,
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle(
        systemNavigationBarColor: color, statusBarColor: color),
  );
}

Widget getSvgImage(String image,
    {double? width,
    double? height,
    Color? color,
    BoxFit boxFit = BoxFit.contain}) {
  return SvgPicture.asset(
    Constant.assetImagePath + image,
    color: color,
    width: width,
    height: height,
    fit: boxFit,
  );
}

Widget getCustomFont(String text, double fontSize, Color fontColor, int maxLine,
    {String fontFamily = Constant.fontsFamily,
    TextOverflow overflow = TextOverflow.ellipsis,
    TextDecoration decoration = TextDecoration.none,
    FontWeight fontWeight = FontWeight.normal,
    TextAlign textAlign = TextAlign.start,
    txtHeight}) {
  return Text(
    text,
    overflow: overflow,
    style: TextStyle(
        decoration: decoration,
        fontSize: fontSize,
        fontStyle: FontStyle.normal,
        color: fontColor,
        fontFamily: fontFamily,
        height: txtHeight,
        fontWeight: fontWeight),
    maxLines: maxLine,
    softWrap: true,
    textAlign: textAlign,
  );
}

Widget getMultilineCustomFont(String text, double fontSize, Color fontColor,
    {String fontFamily = Constant.fontsFamily,
    TextOverflow overflow = TextOverflow.ellipsis,
    TextDecoration decoration = TextDecoration.none,
    FontWeight fontWeight = FontWeight.normal,
    TextAlign textAlign = TextAlign.start,
    txtHeight = 1.0}) {
  return Text(
    text,
    style: TextStyle(
        decoration: decoration,
        fontSize: fontSize,
        fontStyle: FontStyle.normal,
        color: fontColor,
        fontFamily: fontFamily,
        height: txtHeight,
        fontWeight: fontWeight),
    textAlign: textAlign,
  );
}

BoxDecoration getButtonDecoration(Color bgColor,
    {BorderRadius? borderRadius,
    Border? border,
    List<BoxShadow> shadow = const [],
    DecorationImage? image}) {
  return BoxDecoration(
      color: bgColor,
      borderRadius: borderRadius,
      border: border,
      boxShadow: shadow,
      image: image);
}

Widget getHorSpace(double verSpace) {
  return SizedBox(
    width: verSpace,
  );
}

Widget getButton(BuildContext context, Color bgColor, String text,
    Color textColor, Function function, double fontsize,
    {bool isBorder = false,
    EdgeInsetsGeometry? insetsGeometry,
    borderColor = Colors.transparent,
    FontWeight weight = FontWeight.bold,
    bool isIcon = false,
    String? image,
    Color? imageColor,
    double? imageWidth,
    double? imageHeight,
    bool smallFont = false,
    double? buttonHeight,
    double? buttonWidth,
    List<BoxShadow> boxShadow = const [],
    EdgeInsetsGeometry? insetsGeometrypadding,
    BorderRadius? borderRadius,
    double? borderWidth}) {
  return InkWell(
    onTap: () {
      function();
    },
    child: Container(
      margin: insetsGeometry,
      padding: insetsGeometrypadding,
      width: buttonWidth,
      height: buttonHeight,
      decoration: getButtonDecoration(
        bgColor,
        borderRadius: borderRadius,
        shadow: boxShadow,
        border: (isBorder)
            ? Border.all(color: borderColor, width: borderWidth!)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          (isIcon) ? getSvgImage(image!) : getHorSpace(0),
          (isIcon) ? getHorSpace(15.h) : getHorSpace(0),
          getCustomFont(text, fontsize, textColor, 1,
              textAlign: TextAlign.center,
              fontWeight: weight,
              fontFamily: Constant.fontsFamily)
        ],
      ),
    ),
  );
}

Widget loginAppBar(Function function) {
  return Stack(
    children: [
      GestureDetector(
        onTap: () {
          function();
        },
        child: getSvgImage("arrow_back.svg", height: 24.h, width: 24.h)
            .marginOnly(top: 10.h),
      ),
      Align(
        alignment: Alignment.topCenter,
        child:
            getAssetImage("title_logo.png", width: 190.48.h, height: 114.28.h),
      )
    ],
  );
}

Widget loginHeader(String title, String description) {
  return Column(
    children: [
      getCustomFont(title, 24.sp, Colors.black, 1,
          fontWeight: FontWeight.w700, txtHeight: 1.5.h),
      getVerSpace(10.h),
      getMultilineCustomFont(description, 17.sp, Colors.black,
          fontWeight: FontWeight.w500,
          txtHeight: 1.7.h,
          textAlign: TextAlign.center)
    ],
  );
}

Widget getDefaultTextFiledWithLabel(
  BuildContext context,
  String s,
  TextEditingController textEditingController, {
  bool withSufix = false,
  bool minLines = false,
  bool isPass = false,
  bool isEnable = true,
  bool isprefix = false,
  Widget? prefix,
  double? height,
  String? suffiximage,
  Function? imagefunction,
  List<TextInputFormatter>? inputFormatters,
  FormFieldValidator<String>? validator,
  BoxConstraints? constraint,
  ValueChanged<String>? onChanged,
  double vertical = 20,
  double horizontal = 20,
  double suffixHeight = 24,
  double suffixWidth = 24,
  double suffixRightPad = 18,
  int? length,
  String obscuringCharacter = '•',
  GestureTapCallback? onTap,
  bool isReadonly = false,
  TextInputType? keyboardType,
}) {
  return StatefulBuilder(
    builder: (context, setState) {
      return SizedBox(
        height: height,
        child: TextFormField(
          readOnly: isReadonly,
          onTap: onTap,
          onChanged: onChanged,
          validator: validator,
          enabled: true,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: (minLines) ? null : 1,
          controller: textEditingController,
          obscuringCharacter: obscuringCharacter,
          autofocus: false,
          obscureText: isPass,
          showCursor: true,
          cursorColor: accentColor,
          maxLength: length,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 17.sp,
              fontFamily: Constant.fontsFamily),
          decoration: InputDecoration(
              counterText: "",
              contentPadding: EdgeInsets.symmetric(
                  vertical: vertical.h, horizontal: horizontal.h),
              isDense: true,
              filled: true,
              fillColor: fillColor,
              suffixIconConstraints: BoxConstraints(
                maxHeight: suffixHeight.h,
              ),
              disabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(22.h),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(22.h),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(22.h),
              ),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(22.h),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(22.h),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(22.h),
              ),
              suffixIcon: withSufix
                  ? GestureDetector(
                      onTap: () {
                        imagefunction!();
                      },
                      child: getSvgImage(suffiximage.toString(),
                              width: suffixWidth.h, height: suffixHeight.h)
                          .paddingOnly(right: suffixRightPad.h))
                  : null,
              errorStyle: TextStyle(
                  color: redColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 15.sp,
                  fontFamily: Constant.fontsFamily,
                  height: 1.4.h),
              prefixIconConstraints: constraint,
              prefixIcon: isprefix == true ? prefix : null,
              hintText: s,
              hintStyle: TextStyle(
                  color: skipColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 17.sp,
                  fontFamily: Constant.fontsFamily)),
        ),
      );
    },
  );
}

Widget getImageButton(String image, {double? height, double? width}) {
  return Expanded(
    child: Container(
      height: height,
      width: width,
      padding: EdgeInsets.symmetric(vertical: 18.h),
      decoration: BoxDecoration(
          color: fillColor, borderRadius: BorderRadius.circular(22.h)),
      child: getSvgImage(image, height: 24.h, width: 24.h),
    ),
  );
}

Widget getImageButtonWithSize(String image, {Color imageColor = Colors.black}) {
  return Container(
    height: 60.h,
    width: 60.h,
    decoration: BoxDecoration(
        color: fillColor, borderRadius: BorderRadius.circular(22.h)),
    child: Center(
        child:
            getSvgImage(image, height: 24.h, width: 24.h, color: imageColor)),
  );
}

Widget getRichText(
    String firstText,
    Color firstColor,
    FontWeight firstWeight,
    double firstSize,
    String secondText,
    Color secondColor,
    FontWeight secondWeight,
    double secondSize,
    {TextAlign textAlign = TextAlign.center,
    double? txtHeight,
    Function? function}) {
  return RichText(
    textAlign: textAlign,
    text: TextSpan(
        text: firstText,
        style: TextStyle(
          color: firstColor,
          fontWeight: firstWeight,
          fontFamily: Constant.fontsFamily,
          fontSize: firstSize,
          height: txtHeight,
        ),
        children: [
          TextSpan(
              text: secondText,
              style: TextStyle(
                  color: secondColor,
                  fontWeight: secondWeight,
                  fontFamily: Constant.fontsFamily,
                  fontSize: secondSize,
                  height: txtHeight),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  function!();
                }),
        ]),
  );
}

Widget getBackIcon(Function function, {Color? color}) {
  return GestureDetector(
      onTap: () {
        function();
      },
      child:
          getSvgImage('arrow_back.svg', height: 24.h, width: 24.h, color: color)
              .marginSymmetric(horizontal: 20.h));
}

Widget getBackAppBar(BuildContext context, Function backClick, String title,
    {Color fontColor = Colors.black,
    Color iconColor = Colors.black,
    bool isDivider = true,
    bool withLeading = true,
    bool withAction = false,
    String? actionIcon,
    Function? actionClick}) {
  return SizedBox(
    height: 60.h,
    child: Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: (withLeading)
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: getBackIcon(() {
                        backClick();
                      }, color: iconColor),
                    )
                  : const SizedBox(),
            ),
            (withAction)
                ? Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                        onTap: () {
                          actionClick!();
                        },
                        child:
                            getSvgImage(actionIcon!, height: 24.h, width: 24.h)
                                .marginSymmetric(horizontal: 20.h)))
                : const SizedBox(),
          ],
        ),
        Center(
          child: getCustomFont(title, 24.sp, fontColor, 1,
              fontWeight: FontWeight.w700, textAlign: TextAlign.center),
        ),
        Align(
            alignment: Alignment.bottomCenter,
            child: (isDivider) ? getDivider() : null)
      ],
    ),
  );
}

Widget getDivider(
    {double dividerHeight = 2,
    Color setColor = Colors.grey,
    double endIndent = 0,
    double indent = 0}) {
  return Divider(
    height: dividerHeight.h,
    color: fillColor,
    endIndent: endIndent,
    indent: indent,
    thickness: 2.h,
  );
}

TextStyle buildTextStyle(BuildContext context, Color fontColor,
    FontWeight fontWeight, double fontSize,
    {double txtHeight = 1}) {
  return TextStyle(
      color: fontColor,
      fontWeight: fontWeight,
      fontFamily: Constant.fontsFamily,
      fontSize: fontSize,
      height: txtHeight);
}

Widget getCircularImage(BuildContext context, double width, double height,
    double radius, String img,
    {BoxFit boxFit = BoxFit.contain}) {
  return SizedBox(
    height: height,
    width: width,
    child: ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      child: getAssetImage(img, width: width, height: height, boxFit: boxFit),
    ),
  );
}

Widget getCircleImage(BuildContext context, String imgName, double size,
    {bool fileImage = false}) {
  return SizedBox(
    width: size,
    height: size,
    child: ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(size / 2)),
      child: (fileImage) ? Image.file(File(imgName)) : getAssetImage(imgName),
    ),
  );
}

Row buildLocationRow(String location) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      getSvgImage('location.svg', height: 20.h, width: 20.h),
      getHorSpace(4.h),
      getCustomFont(location, 15.sp, greyFontColor, 1,
          fontWeight: FontWeight.w500),
    ],
  );
}

Widget getShadowDefaultContainer(
    {double? height,
    double? width,
    EdgeInsets? margin,
    EdgeInsets? padding,
    Color? color,
    Widget? child,
    double radius = 22}) {
  return Container(
    height: height,
    width: width,
    margin: margin,
    padding: padding,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius.h),
      boxShadow: [
        BoxShadow(
          color: const Color(0x289a90b8),
          blurRadius: 32.h,
          offset: const Offset(0, 9),
        ),
      ],
      color: color,
    ),
    child: child,
  );
}

Widget getNoDataText(String title, String description) {
  return Column(
    children: [
      getCustomFont(title, 24.sp, Colors.black, 1,
          fontWeight: FontWeight.w700, txtHeight: 1.5.h),
      getVerSpace(10.h),
      getMultilineCustomFont(description, 17.sp, Colors.black,
          fontWeight: FontWeight.w500,
          txtHeight: 1.7.h,
          textAlign: TextAlign.center)
    ],
  );
}

Widget getNoDataWidget(
    BuildContext context, String title, String desc, String img,
    {bool withButton = false, String btnText = '', Function? btnClick}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        alignment: Alignment.center,
        height: 171.h,
        width: 314.h,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35.h),
            gradient: RadialGradient(
                colors: [gradientFirst, gradientSecond, gradientFirst],
                stops: const [0.0, 0.49, 1.0])),
        child: getSvgImage(img, width: 104.h, height: 104.h),
      ),
      getVerSpace(30.h),
      getNoDataText(title, desc),
      (withButton) ? getVerSpace(30.h) : getVerSpace(0.h),
      (withButton)
          ? getButton(context, Colors.transparent, btnText, accentColor, () {
              btnClick!();
            }, 18.sp,
              weight: FontWeight.w700,
              isBorder: true,
              borderColor: accentColor,
              borderRadius: BorderRadius.all(Radius.circular(22.h)),
              borderWidth: 2.h,
              buttonHeight: 60.h,
              buttonWidth: 184.h)
          : getVerSpace(0.h),
    ],
  );
}

Widget getIconContainer(double height, double width, Color color, String icon,
    {double iconSize = 30}) {
  return Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.all(Radius.circular(22.h)),
    ),
    child:
        Center(child: getSvgImage(icon, height: iconSize.h, width: iconSize.h)),
  );
}

Padding getSearchTextFieldWidget(BuildContext context, double height,
    String hintText, TextEditingController controller) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 20.h),
    // child:getSearchWidget(context, "Search", controller.searchController,
    //     isEnable: false,
    //     isprefix: true,
    //     prefix: Row(
    //       children: [
    //         getHorSpace(18.h),
    //         getSvgImage("search.svg", height: 24.h, width: 24.h),
    //       ],
    //     ),
    //     constraint: BoxConstraints(maxHeight: 24.h, maxWidth: 55.h),
    //     onChanged: controller.onItemChanged),
    child: getDefaultTextFiledWithLabel(
      context, hintText, controller,
      isprefix: true,
      height: height,
      prefix: Row(
        children: [
          getHorSpace(16.h),
          getSvgImage(
            'search.svg',
            height: 24.h,
            width: 24.h,
          ),
          getHorSpace(13.h),
        ],
      ),
      constraint: BoxConstraints(maxHeight: 24.h, maxWidth: 55.h),
      // onChanged: controller.onItemChanged,
    ),
  );
}

PopupMenuButton<String> buildPopupMenuButton(
    PopupMenuItemSelected handleClick) {
  return PopupMenuButton<String>(
    onSelected: handleClick,
    color: Colors.white,
    padding: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22.h))),
    elevation: 2.h,
    itemBuilder: (BuildContext context) {
      return {'Edit', 'Delete'}.map((String choice) {
        return PopupMenuItem<String>(
          padding: EdgeInsets.zero,
          value: choice,
          height: 45.h,
          enabled: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              getVerSpace(10.h),
              getCustomFont(choice, 15.sp, Colors.black, 1,
                      fontWeight: FontWeight.w500)
                  .paddingSymmetric(horizontal: 14.h),
              (choice == 'Edit')
                  ? getDivider().paddingOnly(top: 20.h)
                  : getVerSpace(0),
            ],
          ),
        );
      }).toList();
    },
    child: getSvgImage('menu.svg', height: 24.h, width: 24.h),
  );
}

InkWell buildDefaultTabWidget(
    String color, String icon, String title, Function function) {
  return InkWell(
    onTap: () {
      function();
    },
    child: Row(
      children: [
        getIconContainer(60.h, 60.h, color.toColor(), icon, iconSize: 24),
        getHorSpace(14.h),
        Expanded(
            child: getCustomFont(title, 17.sp, Colors.black, 1,
                fontWeight: FontWeight.w500)),
        getSvgImage('arrow_right.svg', height: 24.h, width: 24.h)
      ],
    ),
  );
}
