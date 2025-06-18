import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'booking_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'عيادات منصة بيتي',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Tajawal',
      ),
      home: MedicalHomeScreen(),
    );
  }
}

class MedicalHomeScreen extends StatefulWidget {
  @override
  _MedicalHomeScreenState createState() => _MedicalHomeScreenState();
}

class _MedicalHomeScreenState extends State<MedicalHomeScreen> {
  List<dynamic> doctors = [];
  bool isLoading = true;
  int _currentIndex = 0;
  String _selectedCategory = 'الكل';

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  Future<void> fetchDoctors() async {
    try {
      final response = await http.get(
        Uri.parse('https://tiby.beytei.com/wp-json/afiya/v1/doctors'),
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        print('API Response: $decodedData');

        final bool success = decodedData['success'] ?? false;
        final List<dynamic> doctorsData = success ? decodedData['data'] ?? [] : [];

        setState(() {
          doctors = doctorsData;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load doctors: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('صيانة في هذا القسيم يمكنك الحجز عبر الرقم 07854076931: ${e.toString()}')),
      );
    }
  }

  List<dynamic> get filteredDoctors {
    if (_selectedCategory == 'الكل') return doctors;
    return doctors.where((doctor) {
      final specialty = doctor['specialization']?.toString()?.toLowerCase() ?? '';
      return specialty.contains(_selectedCategory.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('عيادات منصة بيتي'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: DoctorSearchDelegate(doctors: doctors),
              );
            },
          ),
        ],
      ),
      body: _buildCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'مواعيدي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0: return _buildHomeContent();
      case 1: return Center(child: Text('لاتوجد مواعيد '));
      case 2: return Center(child: Text('تم تسيجل الدخول'));
      default: return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.grey),
            SizedBox(height: 16),
            Text('توجد صيانا يمكمك الحجز عبر الواتساب 07754076931 ً'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchDoctors,
              child: Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // قسم التصنيفات
        Container(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 8),
            children: [
              _buildCategoryItem('الكل', Icons.all_inclusive),
              _buildCategoryItem('أسنان', Icons.medical_services),
              _buildCategoryItem('أطفال', Icons.child_care),
              _buildCategoryItem('باطنية', Icons.healing),
              _buildCategoryItem('عظام', Icons.accessibility),
              _buildCategoryItem('جلدية', Icons.face),
            ],
          ),
        ),
        // قائمة الأطباء
        Expanded(
          child: RefreshIndicator(
            onRefresh: fetchDoctors,
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: filteredDoctors.length,
              itemBuilder: (context, index) {
                return DoctorCard(doctor: filteredDoctors[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String title, IconData icon) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = title;
        });
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: _selectedCategory == title ? Colors.blue[100] : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: _selectedCategory == title ? Colors.blue : Colors.grey[200],
                child: Icon(icon, size: 30, color: _selectedCategory == title ? Colors.white : Colors.black),
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: _selectedCategory == title ? Colors.blue : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class DoctorCard extends StatelessWidget {
  final dynamic doctor;

  DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    // معالجة بيانات الطبيب
    final name = doctor['name'] ?? 'غير معروف';
    final specialty = doctor['specialization'] ?? 'غير محدد';
    final address = doctor['address'] ?? 'غير محدد';
    final hospital = doctor['clinic_name'] ?? '';
    final price = doctor['consultation_price']?.toString() ?? '0';
    final imageUrl = doctor['image_url'] is String ? doctor['image_url'] : null;
    final whatsapp = doctor['whatsapp_number']?.toString() ?? '';

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingScreen(doctor: doctor),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // صورة الطبيب
                  Hero(
                    tag: 'doctor-image-${doctor['id']}',
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                        image: imageUrl != null
                            ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: imageUrl == null
                          ? Icon(Icons.person, size: 40, color: Colors.grey)
                          : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          specialty,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        if (hospital.isNotEmpty) SizedBox(height: 4),
                        if (hospital.isNotEmpty) Text(
                          hospital,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                address,
                                style: TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.attach_money, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              price.isNotEmpty ? '$price دينار' : 'السعر غير متوفر',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // زر الحجز الكبير
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal, // لون جميل
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingScreen(doctor: doctor),
                      ),
                    );
                  },
                  child: Text(
                    'حجز موعد',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DoctorDetailScreen extends StatelessWidget {
  final dynamic doctor;

  DoctorDetailScreen({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final name = doctor['name'] ?? 'غير معروف';
    final specialty = doctor['specialization'] ?? 'غير محدد';
    final address = doctor['address'] ?? 'غير محدد';
    final hospital = doctor['clinic_name'] ?? '';
    final price = doctor['consultation_price']?.toString() ?? '0';
    final imageUrl = doctor['image_url'] is String ? doctor['image_url'] : null;
    final whatsapp = doctor['whatsapp_number']?.toString() ?? '';
    final workingHours = doctor['working_hours'] ?? {};
    final workingDays = doctor['working_days'] is List ? doctor['working_days'] : [];

    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل الطبيب'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Hero(
              tag: 'doctor-image-${doctor['id']}',
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: imageUrl != null
                      ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: imageUrl == null
                    ? Center(child: Icon(Icons.person, size: 100, color: Colors.grey))
                    : null,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    specialty,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 16),
                  if (hospital.isNotEmpty) ...[
                    Text(
                      'العيادة: $hospital',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                  ],
                  Text(
                    'العنوان: $address',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'سعر الكشف: ${price.isNotEmpty ? '$price دينار' : 'غير محدد'}',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  if (workingHours['start'] != null && workingHours['end'] != null)
                    Text(
                      'ساعات العمل: ${workingHours['start']} - ${workingHours['end']}',
                      style: TextStyle(fontSize: 16),
                    ),
                  SizedBox(height: 8),
                  if (workingDays.isNotEmpty)
                    Text(
                      'أيام العمل: ${workingDays.join('، ')}',
                      style: TextStyle(fontSize: 16),
                    ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.calendar_today),
                          label: Text('حجز موعد'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingScreen(doctor: doctor),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      if (whatsapp.isNotEmpty) SizedBox(width: 16),
                      if (whatsapp.isNotEmpty)
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.chat),
                            label: Text('واتساب'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              // يمكنك إضافة فتح الواتساب هنا
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class DoctorSearchDelegate extends SearchDelegate {
  final List<dynamic> doctors;

  DoctorSearchDelegate({required this.doctors});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = doctors.where((doctor) {
      final name = doctor['name']?.toString()?.toLowerCase() ?? '';
      final specialty = doctor['specialization']?.toString()?.toLowerCase() ?? '';
      final searchTerm = query.toLowerCase();
      return name.contains(searchTerm) || specialty.contains(searchTerm);
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: results[index]['image_url'] != null && results[index]['image_url'] != false
                ? NetworkImage(results[index]['image_url'])
                : null,
            child: results[index]['image_url'] == null || results[index]['image_url'] == false
                ? Icon(Icons.person)
                : null,
          ),
          title: Text(results[index]['name'] ?? 'غير معروف'),
          subtitle: Text(results[index]['specialization'] ?? 'غير محدد'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorDetailScreen(doctor: results[index]),
              ),
            );
          },
        );
      },
    );
  }
}