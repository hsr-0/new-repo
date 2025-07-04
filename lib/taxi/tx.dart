import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تكسي بيتي ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: Colors.grey[50],
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// ===================================================================
//  WIDGET لإدارة حالة المصادقة (جديد بالكامل)
// ===================================================================

enum AppStatus { loading, unauthenticated, authenticated }

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _storage = const FlutterSecureStorage();
  AppStatus _status = AppStatus.loading;
  String? _userId;
  String? _displayName;
  String? _token;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final token = await _storage.read(key: 'auth_token');
    final userId = await _storage.read(key: 'user_id');
    final displayName = await _storage.read(key: 'display_name');

    if (token != null && userId != null && displayName != null) {
      setState(() {
        _token = token;
        _userId = userId;
        _displayName = displayName;
        _status = AppStatus.authenticated;
      });
    } else {
      setState(() {
        _status = AppStatus.unauthenticated;
      });
    }
  }

  Future<void> _login(String name, String phone) async {
    try {
      final response = await http.post(
        Uri.parse('https://banner.beytei.com/wp-json/taxi-auth/v1/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'phone_number': phone}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storage.write(key: 'auth_token', value: data['token']);
        await _storage.write(key: 'user_id', value: data['user_id'].toString());
        await _storage.write(key: 'display_name', value: data['display_name']);

        setState(() {
          _token = data['token'];
          _userId = data['user_id'].toString();
          _displayName = data['display_name'];
          _status = AppStatus.authenticated;
        });
      } else {
        throw Exception('فشل تسجيل الدخول: ${response.body}');
      }
    } catch (e) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ في تسجيل الدخول. يرجى مراجعة اتصالك بالانترنت او بياناتك.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _storage.deleteAll();
    setState(() {
      _token = null;
      _userId = null;
      _displayName = null;
      _status = AppStatus.unauthenticated;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case AppStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AppStatus.unauthenticated:
        return LoginScreen(onLogin: _login);
      case AppStatus.authenticated:
        return TripScreen(
          userId: _userId!,
          displayName: _displayName!,
          token: _token!,
          onLogout: _logout,
        );
    }
  }
}

// ===================================================================
// شاشة تسجيل الدخول (جديدة بالكامل)
// ===================================================================

class LoginScreen extends StatefulWidget {
  final Future<void> Function(String name, String phone) onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await widget.onLogin(_nameController.text, _phoneController.text);
      if(mounted){
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_taxi, size: 60, color: Colors.blue[700]),
                      const SizedBox(height: 16),
                      Text(
                        'مرحباً بك في تكسي بيتي ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'سجل الدخول للمتابعة',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'الاسم الكامل',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) =>
                        value!.isEmpty ? 'الرجاء إدخال الاسم' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'رقم الهاتف',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) =>
                        value!.isEmpty ? 'الرجاء إدخال رقم الهاتف' : null,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('تسجيل الدخول', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===================================================================
// شاشة الرحلات (تم تعديلها)
// ===================================================================

class TripScreen extends StatefulWidget {
  final String userId;
  final String displayName;
  final String token;
  final VoidCallback onLogout;

  const TripScreen({
    super.key,
    required this.userId,
    required this.displayName,
    required this.token,
    required this.onLogout,
  });

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> trips = [];
  bool isLoading = true;
  String error = '';
  bool isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadTrips();
    }
  }

  Future<void> _loadTrips() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://banner.beytei.com/wp-json/taxi/v1/trips'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        if (decodedData is List) {
          setState(() {
            trips = decodedData.map((item) => Map<String, dynamic>.from(item as Map)).toList();
            isLoading = false;
            isFirstLoad = false;
          });
        } else {
          throw Exception('تنسيق البيانات غير صحيح.');
        }
      } else {
        throw Exception('فشل تحميل الرحلات: ${response.statusCode}');
      }
    } on SocketException {
      setState(() {
        error = 'فشل الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت.';
        isLoading = false;
        isFirstLoad = false;
      });
    } catch (e) {
      setState(() {
        error = 'حدث خطأ غير متوقع أثناء تحميل البيانات.';
        isLoading = false;
        isFirstLoad = false;
      });
    }
  }

  Future<void> _bookTrip({
    required String tripId,
    required String name,
    required String phone,
    required String address,
    required int quantity,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://banner.beytei.com/wp-json/taxi/v1/book'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({
          'trip_id': tripId,
          'name': name,
          'phone': phone,
          'address': address,
          'quantity': quantity,
        }),
      );

      final dynamic result = json.decode(response.body);
      if (response.statusCode == 200 && result['success'] == true) {
        _updateTripLocally(Map<String, dynamic>.from(result['trip']));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم الحجز بنجاح لـ $quantity مقاعد!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'فشل الحجز لسبب غير معروف.');
      }
    }  catch (e) {
      // هذا التعديل سيعرض لنا رسالة الخطأ الكاملة من الخادم
      String errorMessage = e.toString();
      // نحاول استخراج رسالة الخطأ من جسم الرد إذا كانت موجودة
      if (e is http.ClientException && e.message.contains('response')) {
        try {
          final errorBody = e.message.substring(e.message.indexOf('{'));
          final errorJson = json.decode(errorBody);
          errorMessage = errorJson['message'] ?? errorMessage;
        } catch (_) {
          // تجاهل الخطأ إذا لم يكن JSON
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحجز: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelBooking(String tripId, String passengerId) async {
    try {
      final response = await http.post(
        Uri.parse('https://banner.beytei.com/wp-json/taxi/v1/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({
          'trip_id': tripId,
          'passenger_id': passengerId,
        }),
      );

      final dynamic result = json.decode(response.body);
      if (response.statusCode == 200 && result['success'] == true) {
        _updateTripLocally(Map<String, dynamic>.from(result['trip']));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إلغاء الحجز بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'فشل إلغاء الحجز لسبب غير معروف.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الإلغاء: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
        _loadTrips();
      }
    }
  }

  void _updateTripLocally(Map<String, dynamic> updatedTrip) {
    setState(() {
      final index = trips.indexWhere((t) => t['id'].toString() == updatedTrip['id'].toString());
      if (index != -1) {
        final passengers = updatedTrip['passengers'] is List ? List<Map<String, dynamic>>.from(updatedTrip['passengers']) : <Map<String, dynamic>>[];
        final totalSeats = int.tryParse(updatedTrip['total_seats'].toString()) ?? 0;
        updatedTrip['available_seats'] = totalSeats - passengers.length;
        trips[index] = updatedTrip;
      }
    });
  }

  String _formatDate(String dateString) {
    try {
      return DateFormat('yyyy/MM/dd', 'en_US').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  int _getUserBookedSeatsCount(Map<String, dynamic> trip) {
    if (trip['passengers'] is! List) return 0;
    final passengers = List<Map<String, dynamic>>.from(trip['passengers']);
    return passengers.where((p) => p['user_id']?.toString() == widget.userId).length;
  }

  void _showBookingDialog(Map<String, dynamic> trip) {
    final nameController = TextEditingController(text: widget.displayName);
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final availableSeats = (trip['available_seats'] ?? 0) as int;
    int selectedQuantity = availableSeats > 0 ? 1 : 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('حجز مقعد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 16),
                      Text('${trip['from']} → ${trip['to']}', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      Text('${_formatDate(trip['date'].toString())} - ${trip['time']}', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person))),
                      const SizedBox(height: 12),
                      TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      TextField(controller: addressController, decoration: const InputDecoration(labelText: 'عنوان الاستلام', prefixIcon: Icon(Icons.location_on))),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('عدد المقاعد:'),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: selectedQuantity > 1 ? () => setStateSB(() => selectedQuantity--) : null,
                          ),
                          Text('$selectedQuantity'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: selectedQuantity < availableSeats ? () => setStateSB(() => selectedQuantity++) : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                          ElevatedButton(
                            onPressed: (selectedQuantity > 0 && nameController.text.isNotEmpty && phoneController.text.isNotEmpty && addressController.text.isNotEmpty)
                                ? () async {
                              Navigator.pop(ctx);
                              await _bookTrip(tripId: trip['id'].toString(), name: nameController.text, phone: phoneController.text, address: addressController.text, quantity: selectedQuantity);
                            }
                                : null,
                            child: const Text('تأكيد الحجز'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPassengersScreen(Map<String, dynamic> trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PassengersScreen(
          trip: trip,
          currentUserId: widget.userId,
          onCancelBooking: (passengerId) async {
            await _cancelBooking(trip['id'].toString(), passengerId);
          },
        ),
      ),
    ).then((_) => _loadTrips());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مرحباً، ${widget.displayName}'),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTrips, tooltip: 'تحديث'),
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout, tooltip: 'تسجيل الخروج'),
        ],
      ),
      body: isLoading && isFirstLoad
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(child: Text(error, style: const TextStyle(color: Colors.red)))
          : trips.isEmpty
          ? const Center(child: Text('لا توجد رحلات متاحة حالياً'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          final totalSeats = int.tryParse(trip['total_seats'].toString()) ?? 0;
          final passengers = (trip['passengers'] as List?) ?? [];
          final bookedSeatsCount = passengers.length;
          trip['available_seats'] = totalSeats - bookedSeatsCount;
          final availableSeats = trip['available_seats'] as int;
          final driver = (trip['driver'] as Map?) ?? {};
          final userBookedSeats = _getUserBookedSeatsCount(trip);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blue, width: 2)),
                      child: ClipOval(child: driver['image'] != null && driver['image'].toString().isNotEmpty
                          ? Image.network(driver['image'].toString(), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 30))
                          : const Icon(Icons.person, size: 30)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(driver['name']?.toString() ?? 'غير معروف', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${driver['car_model'] ?? ''} - ${driver['car_color'] ?? ''}', style: const TextStyle(color: Colors.grey)),
                    ])),
                  ]),
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child: Text(trip['from'].toString(), style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      const Icon(Icons.arrow_forward, color: Colors.blue),
                      Expanded(child: Text(trip['to'].toString(), style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    _buildInfoItem(Icons.calendar_today, _formatDate(trip['date'].toString()), Colors.blue),
                    _buildInfoItem(Icons.access_time, trip['time'].toString(), Colors.orange),
                    _buildInfoItem(Icons.event_seat, '$bookedSeatsCount/$totalSeats', availableSeats > 0 ? Colors.green : Colors.red),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(
                        icon: const Icon(Icons.people, size: 18),
                        label: Text('عرض الركاب (${passengers.length})'),
                        onPressed: passengers.isNotEmpty ? () => _showPassengersScreen(trip) : null)),
                    const SizedBox(width: 12),
                    Expanded(child: userBookedSeats > 0
                        ? ElevatedButton.icon(
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: Text('إلغاء ($userBookedSeats)'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => _showPassengersScreen(trip))
                        : ElevatedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                        label: const Text('حجز مقعد'),
                        style: ElevatedButton.styleFrom(backgroundColor: availableSeats > 0 ? Colors.blue : Colors.grey),
                        onPressed: availableSeats > 0 ? () => _showBookingDialog(trip) : null)),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// ===================================================================
// 4. شاشة الركاب (PassengersScreen)
// ===================================================================

class PassengersScreen extends StatelessWidget {
  final Map<String, dynamic> trip;
  final String currentUserId;
  final Future<void> Function(String) onCancelBooking;

  const PassengersScreen({
    super.key,
    required this.trip,
    required this.currentUserId,
    required this.onCancelBooking,
  });

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy/MM/dd', 'en_US').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final passengers = (trip['passengers'] as List?)?.map((p) => Map<String, dynamic>.from(p)).toList() ?? [];
    final totalSeats = int.tryParse(trip['total_seats'].toString()) ?? 0;
    final availableSeats = totalSeats - passengers.length;

    final currentUserBookings = passengers.where((p) => p['user_id']?.toString() == currentUserId).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('قائمة الركاب'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
              Text('${trip['from']} → ${trip['to']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('${_formatDate(trip['date'].toString())} - ${trip['time']}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Text('المقاعد: ${passengers.length}/$totalSeats (المتبقي: $availableSeats)', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]))),
            const SizedBox(height: 16),
            const Text('حجوزاتي لهذه الرحلة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            currentUserBookings.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('لم تقم بأي حجز في هذه الرحلة.', style: TextStyle(color: Colors.grey))))
                : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentUserBookings.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final passenger = currentUserBookings[index];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.2), child: Text('${index + 1}')),
                  title: Text(passenger['name']?.toString() ?? 'غير معروف'),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('الهاتف: ${passenger['phone']?.toString() ?? ''}'),
                    if (passenger['address'] != null) Text('العنوان: ${passenger['address'].toString()}', style: const TextStyle(fontSize: 12)),
                    Text('معرف الحجز: ${passenger['id']?.toString() ?? ''}', style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                  ]),
                  trailing: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('تأكيد الإلغاء'),
                        content: const Text('هل أنت متأكد من إلغاء هذا المقعد؟'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('لا')),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              await onCancelBooking(passenger['id'].toString());
                              Navigator.pop(context);
                            },
                            child: const Text('نعم، إلغاء'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text('جميع الركاب المسجلين في الرحلة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            passengers.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('لا يوجد ركاب مسجلين بعد', style: TextStyle(color: Colors.grey))))
                : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: passengers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final passenger = passengers[index];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.grey.withOpacity(0.2), child: Text('${index + 1}')),
                  title: Text(passenger['name']?.toString() ?? 'غير معروف'),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('الهاتف: ${passenger['phone']?.toString() ?? ''}'),
                    if (passenger['address'] != null) Text('العنوان: ${passenger['address'].toString()}', style: const TextStyle(fontSize: 12)),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}