import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IosCrashDebuggerFAB extends StatefulWidget {
  const IosCrashDebuggerFAB({super.key});

  @override
  State<IosCrashDebuggerFAB> createState() => _IosCrashDebuggerFABState();
}

class _IosCrashDebuggerFABState extends State<IosCrashDebuggerFAB> {
  // اسم القناة يجب أن يطابق الموجود في AppDelegate.swift
  static const platform = MethodChannel('beytei_deep_debugger');

  Future<void> _fetchLogs() async {
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
            Text("جاري سحب السجلات من جذور آبل..."),
          ],
        ),
      ),
    );

    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod('getLogs');
      final String logs = result['logs'] ?? "لا توجد سجلات بعد.";
      final String token = result['token'] ?? "لم يتم استلام توكن.";

      if (mounted) {
        Navigator.pop(context); // إغلاق التحميل
        _showConsole(token, logs);
      }
    } on PlatformException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showConsole("Error", "❌ خطأ في الاتصال بالكود الأصلي: ${e.message}");
      }
    }
  }

  void _showConsole(String token, String logText) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E), // لون يشبه الكونسول
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Row(
          children: [
            Icon(Icons.terminal, color: Colors.greenAccent, size: 28),
            SizedBox(width: 10),
            Text("سجلات الآيفون الداخلية", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400, // ارتفاع الشاشة
          child: SingleChildScrollView(
            child: SelectableText(
              "🔑 VoIP Token:\n$token\n\n\n📝 سجلات المكالمة (Log):\n\n$logText",
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.5,
              ),
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: "Token: $token\nLogs: $logText"));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("تم نسخ السجلات")),
              );
            },
            child: const Text("نسخ الكل", style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إغلاق", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: "console_debugger_btn",
      onPressed: _fetchLogs,
      backgroundColor: Colors.black87,
      icon: const Icon(Icons.terminal, color: Colors.greenAccent),
      label: const Text("فحص المكالمة", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
    );
  }
}