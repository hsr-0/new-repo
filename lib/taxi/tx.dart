import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام حجز الرحلات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Cairo', // تأكد من أن هذا الخط متاح في مشروعك
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        useMaterial3: true,
      ),
      home: const TripScreen(),
    );
  }
}

class TripScreen extends StatefulWidget {
  const TripScreen({super.key});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  List<Map<String, dynamic>> trips = [];
  bool isLoading = true;
  String error = '';
  String? currentUserId;
  bool isFirstLoad = true;

  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _initializeUserId();
    _loadTrips();
  }

  // تهيئة أو تحميل معرف المستخدم الفريد للجهاز
  Future<void> _initializeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString('user_id');

    if (storedUserId == null) {
      String newUserId = _uuid.v4();
      await prefs.setString('user_id', newUserId);
      setState(() {
        currentUserId = newUserId;
      });
      print('DEBUG: New User ID generated and saved: $newUserId');
    } else {
      setState(() {
        currentUserId = storedUserId;
      });
      print('DEBUG: Existing User ID loaded: $storedUserId');
    }
  }

  // تحميل بيانات الرحلات من الـ API
  Future<void> _loadTrips() async {
    print('DEBUG: Starting _loadTrips to refresh data.');
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://banner.beytei.com/wp-json/taxi/v1/trips'),
        headers: {'Content-Type': 'application/json'},
      );

      print('DEBUG: _loadTrips response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        if (decodedData is List) {
          setState(() {
            // تحويل كل عنصر في القائمة إلى Map<String, dynamic> بشكل صريح
            trips = decodedData
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList();
            trips = _processTripData(trips); // معالجة البيانات لحساب المقاعد المتاحة
            isLoading = false;
            isFirstLoad = false;
            print('DEBUG: Trips loaded successfully. Count: ${trips.length}');
          });
        } else {
          throw Exception('Expected a list of trips, but got a different type.');
        }
      } else {
        throw Exception('Failed to load trips: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error loading trips: ${e.toString()}');
      setState(() {
        error = 'Error loading trips: ${e.toString()}';
        isLoading = false;
        isFirstLoad = false;
      });
    }
  }

  // معالجة بيانات الرحلة (لحساب المقاعد المتاحة إذا لم تكن محسوبة من الخادم)
  List<Map<String, dynamic>> _processTripData(
      List<Map<String, dynamic>> tripsData) {
    return tripsData.map((trip) {
      final passengers = trip['passengers'] is List
          ? List<Map<String, dynamic>>.from(trip['passengers'] as List)
          : <Map<String, dynamic>>[];
      final totalSeats = trip['total_seats'] is int
          ? trip['total_seats'] as int
          : int.tryParse(trip['total_seats'].toString()) ?? 0;

      final actualAvailableSeats = totalSeats - passengers.length;

      return {
        ...trip,
        'passengers': passengers,
        'available_seats': actualAvailableSeats, // ضمان أنها محسوبة بشكل صحيح
      };
    }).toList();
  }

  // دالة لحجز الرحلة
  Future<void> _bookTrip({
    required String tripId,
    required String name,
    required String phone,
    required String address,
    required int quantity, // عدد المقاعد المطلوب حجزها
  }) async {
    // تحقق من أن معرف المستخدم موجود
    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ: لم يتم تهيئة معرف المستخدم بعد. يرجى إعادة تشغيل التطبيق.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      print('DEBUG: Sending booking request for trip ID: $tripId, Quantity: $quantity');
      final response = await http.post(
        Uri.parse('https://banner.beytei.com/wp-json/taxi/v1/book'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trip_id': tripId,
          'name': name,
          'phone': phone,
          'address': address,
          'user_id': currentUserId, // معرف المستخدم الذي تم إنشاؤه تلقائيًا
          'quantity': quantity, // إرسال عدد المقاعد
        }),
      );

      print('DEBUG: Booking response status: ${response.statusCode}');
      final dynamic result = json.decode(response.body);
      print('DEBUG: Booking response body: $result');

      if (response.statusCode == 200 &&
          result is Map &&
          result['success'] == true) {
        if (result['trip'] is Map) {
          _updateTripLocally(Map<String, dynamic>.from(result['trip'] as Map));
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم الحجز بنجاح لـ $quantity مقاعد!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // إذا كان هناك رسالة خطأ من الـ API، اعرضها
        final errorMessage = result is Map && result.containsKey('message')
            ? result['message']
            : 'فشل الحجز لسبب غير معروف.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Error during booking: ${e.toString()}'); // طباعة الخطأ في الكونسول
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحجز: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // دالة لإلغاء الحجز لمقعد واحد
  Future<void> _cancelBooking(String tripId, String passengerId) async {
    try {
      print('DEBUG: Sending cancellation request for trip ID: $tripId, Passenger ID: $passengerId');
      final response = await http.post(
        Uri.parse('https://banner.beytei.com/wp-json/taxi/v1/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trip_id': tripId,
          'passenger_id': passengerId,
          'user_id': currentUserId, // تأكد من إرسال معرف المستخدم
        }),
      );

      print('DEBUG: Cancellation response status: ${response.statusCode}');
      final dynamic result = json.decode(response.body);
      print('DEBUG: Cancellation response body: $result');

      if (response.statusCode == 200 &&
          result is Map &&
          result['success'] == true) {
        if (result['trip'] is Map) {
          _updateTripLocally(Map<String, dynamic>.from(result['trip'] as Map));
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إلغاء الحجز بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final errorMessage = result is Map && result.containsKey('message')
            ? result['message']
            : 'فشل إلغاء الحجز لسبب غير معروف.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Error during cancellation: ${e.toString()}'); // طباعة الخطأ في الكونسول
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إلغاء الحجز: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        _loadTrips(); // إعادة تحميل البيانات لضمان المزامنة
      }
    }
  }

  // تحديث بيانات الرحلة محليًا بعد الحجز أو الإلغاء
  // هذا هو المكان الذي كان فيه الخطأ في الصورة: _processSingleTripData لم تكن معرفة
  void _updateTripLocally(Map<String, dynamic> updatedTrip) {
    print('DEBUG: Attempting to update trip locally for ID: ${updatedTrip['id']}');
    setState(() {
      final index =
      trips.indexWhere((t) => t['id'].toString() == updatedTrip['id'].toString());
      if (index != -1) {
        trips[index] = _processSingleTripData(updatedTrip); // استخدام الدالة هنا
        print('DEBUG: Trip ID ${updatedTrip['id']} updated locally.');
      } else {
        print('DEBUG: Trip ID ${updatedTrip['id']} not found in local list. Reloading all trips.');
        // إذا لم يتم العثور على الرحلة، قم بتحميل جميع الرحلات مجددًا لضمان التناسق
        _loadTrips();
      }
    });
  }

  // دالة لمعالجة بيانات رحلة واحدة
  Map<String, dynamic> _processSingleTripData(Map<String, dynamic> trip) {
    final passengers = trip['passengers'] is List
        ? List<Map<String, dynamic>>.from(trip['passengers'] as List)
        : <Map<String, dynamic>>[];
    final totalSeats = trip['total_seats'] is int
        ? trip['total_seats'] as int
        : int.tryParse(trip['total_seats'].toString()) ?? 0;

    return {
      ...trip,
      'passengers': passengers,
      'available_seats': totalSeats - passengers.length,
    };
  }

  // عرض مربع حوار الحجز
  void _showBookingDialog(Map<String, dynamic> trip) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    // تأكد أن القيمة الافتراضية للكمية هي 1 إذا كانت المقاعد المتاحة أكبر من 0، وإلا 0
    int initialQuantity = (trip['available_seats'] as int) > 0 ? 1 : 0;
    int selectedQuantity = initialQuantity;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            final int maxAvailableSeats = trip['available_seats'] as int;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'حجز مقعد',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${trip['from']} → ${trip['to']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${_formatDate(trip['date'].toString())} - ${trip['time']}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'الاسم الكامل',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: 'عنوان الاستلام',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('عدد المقاعد:'),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: selectedQuantity > 1
                              ? () {
                            setStateSB(() {
                              selectedQuantity--;
                            });
                          }
                              : null,
                        ),
                        Text('$selectedQuantity'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: selectedQuantity < maxAvailableSeats
                              ? () {
                            setStateSB(() {
                              selectedQuantity++;
                            });
                          }
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('إلغاء'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          onPressed: (selectedQuantity > 0 && // تأكد أن الكمية > 0
                              nameController.text.isNotEmpty &&
                              phoneController.text.isNotEmpty &&
                              addressController.text.isNotEmpty)
                              ? () async {
                            // إغلاق مربع الحوار أولاً
                            Navigator.pop(ctx);

                            // استدعاء دالة الحجز
                            await _bookTrip(
                              tripId: trip['id'].toString(),
                              name: nameController.text,
                              phone: phoneController.text,
                              address: addressController.text,
                              quantity: selectedQuantity,
                            );

                            // إعادة تحميل الرحلات بعد اكتمال الحجز لتحديث الواجهة
                            if (mounted) {
                              _loadTrips();
                            }
                          }
                              : null, // تعطيل الزر إذا لم تكن الشروط مستوفاة
                          child: const Text('تأكيد الحجز'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // عرض شاشة الركاب
  void _showPassengersScreen(Map<String, dynamic> trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PassengersScreen(
          trip: Map<String, dynamic>.from(trip),
          currentUserId: currentUserId,
          onCancelBooking: (passengerId) async {
            await _cancelBooking(trip['id'].toString(), passengerId);
          },
        ),
      ),
    ).then((_) {
      // عند العودة من شاشة الركاب، قم بتحديث الرحلات للتأكد من أحدث البيانات
      _loadTrips();
    });
  }

  // تنسيق التاريخ
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy/MM/dd').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // حساب عدد المقاعد التي حجزها المستخدم الحالي
  int _getUserBookedSeatsCount(Map<String, dynamic> trip) {
    if (currentUserId == null) return 0;
    if (trip['passengers'] is! List) return 0;

    final passengers =
    List<Map<String, dynamic>>.from(trip['passengers'] as List);
    return passengers
        .where((passenger) => passenger['user_id']?.toString() == currentUserId)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرحلات المتاحة'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrips,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: isLoading && isFirstLoad
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(child: Text(error))
          : trips.isEmpty
          ? const Center(child: Text('لا توجد رحلات متاحة حالياً'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          final totalSeats = trip['total_seats'] is int
              ? trip['total_seats'] as int
              : int.tryParse(trip['total_seats'].toString()) ?? 0;
          final passengers = trip['passengers'] is List
              ? List<Map<String, dynamic>>.from(trip['passengers'] as List)
              : <Map<String, dynamic>>[];
          final bookedSeatsCount = passengers.length;
          final availableSeats = trip['available_seats'] is int
              ? trip['available_seats'] as int
              : totalSeats - bookedSeatsCount;
          final driver = trip['driver'] is Map
              ? Map<String, dynamic>.from(trip['driver'] as Map)
              : <String, dynamic>{};

          final userBookedSeats = _getUserBookedSeatsCount(trip);
          final isUserBookedAnySeat = userBookedSeats > 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // معلومات السائق
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                          Border.all(color: Colors.blue, width: 2),
                        ),
                        child: ClipOval(
                          child: driver['image'] != null &&
                              driver['image'].toString().isNotEmpty
                              ? Image.network(
                            driver['image'].toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person, size: 30),
                          )
                              : const Icon(Icons.person, size: 30),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver['name']?.toString() ?? 'غير معروف',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${driver['car_model'] ?? ''} - ${driver['car_color'] ?? ''}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1),

                  // معلومات الرحلة
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            trip['from'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.blue),
                        Expanded(
                          child: Text(
                            trip['to'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // التاريخ والمقاعد
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(
                          Icons.calendar_today,
                          _formatDate(trip['date'].toString()),
                          Colors.blue),
                      _buildInfoItem(
                          Icons.access_time,
                          trip['time'].toString(),
                          Colors.orange),
                      _buildInfoItem(
                        Icons.event_seat,
                        '$bookedSeatsCount/$totalSeats',
                        availableSeats > 0 ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // أزرار الإجراءات
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.people, size: 18),
                          label: const Text('عرض الركاب'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: passengers.isNotEmpty
                              ? () => _showPassengersScreen(trip)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: isUserBookedAnySeat
                            ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(8),
                            ),
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            _showPassengersScreen(trip);
                          },
                          child: Text('إلغاء حجز ($userBookedSeats)'),
                        )
                            : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(8),
                            ),
                            backgroundColor: availableSeats > 0
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          onPressed: availableSeats > 0
                              ? () => _showBookingDialog(trip)
                              : null,
                          child: const Text('حجز مقعد'),
                        ),
                      ),
                    ],
                  ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

