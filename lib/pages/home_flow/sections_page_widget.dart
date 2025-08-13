import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
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

// --- استيراد الصفحات الأخرى (تأكد من صحة المسارات) ---
import '../../doctore/medical_home_screen.dart'; // تأكد من صحة هذا المسار
import '../webview_flow/webview_page.dart'; // تأكد من صحة هذا المسار


// --- كلاس طلب التقييم ---
class AppReviewManager {
  final InAppReview _inAppReview = InAppReview.instance;

  Future<void> requestReviewIfAppropriate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int appOpenCount = prefs.getInt('appOpenCount') ?? 0;
      bool hasRequestedReview = prefs.getBool('hasRequestedReview') ?? false;

      print('[AppReview] Open count: $appOpenCount, Has review been requested before? $hasRequestedReview');

      if (hasRequestedReview) {
        print('[AppReview] Review already requested. Skipping.');
        return;
      }

      appOpenCount++;
      await prefs.setInt('appOpenCount', appOpenCount);

      if (appOpenCount >= 5) {
        print('[AppReview] Threshold reached. Requesting review...');
        if (await _inAppReview.isAvailable()) {
          _inAppReview.requestReview();
          await prefs.setBool('hasRequestedReview', true);
          print('[AppReview] Review requested successfully and flag set to true.');
        } else {
          print('[AppReview] In-app review is not available on this device.');
        }
      } else {
        print('[AppReview] Threshold not reached yet.');
      }
    } catch (e) {
      print('[AppReview] Failed to request App Review: $e');
    }
  }
}

// --- كلاس عناصر البانر ---
class BannerItem {
  final String imageUrl;
  final String targetType;
  final String targetUrl;

  BannerItem({required this.imageUrl, required this.targetType, required this.targetUrl});

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      imageUrl: json['imageUrl'] ?? '',
      targetType: json['targetType'] ?? '',
      targetUrl: json['targetUrl'] ?? '',
    );
  }
}

