import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class BeyteiZoneScreen extends StatefulWidget {
  const BeyteiZoneScreen({Key? key}) : super(key: key);

  @override
  State<BeyteiZoneScreen> createState() => _BeyteiZoneScreenState();
}

class _BeyteiZoneScreenState extends State<BeyteiZoneScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _spinAnimation;

  // المتغيرات
  List<Map<String, dynamic>> _participants = [];
  bool _shouldSpin = false;
  String? _winnerName;
  bool _isResultShown = false;

  bool _isLoading = true; // حالة التحميل
  bool _isOffline = false; // حالة الاتصال
  String _lastUpdateText = "";

  String _timeUntilDraw = "00:00:00";
  Timer? _timer;

  // 🔴🔴 هام: تأكد من أن هذا الرابط صحيح ويعمل في المتصفح 🔴🔴
  final String _apiUrl = 'https://re.beytei.com/wp-json/restaurant-app/v1/zone-status';

  @override
  void initState() {
    super.initState();

    // إعداد حركة الدوران المستمر
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _startCountdown();

    // بدء عملية جلب البيانات
    _loadDataWithCacheStrategy();
  }

  Future<void> _loadDataWithCacheStrategy() async {
    // 1. محاولة التحميل من الكاش أولاً (لعرض البيانات القديمة فوراً)
    await _loadFromCache();

    // 2. طلب البيانات من السيرفر (للتحديث)
    await _fetchFromApi();
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString('beytei_zone_data');
    final String? cachedTime = prefs.getString('beytei_zone_last_update');

    if (cachedData != null) {
      try {
        final Map<String, dynamic> data = json.decode(cachedData);
        _processData(data);

        if (cachedTime != null && mounted) {
          setState(() {
            _lastUpdateText = "آخر تحديث: $cachedTime";
            // إذا وجدنا كاش، نوقف التحميل المبدئي حتى لو السيرفر لسه ماردش
            _isLoading = false;
          });
        }
      } catch (e) {
        print("Error parsing cache: $e");
      }
    }
  }

  Future<void> _fetchFromApi() async {
    if (mounted) setState(() => _isLoading = true);

    print("🚀 جاري الاتصال بالسيرفر: $_apiUrl");

    try {
      final response = await http.get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 15));

      print("📡 كود الحالة (Status Code): ${response.statusCode}");
      // print("📄 الرد (Body): ${response.body}"); // فعل هذا السطر لترى الرد كاملاً

      if (response.statusCode == 200) {
        // ✅ نجح الاتصال
        final data = json.decode(response.body);
        _processData(data);

        // حفظ البيانات الجديدة في الكاش
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('beytei_zone_data', response.body);

        final now = DateTime.now();
        final timeString = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
        await prefs.setString('beytei_zone_last_update', timeString);

        if (mounted) {
          setState(() {
            _lastUpdateText = "تم التحديث: $timeString";
            _isOffline = false;
            _isLoading = false;
          });
        }
      } else {
        // ❌ السيرفر رد ولكن بوجود خطأ (404, 500, 403)
        throw Exception('Server Error: Code ${response.statusCode}');
      }
    } catch (e) {
      print("❌ خطأ في الاتصال: $e");

      if (mounted) {
        setState(() {
          _isOffline = true;
          _isLoading = false;
        });

        // نعرض رسالة تنبيه فقط إذا كان هناك بيانات قديمة معروضة
        if (_participants.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("تعذر التحديث: تأكد من الإنترنت أو السيرفر ($e)"),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  void _processData(Map<String, dynamic> data) {
    if (!mounted) return;

    final List<dynamic> rawParticipants = data['participants'] ?? [];

    setState(() {
      _participants = rawParticipants.map((item) {
        return {
          'name': item['name'],
          'color': Colors.primaries[math.Random().nextInt(Colors.primaries.length)],
          'service': item['service'] ?? 'عام',
        };
      }).toList();

      _shouldSpin = data['should_spin'] ?? false;
      _winnerName = data['winner_name'];
      // بمجرد معالجة البيانات، نوقف التحميل
      _isLoading = false;
    });

    if (_shouldSpin && _winnerName != null && !_isResultShown) {
      _startAutoSpinToWinner();
    }
  }

  void _startAutoSpinToWinner() {
    _controller.stop();
    int winnerIndex = _participants.indexWhere((p) => p['name'] == _winnerName);
    if (winnerIndex == -1) winnerIndex = 0;

    final double segmentAngle = 2 * math.pi / _participants.length;
    double targetAngle = (winnerIndex * segmentAngle);
    double endValue = (5 * 2 * math.pi) - targetAngle;

    _spinAnimation = Tween<double>(begin: 0, end: endValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );

    _controller.duration = const Duration(seconds: 6);
    _controller.reset();
    _controller.forward().then((value) {
      _showElegantWinnerDialog();
    });
  }

  void _showElegantWinnerDialog() {
    setState(() => _isResultShown = true);
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Winner",
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: Curves.elasticOut.transform(anim1.value) as Animation<double>,
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20)],
                  border: Border.all(color: Colors.amber, width: 3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 70),
                    const SizedBox(height: 10),
                    const Text("🎉 الفائز اليوم هو 🎉", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 10),
                    Text(
                      _winnerName ?? "مبروك!",
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const Divider(color: Colors.white24, height: 30),
                    const Text("لاستلام جائزتك، تواصل معنا:", style: TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final Uri launchUri = Uri(scheme: 'tel', path: '07854076931');
                        if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text("07854076931", style: TextStyle(fontSize: 18, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4A00E0),
                        shape: const StadiumBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("إغلاق", style: TextStyle(color: Colors.white54)),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final drawTime = DateTime(now.year, now.month, now.day, 20, 0, 0);
      Duration difference = drawTime.difference(now);
      if (difference.isNegative) {
        difference = drawTime.add(const Duration(days: 1)).difference(now);
      }
      if(mounted) {
        setState(() {
          _timeUntilDraw = "${difference.inHours.toString().padLeft(2, '0')}:${(difference.inMinutes % 60).toString().padLeft(2, '0')}:${(difference.inSeconds % 60).toString().padLeft(2, '0')}";
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // التحقق: هل المستخدم جديد + لا يوجد كاش + فشل الاتصال؟
    bool showOfflineFirstRunError = !_isLoading && _participants.isEmpty && _isOffline;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Beytei Zone 💎", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isOffline ? Icons.cloud_off : Icons.refresh, color: Colors.white),
            onPressed: () => _fetchFromApi(),
          )
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
        ),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 5,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.shopping_cart, size: 28),
              SizedBox(width: 10),
              Text("اطلب الآن لتدخل سحب اليوم! 🚀", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),

      body: _isLoading && _participants.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : showOfflineFirstRunError
          ? _buildNoInternetView()
          : _buildMainContent(),
    );
  }

  Widget _buildNoInternetView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text(
              "تعذر الاتصال بالسيرفر",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            const Text(
              "تأكد من اتصالك بالإنترنت، أو قد تكون هناك مشكلة في السيرفر حالياً.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _fetchFromApi,
                icon: const Icon(Icons.refresh),
                label: const Text("إعادة المحاولة", style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: _fetchFromApi,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 380,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.indigo],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(50),
                      bottomRight: Radius.circular(50),
                    ),
                  ),
                ),
                Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_isOffline ? Icons.wifi_off : Icons.cloud_done, color: Colors.white70, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            _isOffline ? "وضع غير متصل (كاش)" : _lastUpdateText,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.stars, color: Colors.amber, size: 30),
                          SizedBox(width: 10),
                          Text("طلبات اليوم فقط", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _timeUntilDraw,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 35, fontWeight: FontWeight.w900,
                        letterSpacing: 3, fontFamily: 'Courier',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 300,
                      width: 300,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.amber, width: 5),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                            ),
                            child: AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                double val = (_shouldSpin && !_isResultShown)
                                    ? _spinAnimation.value
                                    : _controller.value * 2 * math.pi;
                                return Transform.rotate(
                                  angle: val,
                                  child: CustomPaint(
                                    size: const Size(280, 280),
                                    painter: WheelWithNamesPainter(
                                      names: _participants.isEmpty
                                          ? ['جاري', 'تحميل']
                                          : _participants.map((e) => e['name'] as String).toList(),
                                      colors: _participants.isEmpty
                                          ? [Colors.grey]
                                          : _participants.map((e) => e['color'] as Color).toList(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const Positioned(top: -10, child: Icon(Icons.arrow_drop_down, size: 60, color: Colors.white)),
                          Container(
                            width: 60, height: 60,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Center(child: Text("بيتي", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("مشاركو اليوم (${_participants.length}) 🔴", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("يتحدث تلقائياً", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            _participants.isEmpty
                ? Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  Icon(Icons.hourglass_empty, size: 50, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("لا توجد طلبات اليوم حتى الآن.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _participants.length,
              itemBuilder: (context, index) {
                final item = _participants[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item['color'].withOpacity(0.2),
                    child: Icon(Icons.person, color: item['color']),
                  ),
                  title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("طلب مكتمل - ${item['service']}"),
                  trailing: const Icon(Icons.verified, color: Colors.blue, size: 20),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class WheelWithNamesPainter extends CustomPainter {
  final List<String> names;
  final List<Color> colors;

  WheelWithNamesPainter({required this.names, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (names.isEmpty) return;

    final double segmentAngle = 2 * math.pi / names.length;

    for (int i = 0; i < names.length; i++) {
      final paint = Paint()..color = colors[i % colors.length]..style = PaintingStyle.fill;
      canvas.drawArc(rect, i * segmentAngle, segmentAngle, true, paint);
      _drawName(canvas, center, radius, i * segmentAngle, segmentAngle, names[i]);
    }
  }

  void _drawName(Canvas canvas, Offset center, double radius, double startAngle, double sweepAngle, String name) {
    final double angle = startAngle + (sweepAngle / 2);
    String displayName = name;
    if (names.length > 12 && name.length > 6) {
      displayName = "${name.substring(0, 5)}..";
    }

    final textSpan = TextSpan(
      text: displayName,
      style: TextStyle(
          color: Colors.white,
          fontSize: names.length > 20 ? 8 : 12,
          fontWeight: FontWeight.bold
      ),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.rtl);
    textPainter.layout();

    final double r = radius * 0.75;
    final double x = center.dx + r * math.cos(angle);
    final double y = center.dy + r * math.sin(angle);

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle + math.pi);
    canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}