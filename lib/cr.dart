import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IosCrashDebuggerFAB extends StatefulWidget {
  const IosCrashDebuggerFAB({super.key});

  @override
  State<IosCrashDebuggerFAB> createState() => _IosCrashDebuggerFABState();
}

class _IosCrashDebuggerFABState extends State<IosCrashDebuggerFAB> {
  // نفس اسم القناة الموجودة في AppDelegate
  static const platform = MethodChannel('beytei_deep_debugger');

  Future<void> _fetchAndShowLogs() async {
    // إذا لم يكن النظام iOS، نتجاهل الأمر
    if (!Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("هذه الأداة مخصصة لمعرفة أخطاء الآيفون فقط.")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 15),
            Text("جاري سحب السجلات من النظام..."),
          ],
        ),
      ),
    );

    try {
      // الاتصال بـ Swift لجلب السجلات
      final Map<dynamic, dynamic> result = await platform.invokeMethod('getLogs');
      final String logs = result['logs'] ?? "لا توجد سجلات.";
      final String token = result['token'] ?? "لا يوجد توكن.";

      if (mounted) {
        Navigator.pop(context); // إغلاق نافذة التحميل
        _showLogsDialog(token, logs);
      }
    } on PlatformException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showLogsDialog("Error", "فشل الاتصال بـ iOS: ${e.message}");
      }
    }
  }

  void _showLogsDialog(String token, String logs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black, // شاشة سوداء مثل الكونسول
        title: const Text("🍏 سجلات النظام قبل الـ Crash", style: TextStyle(color: Colors.greenAccent, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
            child: SelectableText(
              "🔑 VoIP Token:\n$token\n\n📝 السجلات:\n$logs",
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: "Token: $token\nLogs: $logs"));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم نسخ السجلات")));
            },
            child: const Text("نسخ", style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إغلاق", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "ios_debugger_btn",
      onPressed: _fetchAndShowLogs,
      backgroundColor: Colors.black87,
      child: const Icon(Icons.bug_report, color: Colors.greenAccent),
    );
  }
}