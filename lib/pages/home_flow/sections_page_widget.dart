import 'dart:async';
import 'dart:convert';
import 'dart:io'; // NEW: Import to check the platform (iOS/Android)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../doctore/medical_home_screen.dart';
import '../webview_flow/webview_page.dart';

// 1. Create a model class for the banner data
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
  // 2. Update the state variable to hold a list of BannerItem objects
  List<BannerItem> banners = [];
  bool showBanners = false;

  @override
  void initState() {
    super.initState();
    // It's good practice to not make initState async.
    // Call async functions from within it.
    _initialize();
  }

  Future<void> _initialize() async {
    // Firebase is initialized once, so we can just ensure it's ready.
    await Firebase.initializeApp();

    // NEW: Request notification permissions ONLY on iOS
    if (Platform.isIOS) {
      await requestNotificationPermissions();
    }

    await fetchBannerImages();
  }

  // MODIFIED: This function will now only be called on iOS devices.
  Future<void> requestNotificationPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications on iOS');
    } else {
      print('User declined or has not accepted permission for notifications on iOS');
    }
  }

  // 3. Modify the fetchBannerImages method
  Future<void> fetchBannerImages() async {
    final url = Uri.parse('https://banner.beytei.com/images/banners.json');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final bannerList =
        List<Map<String, dynamic>>.from(jsonData['banners'] ?? []);

        if (mounted) {
          setState(() {
            showBanners = jsonData['showBanners'] ?? false;
            // Parse the JSON array into a list of BannerItem objects
            banners =
                bannerList.map((item) => BannerItem.fromJson(item)).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching banners: $e');
    }
  }

  // Helper method for navigation
  void _onBannerTapped(BannerItem banner) {
    if (banner.targetType == 'route') {
      // Use GoRouter for internal app navigation
      GoRouter.of(context).push(banner.targetUrl);
    } else if (banner.targetType == 'webview') {
      // Use Navigator to push a new page for the webview
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
        title:
        const Text('منصة بيتي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true, // This line centers the title
        backgroundColor: Colors.white,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.discount)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 4. Update the CarouselSlider to use the new banners list
            if (showBanners && banners.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(10.0),
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
                // Map over the 'banners' list of objects
                items: banners.map((banner) {
                  return Builder(
                    builder: (BuildContext context) {
                      // Wrap the image with GestureDetector for tap handling
                      return GestureDetector(
                        onTap: () => _onBannerTapped(banner),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            banner.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            // Add a loading builder for a better user experience
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                            // Add an error builder to handle failed image loads
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
                    title: 'استشارة طبية ',
                    description: '',
                    imagePath: 'assets/images/clinic.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const WebViewPage(
                                url:
                                'https://tawk.to/chat/6848a65fb0285c1909e28cd2/1itdsjq3f')),
                      );
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
