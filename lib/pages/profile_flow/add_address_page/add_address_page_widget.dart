import '';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/pages/components/main_appbar/main_appbar_widget.dart';
import '/pages/components/response_component/response_component_widget.dart';
import 'dart:ui';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'add_address_page_model.dart';
export 'add_address_page_model.dart';

class AddAddressPageWidget extends StatefulWidget {
  const AddAddressPageWidget({
    super.key,
    bool? isEdit,
    bool? isShipping,
    this.address,
  })  : this.isEdit = isEdit ?? false,
        this.isShipping = isShipping ?? false;

  final bool isEdit;
  final bool isShipping;
  final dynamic address;

  static String routeName = 'AddAddressPage';
  static String routePath = '/addAddressPage';

  @override
  State<AddAddressPageWidget> createState() => _AddAddressPageWidgetState();
}

class _AddAddressPageWidgetState extends State<AddAddressPageWidget>
    with RouteAware {
  late AddAddressPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddAddressPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        Future(() async {
          await action_blocks.responseAction(context);
          safeSetState(() {});
        }),
        Future(() async {
          await action_blocks.listAllCountries(context);
          safeSetState(() {});
        }),
        Future(() async {
          if ('' !=
              getJsonField(
                widget!.address,
                r'''$.phone''',
              ).toString().toString()) {
            _model.code = (String var1) {
              return var1.split(' ').first;
            }(getJsonField(
              widget!.address,
              r'''$.phone''',
            ).toString().toString());
            _model.phone = (String var1) {
              return var1.split(' ').last;
            }(getJsonField(
              widget!.address,
              r'''$.phone''',
            ).toString().toString());
            safeSetState(() {});
          } else {
            _model.code = null;
            _model.phone = null;
            safeSetState(() {});
          }
        }),
      ]);
    });

    _model.textController1 ??= TextEditingController(
        text: getJsonField(
      widget!.address,
      r'''$.first_name''',
    ).toString().toString())
      ..addListener(() {
        debugLogWidgetClass(_model);
      });
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController(
        text: getJsonField(
      widget!.address,
      r'''$.last_name''',
    ).toString().toString())
      ..addListener(() {
        debugLogWidgetClass(_model);
      });
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.textController3 ??= TextEditingController(
        text: getJsonField(
      widget!.address,
      r'''$.email''',
    ).toString().toString())
      ..addListener(() {
        debugLogWidgetClass(_model);
      });
    _model.textFieldFocusNode3 ??= FocusNode();

    _model.textController4 ??= TextEditingController(
        text: getJsonField(
      widget!.address,
      r'''$.address_1''',
    ).toString().toString())
      ..addListener(() {
        debugLogWidgetClass(_model);
      });
    _model.textFieldFocusNode4 ??= FocusNode();

    _model.textController5 ??= TextEditingController(
        text: getJsonField(
      widget!.address,
      r'''$.address_2''',
    ).toString().toString())
      ..addListener(() {
        debugLogWidgetClass(_model);
      });
    _model.textFieldFocusNode5 ??= FocusNode();

    _model.textController6 ??= TextEditingController(
        text: getJsonField(
      widget!.address,
      r'''$.city''',
    ).toString().toString())
      ..addListener(() {
        debugLogWidgetClass(_model);
      });
    _model.textFieldFocusNode6 ??= FocusNode();

    _model.textController7 ??= TextEditingController(
        text: getJsonField(
      widget!.address,
      r'''$.postcode''',
    ).toString().toString())
      ..addListener(() {
        debugLogWidgetClass(_model);
      });
    _model.textFieldFocusNode7 ??= FocusNode();
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
            height: double.infinity,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primaryBackground,
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
                        title: widget!.isEdit
                            ? FFLocalizations.of(context).getVariableText(
                                enText: 'Edit Address',
                                arText: 'تعديل العنوان',
                              )
                            : FFLocalizations.of(context).getVariableText(
                                enText: 'Add Address',
                                arText: 'إضافة عنوان',
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
                              return Container(
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).lightGray,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Form(
                                        key: _model.formKey,
                                        autovalidateMode:
                                            AutovalidateMode.disabled,
                                        child: ListView(
                                          padding: EdgeInsets.fromLTRB(
                                            0,
                                            12.0,
                                            0,
                                            12.0,
                                          ),
                                          scrollDirection: Axis.vertical,
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryBackground,
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                                12.0,
                                                                22.0,
                                                                12.0,
                                                                0.0),
                                                    child: Container(
                                                      width: double.infinity,
                                                      child: TextFormField(
                                                        controller: _model
                                                            .textController1,
                                                        focusNode: _model
                                                            .textFieldFocusNode1,
                                                        autofocus: false,
                                                        textCapitalization:
                                                            TextCapitalization
                                                                .sentences,
                                                        textInputAction:
                                                            TextInputAction
                                                                .next,
                                                        obscureText: false,
                                                        decoration:
                                                            InputDecoration(
                                                          isDense: true,
                                                          labelText:
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .getText(
                                                            '0mjzh96n' /* First name */,
                                                          ),
                                                          labelStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    fontSize:
                                                                        16.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    useGoogleFonts:
                                                                        false,
                                                                  ),
                                                          hintText:
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .getText(
                                                            'gfsim0le' /* Enter first name */,
                                                          ),
                                                          hintStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    fontSize:
                                                                        16.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal,
                                                                    useGoogleFonts:
                                                                        false,
                                                                  ),
                                                          errorStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .error,
                                                                    fontSize:
                                                                        14.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    useGoogleFonts:
                                                                        false,
                                                                  ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .black20,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primaryText,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          errorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .error,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          focusedErrorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .error,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          contentPadding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      20.0,
                                                                      16.5,
                                                                      20.0,
                                                                      16.5),
                                                        ),
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodyMedium
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              fontSize: 16.0,
                                                              letterSpacing:
                                                                  0.0,
                                                              useGoogleFonts:
                                                                  false,
                                                            ),
                                                        cursorColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
                                                        validator: _model
                                                            .textController1Validator
                                                            .asValidator(
                                                                context),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                                12.0,
                                                                29.0,
                                                                12.0,
                                                                0.0),
                                                    child: Container(
                                                      width: double.infinity,
                                                      child: TextFormField(
                                                        controller: _model
                                                            .textController2,
                                                        focusNode: _model
                                                            .textFieldFocusNode2,
                                                        autofocus: false,
                                                        textCapitalization:
                                                            TextCapitalization
                                                                .sentences,
                                                        textInputAction:
                                                            TextInputAction
                                                                .next,
                                                        obscureText: false,
                                                        decoration:
                                                            InputDecoration(
                                                          isDense: true,
                                                          labelText:
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .getText(
                                                            'wm1ho79n' /* Last name */,
                                                          ),
                                                          labelStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    fontSize:
                                                                        16.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    useGoogleFonts:
                                                                        false,
                                                                  ),
                                                          hintText:
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .getText(
                                                            'twgofq5x' /* Enter last name */,
                                                          ),
                                                          hintStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    fontSize:
                                                                        16.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal,
                                                                    useGoogleFonts:
                                                                        false,
                                                                  ),
                                                          errorStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .error,
                                                                    fontSize:
                                                                        14.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    useGoogleFonts:
                                                                        false,
                                                                  ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .black20,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primaryText,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          errorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .error,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          focusedErrorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .error,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          contentPadding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      20.0,
                                                                      16.5,
                                                                      20.0,
                                                                      16.5),
                                                        ),
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodyMedium
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              fontSize: 16.0,
                                                              letterSpacing:
                                                                  0.0,
                                                              useGoogleFonts:
                                                                  false,
                                                            ),
                                                        cursorColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
                                                        validator: _model
                                                            .textController2Validator
                                                            .asValidator(
                                                                context),
                                                      ),
                                                    ),
                                                  ),
                                                  if (!widget!.isShipping)
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  12.0,
                                                                  29.0,
                                                                  12.0,
                                                                  0.0),
                                                      child: Container(
                                                        width: double.infinity,
                                                        child: TextFormField(
                                                          controller: _model
                                                              .textController3,
                                                          focusNode: _model
                                                              .textFieldFocusNode3,
                                                          autofocus: false,
                                                          textCapitalization:
                                                              TextCapitalization
                                                                  .none,
                                                          textInputAction:
                                                              TextInputAction
                                                                  .next,
                                                          obscureText: false,
                                                          decoration:
                                                              InputDecoration(
                                                            isDense: true,
                                                            labelText:
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                              'raa65d3s' /* Email */,
                                                            ),
                                                            labelStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      fontSize:
                                                                          16.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      useGoogleFonts:
                                                                          false,
                                                                    ),
                                                            hintText:
                                                                FFLocalizations.of(
                                                                        context)
                                                                    .getText(
                                                              'knbvh0qk' /* Enter email */,
                                                            ),
                                                            hintStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      fontSize:
                                                                          16.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal,
                                                                      useGoogleFonts:
                                                                          false,
                                                                    ),
                                                            errorStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'SF Pro Display',
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .error,
                                                                      fontSize:
                                                                          14.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      useGoogleFonts:
                                                                          false,
                                                                    ),
                                                            enabledBorder:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .black20,
                                                                width: 1.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12.0),
                                                            ),
                                                            focusedBorder:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                                width: 1.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12.0),
                                                            ),
                                                            errorBorder:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .error,
                                                                width: 1.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12.0),
                                                            ),
                                                            focusedErrorBorder:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .error,
                                                                width: 1.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12.0),
                                                            ),
                                                            contentPadding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        20.0,
                                                                        16.5,
                                                                        20.0,
                                                                        16.5),
                                                          ),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                fontSize: 16.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                useGoogleFonts:
                                                                    false,
                                                              ),
                                                          keyboardType:
                                                              TextInputType
                                                                  .emailAddress,
                                                          cursorColor:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .primaryText,
                                                          validator: _model
                                                              .textController3Validator
                                                              .asValidator(
                                                                  context),
                                                        ),
                                                      ),
                                                    ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                                12.0,
                                                                29.0,
                                                                12.0,
                                                                0.0),
                                                    child: Container(
                                                      width: double.infinity,
                                                      child: TextFormField(
                                                        controller: _model
                                                            .textController4,
                                                        focusNode: _model
                                                            .textFieldFocusNode4,
                                                        autofocus: false,
                                                        textInputAction:
                                                            TextInputAction
                                                                .next,
                                                        obscureText: false,
                                                        decoration:
                                                            InputDecoration(
                                                          isDense: true,
                                                          labelText:
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .getText(
                                                            'p93gq2j9' /* Address line 1 */,
                                                          ),
                                                          labelStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    fontSize:
                                                                        16.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    useGoogleFonts:
                                                                        false,
                                                                  ),
                                                          alignLabelWithHint:
                                                              true,
                                                          hintText:
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .getText(
                                                            'maz889ao' /* Enter address line 1 */,
                                                          ),
                                                          hintStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    fontSize:
                                                                        16.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal,
                                                                    useGoogleFonts:
                                                                        false,
                                                                  ),
                                                          errorStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .error,
                                                                    fontSize:
                                                                        14.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    useGoogleFonts:
                                                                        false,
                                                                  ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .black20,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primaryText,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          errorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .error,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          focusedErrorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .error,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          contentPadding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      20.0,
                                                                      16.5,
                                                                      20.0,
                                                                      16.5),
                                                        ),
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodyMedium
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              fontSize: 16.0,
                                                              letterSpacing:
                                                                  0.0,
                                                              useGoogleFonts:
                                                                  false,
                                                            ),
                                                        keyboardType:
                                                            TextInputType
                                                                .streetAddress,
                                                        cursorColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
                                                        validator: _model
                                                            .textController4Validator
                                                            .asValidator(
                                                                context),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                                12.0,
                                                                29.0,
                                                                12.0,
                                                                10.0),
                                                    child: Container(
                                                      width: double.infinity,
                                                      child: TextFormField(
                                                        controller: _model
                                                            .textController5,
                                                        focusNode: _model
                                                            .textFieldFocusNode5,
                                                        autofocus: false,
                                                        textInputAction:
                                                            TextInputAction
                                                                .next,
                                                        obscureText: false,
                                                        decoration:
                                                            InputDecoration(
                                                          isDense: true,
                                                          labelText:
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .getText(
                                                            'n46yv5wm' /* Address line 2 */,
                                                          ),
                                                          labelStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    fontSize:
                                                                        16.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    useGoogleFonts:
                                                                        false,
                                                                  ),
                                                          alignLabelWithHint:
                                                              true,
                                                          hintText:
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .getText(
                                                            'l99qyk44' /* Enter address line 2 */,
                                                          ),
                                                          hintStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    fontSize:
                                                                        16.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal,
                                                                    useGoogleFonts:
                                                                        false,
                                                                  ),
                                                          errorStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .error,
                                                                    fontSize:
                                                                        14.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    useGoogleFonts:
                                                                        false,
                                                                  ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .black20,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primaryText,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          errorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .error,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          focusedErrorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .error,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          contentPadding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      20.0,
                                                                      16.5,
                                                                      20.0,
                                                                      16.5),
                                                        ),
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodyMedium
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              fontSize: 16.0,
                                                              letterSpacing:
                                                                  0.0,
                                                              useGoogleFonts:
                                                                  false,
                                                            ),
                                                        keyboardType:
                                                            TextInputType
                                                                .streetAddress,
                                                        cursorColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
                                                        validator: _model
                                                            .textController5Validator
                                                            .asValidator(
                                                                context),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                                12.0,
                                                                19.0,
                                                                12.0,
                                                                19.0),
                                                    child: FlutterFlowDropDown<
                                                        String>(
                                                      controller: _model
                                                              .dropDownValueController1 ??=
                                                          FormFieldController<
                                                              String>(
                                                        _model.dropDownValue1 ??=
                                                            '' !=
                                                                    getJsonField(
                                                                      widget!
                                                                          .address,
                                                                      r'''$.country''',
                                                                    ).toString()
                                                                ? getJsonField(
                                                                    FFAppState()
                                                                        .allCountrysList
                                                                        .where((e) =>
                                                                            getJsonField(
                                                                              widget!.address,
                                                                              r'''$.country''',
                                                                            ) ==
                                                                            getJsonField(
                                                                              e,
                                                                              r'''$.code''',
                                                                            ))
                                                                        .toList()
                                                                        .firstOrNull,
                                                                    r'''$.name''',
                                                                  ).toString()
                                                                : '',
                                                      ),
                                                      options: functions
                                                          .getCountryAndStateName(
                                                              FFAppState()
                                                                  .allCountrysList
                                                                  .toList()),
                                                      onChanged: (val) async {
                                                        safeSetState(() => _model
                                                                .dropDownValue1 =
                                                            val);
                                                        safeSetState(() {});
                                                      },
                                                      width: double.infinity,
                                                      height: 54.0,
                                                      searchHintTextStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                letterSpacing:
                                                                    0.0,
                                                                useGoogleFonts:
                                                                    false,
                                                              ),
                                                      searchTextStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                letterSpacing:
                                                                    0.0,
                                                                useGoogleFonts:
                                                                    false,
                                                              ),
                                                      textStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'SF Pro Display',
                                                                fontSize: 16.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                useGoogleFonts:
                                                                    false,
                                                              ),
                                                      hintText:
                                                          FFLocalizations.of(
                                                                  context)
                                                              .getText(
                                                        'idf0u7pp' /* Select  country */,
                                                      ),
                                                      searchHintText:
                                                          FFLocalizations.of(
                                                                  context)
                                                              .getText(
                                                        'ugv5b2h7' /* Search... */,
                                                      ),
                                                      searchCursorColor:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                      icon: Icon(
                                                        Icons
                                                            .keyboard_arrow_down_rounded,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
                                                        size: 24.0,
                                                      ),
                                                      fillColor:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryBackground,
                                                      elevation: 1.0,
                                                      borderColor:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .black20,
                                                      borderWidth: 1.0,
                                                      borderRadius: 8.0,
                                                      margin:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  12.0,
                                                                  0.0,
                                                                  12.0,
                                                                  0.0),
                                                      hidesUnderline: true,
                                                      isOverButton: false,
                                                      isSearchable: true,
                                                      isMultiSelect: false,
                                                    ),
                                                  ),
                                                  if ((_model.dropDownValue1 !=
                                                              null &&
                                                          _model.dropDownValue1 !=
                                                              '') &&
                                                      (functions
                                                          .jsonToListConverter(
                                                              getJsonField(
                                                            FFAppState()
                                                                .allCountrysList
                                                                .where((e) =>
                                                                    _model
                                                                        .dropDownValue1 ==
                                                                    getJsonField(
                                                                      e,
                                                                      r'''$.name''',
                                                                    ).toString())
                                                                .toList()
                                                                .firstOrNull,
                                                            r'''$.states''',
                                                            true,
                                                          )!)
                                                          .isNotEmpty))
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  12.0,
                                                                  0.0,
                                                                  12.0,
                                                                  19.0),
                                                      child:
                                                          FlutterFlowDropDown<
                                                              String>(
                                                        controller: _model
                                                                .dropDownValueController2 ??=
                                                            FormFieldController<
                                                                String>(
                                                          _model
                                                              .dropDownValue2 ??= '' !=
                                                                  getJsonField(
                                                                    widget!
                                                                        .address,
                                                                    r'''$.state''',
                                                                  ).toString()
                                                              ? getJsonField(
                                                                  functions
                                                                      .jsonToListConverter(
                                                                          getJsonField(
                                                                        FFAppState()
                                                                            .allCountrysList
                                                                            .where((e) =>
                                                                                getJsonField(
                                                                                  widget!.address,
                                                                                  r'''$.country''',
                                                                                ) ==
                                                                                getJsonField(
                                                                                  e,
                                                                                  r'''$.code''',
                                                                                ))
                                                                            .toList()
                                                                            .firstOrNull,
                                                                        r'''$.states''',
                                                                        true,
                                                                      )!)
                                                                      .where((e) =>
                                                                          getJsonField(
                                                                            widget!.address,
                                                                            r'''$.state''',
                                                                          ) ==
                                                                          getJsonField(
                                                                            e,
                                                                            r'''$.code''',
                                                                          ))
                                                                      .toList()
                                                                      .firstOrNull,
                                                                  r'''$.name''',
                                                                ).toString()
                                                              : '',
                                                        ),
                                                        options: functions
                                                            .getCountryAndStateName(
                                                                getJsonField(
                                                          FFAppState()
                                                              .allCountrysList
                                                              .where((e) =>
                                                                  _model
                                                                      .dropDownValue1 ==
                                                                  getJsonField(
                                                                    e,
                                                                    r'''$.name''',
                                                                  ).toString())
                                                              .toList()
                                                              .firstOrNull,
                                                          r'''$.states''',
                                                          true,
                                                        )!),
                                                        onChanged: (val) =>
                                                            safeSetState(() =>
                                                                _model.dropDownValue2 =
                                                                    val),
                                                        width: double.infinity,
                                                        height: 54.0,
                                                        searchHintTextStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  letterSpacing:
                                                                      0.0,
                                                                  useGoogleFonts:
                                                                      false,
                                                                ),
                                                        searchTextStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  letterSpacing:
                                                                      0.0,
                                                                  useGoogleFonts:
                                                                      false,
                                                                ),
                                                        textStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'SF Pro Display',
                                                                  fontSize:
                                                                      16.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  useGoogleFonts:
                                                                      false,
                                                                ),
                                                        hintText:
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                          '6kh21akw' /* Select state */,
                                                        ),
                                                        searchHintText:
                                                            FFLocalizations.of(
                                                                    context)
                                                                .getText(
                                                          'thi2wl8q' /* Search... */,
                                                        ),
                                                        searchCursorColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
                                                        icon: Icon(
                                                          Icons
                                                              .keyboard_arrow_down_rounded,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primaryText,
                                                          size: 24.0,
                                                        ),
                                                        fillColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryBackground,
                                                        elevation: 1.0,
                                                        borderColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .black20,
                                                        borderWidth: 1.0,
                                                        borderRadius: 8.0,
                                                        margin:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    12.0,
                                                                    0.0,
                                                                    12.0,
                                                                    0.0),
                                                        hidesUnderline: true,
                                                        isOverButton: false,
                                                        isSearchable: true,
                                                        isMultiSelect: false,
                                                      ),
                                                    ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(12.0, 0.0,
                                                                12.0, 19.0),
                                                    child: Container(
                                                      width: double.infinity,
                                                      child: TextFormField(
                                                        controller: _model
                                                            .textController6,
                                                        focusNode: _model
                                                            .textFieldFocusNode6,
                                                        autofocus: false,
                                                        textCapitalization:
                                                            TextCapitalization
                                                                .sentences,
                                                        textInputAction:
                                                            TextInputAction
                                                                .next,
                                                        obscureText: false,
                                                        decoration:
                                                            InputDecoration(
                                                          isDense: true,
                                                          labelText:
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .getText(
                                                            'fme2q2kk' /* City */,
                                                          ),
                                                          labelStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    fontSize:
                                                                        16.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    useGoogleFonts:
                                                                        false,
                                                                  ),
                                                          hintText:
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .getText(
                                                            '7ex062p0' /* Enter city */,
                                                          ),
                                                          hintStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    fontSize:
                                                                        16.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal,
                                                                    useGoogleFonts:
                                                                        false,
                                                                  ),
                                                          errorStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .error,
                                                                    fontSize:
                                                                        14.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    useGoogleFonts:
                                                                        false,
                                                                  ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .black20,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primaryText,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          errorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .error,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          focusedErrorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .error,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          contentPadding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      20.0,
                                                                      16.5,
                                                                      20.0,
                                                                      16.5),
                                                        ),
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodyMedium
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              fontSize: 16.0,
                                                              letterSpacing:
                                                                  0.0,
                                                              useGoogleFonts:
                                                                  false,
                                                            ),
                                                        cursorColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
                                                        validator: _model
                                                            .textController6Validator
                                                            .asValidator(
                                                                context),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(12.0, 0.0,
                                                                12.0, 19.0),
                                                    child: Container(
                                                      width: double.infinity,
                                                      child: TextFormField(
                                                        controller: _model
                                                            .textController7,
                                                        focusNode: _model
                                                            .textFieldFocusNode7,
                                                        autofocus: false,
                                                        textInputAction:
                                                            TextInputAction
                                                                .next,
                                                        obscureText: false,
                                                        decoration:
                                                            InputDecoration(
                                                          isDense: true,
                                                          labelText:
                                                              FFLocalizations.of(
                                                                      context)
                                                                  .getText(
                                                            'oq9dwncq' /* Pincode */,
                                                          ),
                                                          labelStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    fontSize:
                                                                        16.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    useGoogleFonts:
                                                                        false,
                                                                  ),
                                                          hintStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    fontSize:
                                                                        16.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal,
                                                                    useGoogleFonts:
                                                                        false,
                                                                  ),
                                                          errorStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'SF Pro Display',
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .error,
                                                                    fontSize:
                                                                        14.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    useGoogleFonts:
                                                                        false,
                                                                  ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .black20,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .primaryText,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          errorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .error,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          focusedErrorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .error,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                          ),
                                                          contentPadding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      20.0,
                                                                      16.5,
                                                                      20.0,
                                                                      16.5),
                                                        ),
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodyMedium
                                                            .override(
                                                              fontFamily:
                                                                  'SF Pro Display',
                                                              fontSize: 16.0,
                                                              letterSpacing:
                                                                  0.0,
                                                              useGoogleFonts:
                                                                  false,
                                                            ),
                                                        cursorColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
                                                        validator: _model
                                                            .textController7Validator
                                                            .asValidator(
                                                                context),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(12.0, 0.0,
                                                                12.0, 0.0),
                                                    child: custom_widgets
                                                        .CustomLabelCountryCodeWidget(
                                                      width: double.infinity,
                                                      height: 54.0,
                                                      initialValue: widget!
                                                              .isEdit
                                                          ? ((String var1,
                                                                  String var2) {
                                                              return var1
                                                                  .replaceAll(
                                                                      '$var2 ',
                                                                      '');
                                                            }(
                                                              getJsonField(
                                                                widget!.address,
                                                                r'''$.phone''',
                                                              ).toString(),
                                                              ((String var1) {
                                                                return var1
                                                                    .split(' ')
                                                                    .first;
                                                              }(getJsonField(
                                                                widget!.address,
                                                                r'''$.phone''',
                                                              ).toString()))))
                                                          : _model.phone,
                                                      code: getJsonField(
                                                                FFAppState()
                                                                    .allCountrysList
                                                                    .where((e) =>
                                                                        _model.dropDownValue1 ==
                                                                        getJsonField(
                                                                          e,
                                                                          r'''$.name''',
                                                                        ).toString())
                                                                    .toList()
                                                                    .firstOrNull,
                                                                r'''$.code''',
                                                              ) !=
                                                              null
                                                          ? getJsonField(
                                                              FFAppState()
                                                                  .allCountrysList
                                                                  .where((e) =>
                                                                      _model
                                                                          .dropDownValue1 ==
                                                                      getJsonField(
                                                                        e,
                                                                        r'''$.name''',
                                                                      ).toString())
                                                                  .toList()
                                                                  .firstOrNull,
                                                              r'''$.code''',
                                                            ).toString()
                                                          : FFAppState()
                                                              .countryName,
                                                      updateAction:
                                                          (countryCode,
                                                              phone) async {
                                                        _model.code =
                                                            countryCode;
                                                        _model.phone = phone;
                                                        safeSetState(() {});
                                                      },
                                                    ),
                                                  ),
                                                ]
                                                    .addToStart(
                                                        SizedBox(height: 8.0))
                                                    .addToEnd(
                                                        SizedBox(height: 22.0)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            12.0, 16.0, 12.0, 24.0),
                                        child: FFButtonWidget(
                                          onPressed: () async {
                                            if (_model.formKey.currentState ==
                                                    null ||
                                                !_model.formKey.currentState!
                                                    .validate()) {
                                              return;
                                            }
                                            if (_model.dropDownValue1 == null) {
                                              await actions.showCustomToastTop(
                                                'Please select country',
                                              );
                                              return;
                                            }
                                            if (_model.dropDownValue1 != null &&
                                                _model.dropDownValue1 != '') {
                                              if ((functions
                                                          .jsonToListConverter(
                                                              getJsonField(
                                                            FFAppState()
                                                                .allCountrysList
                                                                .where((e) =>
                                                                    _model
                                                                        .dropDownValue1 ==
                                                                    getJsonField(
                                                                      e,
                                                                      r'''$.name''',
                                                                    ).toString())
                                                                .toList()
                                                                .firstOrNull,
                                                            r'''$.states''',
                                                            true,
                                                          )!)
                                                          .isNotEmpty) &&
                                                      (_model.dropDownValue2 ==
                                                              null ||
                                                          _model.dropDownValue2 ==
                                                              '')
                                                  ? false
                                                  : true) {
                                                if ((_model.phone != null &&
                                                        _model.phone != '') &&
                                                    (_model.code != null &&
                                                        _model.code != '')) {
                                                  if (widget!.isShipping) {
                                                    _model.shippingAddress =
                                                        await PlantShopGroup
                                                            .editShippingAddressCall
                                                            .call(
                                                      userId: getJsonField(
                                                        FFAppState().userDetail,
                                                        r'''$.id''',
                                                      ).toString(),
                                                      firstName: _model
                                                          .textController1.text,
                                                      lastName: _model
                                                          .textController2.text,
                                                      address1: _model
                                                          .textController4.text,
                                                      address2: _model
                                                          .textController5.text,
                                                      city: _model
                                                          .textController6.text,
                                                      state: functions
                                                              .jsonToListConverter(
                                                                  getJsonField(
                                                                FFAppState()
                                                                    .allCountrysList
                                                                    .where((e) =>
                                                                        _model.dropDownValue1 ==
                                                                        getJsonField(
                                                                          e,
                                                                          r'''$.name''',
                                                                        ).toString())
                                                                    .toList()
                                                                    .firstOrNull,
                                                                r'''$.states''',
                                                                true,
                                                              )!)
                                                              .isNotEmpty
                                                          ? getJsonField(
                                                              functions
                                                                  .jsonToListConverter(
                                                                      getJsonField(
                                                                    FFAppState()
                                                                        .allCountrysList
                                                                        .where((e) =>
                                                                            _model.dropDownValue1 ==
                                                                            getJsonField(
                                                                              e,
                                                                              r'''$.name''',
                                                                            ).toString())
                                                                        .toList()
                                                                        .firstOrNull,
                                                                    r'''$.states''',
                                                                    true,
                                                                  )!)
                                                                  .where((e) =>
                                                                      _model
                                                                          .dropDownValue2 ==
                                                                      getJsonField(
                                                                        e,
                                                                        r'''$.name''',
                                                                      ).toString())
                                                                  .toList()
                                                                  .firstOrNull,
                                                              r'''$.code''',
                                                            ).toString()
                                                          : '',
                                                      postcode: _model
                                                          .textController7.text,
                                                      country: getJsonField(
                                                        FFAppState()
                                                            .allCountrysList
                                                            .where((e) =>
                                                                _model
                                                                    .dropDownValue1 ==
                                                                getJsonField(
                                                                  e,
                                                                  r'''$.name''',
                                                                ).toString())
                                                            .toList()
                                                            .firstOrNull,
                                                        r'''$.code''',
                                                      ).toString(),
                                                      phone:
                                                          '${_model.code} ${_model.phone}',
                                                    );

                                                    if (PlantShopGroup
                                                            .editShippingAddressCall
                                                            .status(
                                                          (_model.shippingAddress
                                                                  ?.jsonBody ??
                                                              ''),
                                                        ) ==
                                                        null) {
                                                      _model.success =
                                                          await action_blocks
                                                              .getCustomer(
                                                                  context);
                                                      if (_model.success!) {
                                                        FFAppState()
                                                            .clearCartCache();
                                                        context.safePop();
                                                      }
                                                    } else {
                                                      await actions
                                                          .showCustomToastTop(
                                                        PlantShopGroup
                                                            .editShippingAddressCall
                                                            .message(
                                                          (_model.shippingAddress
                                                                  ?.jsonBody ??
                                                              ''),
                                                        )!,
                                                      );
                                                    }
                                                  } else {
                                                    if (widget!.isEdit) {
                                                      if (widget!.isShipping) {
                                                        _model.shippingAddressEdit =
                                                            await PlantShopGroup
                                                                .editShippingAddressCall
                                                                .call(
                                                          userId: getJsonField(
                                                            FFAppState()
                                                                .userDetail,
                                                            r'''$.id''',
                                                          ).toString(),
                                                          firstName: _model
                                                              .textController1
                                                              .text,
                                                          lastName: _model
                                                              .textController2
                                                              .text,
                                                          address1: _model
                                                              .textController4
                                                              .text,
                                                          address2: _model
                                                              .textController5
                                                              .text,
                                                          city: _model
                                                              .textController6
                                                              .text,
                                                          state: functions
                                                                  .jsonToListConverter(
                                                                      getJsonField(
                                                                    FFAppState()
                                                                        .allCountrysList
                                                                        .where((e) =>
                                                                            _model.dropDownValue1 ==
                                                                            getJsonField(
                                                                              e,
                                                                              r'''$.name''',
                                                                            ).toString())
                                                                        .toList()
                                                                        .firstOrNull,
                                                                    r'''$.states''',
                                                                    true,
                                                                  )!)
                                                                  .isNotEmpty
                                                              ? getJsonField(
                                                                  functions
                                                                      .jsonToListConverter(
                                                                          getJsonField(
                                                                        FFAppState()
                                                                            .allCountrysList
                                                                            .where((e) =>
                                                                                _model.dropDownValue1 ==
                                                                                getJsonField(
                                                                                  e,
                                                                                  r'''$.name''',
                                                                                ).toString())
                                                                            .toList()
                                                                            .firstOrNull,
                                                                        r'''$.states''',
                                                                        true,
                                                                      )!)
                                                                      .where((e) =>
                                                                          _model.dropDownValue2 ==
                                                                          getJsonField(
                                                                            e,
                                                                            r'''$.name''',
                                                                          ).toString())
                                                                      .toList()
                                                                      .firstOrNull,
                                                                  r'''$.code''',
                                                                ).toString()
                                                              : '',
                                                          postcode: _model
                                                              .textController7
                                                              .text,
                                                          country: getJsonField(
                                                            FFAppState()
                                                                .allCountrysList
                                                                .where((e) =>
                                                                    _model
                                                                        .dropDownValue1 ==
                                                                    getJsonField(
                                                                      e,
                                                                      r'''$.name''',
                                                                    ).toString())
                                                                .toList()
                                                                .firstOrNull,
                                                            r'''$.code''',
                                                          ).toString(),
                                                          phone:
                                                              '${_model.code} ${_model.phone}',
                                                        );

                                                        if (PlantShopGroup
                                                                .editShippingAddressCall
                                                                .status(
                                                              (_model.shippingAddressEdit
                                                                      ?.jsonBody ??
                                                                  ''),
                                                            ) ==
                                                            null) {
                                                          _model.successShippingEdit =
                                                              await action_blocks
                                                                  .getCustomer(
                                                                      context);
                                                          if (_model
                                                              .successShippingEdit!) {
                                                            FFAppState()
                                                                .clearCartCache();
                                                            context.safePop();
                                                          }
                                                        } else {
                                                          await actions
                                                              .showCustomToastTop(
                                                            PlantShopGroup
                                                                .editShippingAddressCall
                                                                .message(
                                                              (_model.shippingAddressEdit
                                                                      ?.jsonBody ??
                                                                  ''),
                                                            )!,
                                                          );
                                                        }
                                                      } else {
                                                        _model.billingAddressEdit =
                                                            await PlantShopGroup
                                                                .editBillingAddressCall
                                                                .call(
                                                          userId: getJsonField(
                                                            FFAppState()
                                                                .userDetail,
                                                            r'''$.id''',
                                                          ).toString(),
                                                          firstName: _model
                                                              .textController1
                                                              .text,
                                                          lastName: _model
                                                              .textController2
                                                              .text,
                                                          address1: _model
                                                              .textController4
                                                              .text,
                                                          address2: _model
                                                              .textController5
                                                              .text,
                                                          city: _model
                                                              .textController6
                                                              .text,
                                                          state: functions
                                                                  .jsonToListConverter(
                                                                      getJsonField(
                                                                    FFAppState()
                                                                        .allCountrysList
                                                                        .where((e) =>
                                                                            _model.dropDownValue1 ==
                                                                            getJsonField(
                                                                              e,
                                                                              r'''$.name''',
                                                                            ).toString())
                                                                        .toList()
                                                                        .firstOrNull,
                                                                    r'''$.states''',
                                                                    true,
                                                                  )!)
                                                                  .isNotEmpty
                                                              ? getJsonField(
                                                                  functions
                                                                      .jsonToListConverter(
                                                                          getJsonField(
                                                                        FFAppState()
                                                                            .allCountrysList
                                                                            .where((e) =>
                                                                                _model.dropDownValue1 ==
                                                                                getJsonField(
                                                                                  e,
                                                                                  r'''$.name''',
                                                                                ).toString())
                                                                            .toList()
                                                                            .firstOrNull,
                                                                        r'''$.states''',
                                                                        true,
                                                                      )!)
                                                                      .where((e) =>
                                                                          _model.dropDownValue2 ==
                                                                          getJsonField(
                                                                            e,
                                                                            r'''$.name''',
                                                                          ).toString())
                                                                      .toList()
                                                                      .firstOrNull,
                                                                  r'''$.code''',
                                                                ).toString()
                                                              : '',
                                                          postcode: _model
                                                              .textController7
                                                              .text,
                                                          country: getJsonField(
                                                            FFAppState()
                                                                .allCountrysList
                                                                .where((e) =>
                                                                    _model
                                                                        .dropDownValue1 ==
                                                                    getJsonField(
                                                                      e,
                                                                      r'''$.name''',
                                                                    ).toString())
                                                                .toList()
                                                                .firstOrNull,
                                                            r'''$.code''',
                                                          ).toString(),
                                                          email: _model
                                                              .textController3
                                                              .text,
                                                          phone:
                                                              '${_model.code} ${_model.phone}',
                                                        );

                                                        if (PlantShopGroup
                                                                .editBillingAddressCall
                                                                .status(
                                                              (_model.billingAddressEdit
                                                                      ?.jsonBody ??
                                                                  ''),
                                                            ) ==
                                                            null) {
                                                          _model.successBillingEdit =
                                                              await action_blocks
                                                                  .getCustomer(
                                                                      context);
                                                          if (_model
                                                              .successBillingEdit!) {
                                                            FFAppState()
                                                                .clearCartCache();
                                                            context.safePop();
                                                          }
                                                        } else {
                                                          await actions
                                                              .showCustomToastTop(
                                                            PlantShopGroup
                                                                .editBillingAddressCall
                                                                .message(
                                                              (_model.billingAddressEdit
                                                                      ?.jsonBody ??
                                                                  ''),
                                                            )!,
                                                          );
                                                        }
                                                      }
                                                    } else {
                                                      _model.billingAddress =
                                                          await PlantShopGroup
                                                              .editBillingAddressCall
                                                              .call(
                                                        userId: getJsonField(
                                                          FFAppState()
                                                              .userDetail,
                                                          r'''$.id''',
                                                        ).toString(),
                                                        firstName: _model
                                                            .textController1
                                                            .text,
                                                        lastName: _model
                                                            .textController2
                                                            .text,
                                                        address1: _model
                                                            .textController4
                                                            .text,
                                                        address2: _model
                                                            .textController5
                                                            .text,
                                                        city: _model
                                                            .textController6
                                                            .text,
                                                        state: functions
                                                                .jsonToListConverter(
                                                                    getJsonField(
                                                                  FFAppState()
                                                                      .allCountrysList
                                                                      .where((e) =>
                                                                          _model.dropDownValue1 ==
                                                                          getJsonField(
                                                                            e,
                                                                            r'''$.name''',
                                                                          ).toString())
                                                                      .toList()
                                                                      .firstOrNull,
                                                                  r'''$.states''',
                                                                  true,
                                                                )!)
                                                                .isNotEmpty
                                                            ? getJsonField(
                                                                functions
                                                                    .jsonToListConverter(
                                                                        getJsonField(
                                                                      FFAppState()
                                                                          .allCountrysList
                                                                          .where((e) =>
                                                                              _model.dropDownValue1 ==
                                                                              getJsonField(
                                                                                e,
                                                                                r'''$.name''',
                                                                              ).toString())
                                                                          .toList()
                                                                          .firstOrNull,
                                                                      r'''$.states''',
                                                                      true,
                                                                    )!)
                                                                    .where((e) =>
                                                                        _model.dropDownValue2 ==
                                                                        getJsonField(
                                                                          e,
                                                                          r'''$.name''',
                                                                        ).toString())
                                                                    .toList()
                                                                    .firstOrNull,
                                                                r'''$.code''',
                                                              ).toString()
                                                            : '',
                                                        postcode: _model
                                                            .textController7
                                                            .text,
                                                        country: getJsonField(
                                                          FFAppState()
                                                              .allCountrysList
                                                              .where((e) =>
                                                                  _model
                                                                      .dropDownValue1 ==
                                                                  getJsonField(
                                                                    e,
                                                                    r'''$.name''',
                                                                  ).toString())
                                                              .toList()
                                                              .firstOrNull,
                                                          r'''$.code''',
                                                        ).toString(),
                                                        email: _model
                                                            .textController3
                                                            .text,
                                                        phone:
                                                            '${_model.code} ${_model.phone}',
                                                      );

                                                      if (PlantShopGroup
                                                              .editBillingAddressCall
                                                              .status(
                                                            (_model.billingAddress
                                                                    ?.jsonBody ??
                                                                ''),
                                                          ) ==
                                                          null) {
                                                        _model.shippingAddressAdd =
                                                            await PlantShopGroup
                                                                .editShippingAddressCall
                                                                .call(
                                                          userId: getJsonField(
                                                            FFAppState()
                                                                .userDetail,
                                                            r'''$.id''',
                                                          ).toString(),
                                                          firstName: _model
                                                              .textController1
                                                              .text,
                                                          lastName: _model
                                                              .textController2
                                                              .text,
                                                          address1: _model
                                                              .textController4
                                                              .text,
                                                          address2: _model
                                                              .textController5
                                                              .text,
                                                          city: _model
                                                              .textController6
                                                              .text,
                                                          state: functions
                                                                  .jsonToListConverter(
                                                                      getJsonField(
                                                                    FFAppState()
                                                                        .allCountrysList
                                                                        .where((e) =>
                                                                            _model.dropDownValue1 ==
                                                                            getJsonField(
                                                                              e,
                                                                              r'''$.name''',
                                                                            ).toString())
                                                                        .toList()
                                                                        .firstOrNull,
                                                                    r'''$.states''',
                                                                    true,
                                                                  )!)
                                                                  .isNotEmpty
                                                              ? getJsonField(
                                                                  functions
                                                                      .jsonToListConverter(
                                                                          getJsonField(
                                                                        FFAppState()
                                                                            .allCountrysList
                                                                            .where((e) =>
                                                                                _model.dropDownValue1 ==
                                                                                getJsonField(
                                                                                  e,
                                                                                  r'''$.name''',
                                                                                ).toString())
                                                                            .toList()
                                                                            .firstOrNull,
                                                                        r'''$.states''',
                                                                        true,
                                                                      )!)
                                                                      .where((e) =>
                                                                          _model.dropDownValue2 ==
                                                                          getJsonField(
                                                                            e,
                                                                            r'''$.name''',
                                                                          ).toString())
                                                                      .toList()
                                                                      .firstOrNull,
                                                                  r'''$.code''',
                                                                ).toString()
                                                              : '',
                                                          postcode: _model
                                                              .textController7
                                                              .text,
                                                          country: getJsonField(
                                                            FFAppState()
                                                                .allCountrysList
                                                                .where((e) =>
                                                                    _model
                                                                        .dropDownValue1 ==
                                                                    getJsonField(
                                                                      e,
                                                                      r'''$.name''',
                                                                    ).toString())
                                                                .toList()
                                                                .firstOrNull,
                                                            r'''$.code''',
                                                          ).toString(),
                                                          phone:
                                                              '${_model.code} ${_model.phone}',
                                                        );

                                                        if (PlantShopGroup
                                                                .editShippingAddressCall
                                                                .status(
                                                              (_model.shippingAddressAdd
                                                                      ?.jsonBody ??
                                                                  ''),
                                                            ) ==
                                                            null) {
                                                          _model.successAdd =
                                                              await action_blocks
                                                                  .getCustomer(
                                                                      context);
                                                          if (_model
                                                              .successAdd!) {
                                                            FFAppState()
                                                                .clearCartCache();
                                                            context.safePop();
                                                          }
                                                        } else {
                                                          await actions
                                                              .showCustomToastTop(
                                                            PlantShopGroup
                                                                .editShippingAddressCall
                                                                .message(
                                                              (_model.shippingAddressAdd
                                                                      ?.jsonBody ??
                                                                  ''),
                                                            )!,
                                                          );
                                                        }
                                                      } else {
                                                        await actions
                                                            .showCustomToastTop(
                                                          PlantShopGroup
                                                              .editBillingAddressCall
                                                              .message(
                                                            (_model.billingAddress
                                                                    ?.jsonBody ??
                                                                ''),
                                                          )!,
                                                        );
                                                      }
                                                    }
                                                  }
                                                } else {
                                                  await actions
                                                      .showCustomToastTop(
                                                    FFLocalizations.of(context)
                                                        .getVariableText(
                                                      enText:
                                                          'Please enter phone number',
                                                      arText:
                                                          'الرجاء إدخال رقم الهاتف',
                                                    ),
                                                  );
                                                }
                                              } else {
                                                await actions
                                                    .showCustomToastTop(
                                                  FFLocalizations.of(context)
                                                      .getVariableText(
                                                    enText:
                                                        'Please select state',
                                                    arText:
                                                        'الرجاء تحديد الدولة',
                                                  ),
                                                );
                                              }
                                            } else {
                                              await actions.showCustomToastTop(
                                                FFLocalizations.of(context)
                                                    .getVariableText(
                                                  enText:
                                                      'Please select country',
                                                  arText: 'الرجاء اختيار البلد',
                                                ),
                                              );
                                            }

                                            safeSetState(() {});
                                          },
                                          text: widget!.isEdit
                                              ? FFLocalizations.of(context)
                                                  .getVariableText(
                                                  enText: 'Save',
                                                  arText: 'يحفظ',
                                                )
                                              : FFLocalizations.of(context)
                                                  .getVariableText(
                                                  enText: 'Add',
                                                  arText: 'يضيف',
                                                ),
                                          options: FFButtonOptions(
                                            width: double.infinity,
                                            height: 56.0,
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    20.0, 0.0, 20.0, 0.0),
                                            iconPadding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 0.0, 0.0, 0.0),
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            textStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .override(
                                                      fontFamily:
                                                          'SF Pro Display',
                                                      color: Colors.white,
                                                      letterSpacing: 0.0,
                                                      useGoogleFonts: false,
                                                    ),
                                            elevation: 0.0,
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
