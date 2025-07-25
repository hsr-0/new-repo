import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:carousel_slider/carousel_slider.dart';

// --- الحزم المطلوبة لنظام التحديث والتقييم ---
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';
import 'package:in_app_review/in_app_review.dart'; // [جديد] حزمة طلب التقييم
import 'package:shared_preferences/shared_preferences.dart'; // [جديد] حزمة حفظ البيانات محلياً
// --- نهاية الحزم ---

import '../../doctore/medical_home_screen.dart';
import '../webview_flow/webview_page.dart';


// --- [جديد] كلاس مسؤول عن منطق طلب التقييم ---
class AppReviewManager {
  final InAppReview _inAppReview = InAppReview.instance;

  // دالة لطلب التقييم اذا كان الوقت مناسباً
  Future<void> requestReviewIfAppropriate() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // جلب عدد مرات فتح التطبيق، القيمة الافتراضية هي 0
      int appOpenCount = prefs.getInt('appOpenCount') ?? 0;

      // التحقق مما إذا كان قد تم طلب التقييم من قبل
      bool hasRequestedReview = prefs.getBool('hasRequestedReview') ?? false;

      // إذا تم الطلب مسبقاً، لا تفعل شيئاً
      if (hasRequestedReview) {
        return;
      }

      // زيادة عداد فتح التطبيق بواحد
      appOpenCount++;
      await prefs.setInt('appOpenCount', appOpenCount);

      // إذا تم فتح التطبيق 3 مرات أو أكثر
      if (appOpenCount >= 1) {
        if (await _inAppReview.isAvailable()) {
          // اطلب التقييم
          _inAppReview.requestReview();
          // سجل أنه تم الطلب بنجاح لمنع تكراره
          await prefs.setBool('hasRequestedReview', true);
        }
      }
    } catch (e) {
      // في حال حدوث خطأ، اطبعه في الـ console فقط لتجنب تعطيل التطبيق
      print('Failed to request App Review: $e');
    }
  }
}
// --- نهاية الكلاس ---


class BannerItem {
  final String imageUrl;
  final String targetType;
  final String targetUrl;

  BannerItem({
    required this.imageUrl,
    required this.targetType,
    required this.targetUrl,
  });

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
    // افترض أن تهيئة Firebase تمت في شاشة الـ splash
    // await Firebase.initializeApp();

    if (Platform.isIOS) {
      await requestNotificationPermissions();
    }

    fetchBannerImages();

    // التحقق من التحديث في الخلفية
    _checkForUpdate();

    // --- [جديد] طلب التقييم عند بدء الصفحة ---
    AppReviewManager().requestReviewIfAppropriate();
  }

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

  Future<void> requestNotificationPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

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
    if (banner.targetType == 'route') {
      GoRouter.of(context).push(banner.targetUrl);
    } else if (banner.targetType == 'webview') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewPage(url: banner.targetUrl),
        ),
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
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.discount)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
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
                options: CarouselOptions(
                  height: 180.0,
                  autoPlay: true,
                  enlargeCenterPage: true,
                ),
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
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}






