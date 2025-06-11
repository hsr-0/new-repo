import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart'; // ✅ استيراد السبنر

class WebViewPage extends StatefulWidget {
  final String url;

  const WebViewPage({Key? key, required this.url}) : super(key: key);

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  WebViewController? _controller;
  bool isLoading = true;
  bool hasInternet = true;
  bool webViewError = false;

  final Color primaryColor = const Color(0xFF1A73E8); // ✅ لون شعار المنصة (مثال: أزرق بيتي)

  @override
  void initState() {
    super.initState();
    _checkInternetAndLoad();
  }

  Future<void> _checkInternetAndLoad() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) {
      setState(() => hasInternet = false);
    } else {
      try {
        final response = await http.get(Uri.parse('https://www.google.com'));
        if (response.statusCode == 200) {
          _initWebView();
        } else {
          setState(() => hasInternet = false);
        }
      } catch (_) {
        setState(() => hasInternet = false);
      }
    }

    if (!hasInternet) {
      Future.delayed(const Duration(seconds: 5), _checkInternetAndLoad);
    }
  }

  void _initWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            if (_shouldOpenExternally(request.url)) {
              await _launchExternalUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (_) {
            setState(() {
              isLoading = true;
              webViewError = false;
            });
          },
          onPageFinished: (_) => setState(() => isLoading = false),
          onWebResourceError: (_) {
            setState(() {
              webViewError = true;
              isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    setState(() {
      _controller = controller;
      hasInternet = true;
      webViewError = false;
    });
  }

  bool _shouldOpenExternally(String url) {
    return url.startsWith('tel:') ||
        url.startsWith('mailto:') ||
        url.startsWith('whatsapp:') ||
        url.contains('wa.me');
  }

  Future<void> _launchExternalUrl(String url) async {
    try {
      Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('لا يمكن فتح الرابط: $url');
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء محاولة فتح الرابط: $url');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _onWillPop() async {
    if (_controller != null && await _controller!.canGoBack()) {
      _controller!.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!hasInternet || webViewError) {
      return Scaffold(
        appBar: AppBar(title: const Text(' لا يوجد اتصال')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              const Text('حاول الاتصال بالانترنيت', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkInternetAndLoad,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: const Text('منصة بيتي')),
        body: Stack(
          children: [
            if (_controller != null)
              WebViewWidget(controller: _controller!),
            if (isLoading)
              Center(
                child: SpinKitFadingCircle( // ✅ سبنر جميل
                  color: primaryColor,
                  size: 50.0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
