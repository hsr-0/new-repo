import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:carousel_slider/carousel_slider.dart';

// --- الحزم المطلوبة ---
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart'; // [جديد] حزمة المشاركة

import '../../doctore/medical_home_screen.dart';
import '../webview_flow/webview_page.dart';

// ... (كلاس AppReviewManager وكلاس BannerItem يبقيان كما هما)

class AppReviewManager {
  final InAppReview _inAppReview = InAppReview.instance;

  Future<void> requestReviewIfAppropriate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int appOpenCount = prefs.getInt('appOpenCount') ?? 0;
      bool hasRequestedReview = prefs.getBool('hasRequestedReview') ?? false;
      if (hasRequestedReview) return;
      appOpenCount++;
      await prefs.setInt('appOpenCount', appOpenCount);
      if (appOpenCount >= 3) {
        if (await _inAppReview.isAvailable()) {
          _inAppReview.requestReview();
          await prefs.setBool('hasRequestedReview', true);
        }
      }
    } catch (e) {
      print('[AppReview] Failed to request App Review: $e');
    }
  }
}

class BannerItem {
  final String imageUrl;
  final String targetType;
  final String targetUrl;

  BannerItem({required this.imageUrl, required this.targetType, required this.targetUrl});

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      imageUrl: json['imageUrl'],
      targetType: json['targetType'],
      targetUrl: json['targetUrl'],
    );
  }
}


class SectionsPageWidget extends StatefulWidget {
  const SectionsPageWidget({Key? key}) : super(key: key);

  @override
  State<SectionsPageWidget> createState() => _SectionsPageWidgetState();
}

class _SectionsPageWidgetState extends State<SectionsPageWidget> {
  List<BannerItem> banners = [];
  bool showBanners = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _requestAllPermissions();
    fetchBannerImages();
    _checkForUpdate();
    AppReviewManager().requestReviewIfAppropriate();
  }

  // --- [جديد] دالة لجلب التوكن ومشاركته ---
  Future<void> _getAndShareFcmToken() async {
    // جلب توكن FCM
    final fcmToken = await FirebaseMessaging.instance.getToken();

    if (fcmToken == null) {
      print("Failed to get FCM token.");
      // يمكنك إظهار رسالة خطأ للمستخدم هنا إذا أردت
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("فشل الحصول على التوكن. تأكد من اتصالك بالإنترنت.")),
      );
      return;
    }

    print("FCM Token: $fcmToken");

    // استخدام حزمة المشاركة لفتح نافذة المشاركة
    await Share.share(
      'My FCM Token is: $fcmToken',
      subject: 'FCM Token for Beytei App',
    );
  }


  // ... (باقي الدوال تبقى كما هي: _requestAllPermissions, _checkForUpdate, etc.)
  Future<void> _requestAllPermissions() async {
    if (Platform.isIOS) {
      await _requestNotificationPermission();
    }
    await _requestLocationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _requestLocationPermission() async {
    await Permission.location.request();
  }

  Future<void> _checkForUpdate() async {
    // ...
  }

  void _showUpdateDialog(String url) {
    // ...
  }

  Future<void> fetchBannerImages() async {
    // ...
  }

  void _onBannerTapped(BannerItem banner) {
    // ...
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة بيتي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.discount)),
        ],
      ),

      // --- [جديد] إضافة الزر العائم ---
      floatingActionButton: FloatingActionButton(
        onPressed: _getAndShareFcmToken,
        backgroundColor: Colors.blue.shade800,
        tooltip: 'Share FCM Token',
        child: const Icon(Icons.share, color: Colors.white),
      ),

      body: SingleChildScrollView(
        child: Column(
          // ... (محتوى الصفحة يبقى كما هو)
          children: [
            if (showBanners && banners.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 20, 10, 10),
                child: Text(
                  'العروض المميزة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              CarouselSlider(
                options: CarouselOptions(height: 180.0, autoPlay: true, enlargeCenterPage: true),
                items: banners.map((banner) {
                  return Builder(
                    builder: (BuildContext context) {
                      return GestureDetector(
                        onTap: () => _onBannerTapped(banner),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            banner.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Icon(Icons.error));
                            },
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'خدماتنا',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // ... محتوى الـ GridView كما هو
                  _buildGridCard(
                    context: context,
                    title: 'منصة بيتي العقارية',
                    description: '',
                    imagePath: 'assets/images/beytei.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                            const WebViewPage(url: 'https://beytei.com')),
                      );
                    },
                  ),
                  _buildGridCard(
                    context: context,
                    title: 'الصيدليات',
                    description: '',
                    imagePath: 'assets/images/ph.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                            const WebViewPage(url: 'https://ph.beytei.com')),
                      );
                    },
                  ),
                  _buildGridCard(
                    context: context,
                    title: 'بوتيك وكوزمتك بيتي',
                    description: '',
                    imagePath: 'assets/images/cosmetics.png',
                    onTap: () {
                      context.push('/splash');
                    },
                  ),
                  _buildGridCard(
                    context: context,
                    title: 'تكسي بيتي  ',
                    description: '',
                    imagePath: 'assets/images/taxi.png',
                    onTap: () {
                      GoRouter.of(context).push('/trb-store');
                    },
                  ),
                  _buildGridCard(
                    context: context,
                    title: 'استشارة بيتي  ',
                    description: '',
                    imagePath: 'assets/images/clinic.png',
                    onTap: () {
                      context.push('/medical-store');
                    },
                  ),
                  _buildGridCard(
                    context: context,
                    title: 'الحجز الطبي',
                    description: 'حجز موعد مع الطبيب',
                    imagePath: 'assets/images/medical.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MedicalHomeScreen()),
                      );
                    },
                  ),
                  _buildGridCard(
                    context: context,
                    title: 'مسواك بيتي ',
                    description: '',
                    imagePath: 'assets/images/ms.jpg',
                    onTap: () {
                      GoRouter.of(context).push('/miswak-store');
                    },
                  ),
                  _buildGridCard(
                    context: context,
                    title: 'سجل بيتي الطبي ',
                    description: '',
                    imagePath: 'assets/images/ph.png',
                    onTap: () {
                      GoRouter.of(context).push('/do-store');
                    },
                  ),
                  _buildGridCard(
                    context: context,
                    title: 'المختبرات ',
                    description: '',
                    imagePath: 'assets/images/lab.jpg',
                    onTap: () {
                      GoRouter.of(context).push('/lab-store');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(
              icon: Icon(Icons.discount), label: 'الخصومات'),
        ],
      ),
    );
  }

  Widget _buildGridCard({
    required BuildContext context,
    required String title,
    required String description,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    // ...
    return Container();
  }
}

class MedicalHomeScreen extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medical Home Screen"),
      ),
    );
  }
}

class WebViewPage extends StatelessWidget{
  final String url;
  const WebViewPage({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text(url),
      ),
    );
  }
}