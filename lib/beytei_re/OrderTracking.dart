import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../beytei_re/re.dart'; // تأكد من المسار الصحيح لكلاس CustomerChatPage و AuthProvider و SmartWalletProvider

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

  // 🔥 متغير لمنع منح الصندوق مرتين لنفس الطلب في الجلسة الواحدة
  bool _boxAlreadyClaimedThisSession = false;

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

    await _syncWithTaxiServer();

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
          if (driver != null && driver.isNotEmpty) _driverName = driver;
        });

        await _updateLocalStorage(widget.order.id, taxiStatus);

        // 🔥🔥🔥 التحقق من اكتمال الطلب ومنح الصندوق 🔥🔥🔥
        await _checkAndClaimBoxOnDelivery(taxiStatus);

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

  // 🔥🔥🔥 الدالة الجديدة: التحقق من اكتمال الطلب ومنح الصندوق 🔥🔥🔥
  Future<void> _checkAndClaimBoxOnDelivery(String status) async {
    // 1. هل الحالة هي "تم التوصيل"؟
    if (status.toLowerCase() != 'delivered' && status.toLowerCase() != 'completed') {
      return;
    }

    // 2. هل تم منح الصندوق لهذا الطلب بالفعل في هذه الجلسة؟
    if (_boxAlreadyClaimedThisSession) {
      print("ℹ️ تم منح الصندوق لهذا الطلب مسبقاً في هذه الجلسة.");
      return;
    }

    // 3. هل تم منح الصندوق لهذا الطلب في جلسات سابقة؟ (حماية من التكرار)
    final hasClaimed = await _hasClaimedBoxForOrder(widget.order.id);
    if (hasClaimed) {
      print("ℹ️ تم منح الصندوق للطلب #${widget.order.id} مسبقاً.");
      _boxAlreadyClaimedThisSession = true;
      return;
    }

    // 4. جلب منطقة الزبون
    final prefs = await SharedPreferences.getInstance();
    final int areaId = prefs.getInt('selectedAreaId') ?? 0;

    // 5. منطقة الكوت (84) لها نظام كاش باك مختلف، لا نعطيها صندوق
    if (areaId == 84) {
      print("ℹ️ منطقة الكوت (84) - نظام الكاش باك فقط، لا صناديق.");
      return;
    }

    // 6. منح الصندوق الفضي
    try {
      print("🎁 جاري منح صندوق فضي للطلب #${widget.order.id}...");

      if (mounted) {
        final wallet = Provider.of<SmartWalletProvider>(context, listen: false);
        await wallet.claimBoxOnDelivery(areaId);

        // 7. حفظ معرف الطلب كـ "تم منحه" لمنع التكرار
        await _markOrderAsBoxClaimed(widget.order.id);
        _boxAlreadyClaimedThisSession = true;

        print("✅ تم منح الصندوق الفضي بنجاح للطلب #${widget.order.id}");

        // 8. إظهار إشعار لطيف للزبون
        if (mounted) {
          _showBoxRewardSnackbar();
        }
      }
    } catch (e) {
      print("❌ فشل منح الصندوق: $e");
    }
  }

  // 🔍 التحقق من SharedPreferences هل تم منح الصندوق لهذا الطلب
  Future<bool> _hasClaimedBoxForOrder(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> claimedOrders = prefs.getStringList('claimed_box_orders') ?? [];
      return claimedOrders.contains(orderId.toString());
    } catch (e) {
      return false;
    }
  }

  // 💾 حفظ معرف الطلب كـ "تم منحه صندوق"
  Future<void> _markOrderAsBoxClaimed(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> claimedOrders = prefs.getStringList('claimed_box_orders') ?? [];
      if (!claimedOrders.contains(orderId.toString())) {
        claimedOrders.add(orderId.toString());
        await prefs.setStringList('claimed_box_orders', claimedOrders);
      }
    } catch (e) {
      print("❌ فشل حفظ حالة المنح: $e");
    }
  }

  // 🎉 إظهار Snackbar لطيف للزبون عند حصوله على صندوق
  void _showBoxRewardSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.inventory_2, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "🎁 مبروك! حصلت على صندوق فضي جديد!",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00BCD4),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'فتح الآن',
          textColor: Colors.white,
          onPressed: () {
            // يمكن الانتقال لشاشة الصناديق هنا إذا أردت
            // Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerWalletScreen()));
          },
        ),
      ),
    );
  }

  void _listenToTaxiUpdates() {
    _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data.isNotEmpty && message.data['order_id'] == widget.order.id.toString()) {
        String? newStatus = message.data['new_status'] ?? message.data['status'];
        String? driver = message.data['driver_name'];

        if (mounted) {
          setState(() {
            if (newStatus != null) _currentStatus = newStatus;
            if (driver != null && driver.isNotEmpty) _driverName = driver;
          });
        }

        if (newStatus != null) {
          _updateLocalStorage(widget.order.id, newStatus);

          // 🔥 التحقق من اكتمال الطلب عند استقبال إشعار لحظي
          _checkAndClaimBoxOnDelivery(newStatus);
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

              // ---------------- البطاقة الثانية: المندوب (مع زر الدردشة) ----------------
              if (currentStep >= 1 && _driverName != null && !isCancelled)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade800,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white24,
                        radius: 25,
                        child: Icon(Icons.motorcycle, color: Colors.white, size: 28),
                      ),
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
                      // 🔥 زر الدردشة الجديد 🔥
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerChatPage(
                                orderId: widget.order.id.toString(),
                                driverName: _driverName ?? 'المندوب',
                                customerName: widget.order.customerName, // يفترض أن order يحتوي على customerName
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_rounded),
                        color: Colors.white,
                        iconSize: 28,
                        tooltip: "محادثة المندوب",
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.all(10),
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