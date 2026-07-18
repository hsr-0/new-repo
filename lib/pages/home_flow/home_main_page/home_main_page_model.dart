import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/bottom_flow/cart_component/cart_component_widget.dart';
import '/pages/bottom_flow/category_component/category_component_widget.dart';
import '/pages/bottom_flow/home_component/home_component_widget.dart';
import '/pages/bottom_flow/profile_component/profile_component_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import 'dart:async';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import 'home_main_page_widget.dart' show HomeMainPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class HomeMainPageModel extends FlutterFlowModel<HomeMainPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for HomeComponent component.
  late HomeComponentModel homeComponentModel;
  // Model for CategoryComponent component.
  late CategoryComponentModel categoryComponentModel;
  // Model for CartComponent component.
  late CartComponentModel cartComponentModel;
  // Model for ProfileComponent component.
  late ProfileComponentModel profileComponentModel;
  // Model for responseComponent component.
  late ResponseComponentModel responseComponentModel;

   
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    homeComponentModel = createModel(context, () => HomeComponentModel());
    categoryComponentModel =
        createModel(context, () => CategoryComponentModel());
    cartComponentModel = createModel(context, () => CartComponentModel());
    profileComponentModel = createModel(context, () => ProfileComponentModel());
    responseComponentModel =
        createModel(context, () => ResponseComponentModel());

    debugLogWidgetClass(this);
  }

  @override
  void dispose() {
    homeComponentModel.dispose();
    categoryComponentModel.dispose();
    cartComponentModel.dispose();
    profileComponentModel.dispose();
    responseComponentModel.dispose();
  }


}
