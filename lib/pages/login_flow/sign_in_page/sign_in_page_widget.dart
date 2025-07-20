import 'package:provider/provider.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/actions/actions.dart' as action_blocks;
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'sign_in_page_model.dart';
export 'sign_in_page_model.dart';

class SignInPageWidget extends StatefulWidget {
  const SignInPageWidget({
    super.key,
    bool? isInner,
  }) : this.isInner = isInner ?? true;

  final bool isInner;

  static String routeName = 'SignInPage';
  static String routePath = '/signInPage';

  @override
  State<SignInPageWidget> createState() => _SignInPageWidgetState();
}

class _SignInPageWidgetState extends State<SignInPageWidget> {
  late SignInPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SignInPageModel());
    _model.nameController ??= TextEditingController();
    _model.phoneController ??= TextEditingController();
    _model.passwordController ??= TextEditingController();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // دالة مساعدة لمعالجة تسجيل الدخول الناجح
  Future<void> _handleSuccessfulLogin(ApiCallResponse loginResult) async {
    FFAppState().token = PlantShopGroup.logInCall.token((loginResult.jsonBody ?? ''))!;
    FFAppState().update(() {});

    final userId = await actions.tokenDecoder(FFAppState().token);
    final customerData = await PlantShopGroup.getCustomerCall.call(userId: userId);

    if (customerData.succeeded) {
      FFAppState().userDetail = PlantShopGroup.getCustomerCall.userDetail((customerData.jsonBody ?? ''));
      FFAppState().isLogin = true;
      setState(() {});
      await action_blocks.cartItemCount(context);

      if (widget.isInner) {
        context.safePop();
      } else {
        context.pushReplacementNamed(HomeMainPageWidget.routeName);
      }
    } else {
      await actions.showCustomToastTop('فشل في جلب بيانات المستخدم.');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Form(
            key: _model.formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              children: [
                SizedBox(height: 40),
                Text(
                  'تسجيل الدخول أو إنشاء حساب',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).headlineMedium,
                ),
                SizedBox(height: 8),
                Text(
                  'أدخل بياناتك للمتابعة',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyMedium,
                ),
                SizedBox(height: 48),
                TextFormField(
                  controller: _model.nameController,
                  decoration: InputDecoration(labelText: 'الاسم الكامل'),
                  validator: (val) => val == null || val.isEmpty ? 'الاسم مطلوب' : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _model.phoneController,
                  decoration: InputDecoration(labelText: 'رقم الهاتف'),
                  keyboardType: TextInputType.phone,
                  validator: (val) => val == null || val.isEmpty ? 'رقم الهاتف مطلوب' : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _model.passwordController,
                  obscureText: !_model.passwordVisibility,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    suffixIcon: InkWell(
                      onTap: () => setState(() => _model.passwordVisibility = !_model.passwordVisibility),
                      child: Icon(_model.passwordVisibility ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'كلمة المرور مطلوبة' : null,
                ),
                SizedBox(height: 48),
                FFButtonWidget(
                  onPressed: () async {
                    if (!_model.formKey.currentState!.validate()) return;

                    final phone = _model.phoneController.text;
                    final name = _model.nameController.text;
                    final password = _model.passwordController.text;
                    final email = '$phone@cosmetic.app'; // إنشاء الإيميل تلقائياً
                    final username = phone;

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => Center(child: CircularProgressIndicator()),
                    );

                    // الخطوة 1: محاولة تسجيل الدخول
                    _model.loginResult = await PlantShopGroup.logInCall.call(
                      username: email,
                      password: password,
                    );

                    if (_model.loginResult?.succeeded ?? false) {
                      // نجح تسجيل الدخول
                      Navigator.of(context).pop();
                      await _handleSuccessfulLogin(_model.loginResult!);
                    } else {
                      // فشل تسجيل الدخول، ربما الحساب غير موجود. الخطوة 2: محاولة إنشاء حساب جديد
                      _model.signupResult = await PlantShopGroup.signUpCall.call(
                        email: email,
                        userName: username, // استخدام رقم الهاتف كاسم مستخدم
                        password: password,
                      );

                      if (_model.signupResult?.succeeded ?? false) {
                        // نجح إنشاء الحساب. الخطوة 3: تسجيل الدخول مرة أخرى للحصول على التوكن
                        final newLoginResult = await PlantShopGroup.logInCall.call(
                          username: email,
                          password: password,
                        );

                        if (newLoginResult.succeeded) {
                          // إضافة: تحديث اسم المستخدم بعد إنشاء الحساب
                          final newUserId = await actions.tokenDecoder(PlantShopGroup.logInCall.token((newLoginResult.jsonBody ?? ''))!);
                          await PlantShopGroup.editUserCall.call(
                            userId: newUserId,
                            firstName: name,
                            lastName: '', // يمكن تركه فارغاً
                          );
                          Navigator.of(context).pop();
                          await _handleSuccessfulLogin(newLoginResult);
                        } else {
                          Navigator.of(context).pop();
                          await actions.showCustomToastTop('حدث خطأ بعد إنشاء الحساب. يرجى محاولة تسجيل الدخول يدوياً.');
                        }
                      } else {
                        // فشل إنشاء الحساب (ربما كلمة المرور ضعيفة أو خطأ آخر)
                        Navigator.of(context).pop();
                        await actions.showCustomToastTop(
                          PlantShopGroup.signUpCall.message((_model.signupResult?.jsonBody ?? '')) ?? 'فشل إنشاء الحساب.',
                        );
                      }
                    }
                  },
                  text: 'متابعة',
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 50,
                    color: FlutterFlowTheme.of(context).primary,
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(fontFamily: 'Readex Pro', color: Colors.white),
                    elevation: 3,
                    borderRadius: BorderRadius.circular(8),
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
