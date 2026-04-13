import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/dimensions.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_color.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/style.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/card/inner_shadow_container.dart';

class LocationPickTextField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final Function? onChanged;
  final TextEditingController? controller;
  final TextInputType? textInputType;
  final VoidCallback? onTap;
  final TextInputAction inputAction;
  final Color fillColor;
  final Color borderColor;
  final Color? shadowColor;
  final Color textColor;
  final VoidCallback? onSubmit;
  final double? radius;
  final bool readOnly;
  final Widget? suffixIcon;
  final Widget? prefixIcon;

  // ✅ تمت إضافة هذا المتغير للتحكم في التركيز (فتح الكيبورد)
  final FocusNode? focusNode;

  const LocationPickTextField({
    super.key,
    this.labelText,
    this.fillColor = MyColor.transparentColor,
    this.borderColor = MyColor.borderColor,
    this.shadowColor,
    this.textColor = MyColor.bodyTextColor,
    required this.onChanged,
    this.hintText,
    this.controller,
    this.textInputType,
    this.onTap,
    this.inputAction = TextInputAction.next,
    this.onSubmit,
    this.radius = Dimensions.mediumRadius,
    this.readOnly = false,
    this.suffixIcon,
    this.prefixIcon,
    this.focusNode, // ✅ تمت إضافته للـ Constructor
  });

  @override
  State<LocationPickTextField> createState() => _LocationPickTextFieldState();
}

class _LocationPickTextFieldState extends State<LocationPickTextField> {
  @override
  Widget build(BuildContext context) {
    return InnerShadowContainer(
      width: double.infinity,
      backgroundColor: widget.fillColor,
      borderRadius: Dimensions.moreRadius,
      blur: 6,
      offset: const Offset(3, 3), // أضفت const هنا كتحسين بسيط للأداء
      shadowColor: widget.shadowColor ?? MyColor.colorBlack.withValues(alpha: 0.04),
      isShadowTopLeft: true,
      isShadowBottomRight: true,
      child: TextFormField(
        focusNode: widget.focusNode, // ✅ تمرير الـ focusNode هنا ليعمل بشكل صحيح
        style: regularDefault.copyWith(
          color: widget.textColor,
          fontSize: Dimensions.fontLarge,
        ),
        readOnly: widget.readOnly,
        cursorColor: widget.textColor,
        controller: widget.controller,
        autofocus: false,
        textInputAction: widget.inputAction,
        keyboardType: widget.textInputType,
        decoration: InputDecoration(
          hintStyle: regularDefault.copyWith(
            color: widget.textColor,
            fontSize: Dimensions.fontLarge,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 15,
          ),
          fillColor: MyColor.transparentColor,
          filled: true,
          hintText: widget.hintText?.tr ?? '',
          suffixIcon: widget.suffixIcon,
          prefixIcon: widget.prefixIcon,
          prefixIconConstraints:  BoxConstraints.loose(Size(40, 40)), // أضفت const
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: (text) => widget.onChanged!(text),
        onTap: () {
          if (widget.onTap != null) {
            widget.onTap!();
          }
        },
      ),
    );
  }
}