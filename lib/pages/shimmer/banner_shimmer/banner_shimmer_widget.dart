import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:math';
import 'dart:ui';
import '/flutter_flow/random_data_util.dart' as random_data;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'banner_shimmer_model.dart';
export 'banner_shimmer_model.dart';

class BannerShimmerWidget extends StatefulWidget {
  const BannerShimmerWidget({
    super.key,
    bool? isBig,
    required this.image,
  }) : this.isBig = isBig ?? false;

  final bool isBig;
  final String? image;

  @override
  State<BannerShimmerWidget> createState() => _BannerShimmerWidgetState();
}

class _BannerShimmerWidgetState extends State<BannerShimmerWidget>
    with TickerProviderStateMixin, RouteAware {
  late BannerShimmerModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BannerShimmerModel());

    animationsMap.addAll({
      'containerOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ShimmerEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            color: FlutterFlowTheme.of(context).black20,
            angle: 0.524,
          ),
        ],
      ),
      'containerOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ShimmerEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            color: FlutterFlowTheme.of(context).black20,
            angle: 0.524,
          ),
        ],
      ),
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

    return Builder(
      builder: (context) {
        if (widget!.isBig) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primaryBackground,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final bannerList = List.generate(
                            random_data.randomInteger(3, 3),
                            (index) => random_data.randomName(true, false))
                        .toList();
                    _model.debugGeneratorVariables[
                            'bannerList${bannerList.length > 100 ? ' (first 100)' : ''}'] =
                        debugSerializeParam(
                      bannerList.take(100),
                      ParamType.String,
                      isList: true,
                      link:
                          'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=BannerShimmer',
                      name: 'String',
                      nullable: false,
                    );
                    debugLogWidgetClass(_model);

                    return Container(
                      width: double.infinity,
                      height: () {
                        if (MediaQuery.sizeOf(context).width <
                            kBreakpointSmall) {
                          return 154.0;
                        } else if (MediaQuery.sizeOf(context).width <
                            kBreakpointMedium) {
                          return 184.0;
                        } else if (MediaQuery.sizeOf(context).width <
                            kBreakpointLarge) {
                          return 204.0;
                        } else {
                          return 234.0;
                        }
                      }(),
                      child: CarouselSlider.builder(
                        itemCount: bannerList.length,
                        itemBuilder: (context, bannerListIndex, _) {
                          final bannerListItem = bannerList[bannerListIndex];
                          return Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).black10,
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                          ).animateOnPageLoad(
                              animationsMap['containerOnPageLoadAnimation1']!);
                        },
                        carouselController: _model.carouselController ??=
                            CarouselSliderController(),
                        options: CarouselOptions(
                          initialPage: max(0, min(1, bannerList.length - 1)),
                          viewportFraction: 0.8,
                          disableCenter: true,
                          enlargeCenterPage: true,
                          enlargeFactor: 0.25,
                          enableInfiniteScroll: true,
                          scrollDirection: Axis.horizontal,
                          autoPlay: false,
                          onPageChanged: (index, _) =>
                              _model.carouselCurrentIndex = index,
                        ),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 16.0),
                  child: Builder(
                    builder: (context) {
                      final rowList = List.generate(
                              random_data.randomInteger(3, 3),
                              (index) => random_data.randomName(true, false))
                          .toList();
                      _model.debugGeneratorVariables[
                              'rowList${rowList.length > 100 ? ' (first 100)' : ''}'] =
                          debugSerializeParam(
                        rowList.take(100),
                        ParamType.String,
                        isList: true,
                        link:
                            'https://app.flutterflow.io/project/plant-shop-brdbek?tab=uiBuilder&page=BannerShimmer',
                        name: 'String',
                        nullable: false,
                      );
                      debugLogWidgetClass(_model);

                      return Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(rowList.length, (rowListIndex) {
                          final rowListItem = rowList[rowListIndex];
                          return Container(
                            width: 10.0,
                            height: 10.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).black10,
                              shape: BoxShape.circle,
                            ),
                          ).animateOnPageLoad(
                              animationsMap['containerOnPageLoadAnimation2']!);
                        }).divide(SizedBox(width: 4.0)),
                      );
                    },
                  ),
                ),
              ].addToStart(SizedBox(height: 16.0)),
            ),
          );
        } else {
          return Container(
            width: double.infinity,
            height: () {
              if (MediaQuery.sizeOf(context).width < kBreakpointSmall) {
                return 154.0;
              } else if (MediaQuery.sizeOf(context).width < kBreakpointMedium) {
                return 184.0;
              } else if (MediaQuery.sizeOf(context).width < kBreakpointLarge) {
                return 204.0;
              } else {
                return 234.0;
              }
            }(),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: CachedNetworkImage(
                fadeInDuration: Duration(milliseconds: 200),
                fadeOutDuration: Duration(milliseconds: 200),
                imageUrl: widget!.image!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (context, error, stackTrace) => Image.asset(
                  'assets/images/error_image.png',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
