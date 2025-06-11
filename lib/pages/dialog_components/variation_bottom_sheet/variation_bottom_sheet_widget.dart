import '';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/custom_drop_down/custom_drop_down_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'variation_bottom_sheet_model.dart';
export 'variation_bottom_sheet_model.dart';

class VariationBottomSheetWidget extends StatefulWidget {
  const VariationBottomSheetWidget({
    super.key,
    int? qty,
    required this.attributesList,
    required this.allVariationsList,
  }) : this.qty = qty ?? 1;

  final int qty;
  final List<dynamic>? attributesList;
  final List<dynamic>? allVariationsList;

  @override
  State<VariationBottomSheetWidget> createState() =>
      _VariationBottomSheetWidgetState();
}

class _VariationBottomSheetWidgetState extends State<VariationBottomSheetWidget>
    with RouteAware {
  late VariationBottomSheetModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VariationBottomSheetModel());

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.process = true;
      safeSetState(() {});
      await Future.wait([
        Future(() async {
          _model.qty = widget!.qty;
          safeSetState(() {});
        }),
        Future(() async {
          while (_model.index < widget!.attributesList!.length) {
            _model.addToSelectedValuesList('');
            _model.index = _model.index + 1;
            safeSetState(() {});
          }
        }),
      ]);
      _model.process = false;
      safeSetState(() {});
    });
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
    context.watch<FFAppState>();

    return Align(
      alignment: AlignmentDirectional(0.0, 1.0),
      child: Container(
        width: double.infinity,
        height: MediaQuery.sizeOf(context).height * 0.6,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(0.0),
            bottomRight: Radius.circular(0.0),
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 10.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    FFLocalizations.of(context).getText(
                      's0c8m3r9' /* Variation */,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'SF Pro Display',
                          fontSize: 20.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                          useGoogleFonts: false,
                          lineHeight: 1.5,
                        ),
                  ),
                  InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).black10,
                        shape: BoxShape.circle,
                      ),
                      alignment: AlignmentDirectional(0.0, 0.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(0.0),
                        child: SvgPicture.asset(
                          'assets/images/close.svg',
                          width: 20.0,
                          height: 20.0,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final attributesList = widget!.attributesList!.toList();
                  _model.debugGeneratorVariables[
                          'attributesList${attributesList.length > 100 ? ' (first 100)' : ''}'] =
                      debugSerializeParam(
                    attributesList.take(100),
                    ParamType.JSON,
                    isList: true,
                    link:
                        'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=VariationBottomSheet',
                    name: 'dynamic',
                    nullable: false,
                  );
                  debugLogWidgetClass(_model);

                  return SingleChildScrollView(
                    primary: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: List.generate(attributesList.length,
                              (attributesListIndex) {
                        final attributesListItem =
                            attributesList[attributesListIndex];
                        return Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 8.0),
                              child: Text(
                                getJsonField(
                                  attributesListItem,
                                  r'''$.name''',
                                ).toString(),
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'SF Pro Display',
                                      fontSize: 17.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                      useGoogleFonts: false,
                                      lineHeight: 1.5,
                                    ),
                              ),
                            ),
                            wrapWithModel(
                              model: _model.customDropDownModels.getModel(
                                getJsonField(
                                  attributesListItem,
                                  r'''$.slug''',
                                ).toString(),
                                attributesListIndex,
                              ),
                              updateCallback: () => safeSetState(() {}),
                              child: Builder(builder: (_) {
                                return DebugFlutterFlowModelContext(
                                  rootModel: _model.rootModel,
                                  child: CustomDropDownWidget(
                                    key: Key(
                                      'Key7kp_${getJsonField(
                                        attributesListItem,
                                        r'''$.slug''',
                                      ).toString()}',
                                    ),
                                    hintText: 'Select ${getJsonField(
                                      attributesListItem,
                                      r'''$.name''',
                                    ).toString()}',
                                    options: (getJsonField(
                                      attributesListItem,
                                      r'''$.options''',
                                      true,
                                    ) as List)
                                        .map<String>((s) => s.toString())
                                        .toList()!,
                                    selectAction: (value) async {
                                      _model.updateSelectedValuesListAtIndex(
                                        attributesListIndex,
                                        (_) => value,
                                      );
                                      safeSetState(() {});
                                      _model.productDetail =
                                          functions.findVariations(
                                              widget!.allVariationsList!
                                                  .toList(),
                                              _model.selectedValuesList
                                                  .toList());
                                      safeSetState(() {});
                                    },
                                  ),
                                );
                              }),
                            ),
                          ],
                        );
                      })
                          .divide(SizedBox(height: 16.0))
                          .addToStart(SizedBox(height: 10.0))
                          .addToEnd(SizedBox(height: 10.0)),
                    ),
                  );
                },
              ),
            ),
            if (_model.productDetail != null
                ? (getJsonField(
                      _model.productDetail,
                      r'''$.on_sale''',
                    ) &&
                    ('' !=
                        getJsonField(
                          _model.productDetail,
                          r'''$.regular_price''',
                        ).toString()) &&
                    !_model.selectedValuesList.contains(''))
                : false)
              Align(
                alignment: AlignmentDirectional(1.0, 0.0),
                child: Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(16.0, 10.0, 16.0, 0.0),
                  child: RichText(
                    textScaler: MediaQuery.of(context).textScaler,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: (100 *
                                  ((double.parse(getJsonField(
                                        _model.productDetail,
                                        r'''$.regular_price''',
                                      ).toString())) -
                                      (double.parse(getJsonField(
                                        _model.productDetail,
                                        r'''$.price''',
                                      ).toString()))) ~/
                                  (double.parse(getJsonField(
                                    _model.productDetail,
                                    r'''$.regular_price''',
                                  ).toString())))
                              .toString(),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'SF Pro Display',
                                    color: FlutterFlowTheme.of(context).success,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    useGoogleFonts: false,
                                  ),
                        ),
                        TextSpan(
                          text: FFLocalizations.of(context).getText(
                            'h8z831pa' /* % OFF */,
                          ),
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            color: FlutterFlowTheme.of(context).success,
                            fontWeight: FontWeight.w500,
                            fontSize: 14.0,
                          ),
                        )
                      ],
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            color: FlutterFlowTheme.of(context).success,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w500,
                            useGoogleFonts: false,
                          ),
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                  16.0,
                  valueOrDefault<double>(
                    (_model.productDetail != null
                            ? (getJsonField(
                                  _model.productDetail,
                                  r'''$.on_sale''',
                                ) &&
                                ('' !=
                                    getJsonField(
                                      _model.productDetail,
                                      r'''$.regular_price''',
                                    ).toString()) &&
                                !_model.selectedValuesList.contains(''))
                            : false)
                        ? 6.0
                        : 16.0,
                    0.0,
                  ),
                  16.0,
                  0.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: AlignmentDirectional(1.0, 0.0),
                    child: Text(
                      functions.formatPrice(
                          _model.selectedValuesList.contains('')
                              ? '00'
                              : getJsonField(
                                  _model.productDetail,
                                  r'''$.price''',
                                ).toString(),
                          FFAppState().thousandSeparator,
                          FFAppState().decimalSeparator,
                          FFAppState().decimalPlaces.toString(),
                          FFAppState().currencyPosition,
                          FFAppState().currency),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            fontSize: 17.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            useGoogleFonts: false,
                            lineHeight: 1.5,
                          ),
                    ),
                  ),
                  if (_model.productDetail != null
                      ? (getJsonField(
                            _model.productDetail,
                            r'''$.on_sale''',
                          ) &&
                          ('' !=
                              getJsonField(
                                _model.productDetail,
                                r'''$.regular_price''',
                              ).toString()) &&
                          !_model.selectedValuesList.contains(''))
                      : false)
                    Text(
                      functions.formatPrice(
                          getJsonField(
                            _model.productDetail,
                            r'''$.regular_price''',
                          ).toString(),
                          FFAppState().thousandSeparator,
                          FFAppState().decimalSeparator,
                          FFAppState().decimalPlaces.toString(),
                          FFAppState().currencyPosition,
                          FFAppState().currency),
                      textAlign: TextAlign.start,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'SF Pro Display',
                            color: FlutterFlowTheme.of(context).black30,
                            fontSize: 14.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.lineThrough,
                            useGoogleFonts: false,
                            lineHeight: 1.5,
                          ),
                    ),
                ].divide(SizedBox(width: 2.0)),
              ),
            ),
            Align(
              alignment: AlignmentDirectional(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                ),
                child: Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Container(
                          height: 56.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).primary,
                              width: 1.0,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                12.0, 0.0, 12.0, 0.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    if (_model.qty > 1) {
                                      _model.qty = _model.qty + -1;
                                      safeSetState(() {});
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .lightGray,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.remove,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        size: 24.0,
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  _model.qty <= 9
                                      ? '0${_model.qty.toString()}'
                                      : _model.qty.toString(),
                                  textAlign: TextAlign.start,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'SF Pro Display',
                                        fontSize: 18.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        useGoogleFonts: false,
                                        lineHeight: 1.2,
                                      ),
                                ),
                                InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    _model.qty = _model.qty + 1;
                                    safeSetState(() {});
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .lightGray,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.add,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        size: 24.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: FFButtonWidget(
                          onPressed: _model.process
                              ? null
                              : () async {
                                  if (FFAppState().connected) {
                                    if (_model.selectedValuesList
                                        .contains('')) {
                                      await actions.showCustomToastTop(
                                        FFLocalizations.of(context)
                                            .getVariableText(
                                          enText: 'Please select variations',
                                          arText: 'الرجاء تحديد الاختلافات',
                                        ),
                                      );
                                    } else {
                                      _model.success =
                                          await action_blocks.addtoCartAction(
                                        context,
                                        id: getJsonField(
                                          _model.productDetail,
                                          r'''$.id''',
                                        ),
                                        quantity: _model.qty.toString(),
                                        variation:
                                            functions.addToCartListConverter(
                                                widget!.attributesList!
                                                    .toList(),
                                                _model.selectedValuesList
                                                    .toList()),
                                      );
                                      if (_model.success!) {
                                        Navigator.pop(context);
                                      }
                                    }
                                  } else {
                                    await action_blocks.internetTost(context);
                                    safeSetState(() {});
                                  }

                                  safeSetState(() {});
                                },
                          text: FFLocalizations.of(context).getText(
                            'fq51bqn7' /* Add to Cart */,
                          ),
                          options: FFButtonOptions(
                            width: double.infinity,
                            height: 56.0,
                            padding: EdgeInsetsDirectional.fromSTEB(
                                20.0, 0.0, 20.0, 0.0),
                            iconPadding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            color: FlutterFlowTheme.of(context).primary,
                            textStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .override(
                                  fontFamily: 'SF Pro Display',
                                  color: Colors.white,
                                  fontSize: 18.0,
                                  letterSpacing: 0.0,
                                  useGoogleFonts: false,
                                ),
                            elevation: 0.0,
                            borderRadius: BorderRadius.circular(12.0),
                            disabledColor:
                                FlutterFlowTheme.of(context).secondary,
                            disabledTextColor:
                                FlutterFlowTheme.of(context).primaryText,
                          ),
                        ),
                      ),
                    ].divide(SizedBox(width: 12.0)),
                  ),
                ),
              ),
            ),
          ].addToStart(SizedBox(height: 16.0)).addToEnd(SizedBox(height: 16.0)),
        ),
      ),
    );
  }
}
