class Appointment {
  final int id;
  final String doctorName;
  final String specialization;
  final String dateTime;
  final String status;

  Appointment({
    required this.id,
    required this.doctorName,
    required this.specialization,
    required this.dateTime,
    required this.status,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      doctorName: json['doctor'],
      specialization: json['doctor_specialization'],
      dateTime: json['date_time'],
      status: json['status'],
    );
  }
}