import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cosmetic_store/taxi/lib/core/helper/shared_preference_helper.dart';

class NewTaxiChatController extends GetxController {
  final String rideId;
  NewTaxiChatController({required this.rideId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController messageController = TextEditingController();

  bool isSubmitLoading = false;

  // دالة إرسال الرسالة لـ Firestore + إشعار للسيرفر
  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    String msgText = messageController.text.trim();
    messageController.clear();
    isSubmitLoading = true;
    update();

    try {
      // جلب معرف الزبون من التخزين المحلي
      final prefs = await SharedPreferences.getInstance();
      String currentUserId = prefs.getString(SharedPreferenceHelper.userIdKey) ?? "0";

      // 1. حفظ الرسالة في Firestore
      await _firestore
          .collection('taxi_rides_chats')
          .doc(rideId)
          .collection('messages')
          .add({
        'message': msgText,
        'userId': currentUserId,
        'driverId': "0",
        'image': "null",
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. إخطار السيرفر عبر البوابة السريعة (الخطة ب)
      await notifyServer(msgText);

    } catch (e) {
      print("Error sending message: $e");
    } finally {
      isSubmitLoading = false;
      update();
    }
  }

  // استدعاء بوابة الإشعارات المباشرة (تتجاوز حماية لارافيل)
  Future<void> notifyServer(String message) async {
    try {
      // تم تغيير الرابط هنا للمسار المباشر المستقل
      const String apiUrl = 'https://taxi.beytei.com/taxi-chat-api.php';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          // ملاحظة: لم نعد بحاجة لإرسال التوكن هنا لأن الملف الجديد مفتوح ومستقر
        },
        body: jsonEncode({
          'ride_id': rideId,
          'message': message,
          'sender_type': 'user'
        }),
      );

      if (response.statusCode == 200) {
        print("✅ تم إخطار السيرفر بنجاح عبر البوابة المباشرة");
      } else {
        print("❌ فشل الإخطار. كود الرد: ${response.statusCode}");
      }
    } catch (e) {
      print("Server notification failed: $e");
    }
  }

  // Stream لجلب الرسائل لحظياً
  Stream<QuerySnapshot> getMessagesStream() {
    return _firestore
        .collection('taxi_rides_chats')
        .doc(rideId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots();
  }
}