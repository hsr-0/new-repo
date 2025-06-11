import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import '/pages/components/review_component/review_component_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'review_page_model.dart';
export 'review_page_model.dart';

class ReviewPageWidget extends StatefulWidget {
  const ReviewPageWidget({
    super.key,
    required this.reviewsList,
    required this.averageRating,
  });

  final List<dynamic>? reviewsList;
  final String? averageRating;

  static String routeName = 'ReviewPage';
  static String routePath = '/reviewPage';

  @override
  State<ReviewPageWidget> createState() => _ReviewPageWidgetState();
}

class _ReviewPageWidgetState extends State<ReviewPageWidget> with RouteAware {
  late ReviewPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReviewPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await action_blocks.responseAction(context);
      safeSetState(() {});
    });
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
            width: double.infinity,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).lightGray,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                wrapWithModel(
                  model: _model.mainAppbarModel,
                  updateCallback: () => safeSetState(() {}),
                  child: Builder(builder: (_) {
                    return DebugFlutterFlowModelContext(
                      rootModel: _model.rootModel,
                      child: MainAppbarWidget(
                        title: FFLocalizations.of(context).getText(
                          'ipw2it5d' /* Review */,
                        ),
                        isBack: false,
                        isEdit: false,
                        isShare: false,
                        backAction: () async {},
                        editAction: () async {},
                      ),
                    );
                  }),
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (FFAppState().connected) {
                        return Builder(
                          builder: (context) {
                            if (FFAppState().response) {
                              return Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 12.0, 0.0, 0.0),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryBackground,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        20.0, 0.0, 20.0, 0.0),
                                    child: ListView(
                                      padding: EdgeInsets.fromLTRB(
                                        0,
                                        20.0,
                                        0,
                                        20.0,
                                      ),
                                      scrollDirection: Axis.vertical,
                                      children: [
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 16.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Column(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  RichText(
                                                    textScaler:
                                                        MediaQuery.of(context)
                                                            .textScaler,
                                                    text: TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text: valueOrDefault<
                                                              String>(
                                                            widget!
                                                                .averageRating,
                                                            '5.0',
                                                          ),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                fontSize: 28.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                useGoogleFonts:
                                                                    false,
                                                              ),
                                                        ),
                                                        TextSpan(
                                                          text: FFLocalizations
                                                                  .of(context)
                                                              .getText(
                                                            'rz2pb5pt' /*  / 5 */,
                                                          ),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                fontSize: 17.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                useGoogleFonts:
                                                                    false,
                                                              ),
                                                        )
                                                      ],
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            fontFamily:
                                                                'SF Pro Display',
                                                            letterSpacing: 0.0,
                                                            useGoogleFonts:
                                                                false,
                                                          ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 14.0,
                                                                0.0, 8.0),
                                                    child: RatingBarIndicator(
                                                      itemBuilder:
                                                          (context, index) =>
                                                              Icon(
                                                        Icons.star_rounded,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .warning,
                                                      ),
                                                      direction:
                                                          Axis.horizontal,
                                                      rating: double.parse(
                                                          (widget!
                                                              .averageRating!)),
                                                      unratedColor:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .black20,
                                                      itemCount: 5,
                                                      itemSize: 18.0,
                                                    ),
                                                  ),
                                                  RichText(
                                                    textScaler:
                                                        MediaQuery.of(context)
                                                            .textScaler,
                                                    text: TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text: widget!
                                                              .reviewsList!
                                                              .length
                                                              .toString(),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .black30,
                                                                fontSize: 17.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                useGoogleFonts:
                                                                    false,
                                                                lineHeight: 1.5,
                                                              ),
                                                        ),
                                                        TextSpan(
                                                          text: FFLocalizations
                                                                  .of(context)
                                                              .getText(
                                                            'k19ouw6k' /*  Reviews */,
                                                          ),
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'SF Pro Display',
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .black30,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: 17.0,
                                                            height: 1.5,
                                                          ),
                                                        )
                                                      ],
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            fontFamily:
                                                                'SF Pro Display',
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .black30,
                                                            fontSize: 17.0,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            useGoogleFonts:
                                                                false,
                                                            lineHeight: 1.5,
                                                          ),
                                                    ),
                                                    textAlign: TextAlign.start,
                                                    maxLines: 1,
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 90.0,
                                                child: VerticalDivider(
                                                  width: 1.0,
                                                  thickness: 1.0,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .black10,
                                                ),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  4.0,
                                                                  0.0,
                                                                  4.0),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          RatingBarIndicator(
                                                            itemBuilder:
                                                                (context,
                                                                        index) =>
                                                                    Icon(
                                                              Icons
                                                                  .star_rounded,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .warning,
                                                            ),
                                                            direction:
                                                                Axis.horizontal,
                                                            rating: 5.0,
                                                            unratedColor:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .black20,
                                                            itemCount: 5,
                                                            itemSize: 14.0,
                                                          ),
                                                          Expanded(
                                                            child:
                                                                LinearPercentIndicator(
                                                              percent: widget!
                                                                      .reviewsList!
                                                                      .where((e) =>
                                                                          '5' ==
                                                                          (getJsonField(
                                                                            e,
                                                                            r'''$.rating''',
                                                                          ).toString()))
                                                                      .toList()
                                                                      .length /
                                                                  widget!.reviewsList!.length,
                                                              lineHeight: 4.0,
                                                              animation: true,
                                                              animateFromLastPercent:
                                                                  true,
                                                              progressColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .warning,
                                                              backgroundColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .black20,
                                                              barRadius: Radius
                                                                  .circular(
                                                                      20.0),
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${widget!.reviewsList!.where((e) => '5' == (getJsonField(
                                                                  e,
                                                                  r'''$.rating''',
                                                                ).toString())).toList().length <= 9 ? '0' : ''}${widget!.reviewsList?.where((e) => '5' == (getJsonField(
                                                                  e,
                                                                  r'''$.rating''',
                                                                ).toString())).toList()?.length?.toString()}',
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  fontSize:
                                                                      14.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                  useGoogleFonts:
                                                                      false,
                                                                  lineHeight:
                                                                      1.5,
                                                                ),
                                                          ),
                                                        ].divide(SizedBox(
                                                            width: 8.0)),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  4.0,
                                                                  0.0,
                                                                  4.0),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          RatingBarIndicator(
                                                            itemBuilder:
                                                                (context,
                                                                        index) =>
                                                                    Icon(
                                                              Icons
                                                                  .star_rounded,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .warning,
                                                            ),
                                                            direction:
                                                                Axis.horizontal,
                                                            rating: 4.0,
                                                            unratedColor:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .black20,
                                                            itemCount: 5,
                                                            itemSize: 14.0,
                                                          ),
                                                          Expanded(
                                                            child:
                                                                LinearPercentIndicator(
                                                              percent: widget!
                                                                      .reviewsList!
                                                                      .where((e) =>
                                                                          '4' ==
                                                                          (getJsonField(
                                                                            e,
                                                                            r'''$.rating''',
                                                                          ).toString()))
                                                                      .toList()
                                                                      .length /
                                                                  widget!.reviewsList!.length,
                                                              lineHeight: 4.0,
                                                              animation: true,
                                                              animateFromLastPercent:
                                                                  true,
                                                              progressColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .warning,
                                                              backgroundColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .black20,
                                                              barRadius: Radius
                                                                  .circular(
                                                                      20.0),
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${widget!.reviewsList!.where((e) => '4' == (getJsonField(
                                                                  e,
                                                                  r'''$.rating''',
                                                                ).toString())).toList().length <= 9 ? '0' : ''}${widget!.reviewsList?.where((e) => '4' == (getJsonField(
                                                                  e,
                                                                  r'''$.rating''',
                                                                ).toString())).toList()?.length?.toString()}',
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  fontSize:
                                                                      14.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                  useGoogleFonts:
                                                                      false,
                                                                  lineHeight:
                                                                      1.5,
                                                                ),
                                                          ),
                                                        ].divide(SizedBox(
                                                            width: 8.0)),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  4.0,
                                                                  0.0,
                                                                  4.0),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          RatingBarIndicator(
                                                            itemBuilder:
                                                                (context,
                                                                        index) =>
                                                                    Icon(
                                                              Icons
                                                                  .star_rounded,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .warning,
                                                            ),
                                                            direction:
                                                                Axis.horizontal,
                                                            rating: 3.0,
                                                            unratedColor:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .black20,
                                                            itemCount: 5,
                                                            itemSize: 14.0,
                                                          ),
                                                          Expanded(
                                                            child:
                                                                LinearPercentIndicator(
                                                              percent: widget!
                                                                      .reviewsList!
                                                                      .where((e) =>
                                                                          '3' ==
                                                                          (getJsonField(
                                                                            e,
                                                                            r'''$.rating''',
                                                                          ).toString()))
                                                                      .toList()
                                                                      .length /
                                                                  widget!.reviewsList!.length,
                                                              lineHeight: 4.0,
                                                              animation: true,
                                                              animateFromLastPercent:
                                                                  true,
                                                              progressColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .warning,
                                                              backgroundColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .black20,
                                                              barRadius: Radius
                                                                  .circular(
                                                                      20.0),
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${widget!.reviewsList!.where((e) => '3' == (getJsonField(
                                                                  e,
                                                                  r'''$.rating''',
                                                                ).toString())).toList().length <= 9 ? '0' : ''}${widget!.reviewsList?.where((e) => '3' == (getJsonField(
                                                                  e,
                                                                  r'''$.rating''',
                                                                ).toString())).toList()?.length?.toString()}',
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  fontSize:
                                                                      14.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                  useGoogleFonts:
                                                                      false,
                                                                  lineHeight:
                                                                      1.5,
                                                                ),
                                                          ),
                                                        ].divide(SizedBox(
                                                            width: 8.0)),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  4.0,
                                                                  0.0,
                                                                  4.0),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          RatingBarIndicator(
                                                            itemBuilder:
                                                                (context,
                                                                        index) =>
                                                                    Icon(
                                                              Icons
                                                                  .star_rounded,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .warning,
                                                            ),
                                                            direction:
                                                                Axis.horizontal,
                                                            rating: 2.0,
                                                            unratedColor:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .black20,
                                                            itemCount: 5,
                                                            itemSize: 14.0,
                                                          ),
                                                          Expanded(
                                                            child:
                                                                LinearPercentIndicator(
                                                              percent: widget!
                                                                      .reviewsList!
                                                                      .where((e) =>
                                                                          '2' ==
                                                                          (getJsonField(
                                                                            e,
                                                                            r'''$.rating''',
                                                                          ).toString()))
                                                                      .toList()
                                                                      .length /
                                                                  widget!.reviewsList!.length,
                                                              lineHeight: 4.0,
                                                              animation: true,
                                                              animateFromLastPercent:
                                                                  true,
                                                              progressColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .warning,
                                                              backgroundColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .black20,
                                                              barRadius: Radius
                                                                  .circular(
                                                                      20.0),
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${widget!.reviewsList!.where((e) => '2' == (getJsonField(
                                                                  e,
                                                                  r'''$.rating''',
                                                                ).toString())).toList().length <= 9 ? '0' : ''}${widget!.reviewsList?.where((e) => '2' == (getJsonField(
                                                                  e,
                                                                  r'''$.rating''',
                                                                ).toString())).toList()?.length?.toString()}',
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  fontSize:
                                                                      14.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                  useGoogleFonts:
                                                                      false,
                                                                  lineHeight:
                                                                      1.5,
                                                                ),
                                                          ),
                                                        ].divide(SizedBox(
                                                            width: 8.0)),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  4.0,
                                                                  0.0,
                                                                  4.0),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          RatingBarIndicator(
                                                            itemBuilder:
                                                                (context,
                                                                        index) =>
                                                                    Icon(
                                                              Icons
                                                                  .star_rounded,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .warning,
                                                            ),
                                                            direction:
                                                                Axis.horizontal,
                                                            rating: 1.0,
                                                            unratedColor:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .black20,
                                                            itemCount: 5,
                                                            itemSize: 14.0,
                                                          ),
                                                          Expanded(
                                                            child:
                                                                LinearPercentIndicator(
                                                              percent: widget!
                                                                      .reviewsList!
                                                                      .where((e) =>
                                                                          '1' ==
                                                                          (getJsonField(
                                                                            e,
                                                                            r'''$.rating''',
                                                                          ).toString()))
                                                                      .toList()
                                                                      .length /
                                                                  widget!.reviewsList!.length,
                                                              lineHeight: 4.0,
                                                              animation: true,
                                                              animateFromLastPercent:
                                                                  true,
                                                              progressColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .warning,
                                                              backgroundColor:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .black20,
                                                              barRadius: Radius
                                                                  .circular(
                                                                      20.0),
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${widget!.reviewsList!.where((e) => '1' == (getJsonField(
                                                                  e,
                                                                  r'''$.rating''',
                                                                ).toString())).toList().length <= 9 ? '0' : ''}${widget!.reviewsList?.where((e) => '1' == (getJsonField(
                                                                  e,
                                                                  r'''$.rating''',
                                                                ).toString())).toList()?.length?.toString()}',
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  fontSize:
                                                                      14.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                  useGoogleFonts:
                                                                      false,
                                                                  lineHeight:
                                                                      1.5,
                                                                ),
                                                          ),
                                                        ].divide(SizedBox(
                                                            width: 8.0)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ].divide(SizedBox(width: 20.0)),
                                          ),
                                        ),
                                        Builder(
                                          builder: (context) {
                                            final reviewList = widget!
                                                .reviewsList!
                                                .toList()
                                                .take(10)
                                                .toList();
                                            _model.debugGeneratorVariables[
                                                    'reviewList${reviewList.length > 100 ? ' (first 100)' : ''}'] =
                                                debugSerializeParam(
                                              reviewList.take(100),
                                              ParamType.JSON,
                                              isList: true,
                                              link:
                                                  'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=ReviewPage',
                                              name: 'dynamic',
                                              nullable: false,
                                            );
                                            debugLogWidgetClass(_model);

                                            return Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: List.generate(
                                                      reviewList.length,
                                                      (reviewListIndex) {
                                                final reviewListItem =
                                                    reviewList[reviewListIndex];
                                                return wrapWithModel(
                                                  model: _model
                                                      .reviewComponentModels
                                                      .getModel(
                                                    getJsonField(
                                                      reviewListItem,
                                                      r'''$.id''',
                                                    ).toString(),
                                                    reviewListIndex,
                                                  ),
                                                  updateCallback: () =>
                                                      safeSetState(() {}),
                                                  child: Builder(builder: (_) {
                                                    return DebugFlutterFlowModelContext(
                                                      rootModel:
                                                          _model.rootModel,
                                                      child:
                                                          ReviewComponentWidget(
                                                        key: Key(
                                                          'Keyczu_${getJsonField(
                                                            reviewListItem,
                                                            r'''$.id''',
                                                          ).toString()}',
                                                        ),
                                                        image: getJsonField(
                                                          reviewListItem,
                                                          r'''$.reviewer_avatar_urls['48']''',
                                                        ).toString(),
                                                        userName: getJsonField(
                                                          reviewListItem,
                                                          r'''$.reviewer''',
                                                        ).toString(),
                                                        createAt: getJsonField(
                                                          reviewListItem,
                                                          r'''$.date_created''',
                                                        ).toString(),
                                                        rate: double.parse(
                                                            getJsonField(
                                                          reviewListItem,
                                                          r'''$.rating''',
                                                        ).toString()),
                                                        description:
                                                            getJsonField(
                                                          reviewListItem,
                                                          r'''$.review''',
                                                        ).toString(),
                                                        isDivider: reviewListIndex !=
                                                            (widget!.reviewsList!
                                                                    .length -
                                                                1),
                                                      ),
                                                    );
                                                  }),
                                                );
                                              })
                                                  .divide(
                                                      SizedBox(height: 20.0))
                                                  .addToStart(
                                                      SizedBox(height: 16.0))
                                                  .addToEnd(
                                                      SizedBox(height: 16.0)),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
