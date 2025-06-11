import 'package:cosmetic_store/doctore/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'doctor_detail_screen.dart';
import 'models/docto.dart';

class DoctorsScreen extends StatefulWidget {
  @override
  _DoctorsScreenState createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  late Future<List<Doctor>> _doctorsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _doctorsFuture = ApiService.getDoctors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الأطباء'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: DoctorsSearch(_doctorsFuture),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Doctor>>(
        future: _doctorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ في تحميل بيانات الأطباء'));
          }
          final doctors = snapshot.data!;
          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(doctor.imageUrl),
                ),
                title: Text(doctor.name),
                subtitle: Text(doctor.specialization),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorDetailScreen(doctor: doctor),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class DoctorsSearch extends SearchDelegate<String> {
  final Future<List<Doctor>> doctorsFuture;

  DoctorsSearch(this.doctorsFuture);

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
        close(context, '');
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
    return FutureBuilder<List<Doctor>>(
      future: doctorsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final results = snapshot.data!
            .where((doctor) => doctor.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final doctor = results[index];
            return ListTile(
              title: Text(doctor.name),
              subtitle: Text(doctor.specialization),
              onTap: () {
                close(context, doctor.name);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DoctorDetailScreen(doctor: doctor),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}