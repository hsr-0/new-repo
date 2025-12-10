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
      plugins: [ZegoUIKitSignalingPlugin()], // الإضافة المسؤولة عن الرنين

      // إعدادات الأحداث (للتعامل مع عدم الرد)
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

/// زر اتصال ذكي يقوم بالاتصال عبر التطبيق، وإذا لم يتم الرد يقترح الاتصال العادي
class SmartCallButton extends StatelessWidget {
  final String targetUserID;
  final String targetUserName;
  final String? phoneNumber; // رقم الهاتف للاتصال العادي

  const SmartCallButton({
    Key? key,
    required this.targetUserID,
    required this.targetUserName,
    this.phoneNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // هذا الزر الجاهز من المكتبة يرسل إشعار "رنين" للطرف الآخر
    return ZegoSendCallInvitationButton(
      isVideoCall: false, // اتصال صوتي فقط
      resourceID: "zego_call", // تأكد من إعداد هذا في Zego Console للإشعارات، أو اتركه فارغاً للتجربة
      invitees: [
        ZegoUIKitUser(
          id: targetUserID,
          name: targetUserName,
        ),
      ],
      iconSize: const Size(40, 40),
      buttonSize: const Size(50, 50),
      icon: ButtonIcon(icon: const Icon(Icons.call, color: Colors.white)),

      // تخصيص شكل الزر ليكون مثل الأزرار الموجودة في تطبيقك
      clickableBackgroundColor: Colors.green,
      borderRadius: 50, // دائري

      // التعامل مع الأحداث عند الضغط
      onPressed: (code, message, p2) {
        // يتم استدعاؤه عند إرسال الدعوة بنجاح
        if (code != 0) {
          // في حال فشل الاتصال عبر الإنترنت فوراً (مثلاً لا يوجد نت)
          _offerRegularCall(context);
        }
      },
    );
  }

  void _offerRegularCall(BuildContext context) {
    if (phoneNumber == null || phoneNumber!.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تعذر الاتصال عبر التطبيق"),
        content: const Text("الطرف الآخر قد يكون غير متصل بالإنترنت. هل تود الاتصال عبر الشبكة العادية؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              makePhoneCall(phoneNumber, context); // دالتك القديمة
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("اتصال عادي"),
          ),
        ],
      ),
    );
  }
}