import 'package:cosmetic_store/taxi/tx.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class CallService {
  // 🔴 استبدل هذه القيم ببياناتك الحقيقية من ZegoCloud Console
  static const int appID = 266389722;
  static const String appSign = "e8e5d2697741a3f706e115c45b1908d0da218ea1b8d67bf674386b70f80adec6";

  /// تهيئة الخدمة عند تسجيل الدخول
  static Future<void> initService({
    required String userId,
    required String userName,
  }) async {
    await ZegoUIKitPrebuiltCallInvitationService().init(
      appID: appID,
      appSign: appSign,
      userID: userId,
      userName: userName,
      plugins: [ZegoUIKitSignalingPlugin()],

      // ✅ إعدادات الإشعارات (تم تصحيحها للإصدار الجديد)
      notificationConfig: ZegoCallInvitationNotificationConfig(
        androidNotificationConfig: ZegoCallAndroidNotificationConfig(
          channelName: "مكالمات بيتي",
          // لم نعد بحاجة لتعريف priority هنا، فهي تلقائية high
        ),
      ),

      events: ZegoUIKitPrebuiltCallEvents(
        onError: (error) {
          debugPrint("Call Error: $error");
        },
      ),
    );
  }

  /// إنهاء الخدمة عند تسجيل الخروج
  static Future<void> uninitService() async {
    await ZegoUIKitPrebuiltCallInvitationService().uninit();
  }
}

/// زر اتصال ذكي بتصميم عصري
class SmartCallButton extends StatelessWidget {
  final String targetUserID;
  final String targetUserName;
  final String? phoneNumber;

  const SmartCallButton({
    Key? key,
    required this.targetUserID,
    required this.targetUserName,
    this.phoneNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ZegoSendCallInvitationButton(
        isVideoCall: false,
        resourceID: "zego_call", // تأكد من إعداد هذا في Zego Console للإشعارات Offline
        invitees: [
          ZegoUIKitUser(
            id: targetUserID,
            name: targetUserName,
          ),
        ],
        iconSize: const Size(28, 28),
        buttonSize: const Size(55, 55),
        icon: ButtonIcon(icon: const Icon(Icons.call, color: Colors.white)),
        clickableBackgroundColor: const Color(0xFF00C853),
        borderRadius: 50,

        // التعامل مع فشل الاتصال
        onPressed: (code, message, p2) {
          // إذا فشل الإرسال (code ليس 0)، نعرض البديل
          if (code.isNotEmpty) {
            _showModernFallbackSheet(context);
          }
        },
      ),
    );
  }

  void _showModernFallbackSheet(BuildContext context) {
    if (phoneNumber == null || phoneNumber!.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              "تعذر الاتصال عبر التطبيق",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 8),
            const Text(
              "يبدو أن الطرف الآخر غير متصل بالإنترنت حالياً.\nهل تود إجراء مكالمة هاتفية عادية؟",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Cairo', height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text("إلغاء", style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      makePhoneCall(phoneNumber, context);
                    },
                    icon: const Icon(Icons.phone, color: Colors.white),
                    label: const Text("اتصال هاتفي", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}