import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/shimmer/main_component_shimmer/main_component_shimmer_widget.dart';
import '/flutter_flow/random_data_util.dart' as random_data;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'products_vert_shimmer_model.dart';
export 'products_vert_shimmer_model.dart';

class ProductsVertShimmerWidget extends StatefulWidget {
  const ProductsVertShimmerWidget({super.key});

  @override
  State<ProductsVertShimmerWidget> createState() =>
      _ProductsVertShimmerWidgetState();
}

class _ProductsVertShimmerWidgetState extends State<ProductsVertShimmerWidget>
    with RouteAware {
  late ProductsVertShimmerModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProductsVertShimmerModel());
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);

    _model.maybeDispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = DebugModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
    debugLogGlobalProperty(context);
  }

  @override
  void didPopNext() {
    if (mounted && DebugFlutterFlowModelContext.maybeOf(context) == null) {
      setState(() => _model.isRouteVisible = true);
      debugLogWidgetClass(_model);
    }
  }

  @override
  void didPush() {
    if (mounted && DebugFlutterFlowModelContext.maybeOf(context) == null) {
      setState(() => _model.isRouteVisible = true);
      debugLogWidgetClass(_model);
    }
  }

  @override
  void didPop() {
    _model.isRouteVisible = false;
  }

  @override
  void didPushNext() {
    _model.isRouteVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    DebugFlutterFlowModelContext.maybeOf(context)
        ?.parentModelCallback
        ?.call(_model);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        0,
        12.0,
        0,
        12.0,
      ),
      scrollDirection: Axis.vertical,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
          child: Builder(
            builder: (context) {
              final dataList = List.generate(random_data.randomInteger(6, 6),
                  (index) => random_data.randomName(true, false)).toList();
              _model.debugGeneratorVariables[
                      'dataList${dataList.length > 100 ? ' (first 100)' : ''}'] =
                  debugSerializeParam(
                dataList.take(100),
                ParamType.String,
                isList: true,
                link:
                    'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductsVertShimmer',
                name: 'String',
                nullable: false,
              );
              debugLogWidgetClass(_model);

              return Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.start,
                direction: Axis.horizontal,
                runAlignment: WrapAlignment.start,
                verticalDirection: VerticalDirection.down,
                clipBehavior: Clip.none,
                children: List.generate(dataList.length, (dataListIndex) {
                  final dataListItem = dataList[dataListIndex];
                  return wrapWithModel(
                    model: _model.mainComponentShimmerModels.getModel(
                      dataListItem,
                      dataListIndex,
                    ),
                    updateCallback: () => safeSetState(() {}),
                    child: Builder(builder: (_) {
                      return DebugFlutterFlowModelContext(
                        rootModel: _model.rootModel,
                        child: MainComponentShimmerWidget(
                          key: Key(
                            'Keydk5_${dataListItem}',
                          ),
                          isBig: true,
                          width: () {
                            if (MediaQuery.sizeOf(context).width < 810.0) {
                              return ((MediaQuery.sizeOf(context).width - 36) *
                                  1 /
                                  2);
                            } else if ((MediaQuery.sizeOf(context).width >=
                                    810.0) &&
                                (MediaQuery.sizeOf(context).width < 1280.0)) {
                              return ((MediaQuery.sizeOf(context).width - 60) *
                                  1 /
                                  4);
                            } else if (MediaQuery.sizeOf(context).width >=
                                1280.0) {
                              return ((MediaQuery.sizeOf(context).width - 84) *
                                  1 /
                                  6);
                            } else {
                              return ((MediaQuery.sizeOf(context).width - 108) *
                                  1 /
                                  8);
                            }
                          }(),
                          height: 298.0,
                        ),
                      );
                    }),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}
