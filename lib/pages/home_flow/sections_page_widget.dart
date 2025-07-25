import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// ... other imports

// [ملاحظة]: تأكد من وجود كل الـ imports الأخرى التي تحتاجها

class SectionsPageWidget extends StatefulWidget {
  const SectionsPageWidget({Key? key}) : super(key: key);

  @override
  State<SectionsPageWidget> createState() => _SectionsPageWidgetState();
}

class _SectionsPageWidgetState extends State<SectionsPageWidget> {
  // ... other variables like banners, showBanners

  // --- [جديد] متغيرات لحفظ نتائج التشخيص ---
  String _permissionStatus = 'جاري التحقق...';
  String _apnsToken = 'جاري التحقق...';
  String _fcmToken = 'جاري التحقق...';
  // --- نهاية المتغيرات الجديدة ---


  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // ... your other initialization code like fetchBannerImages()

    // --- [جديد] تشغيل التشخيص عند بدء التشغيل ---
    if (Platform.isIOS) {
      _runIosDiagnostics();
    }
  }

  // --- [جديد] دالة التشخيص الكاملة ---
  Future<void> _runIosDiagnostics() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. التحقق من حالة الإذن
    try {
      NotificationSettings settings = await messaging.getNotificationSettings();
      setState(() {
        _permissionStatus = settings.authorizationStatus.name; // e.g., authorized, denied
      });
    } catch (e) {
      setState(() {
        _permissionStatus = 'خطأ: ${e.toString()}';
      });
    }

    // 2. محاولة الحصول على توكن APNs (الأهم)
    try {
      String? apnsToken = await messaging.getAPNSToken();
      if (apnsToken == null) {
        setState(() {
          _apnsToken = 'فشل في الحصول على توكن APNs (القيمة null)';
        });
      } else {
        setState(() {
          _apnsToken = apnsToken;
        });
      }
    } catch (e) {
      setState(() {
        _apnsToken = 'خطأ فادح: ${e.toString()}';
      });
    }

    // 3. محاولة الحصول على توكن FCM
    try {
      String? fcmToken = await messaging.getToken();
      setState(() {
        _fcmToken = fcmToken ?? 'فشل في الحصول على توكن FCM (القيمة null)';
      });
    } catch (e) {
      setState(() {
        _fcmToken = 'خطأ: ${e.toString()}';
      });
    }
  }
  // --- نهاية دالة التشخيص ---


  // دالة طلب الإذن اليدوية (تبقى كما هي)
  Future<void> _requestNotificationPermissionManually() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    // إعادة تشغيل التشخيص بعد طلب الإذن لرؤية التغيير
    if (Platform.isIOS) {
      _runIosDiagnostics();
    }
  }

  // دالة مشاركة التوكن (تبقى كما هي)
  Future<void> _getAndShareFcmToken() async {
    // ...
  }

  // ... All your other functions like fetchBannerImages, etc.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة بيتي - تشخيص iOS'),
        centerTitle: true,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _requestNotificationPermissionManually,
            backgroundColor: Colors.red,
            tooltip: 'Request Notification Permission',
            heroTag: 'btn1',
            child: const Icon(Icons.notifications_active, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _getAndShareFcmToken,
            backgroundColor: Colors.blue.shade800,
            tooltip: 'Share FCM Token',
            heroTag: 'btn2',
            child: const Icon(Icons.share, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // --- [جديد] لوحة التشخيص ---
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('نتائج تشخيص إشعارات iOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.right),
                  const Divider(),
                  const Text('1. حالة الإذن (Permission Status):', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                  SelectableText(_permissionStatus, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'monospace')),
                  const SizedBox(height: 10),

                  const Text('2. توكن Apple APNs (الأهم):', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                  SelectableText(_apnsToken, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'monospace', color: Colors.purple)),
                  const SizedBox(height: 10),

                  const Text('3. توكن Firebase FCM:', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                  SelectableText(_fcmToken, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'monospace', color: Colors.green)),
                ],
              ),
            ),
            // --- نهاية لوحة التشخيص ---

            const SizedBox(height: 20),

            // ... Your original UI (CarouselSlider, GridView, etc.)
            // const Text('العروض المميزة', ...),
            // CarouselSlider(...),
          ],
        ),
      ),
    );
  }
}