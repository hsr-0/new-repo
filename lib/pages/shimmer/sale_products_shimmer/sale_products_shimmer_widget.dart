import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/shimmer/main_component_shimmer/main_component_shimmer_widget.dart';
import 'dart:ui';
import '/flutter_flow/random_data_util.dart' as random_data;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'sale_products_shimmer_model.dart';
export 'sale_products_shimmer_model.dart';

class SaleProductsShimmerWidget extends StatefulWidget {
  const SaleProductsShimmerWidget({super.key});

  @override
  State<SaleProductsShimmerWidget> createState() =>
      _SaleProductsShimmerWidgetState();
}

class _SaleProductsShimmerWidgetState extends State<SaleProductsShimmerWidget>
    with RouteAware {
  late SaleProductsShimmerModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SaleProductsShimmerModel());
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
          color: FlutterFlowTheme.of(context).secondary,
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          FFLocalizations.of(context).getText(
                            '65pggxtc' /* Sale products */,
                          ),
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: 'SF Pro Display',
                                color: FlutterFlowTheme.of(context).primaryText,
                                fontSize: 20.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                                useGoogleFonts: false,
                                lineHeight: 1.5,
                              ),
                        ),
                        Image.asset(
                          'assets/images/smile.png',
                          width: 27.0,
                          height: 27.0,
                          fit: BoxFit.cover,
                        ),
                      ].divide(SizedBox(width: 6.0)),
                    ),
                    Container(
                      height: 29.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondary,
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            10.0, 0.0, 10.0, 0.0),
                        child: Text(
                          FFLocalizations.of(context).getText(
                            '99rv79nx' /* View all */,
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
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                  child: Builder(
                    builder: (context) {
                      final featuredCollectionListSale = List.generate(
                              random_data.randomInteger(4, 4),
                              (index) => random_data.randomName(true, false))
                          .toList()
                          .take(4)
                          .toList();
                      _model.debugGeneratorVariables[
                              'featuredCollectionListSale${featuredCollectionListSale.length > 100 ? ' (first 100)' : ''}'] =
                          debugSerializeParam(
                        featuredCollectionListSale.take(100),
                        ParamType.String,
                        isList: true,
                        link:
                            'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SaleProductsShimmer',
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
                        children:
                            List.generate(featuredCollectionListSale.length,
                                (featuredCollectionListSaleIndex) {
                          final featuredCollectionListSaleItem =
                              featuredCollectionListSale[
                                  featuredCollectionListSaleIndex];
                          return wrapWithModel(
                            model: _model.mainComponentShimmerModels.getModel(
                              featuredCollectionListSaleItem,
                              featuredCollectionListSaleIndex,
                            ),
                            updateCallback: () => safeSetState(() {}),
                            child: Builder(builder: (_) {
                              return DebugFlutterFlowModelContext(
                                rootModel: _model.rootModel,
                                child: MainComponentShimmerWidget(
                                  key: Key(
                                    'Keyrow_${featuredCollectionListSaleItem}',
                                  ),
                                  isBig: true,
                                  width: () {
                                    if (MediaQuery.sizeOf(context).width <
                                        810.0) {
                                      return ((MediaQuery.sizeOf(context)
                                                  .width -
                                              36) *
                                          1 /
                                          2);
                                    } else if ((MediaQuery.sizeOf(context)
                                                .width >=
                                            810.0) &&
                                        (MediaQuery.sizeOf(context).width <
                                            1280.0)) {
                                      return ((MediaQuery.sizeOf(context)
                                                  .width -
                                              60) *
                                          1 /
                                          4);
                                    } else if (MediaQuery.sizeOf(context)
                                            .width >=
                                        1280.0) {
                                      return ((MediaQuery.sizeOf(context)
                                                  .width -
                                              84) *
                                          1 /
                                          6);
                                    } else {
                                      return ((MediaQuery.sizeOf(context)
                                                  .width -
                                              108) *
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
