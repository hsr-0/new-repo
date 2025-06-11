import '';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/bottom_flow/cart_component/cart_component_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/actions/actions.dart' as action_blocks;
import 'cart_page_widget.dart' show CartPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class CartPageModel extends FlutterFlowModel<CartPageWidget> {
  ///  Local state fields for this page.

  int _shipping = 0;
  set shipping(int value) {
    _shipping = value;
    debugLogWidgetClass(this);
  }

  int get shipping => _shipping;

  ///  State fields for stateful widgets in this page.

  // Model for CartComponent component.
  late CartComponentModel cartComponentModel;
  // Model for responseComponent component.
  late ResponseComponentModel responseComponentModel;

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};
  @override
  void initState(BuildContext context) {
    cartComponentModel = createModel(context, () => CartComponentModel());
    responseComponentModel =
        createModel(context, () => ResponseComponentModel());

    debugLogWidgetClass(this);
  }

  @override
  void dispose() {
    cartComponentModel.dispose();
    responseComponentModel.dispose();
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        localStates: {
          'shipping': debugSerializeParam(
            shipping,
            ParamType.int,
            link:
                'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=CartPage',
            searchReference:
                'reference=QhkKEQoIc2hpcHBpbmcSBW1sd3FncgQIASABUAFaCHNoaXBwaW5nYghDYXJ0UGFnZQ==',
            name: 'int',
            nullable: false,
          )
        },
        generatorVariables: debugGeneratorVariables,
        backendQueries: debugBackendQueries,
        componentStates: {
          'cartComponentModel (CartComponent)':
              cartComponentModel?.toWidgetClassDebugData(),
          'responseComponentModel (responseComponent)':
              responseComponentModel?.toWidgetClassDebugData(),
          ...widgetBuilderComponents.map(
            (key, value) => MapEntry(
              key,
              value.toWidgetClassDebugData(),
            ),
          ),
        }.withoutNulls,
        link:
            'https://app.flutterflow.io/project/plant-shop-brdbek/tab=uiBuilder&page=CartPage',
        searchReference: 'reference=OghDYXJ0UGFnZVABWghDYXJ0UGFnZQ==',
        widgetClassName: 'CartPage',
      );
}
