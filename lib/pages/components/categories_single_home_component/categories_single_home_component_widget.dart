import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'categories_single_home_component_model.dart';
export 'categories_single_home_component_model.dart';

class CategoriesSingleHomeComponentWidget extends StatefulWidget {
  const CategoriesSingleHomeComponentWidget({
    super.key,
    required this.image,
    required this.name,
    required this.width,
    required this.isMainTap,
    required this.showImage,
  });

  final String? image;
  final String? name;
  final double? width;
  final Future Function()? isMainTap;
  final bool? showImage;

  @override
  State<CategoriesSingleHomeComponentWidget> createState() =>
      _CategoriesSingleHomeComponentWidgetState();
}

class _CategoriesSingleHomeComponentWidgetState
    extends State<CategoriesSingleHomeComponentWidget> with RouteAware {
  late CategoriesSingleHomeComponentModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CategoriesSingleHomeComponentModel());
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

    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () async {
        await widget.isMainTap?.call();
      },
      child: Container(
        width: widget!.width,
        height: 140.0,
        decoration: BoxDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget!.showImage ?? true)
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(2.0, 0.0, 2.0, 6.0),
                child: Hero(
                  tag: widget!.image!,
                  transitionOnUserGestures: true,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: CachedNetworkImage(
                      fadeInDuration: Duration(milliseconds: 200),
                      fadeOutDuration: Duration(milliseconds: 200),
                      imageUrl: widget!.image!,
                      width: double.infinity,
                      height: 79.0,
                      fit: BoxFit.cover,
                      alignment: Alignment(0.0, 0.0),
                      errorWidget: (context, error, stackTrace) => Image.asset(
                        'assets/images/error_image.png',
                        width: double.infinity,
                        height: 79.0,
                        fit: BoxFit.cover,
                        alignment: Alignment(0.0, 0.0),
                      ),
                    ),
                  ),
                ),
              ),
            Text(
              functions.removeHtmlEntities(valueOrDefault<String>(
                widget!.name,
                'Name',
              )),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'SF Pro Display',
                    fontSize: 17.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                    useGoogleFonts: false,
                    lineHeight: 1.5,
                  ),
            ),
            if (widget!.showImage ?? true) Spacer(),
          ],
        ),
      ),
    );
  }
}
