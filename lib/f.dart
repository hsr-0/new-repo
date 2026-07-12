import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({Key? key}) : super(key: key);

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  // 🔑 التوكنات
  String _voipToken = 'جاري التحميل...';
  String _fcmToken = 'جاري التحميل...';
  String _deviceId = 'جاري التحميل...';

  // 📱 معلومات الجهاز
  String _platform = 'جاري التحميل...';
  String _appVersion = 'جاري التحميل...';
  String _osVersion = 'جاري التحميل...';
  String _deviceModel = 'جاري التحميل...';

  // ⚙️ حالة النظام
  String _callKitStatus = 'جاري الفحص...';
  String _notificationPermission = 'جاري الفحص...';
  String _microphonePermission = 'جاري الفحص...';
  String _networkStatus = 'جاري الفحص...';
  String _agoraStatus = 'جاري الفحص...';
  String _batteryOptimization = 'جاري الفحص...';

  // 📋 السجلات
  List<String> _logs = [];
  List<String> _nativeLogs = [];
  Timer? _refreshTimer;

  // 📊 الإحصائيات
  int _totalCalls = 0;
  int _failedCalls = 0;
  int _successfulCalls = 0;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
    _loadNativeLogs();
    _loadStatistics();

    // تحديث تلقائي كل 5 ثوانٍ
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadDiagnostics();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // =========================================================================
  // 🔥 الدوال الرئيسية للفحص
  // =========================================================================

  Future<void> _loadDiagnostics() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. التوكنات
      setState(() {
        _voipToken = prefs.getString('voip_token') ?? '❌ غير موجود';
        _fcmToken = prefs.getString('fcm_token') ?? '❌ غير موجود';
        _deviceId = prefs.getString('device_id') ?? 'غير محدد';
        _platform = Platform.isIOS ? '🍏 iOS' : '🤖 Android';
      });

      // 2. فحص CallKit
      await _checkCallKit();

      // 3. فحص الأذونات
      await _checkPermissions();

      // 4. فحص الشبكة
      await _checkNetwork();

      // 5. فحص Agora
      await _checkAgora();

      // 6. فحص Battery Optimization (للأندرويد)
      if (!Platform.isIOS) {
        await _checkBatteryOptimization();
      }

      _addLog('✅ تم تحديث البيانات - ${DateTime.now().toIso8601String()}');
    } catch (e) {
      _addLog('❌ خطأ في تحميل البيانات: $e');
    }
  }

  // =========================================================================
  // 🍏 فحص CallKit (iOS)
  // =========================================================================

  Future<void> _checkCallKit() async {
    try {
      var activeCalls = await FlutterCallkitIncoming.activeCalls();
      setState(() {
        if (activeCalls.isEmpty) {
          _callKitStatus = '✅ جاهز (لا توجد مكالمات نشطة)';
        } else {
          _callKitStatus = '⚠️ توجد ${activeCalls.length} مكالمة نشطة';
        }
      });
    } catch (e) {
      setState(() {
        _callKitStatus = '❌ خطأ: $e';
      });
    }
  }

  // =========================================================================
  // 🔐 فحص الأذونات
  // =========================================================================

  Future<void> _checkPermissions() async {
    try {
      // إذن الإشعارات
      final notifSettings = await FirebaseMessaging.instance.getNotificationSettings();
      setState(() {
        _notificationPermission = notifSettings.authorizationStatus.name;
      });

      // إذن المايكروفون (من خلال محاولة الحصول على VoIP Token)
      if (Platform.isIOS) {
        try {
          final voipToken = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
          setState(() {
            _microphonePermission = voipToken != null && voipToken.isNotEmpty
                ? '✅ ممنوح (VoIP Token موجود)'
                : '❌ مرفوض';
          });
        } catch (e) {
          setState(() {
            _microphonePermission = '❌ خطأ: $e';
          });
        }
      } else {
        setState(() {
          _microphonePermission = '✅ غير مطلوب للفحص';
        });
      }
    } catch (e) {
      setState(() {
        _notificationPermission = '❌ خطأ: $e';
        _microphonePermission = '❌ خطأ: $e';
      });
    }
  }

  // =========================================================================
  // 🌐 فحص الشبكة
  // =========================================================================

  Future<void> _checkNetwork() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      String status = '';
      if (connectivityResult.contains(ConnectivityResult.mobile)) {
        status = '✅ متصل بالبيانات الخلوية';
      } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
        status = '✅ متصل بـ WiFi';
      } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
        status = '✅ متصل بشبكة سلكية';
      } else {
        status = '❌ لا يوجد اتصال';
      }

      // اختبار سرعة الاتصال
      final stopwatch = Stopwatch()..start();
      try {
        await http.get(Uri.parse('https://re.beytei.com/wp-json/')).timeout(
          const Duration(seconds: 5),
        );
        stopwatch.stop();
        status += ' (${stopwatch.elapsedMilliseconds}ms)';
      } catch (e) {
        status += ' (⚠️ بطيء)';
      }

      setState(() {
        _networkStatus = status;
      });
    } catch (e) {
      setState(() {
        _networkStatus = '❌ خطأ: $e';
      });
    }
  }

  // =========================================================================
  // 🎙️ فحص Agora Engine
  // =========================================================================

  Future<void> _checkAgora() async {
    try {
      // محاولة تهيئة محرك Agora
      final engine = createAgoraRtcEngine();
      await engine.initialize(const RtcEngineContext(
        appId: '3924f8eebe7048f8a65cb3bd4a4adcec',
      ));

      setState(() {
        _agoraStatus = '✅ محرك Agora جاهز';
      });

      // إطلاق المحرك فوراً
      await engine.release();
    } catch (e) {
      setState(() {
        _agoraStatus = '❌ خطأ: $e';
      });
    }
  }

  // =========================================================================
  // 🔋 فحص Battery Optimization (للأندرويد)
  // =========================================================================

  Future<void> _checkBatteryOptimization() async {
    try {
      // في الأندرويد، نستخدم Method Channel للتحقق
      const platform = MethodChannel('beytei_battery');
      final bool isOptimized = await platform.invokeMethod('isBatteryOptimized');

      setState(() {
        _batteryOptimization = isOptimized
            ? '⚠️ التطبيق مقيد (قد يسبب انقطاع المكالمات)'
            : '✅ غير مقيد';
      });
    } catch (e) {
      setState(() {
        _batteryOptimization = 'ℹ️ غير متاح للفحص';
      });
    }
  }

  // =========================================================================
  // 📜 قراءة السجلات من iOS Native (AppDelegate)
  // =========================================================================

  Future<void> _loadNativeLogs() async {
    if (!Platform.isIOS) return;

    try {
      const platform = MethodChannel('beytei_deep_debugger');
      final result = await platform.invokeMethod('getLogs');

      if (result != null && result is Map) {
        final logs = result['logs'] as String? ?? '';
        final voipToken = result['token'] as String? ?? '';

        setState(() {
          _nativeLogs = logs.split('\n\n').where((l) => l.isNotEmpty).toList();
          if (voipToken.isNotEmpty && voipToken != 'لا يوجد توكن') {
            _voipToken = voipToken;
          }
        });
      }
    } catch (e) {
      _addLog('⚠️ فشل قراءة السجلات الأصلية: $e');
    }
  }

  // =========================================================================
  // 📊 تحميل الإحصائيات
  // =========================================================================

  Future<void> _loadStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _totalCalls = prefs.getInt('total_calls') ?? 0;
        _failedCalls = prefs.getInt('failed_calls') ?? 0;
        _successfulCalls = prefs.getInt('successful_calls') ?? 0;
      });
    } catch (e) {
      _addLog('⚠️ فشل تحميل الإحصائيات: $e');
    }
  }

  // =========================================================================
  // 📝 إضافة سجل
  // =========================================================================

  void _addLog(String message) async {
    setState(() {
      _logs.insert(0, message);
      if (_logs.length > 50) _logs.removeLast();
    });

    // حفظ السجل في SharedPreferences (للاستعادة بعد Crash)
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLogs = prefs.getStringList('diagnostic_logs') ?? [];
      savedLogs.insert(0, '${DateTime.now().toIso8601String()} - $message');
      if (savedLogs.length > 100) savedLogs.removeLast();
      await prefs.setStringList('diagnostic_logs', savedLogs);
    } catch (e) {
      // تجاهل الخطأ
    }
  }

  // =========================================================================
  // 🧪 اختبار VoIP Connection
  // =========================================================================

  Future<void> _testVoIPConnection() async {
    _addLog('🧪 بدء اختبار الاتصال بـ VoIP...');

    if (_voipToken == '❌ غير موجود') {
      _addLog('❌ لا يوجد توكن VoIP!');
      _showErrorDialog('لا يوجد توكن VoIP',
          'التطبيق لم يقم بتوليد توكن VoIP.\n\n'
              'الحل:\n'
              '1. تأكد من تفعيل VoIP Push في Xcode\n'
              '2. سجل الدخول مجدداً\n'
              '3. أعد تثبيت التطبيق');
      return;
    }

    try {
      _addLog('📡 جاري إرسال طلب اختبار للسيرفر...');

      final response = await http.post(
        Uri.parse('https://re.beytei.com/wp-json/beytei-calls/v1/test-voip'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'voip_token': _voipToken,
          'test': true,
          'secret_key': 'BEYTEI_SECURE_2025'
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _addLog('✅ استجابة السيرفر: ${data['message']}');

        if (data['apple_response'] != null) {
          _addLog('🍏 رد آبل: ${data['apple_response']}');

          if (data['apple_response'].contains('BadDeviceToken')) {
            _showErrorDialog('توكن VoIP خاطئ',
                'توكن VoIP المخزن غير صحيح.\n\n'
                    'الحل:\n'
                    '1. احذف التطبيق\n'
                    '2. أعد تثبيته\n'
                    '3. سجّل الدخول مجدداً');
          } else if (data['apple_response'].contains('200')) {
            _showSuccessDialog('نجاح!',
                'آبل قبلت الطلب! الهاتف يجب أن يرن الآن.');
          }
        }
      } else {
        _addLog('❌ خطأ من السيرفر: ${response.statusCode}');
        _showErrorDialog('خطأ في السيرفر',
            'السيرفر أرجع خطأ: ${response.statusCode}');
      }
    } catch (e) {
      _addLog('❌ فشل الاتصال: $e');
      _showErrorDialog('خطأ في الاتصال', 'فشل الاتصال بالسيرفر: $e');
    }
  }

  // =========================================================================
  // 🔄 تحديث التوكنات
  // =========================================================================

  Future<void> _refreshTokens() async {
    _addLog('🔄 جاري تحديث التوكنات...');

    try {
      // تحديث FCM Token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', fcmToken);
        _addLog('✅ تم تحديث FCM Token');
      }

      // تحديث VoIP Token (للآيفون فقط)
      if (Platform.isIOS) {
        try {
          final voipToken = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
          if (voipToken != null && voipToken.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('voip_token', voipToken);
            _addLog('✅ تم تحديث VoIP Token');
          }
        } catch (e) {
          _addLog('⚠️ فشل تحديث VoIP Token: $e');
        }
      }

      await _loadDiagnostics();
      _showSuccessDialog('تم التحديث', 'تم تحديث جميع التوكنات بنجاح');
    } catch (e) {
      _addLog('❌ خطأ في التحديث: $e');
      _showErrorDialog('خطأ', 'فشل تحديث التوكنات: $e');
    }
  }

  // =========================================================================
  // 🗑️ مسح السجلات
  // =========================================================================

  Future<void> _clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح السجلات'),
        content: const Text('هل أنت متأكد من مسح جميع السجلات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('مسح', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _logs.clear();
        _nativeLogs.clear();
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('diagnostic_logs');

      _addLog('🗑️ تم مسح جميع السجلات');
    }
  }

  // =========================================================================
  // 📤 تصدير السجلات
  // =========================================================================

  Future<void> _exportLogs() async {
    final allLogs = [
      '=== سجلات Flutter ===',
      ..._logs,
      '',
      '=== سجلات iOS Native ===',
      ..._nativeLogs,
      '',
      '=== معلومات الجهاز ===',
      'النظام: $_platform',
      'FCM Token: $_fcmToken',
      'VoIP Token: $_voipToken',
      'الشبكة: $_networkStatus',
      'CallKit: $_callKitStatus',
      'Agora: $_agoraStatus',
    ].join('\n');

    Clipboard.setData(ClipboardData(text: allLogs));
    _showSuccessDialog('تم النسخ', 'تم نسخ جميع السجلات إلى الحافظة');
  }

  // =========================================================================
  // 🎨 Dialogs
  // =========================================================================

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ تم نسخ $label')),
    );
  }

  // =========================================================================
  // 🎨 UI Build
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 شاشة التشخيص الشاملة'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: _exportLogs,
            tooltip: 'تصدير السجلات',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLogs,
            tooltip: 'مسح السجلات',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDiagnostics,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📊 الإحصائيات
            _buildStatisticsCard(),
            const SizedBox(height: 20),

            // 📱 معلومات الجهاز
            _buildSection(
              '📱 معلومات الجهاز',
              [
                _buildInfoRow('النظام', _platform),
                _buildInfoRow('إصدار التطبيق', _appVersion),
                _buildInfoRow('معرف الجهاز', _deviceId, copyable: true),
              ],
            ),
            const SizedBox(height: 20),

            // 🔑 التوكنات
            _buildSection(
              '🔑 التوكنات',
              [
                _buildTokenRow('FCM Token', _fcmToken),
                const SizedBox(height: 10),
                _buildTokenRow('VoIP Token', _voipToken),
              ],
            ),
            const SizedBox(height: 20),

            // ⚙️ حالة النظام
            _buildSection(
              '⚙️ حالة النظام',
              [
                _buildInfoRow('CallKit', _callKitStatus),
                _buildInfoRow('إذن الإشعارات', _notificationPermission),
                _buildInfoRow('إذن المايكروفون', _microphonePermission),
                _buildInfoRow('الشبكة', _networkStatus),
                _buildInfoRow('محرك Agora', _agoraStatus),
                if (!Platform.isIOS)
                  _buildInfoRow('Battery Optimization', _batteryOptimization),
              ],
            ),
            const SizedBox(height: 20),

            // 🛠️ الإجراءات
            _buildSection(
              '🛠️ الإجراءات',
              [
                ElevatedButton.icon(
                  onPressed: _testVoIPConnection,
                  icon: const Icon(Icons.phone),
                  label: const Text('اختبار اتصال VoIP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _refreshTokens,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث التوكنات'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 📋 سجلات Flutter
            _buildSection(
              '📋 سجلات Flutter (${_logs.length})',
              [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Text(
                        _logs[index],
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 🍏 سجلات iOS Native
            if (Platform.isIOS && _nativeLogs.isNotEmpty)
              _buildSection(
                '🍏 سجلات iOS Native (${_nativeLogs.length})',
                [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: _nativeLogs.length,
                      itemBuilder: (context, index) {
                        return Text(
                          _nativeLogs[index],
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // 💡 نصائح
            _buildSection(
              '💡 نصائح',
              [
                Text(
                  'إذا لم تصل المكالمات:\n\n'
                      '1. تأكد من تفعيل VoIP Push في Xcode\n'
                      '2. تأكد من وجود توكن VoIP (ليس فارغاً)\n'
                      '3. اضغط "اختبار اتصال VoIP" لترى رد آبل\n'
                      '4. إذا ظهر BadDeviceToken، أعد تثبيت التطبيق\n'
                      '5. إذا ظهر 200 OK، فالمشكلة في كود Flutter\n'
                      '6. في الأندرويد، تأكد من إلغاء Battery Optimization\n\n'
                      'للمساعدة: اضغط "تصدير السجلات" وأرسلها لي',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 🎨 Widgets مساعدة
  // =========================================================================

  Widget _buildStatisticsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('إجمالي', _totalCalls.toString(), Icons.phone),
          _buildStatItem('ناجح', _successfulCalls.toString(), Icons.check_circle),
          _buildStatItem('فاشل', _failedCalls.toString(), Icons.error),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: value.contains('❌')
                    ? Colors.red
                    : value.contains('⚠️')
                    ? Colors.orange
                    : Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () => _copyToClipboard(value, label),
              tooltip: 'نسخ',
            ),
        ],
      ),
    );
  }

  Widget _buildTokenRow(String label, String token) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: token.contains('❌') ? Colors.red[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: token.contains('❌') ? Colors.red : Colors.blue,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  token.length > 30 ? '${token.substring(0, 30)}...' : token,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () => _copyToClipboard(token, label),
                tooltip: 'نسخ التوكن كاملاً',
              ),
            ],
          ),
        ],
      ),
    );
  }
}