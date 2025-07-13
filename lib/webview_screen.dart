import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // لإضافته، قم بتشغيل: flutter pub add connectivity_plus

class WebViewScreen extends StatefulWidget {
  final String title;
  final String url;

  WebViewScreen({required this.title, required this.url});

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  // متغيرات الحالة لإدارة واجهة المستخدم
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = 'لا يوجد اتصال بالإنترنت';

  @override
  void initState() {
    super.initState();

    // 1. التحقق من حالة الاتصال بالإنترنت بشكل مستمر
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // إذا لم يكن هناك اتصال
      if (results.contains(ConnectivityResult.none)) {
        setState(() {
          _isError = true;
          _errorMessage = 'الرجاء التحقق من اتصالك بالإنترنت';
        });
      } else {
        // إذا عاد الاتصال وكان هناك خطأ سابق، قم بإعادة تحميل الصفحة
        if (_isError) {
          setState(() {
            _isError = false;
          });
          _controller.reload();
        }
      }
    });

    // 2. إعداد WebViewController مع معالجة الأخطاء
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _isError = false; // إعادة تعيين حالة الخطأ عند بدء تحميل صفحة جديدة
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            // 3. التعامل مع أخطاء تحميل الويب بشكل صريح
            // هذا هو الجزء الأهم لمنع ظهور شاشة الخطأ الافتراضية
            setState(() {
              _isLoading = false;
              _isError = true;
              // تخصيص رسالة الخطأ بناءً على نوع الخطأ
              switch (error.errorCode) {
                case -2: // net::ERR_INTERNET_DISCONNECTED
                  _errorMessage = 'لا يوجد اتصال بالإنترنت. حاول مرة أخرى.';
                  break;
                case -6: // net::ERR_CONNECTION_REFUSED
                  _errorMessage = 'تم رفض الاتصال من الخادم.';
                  break;
                default:
                  _errorMessage = 'حدث خطأ غير متوقع. الرجاء المحاولة مرة أخرى.';
              }
            });
          },
          onNavigationRequest: (NavigationRequest request) async {
            // التعامل مع الروابط الخارجية
            if (_shouldOpenExternally(request.url)) {
              await _launchExternalUrl(request.url);
              return NavigationDecision.prevent; // منع WebView من الانتقال للرابط
            }
            return NavigationDecision.navigate; // السماح بالانتقال داخل WebView
          },
        ),
      )
      ..loadRequest(
        Uri.parse(widget.url),
        headers: {'Cache-Control': 'no-cache, no-store, must-revalidate'}, // تعطيل الكاش لتجنب تحميل صفحات خطأ قديمة
      );
  }

  // التحقق من الروابط التي يجب فتحها خارج التطبيق
  bool _shouldOpenExternally(String url) {
    final List<String> externalSchemes = ['tel:', 'mailto:', 'whatsapp:', 'sms:', 'intent:'];
    return externalSchemes.any((scheme) => url.startsWith(scheme)) || url.contains('wa.me');
  }

  // فتح الرابط في تطبيق خارجي
  Future<void> _launchExternalUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('لا يمكن فتح الرابط: $url');
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء محاولة فتح الرابط.');
    }
  }

  // إظهار رسالة SnackBar
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // التعامل مع زر الرجوع للخلف في الأندرويد
  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false; // منع إغلاق الشاشة
    }
    return true; // السماح بإغلاق الشاشة
  }

  // 4. بناء واجهة مستخدم مخصصة لحالة الخطأ
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _isError = false;
              });
              _controller.reload(); // محاولة إعادة التحميل
            },
            child: Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // 5. إلغاء الاشتراك لتجنب تسرب الذاكرة
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            // زر لإعادة التحميل بشكل يدوي
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                if (!_isLoading) {
                  _controller.reload();
                }
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            // عرض WebView أو واجهة الخطأ بناءً على الحالة
            if (_isError)
              _buildErrorWidget()
            else
              WebViewWidget(controller: _controller),

            // عرض مؤشر التحميل في الأعلى
            if (_isLoading)
              Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}