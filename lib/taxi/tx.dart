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

  @override
  void initState() {
    super.initState();
    _loadTrips();
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
        }),
      );

      final result = json.decode(response.body);
      if (response.statusCode == 200 && result['success'] == true) {
        // تحديث بيانات الرحلة مباشرة
        setState(() {
          final index = trips.indexWhere((t) => t['id'].toString() == tripId);
          if (index != -1) {
            trips[index] = result['trip'];
          }
        });

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

  void _showBookingDialog(Map<String, dynamic> trip) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حجز مقعد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${trip['from']} → ${trip['to']}',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${_formatDate(trip['date'])} - ${trip['time']}'),
              SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'الاسم الكامل',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'مطلوب' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'مطلوب' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'عنوان الاستلام',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'مطلوب' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
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
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          final availableSeats = trip['available_seats'] is int
              ? trip['available_seats']
              : int.tryParse(trip['available_seats'].toString()) ?? 0;
          final totalSeats = trip['total_seats'] is int
              ? trip['total_seats']
              : int.tryParse(trip['total_seats'].toString()) ?? 0;
          final driver = trip['driver'] is Map ? trip['driver'] : {};

          return Card(
            margin: EdgeInsets.all(10),
            elevation: 3,
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // معلومات السائق
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: driver['image'] != null
                            ? NetworkImage(driver['image'].toString())
                            : AssetImage('assets/default_driver.png') as ImageProvider,
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver['name']?.toString() ?? 'غير معروف',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${driver['car_model']} - ${driver['car_color']}',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 20),

                  // معلومات الرحلة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('من ${trip['from']}', style: TextStyle(fontWeight: FontWeight.bold)),
                      Icon(Icons.arrow_forward, color: Colors.blue),
                      Text('إلى ${trip['to']}', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 15),

                  // التاريخ والمقاعد
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(Icons.calendar_today, size: 16),
                        SizedBox(width: 5),
                        Text(_formatDate(trip['date'])),
                      ]),
                      Row(children: [
                        Icon(Icons.access_time, size: 16),
                        SizedBox(width: 5),
                        Text(trip['time']),
                      ]),
                      Row(children: [
                        Icon(Icons.event_seat, size: 16),
                        SizedBox(width: 5),
                        Text(
                          '$availableSeats/$totalSeats',
                          style: TextStyle(
                              color: availableSeats > 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ]),
                    ],
                  ),
                  SizedBox(height: 15),

                  // عرض الركاب
                  if (trip['passengers'] != null && trip['passengers'].isNotEmpty) ...[
                    Divider(height: 20),
                    Text('الركاب المسجلين:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Column(
                      children: List.generate(
                        trip['passengers'].length,
                            (i) => ListTile(
                          leading: CircleAvatar(child: Text('${i+1}')),
                          title: Text(trip['passengers'][i]['name'] ?? ''),
                          dense: true,
                        ),
                      ),
                    ),
                  ],

                  // زر الحجز
                  SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
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
            ),
          );
        },
      ),
    );
  }
}