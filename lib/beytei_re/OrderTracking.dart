import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 👈 ضروري
import 'dart:async';

class OrderTrackingScreen extends StatefulWidget {
  final dynamic order; // مرر الطلب من الشاشة السابقة
  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late String _currentStatus;
  String? _driverName;
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  @override
  void initState() {
    super.initState();
    // 1. أخذ الحالة المبدئية من الطلب
    _currentStatus = widget.order.status ?? 'pending';
    _driverName = widget.order.driverName;

    // 2. تشغيل المستمع اللحظي للإشعارات (هنا يكمن السحر)
    _listenToTaxiUpdates();
  }

  void _listenToTaxiUpdates() {
    _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // نتأكد أن الإشعار يحتوي على بيانات، وأنه يخص هذا الطلب تحديداً
      if (message.data.isNotEmpty && message.data['order_id'] == widget.order.id.toString()) {

        // تحديث واجهة المستخدم فوراً عند وصول إشعار من التكسي
        setState(() {
          // إذا أرسل سيرفر التكسي حالة جديدة
          if (message.data.containsKey('new_status')) {
            _currentStatus = message.data['new_status'];
          }
          // إذا أرسل سيرفر التكسي اسم المندوب
          if (message.data.containsKey('driver_name')) {
            _driverName = message.data['driver_name'];
          }
        });
      }
    });
  }

  @override
  void dispose() {
    // إيقاف المستمع عند الخروج من الشاشة لتوفير الموارد
    _fcmSubscription?.cancel();
    super.dispose();
  }

  // تحديث يدوي (احتياطي للزبون)
  Future<void> _refreshOrder() async {
    // 💡 هنا تضع كود استدعاء API لجلب حالة الطلب من السيرفر إذا رغب الزبون بالتحديث اليدوي
    // final updatedOrder = await ApiService.getOrder(widget.order.id);
    // setState(() {
    //   _currentStatus = updatedOrder.status;
    //   _driverName = updatedOrder.driverName;
    // });
  }

  // تحويل الحالة النصية إلى رقم الخطوة
  int _getStepIndex(String status) {
    // ⚠️ يجب أن تتطابق هذه الكلمات مع ما يرسله سيرفر التكسي في 'new_status'
    switch (status.toLowerCase()) {
      case 'pending':
      case 'on-hold':
        return 0; // تم الاستلام
      case 'accepted':
      case 'processing':
        return 1; // تم القبول
      case 'at_store':
        return 2; // المندوب في المطعم
      case 'picked_up':
      case 'out-for-delivery':
        return 3; // في الطريق إليك
      case 'delivered':
      case 'completed':
        return 4; // تم التوصيل
      default:
        return 0;
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshOrder)
        ],
      ),
      body: SingleChildScrollView(
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
            // تظهر فقط إذا تجاوزنا مرحلة الاستلام، وتم تعيين اسم سائق، والطلب غير ملغي
            if (currentStep >= 1 && _driverName != null && !isCancelled)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.blue.shade800,
                    borderRadius: BorderRadius.circular(20)
                ),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.motorcycle, color: Colors.white)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("الكابتن الخاص بك", style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                  const Text("تفاصيل الفاتورة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 30),
                  // حساب المجموع (السعر + التوصيل) - تأكد من أسماء المتغيرات حسب الأوبجكت لديك
                  _buildPriceRow(
                      "الإجمالي الكلي",
                      "${(double.tryParse(widget.order.total.toString()) ?? 0 + (double.tryParse(widget.order.shippingTotal.toString()) ?? 0)).toStringAsFixed(0)} د.ع",
                      isBold: true,
                      color: Colors.green
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String title, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: isBold ? 18 : 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: isBold ? 18 : 16, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
      ],
    );
  }

  Widget _buildCustomTimeline(int currentStep) {
    return Column(
      children: [
        _buildTimelineStep(0, "تم الاستلام", Icons.receipt_long, currentStep),
        _buildTimelineStep(1, "تم القبول (جاري التجهيز)", Icons.soup_kitchen, currentStep),
        _buildTimelineStep(2, "الكابتن في المطعم", Icons.storefront, currentStep),
        _buildTimelineStep(3, "في الطريق إليك", Icons.delivery_dining, currentStep),
        _buildTimelineStep(4, "تم التوصيل", Icons.check_circle_outline, currentStep),
      ],
    );
  }

  Widget _buildTimelineStep(int stepIndex, String title, IconData icon, int currentStep) {
    bool isCompleted = currentStep >= stepIndex;
    // التأثير البصري للخطوة الحالية النشطة
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
                fontSize: isActive ? 18 : 16,
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                color: isCompleted ? Colors.black87 : Colors.grey
            )
        ),
      ],
    );
  }
}