// --- الواجهة الرئيسية ---
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
    // ملاحظة: تأكد من تهيئة Firebase في ملف main.dart قبل تشغيل التطبيق
    await _requestAllPermissions();
    fetchBannerImages();
    _checkForUpdate();
    AppReviewManager().requestReviewIfAppropriate();
  }

  // دالة مجمعة لطلب كل الأذونات
  Future<void> _requestAllPermissions() async {
    // طلب إذن الإشعارات ضروري جداً لـ iOS
    if (Platform.isIOS) {
      await _requestNotificationPermission();
    }
    await _requestLocationPermission();
  }

  // دالة طلب إذن الإشعارات
  Future<void> _requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false, // اجعلها false لطلب الإذن بشكل صريح
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('[Permissions] Notification permission granted.');
    } else {
      print('[Permissions] Notification permission denied.');
    }
  }

  // دالة طلب إذن الموقع
  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      final result = await Permission.location.request();
      if (result.isGranted) {
        print('[Permissions] Location permission granted.');
      } else {
        print('[Permissions] Location permission denied.');
      }
    } else if (status.isPermanentlyDenied) {
      print('[Permissions] Location permission permanently denied. Opening app settings.');
      await openAppSettings();
    } else if (status.isGranted) {
      print('[Permissions] Location permission already granted.');
    }
  }

  // دالة التحقق من التحديثات
  Future<void> _checkForUpdate() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 25),
        minimumFetchInterval: const Duration(minutes: 5),
      ));
      await remoteConfig.fetchAndActivate();

      final configString = remoteConfig.getString('app_update_config');
      if (configString.isEmpty) return;

      final config = jsonDecode(configString) as Map<String, dynamic>;
      final platformConfig = (Platform.isIOS ? config['ios'] : config['android']) as Map<String, dynamic>;
      final minimumVersionStr = platformConfig['minimum_version'] as String?;
      final storeUrl = platformConfig['store_url'] as String?;

      if (minimumVersionStr == null || storeUrl == null) return;

      final minimumVersion = Version.parse(minimumVersionStr);
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);

      if (currentVersion < minimumVersion) {
        if (mounted) {
          _showUpdateDialog(storeUrl);
        }
      }
    } catch (e) {
      print('Error checking for update: $e');
    }
  }

  // دالة عرض نافذة التحديث
  void _showUpdateDialog(String updateUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('تحديث إجباري', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('يتوفر إصدار جديد من التطبيق. يرجى التحديث الآن لمتابعة استخدام أفضل الخدمات.'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.blue.shade700),
              child: const Text('تحديث الآن', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final uri = Uri.parse(updateUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // دالة جلب البانرات
  Future<void> fetchBannerImages() async {
    final url = Uri.parse('https://banner.beytei.com/images/banners.json');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final bannerList = List<Map<String, dynamic>>.from(jsonData['banners'] ?? []);
        if (mounted) {
          setState(() {
            showBanners = jsonData['showBanners'] ?? false;
            banners = bannerList.map((item) => BannerItem.fromJson(item)).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching banners: $e');
    }
  }

  void _onBannerTapped(BannerItem banner) {
    if (banner.targetUrl.isEmpty) return;
    if (banner.targetType == 'route') {
      GoRouter.of(context).push(banner.targetUrl);
    } else if (banner.targetType == 'webview') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WebViewPage(url: banner.targetUrl)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة بيتي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showBanners && banners.isNotEmpty)
              _buildCarouselSlider(),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                'خدماتنا',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildGridCard(
                    context: context,
                    title: 'منصة بيتي العقارية',
                    imagePath: 'assets/images/beytei.png',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WebViewPage(url: 'https://beytei.com'))),
                  ),
                  _buildGridCard(
                    context: context,
                    title: 'الصيدليات',
                    imagePath: 'assets/images/ph.png',
                    onTap: () => context.push('/pharmacy-store'),
                  ),
                  _buildGridCard(
                    context: context,
                    title: 'بوتيك وكوزمتك بيتي',
                    imagePath: 'assets/images/cosmetics.png',
                    onTap: () => context.push('/splash'), // تأكد من المسار
                  ),
                  _buildGridCard(
                    context: context,
                    title: 'تكسي بيتي',
                    imagePath: 'assets/images/taxi.png',
                    onTap: () => context.push('/trb-store'),
                  ),
                  _buildGridCard(
                    context: context,
                    title: 'استشارة بيتي',
                    imagePath: 'assets/images/clinic.png',
                    onTap: () => context.push('/medical-store'),
                  ),
                  _buildGridCard(
                    context: context,
                    title: 'المطاعم',
                    imagePath: 'assets/images/re.jpg',
                    onTap: () => context.push('/restaurants-store'),
                  ),
                  _buildGridCard(
                    context: context,
                    title: 'الحجز الطبي',
                    imagePath: 'assets/images/medical.png',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MedicalHomeScreen())),
                  ),
                  _buildGridCard(
                    context: context,
                    title: 'مسواك بيتي',
                    imagePath: 'assets/images/ms.jpg',
                    onTap: () => context.push('/miswak-store'),
                  ),
                  _buildGridCard(
                    context: context,
                    title: 'سجل بيتي الطبي',
                    imagePath: 'assets/images/ph.png',
                    onTap: () => context.push('/do-store'),
                  ),
                  _buildGridCard(
                    context: context,
                    title: 'المختبرات',
                    imagePath: 'assets/images/lab.jpg',
                    onTap: () => context.push('/lab-store'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      // يمكنك إضافة BottomNavigationBar هنا إذا أردت
    );
  }

  Widget _buildCarouselSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(15, 20, 15, 10),
          child: Text(
            'العروض المميزة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        CarouselSlider(
          options: CarouselOptions(
            height: 180.0,
            autoPlay: true,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            viewportFraction: 0.85,
          ),
          items: banners.map((banner) {
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
                    return const Center(child: Icon(Icons.error_outline, color: Colors.red));
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGridCard({
    required BuildContext context,
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.asset(imagePath, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}