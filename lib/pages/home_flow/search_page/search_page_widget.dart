import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/empty_components/no_search_component/no_search_component_widget.dart';
import '/pages/shimmer/search_shimmer/search_shimmer_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'search_page_model.dart';
export 'search_page_model.dart';

class SearchPageWidget extends StatefulWidget {
  const SearchPageWidget({super.key});

  static String routeName = 'SearchPage';
  static String routePath = '/searchPage';

  @override
  State<SearchPageWidget> createState() => _SearchPageWidgetState();
}

class _SearchPageWidgetState extends State<SearchPageWidget> with RouteAware {
  late SearchPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SearchPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await action_blocks.responseAction(context);
      safeSetState(() {});
    });

    _model.textController ??= TextEditingController()
      ..addListener(() {
        debugLogWidgetClass(_model);
      });
    _model.textFieldFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);

    _model.dispose();

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

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Container(
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).lightGray,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(2.0, 10.0, 0.0, 6.0),
                        child: InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            context.safePop();
                          },
                          child: Container(
                            decoration: BoxDecoration(),
                            child: Padding(
                              padding: EdgeInsets.all(10.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(0.0),
                                child: SvgPicture.asset(
                                  'assets/images/arrow-left.svg',
                                  width: 24.0,
                                  height: 24.0,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            12.0, 0.0, 12.0, 16.0),
                        child: Container(
                          width: double.infinity,
                          height: 56.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).lightGray,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                16.0, 0.0, 0.0, 0.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(0.0),
                                  child: SvgPicture.asset(
                                    'assets/images/search.svg',
                                    width: 24.0,
                                    height: 24.0,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    child: TextFormField(
                                      controller: _model.textController,
                                      focusNode: _model.textFieldFocusNode,
                                      onChanged: (_) => EasyDebounce.debounce(
                                        '_model.textController',
                                        Duration(milliseconds: 100),
                                        () async {
                                          if (_model.textController.text !=
                                                  null &&
                                              _model.textController.text !=
                                                  '') {
                                            _model.isSearch = true;
                                            safeSetState(() {});
                                          } else {
                                            _model.isSearch = false;
                                            safeSetState(() {});
                                          }
                                        },
                                      ),
                                      onFieldSubmitted: (_) async {
                                        _model.isSearch = false;
                                        safeSetState(() {});
                                        safeSetState(() =>
                                            _model.apiRequestCompleter = null);
                                        await _model
                                            .waitForApiRequestCompleted();
                                      },
                                      autofocus: false,
                                      textInputAction: TextInputAction.search,
                                      obscureText: false,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        hintText:
                                            FFLocalizations.of(context).getText(
                                          's1uo5zgg' /* Search */,
                                        ),
                                        hintStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .override(
                                              fontFamily: 'SF Pro Display',
                                              fontSize: 16.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.normal,
                                              useGoogleFonts: false,
                                            ),
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        focusedErrorBorder: InputBorder.none,
                                        contentPadding:
                                            EdgeInsetsDirectional.fromSTEB(
                                                12.0, 16.5, 20.0, 16.5),
                                        suffixIcon: _model
                                                .textController!.text.isNotEmpty
                                            ? InkWell(
                                                onTap: () async {
                                                  _model.textController
                                                      ?.clear();
                                                  if (_model.textController
                                                              .text !=
                                                          null &&
                                                      _model.textController
                                                              .text !=
                                                          '') {
                                                    _model.isSearch = true;
                                                    safeSetState(() {});
                                                  } else {
                                                    _model.isSearch = false;
                                                    safeSetState(() {});
                                                  }

                                                  safeSetState(() {});
                                                },
                                                child: Icon(
                                                  Icons.clear,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  size: 24.0,
                                                ),
                                              )
                                            : null,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'SF Pro Display',
                                            fontSize: 16.0,
                                            letterSpacing: 0.0,
                                            useGoogleFonts: false,
                                          ),
                                      cursorColor: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      validator: _model.textControllerValidator
                                          .asValidator(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 1.0, 0.0, 0.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primaryBackground,
                      ),
                      child: Builder(
                        builder: (context) {
                          if (FFAppState().connected) {
                            return Builder(
                              builder: (context) {
                                if (FFAppState().response) {
                                  return Builder(
                                    builder: (context) {
                                      if (!_model.isSearch &&
                                          (_model.textController.text != null &&
                                              _model.textController.text !=
                                                  '')) {
                                        return FutureBuilder<ApiCallResponse>(
                                          future: (_model
                                                      .apiRequestCompleter ??=
                                                  Completer<ApiCallResponse>()
                                                    ..complete(PlantShopGroup
                                                        .searchApiCall
                                                        .call(
                                                      search: _model
                                                          .textController.text,
                                                    )))
                                              .future,
                                          builder: (context, snapshot) {
                                            // Customize what your widget looks like when it's loading.
                                            if (!snapshot.hasData) {
                                              return SearchShimmerWidget();
                                            }
                                            final containerSearchApiResponse =
                                                snapshot.data!;
                                            _model.debugBackendQueries[
                                                    'PlantShopGroup.searchApiCall_statusCode_Container_p8fsgllr'] =
                                                debugSerializeParam(
                                              containerSearchApiResponse
                                                  .statusCode,
                                              ParamType.int,
                                              link:
                                                  'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SearchPage',
                                              name: 'int',
                                              nullable: false,
                                            );
                                            _model.debugBackendQueries[
                                                    'PlantShopGroup.searchApiCall_responseBody_Container_p8fsgllr'] =
                                                debugSerializeParam(
                                              containerSearchApiResponse
                                                  .bodyText,
                                              ParamType.String,
                                              link:
                                                  'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SearchPage',
                                              name: 'String',
                                              nullable: false,
                                            );
                                            debugLogWidgetClass(_model);

                                            return Container(
                                              decoration: BoxDecoration(),
                                              child: Builder(
                                                builder: (context) {
                                                  if ((PlantShopGroup
                                                              .searchApiCall
                                                              .status(
                                                            containerSearchApiResponse
                                                                .jsonBody,
                                                          ) ==
                                                          null) &&
                                                      (PlantShopGroup
                                                                  .searchApiCall
                                                                  .searchList(
                                                                containerSearchApiResponse
                                                                    .jsonBody,
                                                              ) !=
                                                              null &&
                                                          (PlantShopGroup
                                                                  .searchApiCall
                                                                  .searchList(
                                                            containerSearchApiResponse
                                                                .jsonBody,
                                                          ))!
                                                              .isNotEmpty)) {
                                                    return Builder(
                                                      builder: (context) {
                                                        final searchList =
                                                            PlantShopGroup
                                                                    .searchApiCall
                                                                    .searchList(
                                                                      containerSearchApiResponse
                                                                          .jsonBody,
                                                                    )
                                                                    ?.toList() ??
                                                                [];
                                                        _model.debugGeneratorVariables[
                                                                'searchList${searchList.length > 100 ? ' (first 100)' : ''}'] =
                                                            debugSerializeParam(
                                                          searchList.take(100),
                                                          ParamType.JSON,
                                                          isList: true,
                                                          link:
                                                              'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=SearchPage',
                                                          name: 'dynamic',
                                                          nullable: false,
                                                        );
                                                        debugLogWidgetClass(
                                                            _model);

                                                        return SingleChildScrollView(
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            children: List.generate(
                                                                    searchList
                                                                        .length,
                                                                    (searchListIndex) {
                                                              final searchListItem =
                                                                  searchList[
                                                                      searchListIndex];
                                                              return Padding(
                                                                padding: EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        12.0,
                                                                        0.0,
                                                                        12.0,
                                                                        0.0),
                                                                child: InkWell(
                                                                  splashColor:
                                                                      Colors
                                                                          .transparent,
                                                                  focusColor: Colors
                                                                      .transparent,
                                                                  hoverColor: Colors
                                                                      .transparent,
                                                                  highlightColor:
                                                                      Colors
                                                                          .transparent,
                                                                  onTap:
                                                                      () async {
                                                                    context
                                                                        .pushNamed(
                                                                      ProductDetailPageWidget
                                                                          .routeName,
                                                                      queryParameters:
                                                                          {
                                                                        'productDetail':
                                                                            serializeParam(
                                                                          searchListItem,
                                                                          ParamType
                                                                              .JSON,
                                                                        ),
                                                                        'upsellIdsList':
                                                                            serializeParam(
                                                                          (getJsonField(
                                                                            searchListItem,
                                                                            r'''$.upsell_ids''',
                                                                            true,
                                                                          ) as List)
                                                                              .map<String>((s) => s.toString())
                                                                              .toList(),
                                                                          ParamType
                                                                              .String,
                                                                          isList:
                                                                              true,
                                                                        ),
                                                                        'relatedIdsList':
                                                                            serializeParam(
                                                                          (getJsonField(
                                                                            searchListItem,
                                                                            r'''$.related_ids''',
                                                                            true,
                                                                          ) as List)
                                                                              .map<String>((s) => s.toString())
                                                                              .toList(),
                                                                          ParamType
                                                                              .String,
                                                                          isList:
                                                                              true,
                                                                        ),
                                                                        'imagesList':
                                                                            serializeParam(
                                                                          getJsonField(
                                                                            searchListItem,
                                                                            r'''$.images''',
                                                                            true,
                                                                          ),
                                                                          ParamType
                                                                              .JSON,
                                                                          isList:
                                                                              true,
                                                                        ),
                                                                      }.withoutNulls,
                                                                    );
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    width: double
                                                                        .infinity,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12.0),
                                                                      border:
                                                                          Border
                                                                              .all(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .black20,
                                                                        width:
                                                                            1.0,
                                                                      ),
                                                                    ),
                                                                    child:
                                                                        Stack(
                                                                      children: [
                                                                        Padding(
                                                                          padding: EdgeInsetsDirectional.fromSTEB(
                                                                              24.0,
                                                                              14.0,
                                                                              24.0,
                                                                              14.0),
                                                                          child:
                                                                              Row(
                                                                            mainAxisSize:
                                                                                MainAxisSize.max,
                                                                            children: [
                                                                              if (('' !=
                                                                                      getJsonField(
                                                                                        searchListItem,
                                                                                        r'''$.images[0].src''',
                                                                                      ).toString()) &&
                                                                                  (getJsonField(
                                                                                        searchListItem,
                                                                                        r'''$.images[0].src''',
                                                                                      ) !=
                                                                                      null) &&
                                                                                  (getJsonField(
                                                                                        searchListItem,
                                                                                        r'''$.images''',
                                                                                      ) !=
                                                                                      null))
                                                                                Padding(
                                                                                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 8.0, 0.0),
                                                                                  child: Container(
                                                                                    decoration: BoxDecoration(
                                                                                      borderRadius: BorderRadius.circular(12.0),
                                                                                    ),
                                                                                    child: ClipRRect(
                                                                                      borderRadius: BorderRadius.circular(12.0),
                                                                                      child: CachedNetworkImage(
                                                                                        fadeInDuration: Duration(milliseconds: 200),
                                                                                        fadeOutDuration: Duration(milliseconds: 200),
                                                                                        imageUrl: getJsonField(
                                                                                          searchListItem,
                                                                                          r'''$.images[0].src''',
                                                                                        ).toString(),
                                                                                        width: 117.0,
                                                                                        height: 113.0,
                                                                                        fit: BoxFit.cover,
                                                                                        errorWidget: (context, error, stackTrace) => Image.asset(
                                                                                          'assets/images/error_image.png',
                                                                                          width: 117.0,
                                                                                          height: 113.0,
                                                                                          fit: BoxFit.cover,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              Expanded(
                                                                                child: Column(
                                                                                  mainAxisSize: MainAxisSize.max,
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                  children: [
                                                                                    if ('0.00' !=
                                                                                        getJsonField(
                                                                                          searchListItem,
                                                                                          r'''$.average_rating''',
                                                                                        ).toString())
                                                                                      Row(
                                                                                        mainAxisSize: MainAxisSize.max,
                                                                                        children: [
                                                                                          Padding(
                                                                                            padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 4.0, 0.0),
                                                                                            child: SvgPicture.asset(
                                                                                              'assets/images/rating.svg',
                                                                                              width: 12.0,
                                                                                              height: 12.0,
                                                                                              fit: BoxFit.fill,
                                                                                            ),
                                                                                          ),
                                                                                          Text(
                                                                                            '${getJsonField(
                                                                                              searchListItem,
                                                                                              r'''$.average_rating''',
                                                                                            ).toString()} (${getJsonField(
                                                                                              searchListItem,
                                                                                              r'''$.rating_count''',
                                                                                            ).toString()})',
                                                                                            textAlign: TextAlign.start,
                                                                                            maxLines: 1,
                                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                  fontFamily: 'SF Pro Display',
                                                                                                  fontSize: 12.0,
                                                                                                  letterSpacing: 0.0,
                                                                                                  fontWeight: FontWeight.bold,
                                                                                                  useGoogleFonts: false,
                                                                                                  lineHeight: 1.0,
                                                                                                ),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    Padding(
                                                                                      padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
                                                                                      child: Text(
                                                                                        functions.removeHtmlEntities(getJsonField(
                                                                                          searchListItem,
                                                                                          r'''$.name''',
                                                                                        ).toString()),
                                                                                        textAlign: TextAlign.start,
                                                                                        maxLines: 2,
                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                              fontFamily: 'SF Pro Display',
                                                                                              fontSize: 16.0,
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FontWeight.w600,
                                                                                              useGoogleFonts: false,
                                                                                              lineHeight: 1.5,
                                                                                            ),
                                                                                      ),
                                                                                    ),
                                                                                    Padding(
                                                                                      padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
                                                                                      child: Row(
                                                                                        mainAxisSize: MainAxisSize.max,
                                                                                        children: [
                                                                                          if (getJsonField(
                                                                                                searchListItem,
                                                                                                r'''$.on_sale''',
                                                                                              ) &&
                                                                                              ('' !=
                                                                                                  getJsonField(
                                                                                                    searchListItem,
                                                                                                    r'''$.regular_price''',
                                                                                                  ).toString()))
                                                                                            Flexible(
                                                                                              child: Padding(
                                                                                                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 8.0, 0.0),
                                                                                                child: Text(
                                                                                                  functions.formatPrice(
                                                                                                      getJsonField(
                                                                                                        searchListItem,
                                                                                                        r'''$.regular_price''',
                                                                                                      ).toString(),
                                                                                                      FFAppState().thousandSeparator,
                                                                                                      FFAppState().decimalSeparator,
                                                                                                      FFAppState().decimalPlaces.toString(),
                                                                                                      FFAppState().currencyPosition,
                                                                                                      FFAppState().currency),
                                                                                                  textAlign: TextAlign.start,
                                                                                                  maxLines: 1,
                                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                        fontFamily: 'SF Pro Display',
                                                                                                        color: FlutterFlowTheme.of(context).black30,
                                                                                                        fontSize: 14.0,
                                                                                                        letterSpacing: 0.0,
                                                                                                        fontWeight: FontWeight.w500,
                                                                                                        decoration: TextDecoration.lineThrough,
                                                                                                        useGoogleFonts: false,
                                                                                                      ),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                          if (getJsonField(
                                                                                                searchListItem,
                                                                                                r'''$.on_sale''',
                                                                                              ) &&
                                                                                              ('' !=
                                                                                                  getJsonField(
                                                                                                    searchListItem,
                                                                                                    r'''$.regular_price''',
                                                                                                  ).toString()))
                                                                                            Flexible(
                                                                                              child: RichText(
                                                                                                textScaler: MediaQuery.of(context).textScaler,
                                                                                                text: TextSpan(
                                                                                                  children: [
                                                                                                    TextSpan(
                                                                                                      text: (100 *
                                                                                                              ((double.parse(getJsonField(
                                                                                                                    searchListItem,
                                                                                                                    r'''$.regular_price''',
                                                                                                                  ).toString())) -
                                                                                                                  (double.parse(getJsonField(
                                                                                                                    searchListItem,
                                                                                                                    r'''$.price''',
                                                                                                                  ).toString()))) ~/
                                                                                                              (double.parse(getJsonField(
                                                                                                                searchListItem,
                                                                                                                r'''$.regular_price''',
                                                                                                              ).toString())))
                                                                                                          .toString(),
                                                                                                      style: TextStyle(
                                                                                                        fontFamily: 'SF Pro Display',
                                                                                                        color: FlutterFlowTheme.of(context).success,
                                                                                                        fontWeight: FontWeight.w500,
                                                                                                        fontSize: 14.0,
                                                                                                      ),
                                                                                                    ),
                                                                                                    TextSpan(
                                                                                                      text: FFLocalizations.of(context).getText(
                                                                                                        'rng28ddd' /* % OFF */,
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
                                                                                                textAlign: TextAlign.start,
                                                                                                maxLines: 1,
                                                                                              ),
                                                                                            ),
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                    Padding(
                                                                                      padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
                                                                                      child: Text(
                                                                                        functions.formatPrice(
                                                                                            getJsonField(
                                                                                              searchListItem,
                                                                                              r'''$.price''',
                                                                                            ).toString(),
                                                                                            FFAppState().thousandSeparator,
                                                                                            FFAppState().decimalSeparator,
                                                                                            FFAppState().decimalPlaces.toString(),
                                                                                            FFAppState().currencyPosition,
                                                                                            FFAppState().currency),
                                                                                        textAlign: TextAlign.start,
                                                                                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                              fontFamily: 'SF Pro Display',
                                                                                              fontSize: 17.0,
                                                                                              letterSpacing: 0.0,
                                                                                              fontWeight: FontWeight.w500,
                                                                                              useGoogleFonts: false,
                                                                                              lineHeight: 1.5,
                                                                                            ),
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        Padding(
                                                                          padding:
                                                                              EdgeInsets.all(8.0),
                                                                          child:
                                                                              Row(
                                                                            mainAxisSize:
                                                                                MainAxisSize.max,
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children:
                                                                                [
                                                                              Builder(
                                                                                builder: (context) {
                                                                                  if (getJsonField(
                                                                                    searchListItem,
                                                                                    r'''$.on_sale''',
                                                                                  )) {
                                                                                    return Container(
                                                                                      decoration: BoxDecoration(
                                                                                        color: FlutterFlowTheme.of(context).primary,
                                                                                        borderRadius: BorderRadius.circular(30.0),
                                                                                      ),
                                                                                      child: Padding(
                                                                                        padding: EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
                                                                                        child: Text(
                                                                                          FFLocalizations.of(context).getText(
                                                                                            'i3ub5o3d' /* SALE */,
                                                                                          ),
                                                                                          textAlign: TextAlign.center,
                                                                                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                                fontFamily: 'SF Pro Display',
                                                                                                color: FlutterFlowTheme.of(context).primaryBackground,
                                                                                                fontSize: 12.0,
                                                                                                letterSpacing: 0.0,
                                                                                                fontWeight: FontWeight.normal,
                                                                                                useGoogleFonts: false,
                                                                                                lineHeight: 1.0,
                                                                                              ),
                                                                                        ),
                                                                                      ),
                                                                                    );
                                                                                  } else {
                                                                                    return Container(
                                                                                      decoration: BoxDecoration(),
                                                                                    );
                                                                                  }
                                                                                },
                                                                              ),
                                                                              InkWell(
                                                                                splashColor: Colors.transparent,
                                                                                focusColor: Colors.transparent,
                                                                                hoverColor: Colors.transparent,
                                                                                highlightColor: Colors.transparent,
                                                                                onTap: () async {
                                                                                  if (FFAppState().isLogin) {
                                                                                    await action_blocks.addorRemoveFavourite(
                                                                                      context,
                                                                                      id: getJsonField(
                                                                                        searchListItem,
                                                                                        r'''$.id''',
                                                                                      ).toString(),
                                                                                    );
                                                                                    safeSetState(() {});
                                                                                  } else {
                                                                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                                      SnackBar(
                                                                                        content: Text(
                                                                                          FFLocalizations.of(context).getVariableText(
                                                                                            enText: 'Please log in first',
                                                                                            arText: 'الرجاء تسجيل الدخول أولاً',
                                                                                          ),
                                                                                          style: TextStyle(
                                                                                            fontFamily: 'SF Pro Display',
                                                                                            color: FlutterFlowTheme.of(context).primaryText,
                                                                                          ),
                                                                                        ),
                                                                                        duration: Duration(milliseconds: 2000),
                                                                                        backgroundColor: FlutterFlowTheme.of(context).secondary,
                                                                                        action: SnackBarAction(
                                                                                          label: FFLocalizations.of(context).getVariableText(
                                                                                            enText: 'Login',
                                                                                            arText: 'تسجيل الدخول',
                                                                                          ),
                                                                                          textColor: FlutterFlowTheme.of(context).primary,
                                                                                          onPressed: () async {
                                                                                            context.pushNamed(SignInPageWidget.routeName);
                                                                                          },
                                                                                        ),
                                                                                      ),
                                                                                    );
                                                                                  }
                                                                                },
                                                                                child: Container(
                                                                                  width: 24.0,
                                                                                  height: 24.0,
                                                                                  decoration: BoxDecoration(
                                                                                    color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                    boxShadow: [
                                                                                      BoxShadow(
                                                                                        blurRadius: 2.0,
                                                                                        color: FlutterFlowTheme.of(context).shadowColor,
                                                                                        offset: Offset(
                                                                                          0.0,
                                                                                          1.0,
                                                                                        ),
                                                                                        spreadRadius: 0.0,
                                                                                      )
                                                                                    ],
                                                                                    shape: BoxShape.circle,
                                                                                  ),
                                                                                  alignment: AlignmentDirectional(0.0, 0.0),
                                                                                  child: Builder(
                                                                                    builder: (context) {
                                                                                      if (FFAppState().wishList.contains(getJsonField(
                                                                                            searchListItem,
                                                                                            r'''$.id''',
                                                                                          ).toString())) {
                                                                                        return Icon(
                                                                                          Icons.favorite_rounded,
                                                                                          color: FlutterFlowTheme.of(context).primary,
                                                                                          size: 16.0,
                                                                                        );
                                                                                      } else {
                                                                                        return Icon(
                                                                                          Icons.favorite_border_rounded,
                                                                                          color: Colors.black,
                                                                                          size: 16.0,
                                                                                        );
                                                                                      }
                                                                                    },
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ].divide(SizedBox(width: 4.0)),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            })
                                                                .divide(SizedBox(
                                                                    height:
                                                                        20.0))
                                                                .addToStart(
                                                                    SizedBox(
                                                                        height:
                                                                            24.0))
                                                                .addToEnd(SizedBox(
                                                                    height:
                                                                        24.0)),
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  } else {
                                                    return wrapWithModel(
                                                      model: _model
                                                          .noSearchComponentModel,
                                                      updateCallback: () =>
                                                          safeSetState(() {}),
                                                      child:
                                                          Builder(builder: (_) {
                                                        return DebugFlutterFlowModelContext(
                                                          rootModel:
                                                              _model.rootModel,
                                                          child:
                                                              NoSearchComponentWidget(),
                                                        );
                                                      }),
                                                    );
                                                  }
                                                },
                                              ),
                                            );
                                          },
                                        );
                                      } else {
                                        return Align(
                                          alignment:
                                              AlignmentDirectional(0.0, -1.0),
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    60.0, 40.0, 60.0, 0.0),
                                            child: FFButtonWidget(
                                              onPressed:
                                                  (_model.textController.text ==
                                                              null ||
                                                          _model.textController
                                                                  .text ==
                                                              '')
                                                      ? null
                                                      : () async {
                                                          _model.isSearch =
                                                              false;
                                                          safeSetState(() {});
                                                          safeSetState(() =>
                                                              _model.apiRequestCompleter =
                                                                  null);
                                                          await _model
                                                              .waitForApiRequestCompleted();
                                                        },
                                              text: FFLocalizations.of(context)
                                                  .getText(
                                                'x3mrwuob' /* Search */,
                                              ),
                                              icon: Icon(
                                                Icons.search_sharp,
                                                color:
                                                    _model.textController
                                                                    .text ==
                                                                null ||
                                                            _model.textController
                                                                    .text ==
                                                                ''
                                                        ? FlutterFlowTheme.of(
                                                                context)
                                                            .primaryText
                                                        : Colors.white,
                                                size: 24.0,
                                              ),
                                              options: FFButtonOptions(
                                                width: double.infinity,
                                                height: 56.0,
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        24.0, 0.0, 24.0, 0.0),
                                                iconPadding:
                                                    EdgeInsetsDirectional
                                                        .fromSTEB(
                                                            0.0, 0.0, 0.0, 0.0),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                textStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .override(
                                                          fontFamily:
                                                              'SF Pro Display',
                                                          color: Colors.white,
                                                          fontSize: 18.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          useGoogleFonts: false,
                                                        ),
                                                elevation: 0.0,
                                                borderSide: BorderSide(
                                                  color: Colors.transparent,
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                                disabledColor:
                                                    FlutterFlowTheme.of(context)
                                                        .secondary,
                                                disabledTextColor:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                } else {
                                  return wrapWithModel(
                                    model: _model.responseComponentModel,
                                    updateCallback: () => safeSetState(() {}),
                                    child: Builder(builder: (_) {
                                      return DebugFlutterFlowModelContext(
                                        rootModel: _model.rootModel,
                                        child: ResponseComponentWidget(),
                                      );
                                    }),
                                  );
                                }
                              },
                            );
                          } else {
                            return Align(
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Lottie.asset(
                                'assets/jsons/No_Wifi.json',
                                width: 150.0,
                                height: 150.0,
                                fit: BoxFit.contain,
                                animate: true,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
