import 'package:cosmetic_store/doctore/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'models/appoinminet.dart';

class AppointmentsScreen extends StatefulWidget {
  @override
  _AppointmentsScreenState createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  late Future<List<Appointment>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _refreshAppointments();
  }

  Future<void> _refreshAppointments() async {
    setState(() {
      _appointmentsFuture = ApiService.getUserAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('حجوزاتي')),
      body: RefreshIndicator(
        onRefresh: _refreshAppointments,
        child: FutureBuilder<List<Appointment>>(
          future: _appointmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ في تحميل الحجوزات'));
            }
            if (snapshot.data!.isEmpty) {
              return Center(child: Text('لا توجد حجوزات'));
            }
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final appointment = snapshot.data![index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(appointment.doctorName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('التخصص: ${appointment.specialization}'),
                        Text('الموعد: ${appointment.dateTime}'),
                        Text('الحالة: ${_getStatusText(appointment.status)}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _cancelAppointment(appointment.id),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'في الانتظار';
      case 'confirmed': return 'مؤكد';
      case 'cancelled': return 'ملغى';
      case 'completed': return 'مكتمل';
      default: return status;
    }
  }

  Future<void> _cancelAppointment(int appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إلغاء الحجز'),
        content: Text('هل أنت متأكد من إلغاء هذا الحجز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('لا'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('نعم'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.cancelAppointment(appointmentId);
      if (success) {
        _refreshAppointments();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إلغاء الحجز')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الإلغاء')),
        );
      }
    }
  }
}