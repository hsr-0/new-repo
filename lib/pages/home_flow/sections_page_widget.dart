import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

// ✅ 1. تمت إضافة مكتبة فيسبوك هنا
import 'package:facebook_app_events/facebook_app_events.dart';

// تأكد من صحة مسار هذه الملفات في مشروعك
import '../../doctore/medical_home_screen.dart';
import '../../taxi/lib/main.dart';
import '../../taxi/tx.dart';
import '../../zone.dart';
import '../webview_flow/webview_page.dart';

// --- ثوابت التخزين ---
class CacheConstants {
  static const String CACHE_KEY_BANNERS = 'cached_banner_data';
  static const String CACHE_KEY_BANNER_TIME = 'cached_banner_time';
  static const int CACHE_DURATION_HOURS = 6;
}

// --- مدير نافذة الترويج ---
class PromoManager {
  static const String PROMO_TITLE = "🏆 كل ما تطلب أكثر تربح أكثر!";
  static const String PROMO_MESSAGE = "تطبيق منصة بيتي يقدم لك هدايا وجوائز يومية\n\n🎁 الهدية الاسبوعية توزع يوم الجمعة الساعة 8 مساءً\n💰 كل طلب يؤهلك للفوز\n📱 اطلب الآن قبل انتهاء الوقت!";

  static Future<bool> shouldShowPromo() async {
    return true; // تظهر دائماً كما طلبت
  }
}

