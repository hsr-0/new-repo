import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'doctor_detail_screen.dart';
import 'booking_screen.dart';

class MedicalHomeScreen extends StatefulWidget {
  @override
  _MedicalHomeScreenState createState() => _MedicalHomeScreenState();
}

class _MedicalHomeScreenState extends State<MedicalHomeScreen> {
  List<dynamic> doctors = [];
  bool isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  Future<void> fetchDoctors() async {
    try {
      final response = await http.get(
        Uri.parse('https://tiby.beytei.com//wp-json/afiya/v1/doctors'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          doctors = data is List ? data : [];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load doctors: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في تحميل البيانات: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('عيادات منصة  بيتي '),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // إضافة وظيفة البحث هنا
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
      case 1: return Center(child: Text('صفحة المواعيد سيتم تنفيذها لاحقًا'));
      case 2: return Center(child: Text('صفحة الحساب سيتم تنفيذها لاحقًا'));
      default: return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (doctors.isEmpty) {
      return Center(child: Text('لا توجد بيانات للأطباء متاحة حالياً'));
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
          child: ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              return DoctorCard(doctor: doctors[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            child: Icon(icon, size: 30),
          ),
          SizedBox(height: 4),
          Text(title),
        ],
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
    final name = doctor['name'] ?? doctor['post_title'] ?? 'غير معروف';
    final specialty = doctor['specialty'] ?? doctor['specialization'] ?? 'غير محدد';
    final address = doctor['address'] ?? 'غير محدد';
    final hospital = doctor['hospital'] ?? doctor['clinic_name'] ?? '';
    final price = doctor['consultation_price'] ?? '0';
    final imageUrl = doctor['image_url'] is String ? doctor['image_url'] :
    (doctor['image'] is Map ? doctor['image']['url'] : null);

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة الطبيب
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                  image: imageUrl != null && imageUrl != false
                      ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: imageUrl == null || imageUrl == false
                    ? Icon(Icons.person, size: 40, color: Colors.grey)
                    : null,
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
                        Text(
                          address,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          '$price دينار',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.calendar_today, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(doctor: doctor),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}