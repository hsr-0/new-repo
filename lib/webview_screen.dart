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
  bool _isLoading = true; // حتى لو لم نستخدمه الآن

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) async {
            if (_shouldOpenExternally(request.url)) {
              await _launchExternalUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse(widget.url),
        headers: {'Cache-Control': 'max-age=3600'}, // لتفعيل الكاش إن أمكن
      );
  }

  // التحقق من الروابط التي يجب فتحها خارج التطبيق
  bool _shouldOpenExternally(String url) {
    return url.startsWith('tel:') ||
        url.startsWith('mailto:') ||
        url.startsWith('whatsapp:') ||
        url.contains('wa.me') ||
        url.startsWith('sms:') ||
        url.startsWith('intent:');
  }

  // فتح الرابط خارجيًا
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

  // إظهار Snackbar
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // التعامل مع زر الرجوع للخلف
  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      setState(() => _isLoading = true); // إعادة تفعيل التحميل عند الرجوع
      return false;
    }
    return true;
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
