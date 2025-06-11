// Automatic FlutterFlow imports
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:flutter_svg/flutter_svg.dart';

class SliverAppBarCustom extends StatefulWidget {
  const SliverAppBarCustom({
    super.key,
    this.width,
    this.height,
    required this.backAction,
    required this.favouriteAction,
    required this.searchAction,
    required this.cartAction,
    required this.imageWidget,
    required this.detailWidget,
    required this.productId,
  });

  final double? width;
  final double? height;
  final Future Function() backAction;
  final Future Function() favouriteAction;
  final Future Function() searchAction;
  final Future Function() cartAction;
  final Widget Function() imageWidget;
  final Widget Function() detailWidget;
  final String productId;

  @override
  State<SliverAppBarCustom> createState() => _SliverAppBarCustomState();
}

class _SliverAppBarCustomState extends State<SliverAppBarCustom> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          pinned: true,
          snap: false,
          floating: false,
          toolbarHeight: 72,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shadowColor: Colors.black12,
          expandedHeight: 423,
          leadingWidth: 64,
          elevation: 0,
          leading: InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              await widget.backAction.call();
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 12),
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).black10,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: SvgPicture.asset(
                      'assets/images/back.svg',
                      width: 24.0,
                      height: 24.0,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () async {
                await widget.favouriteAction.call();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).black10,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Builder(
                    builder: (context) {
                      if (FFAppState().wishList.contains(widget.productId)) {
                        return Icon(
                          Icons.favorite_rounded,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 24.0,
                        );
                      } else {
                        return Icon(
                          Icons.favorite_border_rounded,
                          color: Colors.black,
                          size: 24.0,
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 12,
            ),
            InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () async {
                await widget.searchAction.call();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).black10,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: SvgPicture.asset(
                      'assets/images/search.svg',
                      width: 24.0,
                      height: 24.0,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 12,
            ),
            InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () async {
                await widget.cartAction.call();
              },
              child: Container(
                decoration: BoxDecoration(),
                child: Stack(
                  alignment: AlignmentDirectional(1.3, -2.2),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).black10,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.black,
                          size: 24.0,
                        ),
                      ),
                    ),
                    if ((FFAppState().cartCount != '0') && FFAppState().isLogin)
                      Container(
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primary,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Text(
                            FFAppState().cartCount,
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'SF Pro Display',
                                  color: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  fontSize: 13.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.normal,
                                  useGoogleFonts: false,
                                  lineHeight: 1.5,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 12,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(background: widget.imageWidget()),
        ),
        SliverList(
          delegate: SliverChildListDelegate(
            [
              widget.detailWidget(),
            ],
          ),
        ),
      ],
    );
  }
}
