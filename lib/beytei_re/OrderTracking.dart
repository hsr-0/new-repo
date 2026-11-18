import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../beytei_re/re.dart'; //

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

  // متغير لمنع منح الصندوق مرتين لنفس الطلب في الجلسة الواحدة
  bool _boxAlreadyClaimedThisSession = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status ?? 'pending';
    _driverName = widget.order.driverName;

    _syncWithServers();
    _listenToTaxiUpdates();
  }

  Future<void> _syncWithServers() async {
    if (!mounted) return;
    setState(() => _isSyncing = true);

    await _syncWithTaxiServer();

    if (mounted) setState(() => _isSyncing = false);
  }

  // 1. جلب الحالة من سيرفر السائق الجديد (de.beytei.com)
  Future<bool> _syncWithTaxiServer() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final String? taxiToken = auth.taxiToken;

      print("📡 جاري فحص الحالة من سيرفر السائق الجديد (de.beytei.com)...");

      final response = await http.get(
        Uri.parse('https://de.beytei.com/api/taxi/v2/delivery/status-by-source/${widget.order.id}'),
        headers: {
          'Content-Type': 'application/json',
          if (taxiToken != null) 'Authorization': 'Bearer $taxiToken',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        String taxiStatus = (data['status'] ?? data['order_status'] ?? 'pending').toString();
        String? driver = data['driver_name'];

        setState(() {
          _currentStatus = taxiStatus;
          if (driver != null && driver.isNotEmpty) _driverName = driver;
        });

        await _updateLocalStorage(widget.order.id, taxiStatus);
        await _checkAndClaimBoxOnDelivery(taxiStatus);

        return true;
      }
    } catch (e) {
      print("⚠️ سيرفر التاكسي الجديد لم يستجب: $e");
    }
    return false;
  }

  Future<void> _updateLocalStorage(int orderId, String newStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? ordersString = prefs.getString('order_history');

      if (ordersString != null) {
        List<dynamic> orders = json.decode(ordersString);
        bool isChanged = false;

        for (var i = 0; i < orders.length; i++) {
          if (orders[i]['id'].toString() == orderId.toString()) {
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

  Future<void> _checkAndClaimBoxOnDelivery(String status) async {
    if (status.toLowerCase() != 'delivered' && status.toLowerCase() != 'completed') {
      return;
    }

    if (_boxAlreadyClaimedThisSession) return;

    final hasClaimed = await _hasClaimedBoxForOrder(widget.order.id);
    if (hasClaimed) {
      _boxAlreadyClaimedThisSession = true;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final int areaId = prefs.getInt('selectedAreaId') ?? 0;

    if (areaId == 84) {
      print("ℹ️ منطقة الكوت (84) - نظام الكاش باك فقط، لا صناديق.");
      return;
    }

    try {
      print("🎁 جاري منح صندوق فضي للطلب #${widget.order.id}...");

      if (mounted) {
        final wallet = Provider.of<SmartWalletProvider>(context, listen: false);
        await wallet.claimBoxOnDelivery(areaId);

        await _markOrderAsBoxClaimed(widget.order.id);
        _boxAlreadyClaimedThisSession = true;

        print("✅ تم منح الصندوق الفضي بنجاح للطلب #${widget.order.id}");

        if (mounted) {
          _showBoxRewardSnackbar();
        }
      }
    } catch (e) {
      print("❌ فشل منح الصندوق: $e");
    }
  }

  Future<bool> _hasClaimedBoxForOrder(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> claimedOrders = prefs.getStringList('claimed_box_orders') ?? [];
      return claimedOrders.contains(orderId.toString());
    } catch (e) {
      return false;
    }
  }

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

  void _showBoxRewardSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
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
      ),
    );
  }

  void _listenToTaxiUpdates() {
    _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final msgOrderId = message.data['order_id']?.toString();
      final targetOrderId = widget.order.id.toString();

      if (msgOrderId == targetOrderId) {
        String? newStatus = (message.data['new_status'] ?? message.data['status'])?.toString();
        String? driver = message.data['driver_name'];

        if (mounted) {
          setState(() {
            if (newStatus != null) _currentStatus = newStatus;
            if (driver != null && driver.isNotEmpty) _driverName = driver;
          });
        }

        if (newStatus != null) {
          _updateLocalStorage(widget.order.id, newStatus);
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

  // فتح نافذة تقييم السائق السفلية
  void _openRatingBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // لتجنب مشكلة الكيبورد
      backgroundColor: Colors.transparent,
      builder: (context) => DriverRatingBottomSheet(
        orderId: widget.order.id,
        driverName: _driverName ?? "المندوب",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int currentStep = _getStepIndex(_currentStatus);
    bool isCancelled = _currentStatus == 'cancelled' || _currentStatus == 'failed';
    bool isDelivered = currentStep == 4;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('تتبع الطلب #${widget.order.id}'),
        centerTitle: true,
        actions: [
          _isSyncing
              ? const Center(
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                  )
              )
          )
              : IconButton(icon: const Icon(Icons.refresh), onPressed: _syncWithServers)
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _syncWithServers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // قسم التايم لاين
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

              // زر تقييم المندوب يظهر فقط عند التوصيل
              if (isDelivered && !isCancelled)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _openRatingBottomSheet,
                      icon: const Icon(Icons.star_rate_rounded, color: Colors.white, size: 28),
                      label: const Text(
                        "قيّم المندوب الآن",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 4,
                      ),
                    ),
                  ),
                ),

              // معلومات المندوب
              if (currentStep >= 1 && _driverName != null && !isCancelled)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerChatPage(
                                orderId: widget.order.id.toString(),
                                driverName: _driverName ?? 'المندوب',
                                customerName: widget.order.customerName ?? 'الزبون',
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

              // ملخص الطلب والأسعار
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
                    const SizedBox(height: 15),

                    // عرض السعر المشطوب والإجمالي بعد الخصم
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("الإجمالي المطلوب", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Builder(
                          builder: (context) {
                            final double finalTotal = double.tryParse(widget.order.total.toString()) ?? 0.0;
                            final double discountAmount = widget.order.discountAmount != null
                                ? double.tryParse(widget.order.discountAmount.toString()) ?? 0.0
                                : 0.0;
                            final double originalTotal = widget.order.originalTotal != null
                                ? double.tryParse(widget.order.originalTotal.toString()) ?? 0.0
                                : (finalTotal + discountAmount);

                            if (discountAmount > 0) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "${NumberFormat('#,###', 'ar_IQ').format(finalTotal)} د.ع",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${NumberFormat('#,###', 'ar_IQ').format(originalTotal)} د.ع",
                                    style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey.shade500,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Text(
                                "${NumberFormat('#,###', 'ar_IQ').format(finalTotal)} د.ع",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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

// ==========================================
// شاشة التقييم السفلية الذكية (Smart Bottom Sheet)
// ==========================================
class DriverRatingBottomSheet extends StatefulWidget {
  final int orderId;
  final String driverName;

  const DriverRatingBottomSheet({
    Key? key,
    required this.orderId,
    required this.driverName,
  }) : super(key: key);

  @override
  State<DriverRatingBottomSheet> createState() => _DriverRatingBottomSheetState();
}

class _DriverRatingBottomSheetState extends State<DriverRatingBottomSheet> {
  int _rating = 0;
  final List<String> _selectedTags = [];
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  // الخيارات الإيجابية تظهر عند التقييم (4 أو 5 نجوم)
  final List<String> _positiveTags = [
    'معاملة جيدة',
    'احترام الموعد',
    'يرتدي زي المنصة ',
    'سياقة آمنة',
    'يحترم الخصوصية'
  ];

  // الخيارات السلبية تظهر عند التقييم (1 إلى 3 نجوم)
  final List<String> _negativeTags = [
    'معاملة سيئة',
    'طلب الدفع نقداً',
    'أخذ مبلغ إضافي',
    'القيادة بتهور',
    'عدم لبس الزي المنصة',
    'مشكلة بالانطلاق/الوصول'
  ];

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _submitRating() async {
    if (_isSubmitting) return;

    if (_rating < 1 || _rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد عدد النجوم أولاً'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse(
          'https://de.beytei.com/api/taxi/v2/rate-driver',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'order_id': widget.orderId,
          'rating': _rating,
          'tags': _selectedTags,
          'comment': _commentController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 20));

      Map<String, dynamic> data = {};

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {}

      if (!mounted) return;

      if (response.statusCode == 200 &&
          data['success'] == true) {

        final messenger = ScaffoldMessenger.of(context);

        Navigator.of(context).pop(true);

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              data['message']?.toString() ??
                  'تم إرسال التقييم بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );

        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data['message']?.toString() ??
                'فشل إرسال التقييم (${response.statusCode})',
          ),
          backgroundColor: Colors.red,
        ),
      );

    } on TimeoutException {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'انتهت مهلة الاتصال. يرجى التحقق من حالة التقييم قبل إعادة المحاولة.',
          ),
          backgroundColor: Colors.orange,
        ),
      );

    } catch (e) {
      if (!mounted) return;

      debugPrint('Rating error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر الاتصال بسيرفر التقييم'),
          backgroundColor: Colors.red,
        ),
      );

    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    // تحديد قائمة الأزرار (Tags) بناءً على النجوم
    List<String> currentTags = _rating >= 4 ? _positiveTags : (_rating > 0 ? _negativeTags : []);

    return Container(
      // تحديد هامش سفلي استجابة لظهور الكيبورد
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 15
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // شريط السحب العلوي (مؤشر بصري)
            Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10)
                )
            ),
            const SizedBox(height: 20),

            Text("تقييم السائق", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            const SizedBox(height: 5),
            Text(widget.driverName, style: TextStyle(fontSize: 16, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),

            // صف النجوم الديناميكي
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: index < _rating ? Colors.amber : Colors.grey.shade400,
                    size: 45,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                      _selectedTags.clear(); // تفريغ الاختيارات السابقة عند تغيير التقييم
                    });
                  },
                );
              }),
            ),

            // ظهور الخيارات (Tags) فقط بعد اختيار النجوم
            if (_rating > 0) ...[
              const SizedBox(height: 15),
              Text(
                  _rating >= 4 ? "المميزات" : "المساوئ",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: currentTags.map((tag) {
                  bool isSelected = _selectedTags.contains(tag);
                  bool isNegative = _rating < 4; // تحديد ما إذا كان التقييم سلبياً
                  return ChoiceChip(
                    label: Text(tag, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                    selected: isSelected,
                    selectedColor: isNegative ? Colors.red.shade500 : Colors.blue.shade600,
                    backgroundColor: Colors.grey.shade100,
                    onSelected: (bool selected) => _toggleTag(tag),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // حقل النص للملاحظات الإضافية
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: "أخبرنا برأيك بخصوص الرحلة (اختياري)...",
                  prefixIcon: const Icon(Icons.comment_outlined, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                maxLines: 2,
              ),
            ],

            const SizedBox(height: 25),

            // زر إرسال التقييم
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("إرسال التقييم", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}