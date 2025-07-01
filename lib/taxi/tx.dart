import 'dart:io';

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
        fontFamily: 'Cairo',
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

class _TripScreenState extends State<TripScreen> with WidgetsBindingObserver {
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

  Future<void> _initializeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString('user_id');

    if (storedUserId == null) {
      String newUserId = _uuid.v4();
      await prefs.setString('user_id', newUserId);
      setState(() {
        currentUserId = newUserId;
      });
    } else {
      setState(() {
        currentUserId = storedUserId;
      });
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
            trips = decodedData
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList();
            trips = _processTripData(trips);
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
      print("Error loading trips: $e");
    }
  }

  List<Map<String, dynamic>> _processTripData(
      List<Map<String, dynamic>> tripsData) {
    return tripsData.map((trip) {
      return _processSingleTripData(trip);
    }).toList();
  }

  Future<void> _bookTrip({
    required String tripId,
    required String name,
    required String phone,
    required String address,
    required int quantity,
  }) async {
    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ: لم يتم تهيئة معرف المستخدم. يرجى إعادة تشغيل التطبيق.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://banner.beytei.com/wp-json/taxi/v1/book'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trip_id': tripId,
          'name': name,
          'phone': phone,
          'address': address,
          'user_id': currentUserId,
          'quantity': quantity,
        }),
      );

      final dynamic result = json.decode(response.body);

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
        final errorMessage = result is Map && result.containsKey('message')
            ? result['message']
            : 'فشل الحجز لسبب غير معروف.';
        throw Exception(errorMessage);
      }
    } on SocketException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل الاتصال بالشبكة. يرجى التحقق من اتصالك.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحجز: ${e.toString().replaceFirst("Exception: ", "")}'),
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
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trip_id': tripId,
          'passenger_id': passengerId,
          'user_id': currentUserId,
        }),
      );

      final dynamic result = json.decode(response.body);

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
    } on SocketException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل الاتصال بالشبكة. يرجى التحقق من اتصالك.'),
            backgroundColor: Colors.red,
          ),
        );
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
      final index =
      trips.indexWhere((t) => t['id'].toString() == updatedTrip['id'].toString());
      if (index != -1) {
        trips[index] = _processSingleTripData(updatedTrip);
      } else {
        _loadTrips();
      }
    });
  }

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

  void _showBookingDialog(Map<String, dynamic> trip) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
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
                child: SingleChildScrollView(
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
                        onChanged: (_) => setStateSB(() {}),
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
                        onChanged: (_) => setStateSB(() {}),
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
                        onChanged: (_) => setStateSB(() {}),
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
                            onPressed: (selectedQuantity > 0 &&
                                nameController.text.isNotEmpty &&
                                phoneController.text.isNotEmpty &&
                                addressController.text.isNotEmpty)
                                ? () async {
                              Navigator.pop(ctx);
                              await _bookTrip(
                                tripId: trip['id'].toString(),
                                name: nameController.text,
                                phone: phoneController.text,
                                address: addressController.text,
                                quantity: selectedQuantity,
                              );
                              if (mounted) {
                                _loadTrips();
                              }
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
          trip: Map<String, dynamic>.from(trip),
          currentUserId: currentUserId,
          onCancelBooking: (passengerId) async {
            await _cancelBooking(trip['id'].toString(), passengerId);
          },
        ),
      ),
    ).then((_) {
      _loadTrips();
    });
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy/MM/dd', 'en_US').format(date);
    } catch (e) {
      return dateString;
    }
  }

  int _getUserBookedSeatsCount(Map<String, dynamic> trip) {
    if (currentUserId == null || trip['passengers'] is! List) return 0;
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
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      )
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
              ? List<Map<String, dynamic>>.from(
              trip['passengers'] as List)
              : <Map<String, dynamic>>[];
          final bookedSeatsCount = passengers.length;

          final availableSeats = trip['available_seats'] as int;



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
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.blue, width: 2),
                        ),
                        child: ClipOval(
                          child: driver['image'] != null &&
                              driver['image']
                                  .toString()
                                  .isNotEmpty
                              ? Image.network(
                            driver['image'].toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person,
                                size: 30),
                          )
                              : const Icon(Icons.person,
                              size: 30),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver['name']?.toString() ??
                                  'غير معروف',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${driver['car_model'] ?? ''} - ${driver['car_color'] ?? ''}',
                              style: const TextStyle(
                                  color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1),
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
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Icon(Icons.arrow_forward,
                            color: Colors.blue),
                        Expanded(
                          child: Text(
                            trip['to'].toString(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(
                          Icons.calendar_today,
                          _formatDate(trip['date'].toString()),
                          Colors.blue),
                      _buildInfoItem(Icons.access_time,
                          trip['time'].toString(), Colors.orange),
                      _buildInfoItem(
                        Icons.event_seat,
                        '$bookedSeatsCount/$totalSeats',
                        availableSeats > 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon:
                          const Icon(Icons.people, size: 18),
                          label: Text(availableSeats > 0 ? 'عرض الركاب' : 'عرض الركاب (مكتمل)'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(8),
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
                            padding:
                            const EdgeInsets.symmetric(
                                vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(8),
                            ),
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            _showPassengersScreen(trip);
                          },
                          child: Text(
                              'إلغاء حجز ($userBookedSeats)'),
                        )
                            : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(
                                vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(8),
                            ),
                            backgroundColor:
                            availableSeats > 0
                                ? Colors.blue
                                : Colors.red[700],
                          ),
                          onPressed: availableSeats > 0
                              ? () =>
                              _showBookingDialog(trip)
                              : null,
                          child: Text(availableSeats > 0
                              ? 'حجز مقعد'
                              : 'المقاعد محجوزة'),
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
  final Future<void> Function(String)? onCancelBooking;

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
                      textAlign: TextAlign.center,
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
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'لم تقم بأي حجز في هذه الرحلة.',
                    style: TextStyle(color: Colors.grey),
                  ),
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
                        Text('الهاتف: ${passenger['phone']?.toString() ?? ''}'),
                        if (passenger['address'] != null)
                          Text(
                              'العنوان: ${passenger['address'].toString()}',
                              style: const TextStyle(fontSize: 12)),
                        Text(
                          'معرف الحجز: ${passenger['id']?.toString() ?? ''}',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.blueGrey),
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
                            content: const Text(
                                'هل أنت متأكد من إلغاء هذا المقعد؟'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext),
                                child: const Text('لا'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(dialogContext);
                                  if (onCancelBooking != null) {
                                    await onCancelBooking!(
                                        passenger['id'].toString());
                                    // The list will refresh on pop
                                    Navigator.pop(context);
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
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'لا يوجد ركاب مسجلين بعد',
                    style: TextStyle(color: Colors.grey),
                  ),
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
                        Text('الهاتف: ${passenger['phone']?.toString() ?? ''}'),
                        if (passenger['address'] != null)
                          Text(
                              'العنوان: ${passenger['address'].toString()}',
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
      return DateFormat('yyyy/MM/dd', 'en_US').format(date);
    } catch (e) {
      return dateString;
    }
  }
}