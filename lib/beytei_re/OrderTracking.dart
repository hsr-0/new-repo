import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../beytei_re/re.dart';
// تأكد من استيراد ملف الثوابت والـ AuthProvider الخاص بك

class OrderTrackingScreen extends StatefulWidget {
  final dynamic order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late String _currentStatus;
  String? _driverName;
  bool _isSyncing = false;
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  @override
  void initState() {
    super.initState();
    // 1. أخذ الحالة المبدئية المخزنة
    _currentStatus = widget.order.status ?? 'pending';
    _driverName = widget.order.driverName;

    // 2. 🔥 المزامنة الذكية فور فتح الشاشة لتصحيح حالة الطلب
    _syncWithServers();

    // 3. تشغيل المستمع للإشعارات اللحظية
    _listenToTaxiUpdates();
  }

  // 🔥 دالة المزامنة المزدوجة (سيرفر السائق + سيرفر المطعم)
  Future<void> _syncWithServers() async {
    if (!mounted) return;
    setState(() => _isSyncing = true);

    bool syncedViaTaxi = await _syncWithTaxiServer();


    if (mounted) setState(() => _isSyncing = false);
  }

  // 1. محاولة جلب الحالة من سيرفر السائق (banner.beytei.com)
  Future<bool> _syncWithTaxiServer() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final String? taxiToken = auth.taxiToken;

      print("📡 جاري فحص الحالة من سيرفر السائق (banner)...");

      final response = await http.get(
        Uri.parse('https://banner.beytei.com/wp-json/taxi/v2/delivery/status-by-source/${widget.order.id}'),

        headers: {
          'Content-Type': 'application/json',
          if (taxiToken != null) 'Authorization': 'Bearer $taxiToken',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String taxiStatus = data['order_status'];
        String? driver = data['driver_name'];

        setState(() {
          _currentStatus = taxiStatus;
          if (driver != null) _driverName = driver;
        });

        await _updateLocalStorage(widget.order.id, taxiStatus);
        return true;
      }
    } catch (e) {
      print("⚠️ سيرفر التاكسي لم يستجب: $e");
    }
    return false;
  }

  // 💾 تحديث SharedPreferences لكي تعرف السلة أن الطلب انتهى
  Future<void> _updateLocalStorage(int orderId, String newStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? ordersString = prefs.getString('order_history');

      if (ordersString != null) {
        List<dynamic> orders = json.decode(ordersString);
        bool isChanged = false;

        for (var i = 0; i < orders.length; i++) {
          if (orders[i]['id'] == orderId) {
            orders[i]['status'] = newStatus;
            isChanged = true;
            break;
          }
        }

        if (isChanged) {
          await prefs.setString('order_history', json.encode(orders));
          print("💾 تم تحديث الكاش المحلي إلى: $newStatus");
        }
      }
    } catch (e) {
      print("❌ فشل تحديث الذاكرة المحلية: $e");
    }
  }

  void _listenToTaxiUpdates() {
    _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data.isNotEmpty && message.data['order_id'] == widget.order.id.toString()) {

        String? newStatus = message.data['new_status'] ?? message.data['status'];
        String? driver = message.data['driver_name'];

        if (mounted) {
          setState(() {
            if (newStatus != null) _currentStatus = newStatus;
            if (driver != null) _driverName = driver;
          });
        }

        if (newStatus != null) {
          _updateLocalStorage(widget.order.id, newStatus);
        }
      }
    });
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    super.dispose();
  }

  int _getStepIndex(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'on-hold': return 0;
      case 'accepted':
      case 'processing': return 1;
      case 'at_store': return 2;
      case 'picked_up':
      case 'out-for-delivery': return 3;
      case 'delivered':
      case 'completed': return 4;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    int currentStep = _getStepIndex(_currentStatus);
    bool isCancelled = _currentStatus == 'cancelled' || _currentStatus == 'failed';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('تتبع الطلب #${widget.order.id}'),
        centerTitle: true,
        actions: [
          _isSyncing
              ? const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))))
              : IconButton(icon: const Icon(Icons.refresh), onPressed: _syncWithServers)
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _syncWithServers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ---------------- البطاقة الأولى: التتبع ----------------
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
                ),
                child: isCancelled
                    ? const Column(
                  children: [
                    Icon(Icons.cancel_outlined, color: Colors.red, size: 60),
                    SizedBox(height: 10),
                    Text("تم إلغاء الطلب", style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                )
                    : _buildCustomTimeline(currentStep),
              ),

              // ---------------- البطاقة الثانية: المندوب ----------------
              if (currentStep >= 1 && _driverName != null && !isCancelled)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blue.shade800, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.motorcycle, color: Colors.white)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("المندوب المسؤول", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(_driverName!, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // ---------------- البطاقة الثالثة: الفاتورة ----------------
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("ملخص الطلب", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 30),
                    _buildPriceRow("حالة الطلب الحالية", _currentStatus.toUpperCase()),
                    const SizedBox(height: 10),
                    _buildPriceRow(
                        "الإجمالي المطلوب",
                        "${(double.tryParse(widget.order.total.toString()) ?? 0).toStringAsFixed(0)} د.ع",
                        isBold: true,
                        color: Colors.green
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String title, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: isBold ? 18 : 15, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: isBold ? 18 : 15, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
      ],
    );
  }

  Widget _buildCustomTimeline(int currentStep) {
    return Column(
      children: [
        _buildTimelineStep(0, "تم استلام الطلب", Icons.receipt_long, currentStep),
        _buildTimelineStep(1, "جاري تحضير الطلب", Icons.soup_kitchen, currentStep),
        _buildTimelineStep(2, "المندوب وصل للمطعم", Icons.storefront, currentStep),
        _buildTimelineStep(3, "المندوب في الطريق إليك", Icons.delivery_dining, currentStep),
        _buildTimelineStep(4, "تم توصيل الطلب بنجاح", Icons.check_circle_outline, currentStep),
      ],
    );
  }

  Widget _buildTimelineStep(int stepIndex, String title, IconData icon, int currentStep) {
    bool isCompleted = currentStep >= stepIndex;
    bool isActive = currentStep == stepIndex;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green : Colors.grey.shade200,
            shape: BoxShape.circle,
            border: isActive ? Border.all(color: Colors.green.shade200, width: 3) : null,
          ),
          child: Icon(icon, color: isCompleted ? Colors.white : Colors.grey, size: 24),
        ),
        const SizedBox(width: 15),
        Text(
            title,
            style: TextStyle(
                fontSize: isActive ? 17 : 15,
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                color: isCompleted ? Colors.black87 : Colors.grey
            )
        ),
      ],
    );
  }
}
