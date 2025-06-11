import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'عافية',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Tajawal',
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Doctor> doctors = [];
  bool isLoading = true;
  String selectedSpecialty = 'جميع التخصصات';

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  Future<void> fetchDoctors() async {
    final response = await http.get(Uri.parse('https://orchid-wallaby-109538.hostingersite.com//wp-json/afia/v1/doctors'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        doctors = data.map((json) => Doctor.fromJson(json)).toList();
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load doctors');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('عافية - الأحياء (848)'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: DoctorSearch(doctors));
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedSpecialty,
              items: [
                'جميع التخصصات',
                'جراحة العظام والكسور',
                // Add other specialties here
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedSpecialty = newValue!;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                if (selectedSpecialty != 'جميع التخصصات' &&
                    doctors[index].specialty != selectedSpecialty) {
                  return Container();
                }
                return DoctorCard(doctor: doctors[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}


class Doctor {
  final String name;
  final String specialty;
  final String city;
  final String address;
  final String hospital;

  Doctor({
    required this.name,
    required this.specialty,
    required this.city,
    required this.address,
    required this.hospital,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      name: json['name'],
      specialty: json['specialty'],
      city: json['city'],
      address: json['address'],
      hospital: json['hospital'],
    );
  }
}

class DoctorCard extends StatelessWidget {
  final Doctor doctor;

  const DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, size: 20),
                SizedBox(width: 8),
                Text(
                  doctor.name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.medical_services, size: 20),
                SizedBox(width: 8),
                Text(doctor.specialty),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 20),
                SizedBox(width: 8),
                Text(doctor.city),
              ],
            ),
            SizedBox(height: 8),
            Text(doctor.address),
            SizedBox(height: 8),
            Text('داخل مستشفى ${doctor.hospital}'),
          ],
        ),
      ),
    );
  }
}

class DoctorSearch extends SearchDelegate<Doctor> {
  final List<Doctor> doctors;

  DoctorSearch(this.doctors);

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
        close(context, Doctor(name: '', specialty: '', city: '', address: '', hospital: ''));
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = doctors.where((doctor) =>
    doctor.name.toLowerCase().contains(query.toLowerCase()) ||
        doctor.specialty.toLowerCase().contains(query.toLowerCase()) ||
        doctor.city.toLowerCase().contains(query.toLowerCase()));

    return ListView(
      children: results.map((doctor) => ListTile(
        title: Text(doctor.name),
        subtitle: Text(doctor.specialty),
        onTap: () {
          close(context, doctor);
        },
      )).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? doctors
        : doctors.where((doctor) =>
    doctor.name.toLowerCase().contains(query.toLowerCase()) ||
        doctor.specialty.toLowerCase().contains(query.toLowerCase()) ||
        doctor.city.toLowerCase().contains(query.toLowerCase()));

    return ListView(
      children: suggestions.map((doctor) => ListTile(
        title: Text(doctor.name),
        subtitle: Text(doctor.specialty),
        onTap: () {
          query = doctor.name;
          showResults(context);
        },
      )).toList(),
    );
  }
}