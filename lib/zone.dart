import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BeyteiZoneScreen extends StatefulWidget {
  const BeyteiZoneScreen({Key? key}) : super(key: key);

  @override
  State<BeyteiZoneScreen> createState() => _BeyteiZoneScreenState();
}

class _BeyteiZoneScreenState extends State<BeyteiZoneScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _spinAnimation; // الأنيميشن الرئيسي

  // --- المتغيرات الرئيسية ---
  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>> _weeklyParticipants = [];

  bool _shouldSpin = false;
  String? _currentWinnerName;
  String? _previousWinnerName;

  bool _isResultShown = false;
  bool _isLoading = true;
  bool _isOffline = false;
  String _lastUpdateText = "";

  // --- المؤقت ---
  String _timeUntilDraw = "00:00:00";
  String _drawInfoText = "السحب الأسبوعي يوم الجمعة 8 مساءً";
  Timer? _timer;
  bool _isWeeklyDrawTime = false;

  // 🔗 رابط السيرفر
  final String _apiUrl = 'https://re.beytei.com/wp-json/restaurant-app/v1/zone-status';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    // ✅ إصلاح الكراش: تهيئة أولية للأنيميشن بقيمة صفر حتى لا تكون null عند البناء
    _spinAnimation = Tween<double>(begin: 0, end: 0).animate(_controller);

    // تشغيل دوران بطيء (Idle) في البداية
    _controller.repeat();

    _startCountdown();
    _loadDataWithCacheStrategy();
  }

  // --- إدارة البيانات والكاش ---
  Future<void> _loadDataWithCacheStrategy() async {
    await _loadFromCache();
    await _fetchFromApi();
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString('beytei_zone_data');

    if (cachedData != null) {
      try {
        final Map<String, dynamic> data = json.decode(cachedData);
        _processData(data);
      } catch (e) {
        print("Error parsing cache: $e");
      }
    }
  }

  Future<void> _fetchFromApi() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // ✅ إصلاح النصوص العربية: استخدام utf8.decode
        final data = json.decode(utf8.decode(response.bodyBytes));
        _processData(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('beytei_zone_data', response.body); // حفظ الخام

        final now = DateTime.now();
        final timeString = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

        if (mounted) {
          setState(() {
            _lastUpdateText = "تم التحديث: $timeString";
            _isOffline = false;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Error: $e");
      if (mounted) {
        setState(() {
          _isOffline = true;
          _isLoading = false;
        });
      }
    }
  }

  void _processData(Map<String, dynamic> data) {
    if (!mounted) return;

    final List<dynamic> rawParticipants = data['participants'] ?? [];
    final List<dynamic> rawWeeklyParticipants = data['weekly_participants'] ?? [];

    setState(() {
      _participants = rawParticipants.map((item) {
        return {
          'name': item['name'],
          'color': Colors.primaries[math.Random().nextInt(Colors.primaries.length)],
          'service': item['service'] ?? 'عام',
        };
      }).toList();

      _weeklyParticipants = rawWeeklyParticipants.map((item) {
        return {
          'name': item['name'],
          'color': Colors.primaries[math.Random().nextInt(Colors.primaries.length)],
        };
      }).toList();

      _shouldSpin = data['should_spin'] ?? false;
      _currentWinnerName = data['winner_name'];
      _previousWinnerName = data['previous_winner'];

      _isLoading = false;
    });

    if (_shouldSpin && _currentWinnerName != null && !_isResultShown) {
      _startAutoSpinToWinner();
    }
  }

  // --- منطق الدوران والسحب (المعدل) ---
  void _startAutoSpinToWinner() {
    _controller.stop(); // إيقاف الدوران اللانهائي

    int winnerIndex = _weeklyParticipants.indexWhere((p) => p['name'] == _currentWinnerName);
    if (winnerIndex == -1) winnerIndex = 0;

    final int itemCount = _weeklyParticipants.length;
    final double segmentAngle = 2 * math.pi / itemCount;

    // ✅ إصلاح الرياضيات لتوقف العجلة عند السهم العلوي بدقة
    // 1. حساب زاوية مركز قطعة الفائز
    double winnerCenterAngle = (winnerIndex * segmentAngle) + (segmentAngle / 2);

    // 2. تعويض مكان السهم (السهم في الأعلى عند زاوية -pi/2 أو 270 درجة)
    // نحتاج تدوير العجلة بحيث تصبح زاوية الفائز في الأعلى
    double offsetToTop = math.pi / 2;

    // 3. عدد اللفات (5 لفات) + المسافة المتبقية للوصول
    double endValue = (5 * 2 * math.pi) - winnerCenterAngle - offsetToTop;

    _spinAnimation = Tween<double>(begin: 0, end: endValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic), // تباطؤ سلس
    );

    _controller.duration = const Duration(seconds: 8);
    _controller.reset();
    _controller.forward().then((value) {
      if (mounted) _showWinnerDialog();
    });
  }
  void _showWinnerDialog() {
    setState(() => _isResultShown = true);

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Winner",
      transitionDuration: const Duration(milliseconds: 800), // زيادة الوقت قليلاً لجمالية الـ Elastic
      pageBuilder: (ctx, anim1, anim2) {
        return Container(); // صفحة فارغة لأننا نعتمد على transitionBuilder
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        // ✅ التصحيح هنا: استخدام CurvedAnimation بدلاً من التحويل اليدوي
        final curvedValue = CurvedAnimation(parent: anim1, curve: Curves.elasticOut);

        return ScaleTransition(
          scale: curvedValue,
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero, // إزالة الحواف الافتراضية
              content: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber, width: 4),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 5)
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // تأثير لمعان بسيط (اختياري)
                    const Icon(Icons.celebration, color: Colors.amber, size: 70),
                    const SizedBox(height: 15),
                    const Text(
                      "🎉 مبروووك للفائز 🎉",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo', // تأكد من دعم الخط
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _currentWinnerName ?? "...",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // إغلاق النافذة وإعادة تعيين الحالة إذا رغبت
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text("موافق", style: TextStyle(fontWeight: FontWeight.bold)),
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
      int daysUntilFriday = (DateTime.friday - now.weekday) % 7;
      if (daysUntilFriday == 0 && now.hour >= 20) {
        daysUntilFriday = 7;
      }
      final nextFridayDraw = DateTime(
          now.year, now.month, now.day + daysUntilFriday, 20, 0, 0
      );
      Duration diff = nextFridayDraw.difference(now);

      if (mounted) {
        setState(() {
          _timeUntilDraw = "${diff.inDays}يوم  ${(diff.inHours % 24).toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}";

          if (diff.inDays == 0 && diff.inHours < 12) {
            _drawInfoText = "🔥 السحب اليوم الساعة 8 مساءً 🔥";
            _isWeeklyDrawTime = true;
          } else {
            _drawInfoText = "السحب القادم يوم الجمعة";
            _isWeeklyDrawTime = false;
          }
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("سحب بيتي الأسبوعي 💎", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF4A00E0),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isOffline ? Icons.cloud_off : Icons.refresh),
            onPressed: _fetchFromApi,
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
              Text("اطلب الآن لتدخل سحب الجمعة! 🚀", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchFromApi,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 520,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                  ),

                  Column(
                    children: [
                      const SizedBox(height: 10),

                      if (_previousWinnerName != null && _previousWinnerName!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFFFD700)]),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                              ),
                              const SizedBox(width: 15),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("بطل الأسبوع الماضي", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text(_previousWinnerName!, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.star, color: Colors.white54, size: 40),
                            ],
                          ),
                        ),

                      const SizedBox(height: 10),

                      Text(_drawInfoText, style: const TextStyle(color: Colors.white70)),
                      Text(
                        _timeUntilDraw,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold,
                            fontFamily: 'Courier', letterSpacing: 2
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
                                border: Border.all(
                                    color: _isWeeklyDrawTime ? Colors.redAccent : Colors.amber,
                                    width: 6
                                ),
                                boxShadow: [const BoxShadow(color: Colors.black45, blurRadius: 20)],
                              ),
                              child: AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  // نستخدم قيمة الأنيميشن المخصص عند السحب، وإلا الدوران العادي
                                  double val = (_shouldSpin && !_isResultShown)
                                      ? _spinAnimation.value
                                      : _controller.value * 2 * math.pi;
                                  return Transform.rotate(
                                    angle: val,
                                    child: CustomPaint(
                                      size: const Size(280, 280),
                                      painter: WheelPainter(
                                        names: _weeklyParticipants.isEmpty
                                            ? ["انتظار", "الطلبات", "الأسبوعية"]
                                            : _weeklyParticipants.map((e) => e['name'] as String).toList(),
                                        colors: _weeklyParticipants.isEmpty
                                            ? [Colors.grey, Colors.grey.shade400, Colors.grey]
                                            : _weeklyParticipants.map((e) => e['color'] as Color).toList(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // السهم في الأعلى
                            const Positioned(top: -15, child: Icon(Icons.arrow_drop_down, size: 70, color: Colors.white)),
                            Container(
                              width: 60, height: 60,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Center(
                                child: Text(
                                    "بيتي",
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 16)
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("فرص الفوز هذا الأسبوع (${_weeklyParticipants.length})",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(10)),
                      child: Text("كل طلب = فرصة إضافية", style: TextStyle(color: Colors.green[800], fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const Divider(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: const [
                    Icon(Icons.today, color: Colors.deepPurple, size: 20),
                    SizedBox(width: 5),
                    Text("طلبات اليوم المضافة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),

              _participants.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: Text("لا توجد طلبات مسجلة اليوم حتى الآن", style: TextStyle(color: Colors.grey))),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _participants.length,
                itemBuilder: (context, index) {
                  final item = _participants[index];
                  return ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item['service']),
                    trailing: const Text("تم الدخول بالسحب", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  );
                },
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

// 🎨 الرسام الخاص بالعجلة (معدل لقص الاسم بشكل صحيح)
class WheelPainter extends CustomPainter {
  final List<String> names;
  final List<Color> colors;

  WheelPainter({required this.names, required this.colors});

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

      final borderPaint = Paint()..color = Colors.white.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1;
      canvas.drawArc(rect, i * segmentAngle, segmentAngle, true, borderPaint);

      _drawName(canvas, center, radius, i * segmentAngle, segmentAngle, names[i]);
    }
  }

  void _drawName(Canvas canvas, Offset center, double radius, double startAngle, double sweepAngle, String name) {
    final double angle = startAngle + (sweepAngle / 2);

    // ✅ تعديل: السماح بظهور 10 أحرف ثم وضع نقاط
    String displayName = name.length > 10 ? "${name.substring(0, 10)}..." : name;

    final textSpan = TextSpan(
      text: displayName,
      style: TextStyle(color: Colors.white, fontSize: names.length > 15 ? 9 : 12, fontWeight: FontWeight.bold),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.rtl)..layout();

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
