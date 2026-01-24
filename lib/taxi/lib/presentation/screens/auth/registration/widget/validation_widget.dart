import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/dimensions.dart';
import 'package:cosmetic_store/taxi/lib/data/model/model/error_model.dart';
import 'validation_chip_widget.dart';

class ValidationWidget extends StatelessWidget {
  final List<ErrorModel> list;
  final bool fromReset;

  const ValidationWidget({
    super.key,
    required this.list,
    this.fromReset = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: Dimensions.textToTextSpace),
        Wrap(
          children: list
              .map(
                (item) => ChipWidget(name: item.text.tr, hasError: item.hasError),
              )
              .toList(),
        ),
        fromReset ? const SizedBox(height: Dimensions.space12) : const SizedBox(),
      ],
    );
  }
}