// --- كلاس طلب التقييم ---
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

      if (appOpenCount >= 5) {
        if (await _inAppReview.isAvailable()) {
          await _inAppReview.requestReview();
          await prefs.setBool('hasRequestedReview', true);
        }
      }
    } catch (e) {
      print('App Review Error: $e');
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
    // تشغيل المهام الخلفية عند بدء الصفحة
    _startBackgroundTasks();
  }

  // ✅ هذه الدالة تحتوي الآن على كود تفعيل فيسبوك
  void _startBackgroundTasks() async {
    // 1. طلب الأذونات
    _requestAllPermissions();

    // 2. تحميل البانرات
    _loadBannersWithCache();

    // 3. التحقق من التحديثات
    _checkForUpdate();

    // 4. طلب التقييم
    AppReviewManager().requestReviewIfAppropriate();

    // ---------------------------------------------------------
    // ✅ 5. تفعيل فيسبوك SDK (تمت الإضافة هنا)
    // ---------------------------------------------------------
    try {
      final facebookAppEvents = FacebookAppEvents();
      // تفعيل التتبع لكي تظهر النقطة الخضراء
      await facebookAppEvents.setAdvertiserTracking(enabled: true);

      // إرسال إشارة "تفعيل التطبيق" يدوياً
      await facebookAppEvents.logEvent(
        name: 'fb_mobile_activate_app',
        parameters: {'platform': 'flutter_home_screen'},
      );
      print("✅ Facebook SDK Activated from Home Screen");
    } catch (e) {
      print("❌ Facebook SDK Error: $e");
    }
    // ---------------------------------------------------------

    // 6. عرض نافذة الترويج (بعد تأخير بسيط)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        if (await PromoManager.shouldShowPromo()) {
          _showPromoDialog();
        }
      }
    });
  }

  // ... (باقي الدوال كما هي تماماً) ...
  Future<void> _showPromoDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(23),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: const BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(23),
                          topRight: Radius.circular(23),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.card_giftcard_rounded, color: Colors.yellow.shade300, size: 60),
                            const SizedBox(height: 10),
                            const Text(
                              PromoManager.PROMO_TITLE,
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        children: [
                          Text(
                            PromoManager.PROMO_MESSAGE,
                            style: TextStyle(fontSize: 16, height: 1.6, color: Colors.grey.shade800),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 25),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.access_time_filled_rounded, color: Colors.orange.shade700),
                                const SizedBox(width: 10),
                                Text(
                                  "موعد التوزيع: 8:00 مساءً",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 25, right: 25, bottom: 25),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(color: Colors.grey.shade400),
                              ),
                              child: Text('لاحقاً', style: TextStyle(color: Colors.grey.shade700, fontSize: 15, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const BeyteiZoneScreen()));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 3,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.rocket_launch_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text('ابدأ الفوز', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
                  ),
                  child: Icon(Icons.close_rounded, color: Colors.grey.shade600, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestAllPermissions() async {
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission();
    }
    final locationStatus = await Permission.location.status;
    if (locationStatus.isDenied) {
      await Permission.location.request();
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();
      final configString = remoteConfig.getString('app_update_config');
      if (configString.isEmpty) return;
      final config = jsonDecode(configString);
      final platformConfig = Platform.isIOS ? config['ios'] : config['android'];
      final minVer = platformConfig['minimum_version'];
      final url = platformConfig['store_url'];
      if (minVer != null && url != null) {
        final current = Version.parse((await PackageInfo.fromPlatform()).version);
        if (current < Version.parse(minVer)) {
          if (mounted) _showUpdateDialog(url);
        }
      }
    } catch (e) {
      print('Update check error: $e');
    }
  }

  void _showUpdateDialog(String updateUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('تحديث إجباري'),
        content: const Text('يرجى تحديث التطبيق للمتابعة.'),
        actions: [
          TextButton(
            child: const Text('تحديث'),
            onPressed: () async {
              final uri = Uri.parse(updateUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          )
        ],
      ),
    );
  }

  Future<void> _loadBannersWithCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(CacheConstants.CACHE_KEY_BANNERS);
    final lastFetchTime = prefs.getInt(CacheConstants.CACHE_KEY_BANNER_TIME);

    if (cachedData != null && lastFetchTime != null) {
      final cacheAge = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastFetchTime));
      if (cacheAge < const Duration(hours: CacheConstants.CACHE_DURATION_HOURS)) {
        _processBannerData(cachedData);
        _fetchBannersSilently();
        return;
      }
    }
    _fetchBannersSilently();
  }

  Future<void> _fetchBannersSilently() async {
    try {
      final url = Uri.parse('https://banner.beytei.com/images/banners.json');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(CacheConstants.CACHE_KEY_BANNERS, response.body);
        await prefs.setInt(CacheConstants.CACHE_KEY_BANNER_TIME, DateTime.now().millisecondsSinceEpoch);
        _processBannerData(response.body);
      }
    } catch (e) {
      print("Banner fetch error: $e");
    }
  }

  void _processBannerData(String jsonData) {
    try {
      final jsonMap = json.decode(jsonData);
      if (mounted) {
        setState(() {
          showBanners = jsonMap['showBanners'] ?? false;
          final bannerList = List<Map<String, dynamic>>.from(jsonMap['banners'] ?? []);
          banners = bannerList.map((item) => BannerItem.fromJson(item)).toList();
        });
      }
    } catch (e) {
      print('Banner processing error: $e');
    }
  }

  void _onBannerTapped(BannerItem banner) {
    if (banner.targetType == 'route') {
      GoRouter.of(context).push(banner.targetUrl);
    } else if (banner.targetType == 'webview') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => WebViewPage(url: banner.targetUrl)));
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
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BeyteiZoneScreen()),
              );
            },
            icon: const Icon(Icons.card_giftcard, color: Colors.deepPurple),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadBannersWithCache();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                    _buildGridCard(
                      context: context,
                      title: 'منصة بيتي العقارية',
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
                      title: 'الصيدليات ',
                      imagePath: 'assets/images/ph.png',
                      onTap: () {
                        context.push('/pharmacy-store');
                      },
                    ),
                    _buildGridCard(
                      context: context,
                      title: 'بوتيك وكوزمتك بيتي',
                      imagePath: 'assets/images/cosmetics.png',
                      onTap: () {
                        context.push('/splash');
                      },
                    ),
                    _buildGridCard(
                      context: context,
                      title: 'تكسي بيتي ',
                      imagePath: 'assets/images/taxi.png',
                      onTap: () {
                        // الانتقال إلى تطبيق التكسي المدمج
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TaxiAppEntry()),
                        );
                      },
                    ),


                    _buildGridCard(
                      context: context,
                      title: 'مسواك بيتي ',
                      imagePath: 'assets/images/ms.jpg',
                      onTap: () {
                        GoRouter.of(context).push('/miswak-store');
                      },
                    ),



                    _buildGridCard(
                      context: context,
                      title: 'المطاعم ',
                      imagePath: 'assets/images/re.jpg',
                      onTap: () {
                        GoRouter.of(context).push('/restaurants-store');
                      },
                    ),



                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BeyteiZoneScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(
            icon: Icon(Icons.stars),
            label: 'بيتي زون',
          ),
        ],
      ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.asset(imagePath, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              color: Colors.blue.withOpacity(0.05),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
