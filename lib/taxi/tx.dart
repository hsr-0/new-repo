import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
      ),
      home: TripScreen(),
    );
  }
}

class TripScreen extends StatefulWidget {
  @override
  _TripScreenState createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  List<dynamic> trips = [];
  bool isLoading = true;
  String error = '';
  String? currentUserId; // سيتم تعبئته عند تسجيل الدخول

  @override
  void initState() {
    super.initState();
    _loadTrips();
    // هنا يجب الحصول على معرف المستخدم الحالي (من نظام تسجيل الدخول)
    // currentUserId = getCurrentUserId();
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
        final data = json.decode(response.body);
        setState(() {
          trips = data;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load trips: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = 'Error loading trips: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _getTripDetails(String tripId) async {
    try {
      final response = await http.get(
        Uri.parse('https://banner.beytei.com/wp-json/taxi/v1/trip/$tripId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load trip details');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  Future<void> _bookTrip({
    required String tripId,
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://banner.beytei.com/wp-json/taxi/v1/book'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trip_id': tripId,
          'name': name,
          'phone': phone,
          'address': address,
          'user_id': currentUserId, // إضافة معرف المستخدم
        }),
      );

      final result = json.decode(response.body);
      if (response.statusCode == 200 && result['success'] == true) {
        _updateTripLocally(result['trip']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم الحجز بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(result['message'] ?? 'فشل الحجز');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الحجز: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
        }),
      );

      final result = json.decode(response.body);
      if (response.statusCode == 200 && result['success'] == true) {
        _updateTripLocally(result['trip']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إلغاء الحجز بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(result['message'] ?? 'فشل إلغاء الحجز');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إلغاء الحجز: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateTripLocally(Map<String, dynamic> updatedTrip) {
    setState(() {
      final index = trips.indexWhere((t) => t['id'].toString() == updatedTrip['id'].toString());
      if (index != -1) {
        trips[index] = updatedTrip;
      }
    });
  }

  void _showBookingDialog(Map<String, dynamic> trip) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'حجز مقعد',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '${trip['from']} → ${trip['to']}',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                '${_formatDate(trip['date'])} - ${trip['time']}',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'الاسم الكامل',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'عنوان الاستلام',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('إلغاء'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () async {
                      if (nameController.text.isNotEmpty &&
                          phoneController.text.isNotEmpty &&
                          addressController.text.isNotEmpty) {
                        Navigator.pop(ctx);
                        await _bookTrip(
                          tripId: trip['id'].toString(),
                          name: nameController.text,
                          phone: phoneController.text,
                          address: addressController.text,
                        );
                      }
                    },
                    child: Text('تأكيد الحجز'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPassengersScreen(Map<String, dynamic> trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PassengersScreen(
          trip: trip,
          currentUserId: currentUserId,
          onCancelBooking: (passengerId) async {
            await _cancelBooking(trip['id'].toString(), passengerId);
            Navigator.pop(context);
          },
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

  bool _isUserBooked(Map<String, dynamic> trip) {
    if (currentUserId == null) return false;
    if (trip['passengers'] is! List) return false;

    return trip['passengers'].any((passenger) =>
    passenger['user_id']?.toString() == currentUserId);
  }

  String? _getUserBookingId(Map<String, dynamic> trip) {
    if (currentUserId == null) return null;
    if (trip['passengers'] is! List) return null;

    final passenger = trip['passengers'].firstWhere(
          (passenger) => passenger['user_id']?.toString() == currentUserId,
      orElse: () => null,
    );

    return passenger?['id']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الرحلات المتاحة'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTrips,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(child: Text(error))
          : trips.isEmpty
          ? Center(child: Text('لا توجد رحلات متاحة حالياً'))
          : ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          final totalSeats = trip['total_seats'] is int
              ? trip['total_seats']
              : int.tryParse(trip['total_seats'].toString()) ?? 0;
          final bookedSeats = trip['passengers'] is List
              ? trip['passengers'].length
              : 0;
          final availableSeats = totalSeats - bookedSeats;
          final driver = trip['driver'] is Map ? trip['driver'] : {};
          final isBooked = _isUserBooked(trip);

          return Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
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
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: ClipOval(
                          child: driver['image'] != null
                              ? Image.network(
                            driver['image'].toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.person, size: 30),
                          )
                              : Icon(Icons.person, size: 30),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver['name']?.toString() ?? 'غير معروف',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${driver['car_model'] ?? ''} - ${driver['car_color'] ?? ''}',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 24, thickness: 1),

                  // معلومات الرحلة
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            trip['from'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Icon(Icons.arrow_forward, color: Colors.blue),
                        Expanded(
                          child: Text(
                            trip['to'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // التاريخ والمقاعد
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(Icons.calendar_today, _formatDate(trip['date']), Colors.blue),
                      _buildInfoItem(Icons.access_time, trip['time'], Colors.orange),
                      _buildInfoItem(
                        Icons.event_seat,
                        '$bookedSeats/$totalSeats',
                        availableSeats > 0 ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // أزرار الإجراءات
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.people, size: 18),
                          label: Text('عرض الركاب'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _showPassengersScreen(trip),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: isBooked
                            ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            final bookingId = _getUserBookingId(trip);
                            if (bookingId != null) {
                              await _cancelBooking(trip['id'].toString(), bookingId);
                            }
                          },
                          child: Text('إلغاء الحجز'),
                        )
                            : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: availableSeats > 0 ? Colors.blue : Colors.grey,
                          ),
                          onPressed: availableSeats > 0
                              ? () => _showBookingDialog(trip)
                              : null,
                          child: Text('حجز مقعد'),
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
        SizedBox(width: 4),
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
    Key? key,
    required this.trip,
    this.currentUserId,
    this.onCancelBooking,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final passengers = trip['passengers'] is List ? trip['passengers'] : [];

    return Scaffold(
      appBar: AppBar(
        title: Text('قائمة الركاب'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '${trip['from']} → ${trip['to']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${_formatDate(trip['date'])} - ${trip['time']}',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'المقاعد: ${passengers.length}/${trip['total_seats']}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'الركاب المسجلين (${passengers.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            if (passengers.isEmpty)
              Center(
                child: Text(
                  'لا يوجد ركاب مسجلين بعد',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: passengers.length,
                separatorBuilder: (_, __) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final passenger = passengers[index];
                  final canCancel = currentUserId != null &&
                      (passenger['user_id']?.toString() == currentUserId);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.2),
                      child: Text('${index + 1}'),
                    ),
                    title: Text(passenger['name'] ?? 'غير معروف'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tel: ${passenger['phone'] ?? ''}'),
                        if (passenger['address'] != null)
                          Text('Address: ${passenger['address']}',
                              style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: canCancel
                        ? IconButton(
                      icon: Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {
                        if (onCancelBooking != null) {
                          onCancelBooking!(passenger['id'].toString());
                        }
                      },
                    )
                        : null,
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