class PassengersScreen extends StatelessWidget {
  final Map<String, dynamic> trip;
  final String? currentUserId;
  final Function(String)? onCancelBooking;

  const PassengersScreen({
    super.key,
    required this.trip,
    this.currentUserId,
    this.onCancelBooking,
  });

  @override
  Widget build(BuildContext context) {
    final passengers = trip['passengers'] is List
        ? List<Map<String, dynamic>>.from(trip['passengers'] as List)
        : <Map<String, dynamic>>[];
    final totalSeats = trip['total_seats'] is int
        ? trip['total_seats'] as int
        : int.tryParse(trip['total_seats'].toString()) ?? 0;
    final availableSeats = totalSeats - passengers.length;

    final currentUserBookings = passengers
        .where((p) => p['user_id']?.toString() == currentUserId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الركاب'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '${trip['from']} → ${trip['to']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatDate(trip['date'].toString())} - ${trip['time']}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'المقاعد: ${passengers.length}/$totalSeats (المتبقي: $availableSeats)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'حجوزاتي لهذه الرحلة:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (currentUserBookings.isEmpty)
              const Center(
                child: Text(
                  'لم تقم بأي حجز في هذه الرحلة.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentUserBookings.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final passenger = currentUserBookings[index];
                  final canCancel = currentUserId != null &&
                      (passenger['user_id']?.toString() == currentUserId);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.2),
                      child: Text('${index + 1}'),
                    ),
                    title: Text(passenger['name']?.toString() ?? 'غير معروف'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tel: ${passenger['phone']?.toString() ?? ''}'),
                        if (passenger['address'] != null)
                          Text('Address: ${passenger['address'].toString()}',
                              style: const TextStyle(fontSize: 12)),
                        Text(
                          'معرف الحجز: ${passenger['id']?.toString() ?? ''}',
                          style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                    trailing: canCancel
                        ? IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('تأكيد الإلغاء'),
                            content: const Text('هل أنت متأكد من إلغاء هذا المقعد؟'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('لا'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(dialogContext);
                                  if (onCancelBooking != null) {
                                    await onCancelBooking!(passenger['id'].toString());
                                  }
                                },
                                child: const Text('نعم، إلغاء'),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                        : null,
                  );
                },
              ),
            const SizedBox(height: 20),
            const Text(
              'جميع الركاب المسجلين في الرحلة:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (passengers.isEmpty)
              const Center(
                child: Text(
                  'لا يوجد ركاب مسجلين بعد',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: passengers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final passenger = passengers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      child: Text('${index + 1}'),
                    ),
                    title: Text(passenger['name']?.toString() ?? 'غير معروف'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tel: ${passenger['phone']?.toString() ?? ''}'),
                        if (passenger['address'] != null)
                          Text('Address: ${passenger['address'].toString()}',
                              style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy/MM/dd').format(date);
    } catch (e) {
      return dateString;
    }
  }
}