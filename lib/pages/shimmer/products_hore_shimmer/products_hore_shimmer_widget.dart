import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/shimmer/main_component_shimmer/main_component_shimmer_widget.dart';
import 'dart:ui';
import '/flutter_flow/random_data_util.dart' as random_data;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'products_hore_shimmer_model.dart';
export 'products_hore_shimmer_model.dart';

class ProductsHoreShimmerWidget extends StatefulWidget {
  const ProductsHoreShimmerWidget({
    super.key,
    required this.name,
  });

  final String? name;

  @override
  State<ProductsHoreShimmerWidget> createState() =>
      _ProductsHoreShimmerWidgetState();
}

class _ProductsHoreShimmerWidgetState extends State<ProductsHoreShimmerWidget>
    with RouteAware {
  late ProductsHoreShimmerModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProductsHoreShimmerModel());
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

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      valueOrDefault<String>(
                        widget!.name,
                        'Trending products',
                      ),
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            color: FlutterFlowTheme.of(context).primaryText,
                            fontSize: 20.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            useGoogleFonts: false,
                            lineHeight: 1.5,
                          ),
                    ),
                    Container(
                      height: 29.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).black10,
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            10.0, 0.0, 10.0, 0.0),
                        child: Text(
                          FFLocalizations.of(context).getText(
                            'taf09wse' /* View all */,
                          ),
                          textAlign: TextAlign.start,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.normal,
                                    useGoogleFonts: false,
                                    lineHeight: 1.0,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(),
                child: Builder(
                  builder: (context) {
                    final trendingProductsList = List.generate(
                            random_data.randomInteger(6, 6),
                            (index) => random_data.randomName(true, false))
                        .toList()
                        .take(6)
                        .toList();
                    _model.debugGeneratorVariables[
                            'trendingProductsList${trendingProductsList.length > 100 ? ' (first 100)' : ''}'] =
                        debugSerializeParam(
                      trendingProductsList.take(100),
                      ParamType.String,
                      isList: true,
                      link:
                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ProductsHoreShimmer',
                      name: 'String',
                      nullable: false,
                    );
                    debugLogWidgetClass(_model);

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: List.generate(trendingProductsList.length,
                                (trendingProductsListIndex) {
                          final trendingProductsListItem =
                              trendingProductsList[trendingProductsListIndex];
                          return wrapWithModel(
                            model: _model.mainComponentShimmerModels.getModel(
                              trendingProductsListItem,
                              trendingProductsListIndex,
                            ),
                            updateCallback: () => safeSetState(() {}),
                            child: Builder(builder: (_) {
                              return DebugFlutterFlowModelContext(
                                rootModel: _model.rootModel,
                                child: MainComponentShimmerWidget(
                                  key: Key(
                                    'Keygyo_${trendingProductsListItem}',
                                  ),
                                  isBig: true,
                                  width: 189.0,
                                  height: 298.0,
                                ),
                              );
                            }),
                          );
                        })
                            .divide(SizedBox(width: 12.0))
                            .addToStart(SizedBox(width: 12.0))
                            .addToEnd(SizedBox(width: 12.0)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
