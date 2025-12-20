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

  // --- المتغيرات الرئيسية ---
  List<Map<String, dynamic>> _participants = []; // طلبات اليوم
  List<Map<String, dynamic>> _weeklyParticipants = []; // جميع طلبات الأسبوع (للعجلة)

  bool _shouldSpin = false;         // هل يجب أن تدور العجلة الآن؟
  String? _currentWinnerName;       // الفائز الذي يتم السحب عليه الآن
  String? _previousWinnerName;      // الفائز السابق (يظل ظاهر طوال الأسبوع)

  bool _isResultShown = false;
  bool _isLoading = true;
  bool _isOffline = false;
  String _lastUpdateText = "";

  // --- المؤقت ---
  String _timeUntilDraw = "00:00:00";
  String _drawInfoText = "السحب الأسبوعي يوم الجمعة 8 مساءً";
  Timer? _timer;
  bool _isWeeklyDrawTime = false; // هل نحن في وقت السحب (الجمعة مساءً)؟

  // 🔗 رابط السيرفر
  final String _apiUrl = 'https://re.beytei.com/wp-json/restaurant-app/v1/zone-status';

  @override
  void initState() {
    super.initState();

    // إعداد حركة الدوران المستمر (Idle Animation)
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

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
      // إرسال طلب للسيرفر
      final response = await http.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _processData(data);

        // حفظ الكاش
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('beytei_zone_data', response.body);

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

  // --- معالجة البيانات القادمة من السيرفر ---
  void _processData(Map<String, dynamic> data) {
    if (!mounted) return;

    final List<dynamic> rawParticipants = data['participants'] ?? [];
    final List<dynamic> rawWeeklyParticipants = data['weekly_participants'] ?? [];

    setState(() {
      // 1. قائمة اليوم
      _participants = rawParticipants.map((item) {
        return {
          'name': item['name'],
          'color': Colors.primaries[math.Random().nextInt(Colors.primaries.length)],
          'service': item['service'] ?? 'عام',
        };
      }).toList();

      // 2. القائمة الأسبوعية (المهمة للعجلة)
      _weeklyParticipants = rawWeeklyParticipants.map((item) {
        return {
          'name': item['name'],
          'color': Colors.primaries[math.Random().nextInt(Colors.primaries.length)],
        };
      }).toList();

      // 3. بيانات الفائزين
      _shouldSpin = data['should_spin'] ?? false;
      _currentWinnerName = data['winner_name']; // الفائز الجديد (لحظة السحب)
      _previousWinnerName = data['previous_winner']; // الفائز القديم (يظهر طوال الأسبوع)

      _isLoading = false;
    });

    // إذا أمر السيرفر بالدوران، وكان لدينا اسم فائز، ولم نعرض النتيجة بعد
    if (_shouldSpin && _currentWinnerName != null && !_isResultShown) {
      _startAutoSpinToWinner();
    }
  }

  // --- منطق الدوران والسحب ---
  void _startAutoSpinToWinner() {
    _controller.stop();

    // البحث عن الفائز داخل القائمة الأسبوعية
    int winnerIndex = _weeklyParticipants.indexWhere((p) => p['name'] == _currentWinnerName);

    // إذا لم نجده (احتياطاً)، نجعله في المؤشر 0
    if (winnerIndex == -1) winnerIndex = 0;

    final double segmentAngle = 2 * math.pi / _weeklyParticipants.length;
    double targetAngle = (winnerIndex * segmentAngle);

    // معادلة التوقف عند الزاوية الصحيحة
    double endValue = (5 * 2 * math.pi) - targetAngle;

    _spinAnimation = Tween<double>(begin: 0, end: endValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );

    _controller.duration = const Duration(seconds: 8); // مدة الدوران
    _controller.reset();
    _controller.forward().then((value) {
      _showWinnerDialog(); // عرض رسالة الفوز عند التوقف
    });
  }

  void _showWinnerDialog() {
    setState(() => _isResultShown = true);

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Winner",
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (ctx, anim1, anim2) {
        return ScaleTransition(
          scale: Curves.elasticOut.transform(anim1.value) as Animation<double>,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            content: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber, width: 4),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.celebration, color: Colors.amber, size: 60),
                  const SizedBox(height: 10),
                  const Text("🎉 مبروووك للفائز 🎉", style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 10),
                  Text(
                    _currentWinnerName ?? "...",
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),

                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- مؤقت يوم الجمعة ---
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();

      // حساب الأيام المتبقية للجمعة
      int daysUntilFriday = (DateTime.friday - now.weekday) % 7;

      // إذا كان اليوم هو الجمعة ولكن تجاوزنا الساعة 8 مساءً، نحسب للجمعة القادمة
      if (daysUntilFriday == 0 && now.hour >= 20) {
        daysUntilFriday = 7;
      }

      final nextFridayDraw = DateTime(
          now.year, now.month, now.day + daysUntilFriday, 20, 0, 0 // الساعة 20:00 أي 8 مساءً
      );

      Duration diff = nextFridayDraw.difference(now);

      if (mounted) {
        setState(() {
          _timeUntilDraw = "${diff.inDays}يوم  ${(diff.inHours % 24).toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}";

          // تحديد حالة النص
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
      body: RefreshIndicator(
        onRefresh: _fetchFromApi,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // --- القسم العلوي (الخلفية + العجلة) ---
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // الخلفية المتدرجة
                  Container(
                    height: 500,
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

                      // 🏆 بطاقة الفائز السابق (ثابتة طوال الأسبوع) 🏆
                      if (_previousWinnerName != null && _previousWinnerName!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFFFD700)]), // ذهبي
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
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

                      // العداد
                      Text(_drawInfoText, style: const TextStyle(color: Colors.white70)),
                      Text(
                        _timeUntilDraw,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold,
                            fontFamily: 'Courier', letterSpacing: 2
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🎡 العجلة الدوارة 🎡
                      SizedBox(
                        height: 300,
                        width: 300,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // إطار العجلة
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _isWeeklyDrawTime ? Colors.redAccent : Colors.amber,
                                    width: 6
                                ),
                                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20)],
                              ),
                              // الرسم الفعلي للعجلة
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
                                      painter: WheelPainter(
                                        // نمرر القائمة الأسبوعية للعجلة
                                        names: _weeklyParticipants.isEmpty
                                            ? ["انتظار", "الطلبات"]
                                            : _weeklyParticipants.map((e) => e['name'] as String).toList(),
                                        colors: _weeklyParticipants.isEmpty
                                            ? [Colors.grey, Colors.grey]
                                            : _weeklyParticipants.map((e) => e['color'] as Color).toList(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // المؤشر (السهم)
                            const Positioned(top: -15, child: Icon(Icons.arrow_drop_down, size: 70, color: Colors.white)),
                            // مركز العجلة
                            Container(
                              width: 60, height: 60,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Center(
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

              // --- قسم الإحصائيات والقوائم ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("المشاركون هذا الأسبوع (${_weeklyParticipants.length})",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              _weeklyParticipants.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(30),
                child: Text("لا توجد طلبات هذا الأسبوع حتى الآن.. كن الأول!", style: TextStyle(color: Colors.grey)),
              )
                  : Container(
                height: 100, // شريط أفقي للمشاركين في العجلة
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _weeklyParticipants.length,
                  itemBuilder: (context, index) {
                    final p = _weeklyParticipants[index];
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: p['color'].withOpacity(0.2),
                            child: Text(p['name'].substring(0,1), style: TextStyle(fontSize: 12, color: p['color'])),
                          ),
                          const SizedBox(height: 5),
                          Text(p['name'],
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const Divider(),

              // قائمة طلبات اليوم فقط (للتأكيد للمستخدم أن طلبه وصل)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: const [
                    Icon(Icons.today, color: Colors.deepPurple, size: 20),
                    SizedBox(width: 5),
                    Text("طلبات اليوم المضافة", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _participants.length,
                itemBuilder: (context, index) {
                  final item = _participants[index];
                  return ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item['service']),
                    trailing: const Text("تم التسجيل", style: TextStyle(color: Colors.grey, fontSize: 12)),
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

// 🎨 الرسام الخاص بالعجلة
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

      // رسم خطوط فاصلة
      final borderPaint = Paint()..color = Colors.white.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1;
      canvas.drawArc(rect, i * segmentAngle, segmentAngle, true, borderPaint);

      _drawName(canvas, center, radius, i * segmentAngle, segmentAngle, names[i]);
    }
  }

  void _drawName(Canvas canvas, Offset center, double radius, double startAngle, double sweepAngle, String name) {
    final double angle = startAngle + (sweepAngle / 2);
    // اختصار الاسم الطويل
    String displayName = name.length > 8 ? "${name.substring(0, 6)}.." : name;

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