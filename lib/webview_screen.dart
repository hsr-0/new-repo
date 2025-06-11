import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewScreen extends StatefulWidget {
  final String title;
  final String url;

  WebViewScreen({required this.title, required this.url});

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            if (_shouldOpenExternally(request.url)) {
              await _launchExternalUrl(request.url); // فتح الرابط خارجيًا
              return NavigationDecision.prevent; // منع التحميل داخل WebView
            }
            return NavigationDecision.navigate; // السماح بالتحميل داخل WebView
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  // التحقق من الروابط الخارجية
  bool _shouldOpenExternally(String url) {
    return url.startsWith('tel:') || url.startsWith('mailto:') || url.startsWith('whatsapp:');
  }

  // إطلاق الرابط في تطبيق خارجي
  Future<void> _launchExternalUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('لا يمكن فتح الرابط: $url');
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء محاولة فتح الرابط: $url');
    }
  }

  // إظهار رسالة Snackbar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // التحكم في الرجوع للخلف
  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false; // لا تغلق الشاشة
    }
    return true; // أغلق الشاشة
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
