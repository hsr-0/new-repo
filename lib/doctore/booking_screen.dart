import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class BookingScreen extends StatefulWidget {
  final dynamic doctor;

  BookingScreen({required this.doctor});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? selectedDate;
  String? selectedTime;
  bool isBooking = false;
  String? errorMessage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> defaultTimes = [
    "08:00", "08:30", "09:00", "09:30",
    "10:00", "10:30", "11:00", "11:30",
    "12:00", "12:30", "13:00", "13:30",
    "14:00", "14:30", "15:00", "15:30",
    "16:00", "16:30", "17:00", "17:30",
    "18:00", "18:30", "19:00", "19:30"
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> sendBookingEmail() async {
    // التحقق من اتصال الإنترنت
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يوجد اتصال بالإنترنت، الرجاء التحقق من الاتصال')),
      );
      return;
    }

    // التحقق من صحة النموذج
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // التحقق من اختيار التاريخ والوقت
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء اختيار التاريخ والوقت')),
      );
      return;
    }

    setState(() => isBooking = true);

    try {
      // إعداد خادم SMTP (استبدل بالقيم الخاصة بك)
      final smtpServer = SmtpServer(
        'smtp.gmail.com',
        username: 'hs28243@gmail.com',
        password: 'eshdthmkqwpgqnht', // كلمة مرور التطبيق بدون مسافات
        port: 587,
      );

      // إنشاء رسالة البريد الإلكتروني
      final message = Message()
        ..from = Address('hs28243@gmail.com', 'نظام حجز المواعيد')
        ..recipients.add('hs28243@gmail.com') // بريدك المستلم
        ..subject = 'حجز موعد جديد - ${_nameController.text}'
        ..text = '''
تفاصيل الحجز الجديد:

الطبيب: ${widget.doctor['name']}
المريض: ${_nameController.text}
رقم الهاتف: ${_phoneController.text}
التاريخ: ${DateFormat('EEEE, dd MMM yyyy', 'ar').format(selectedDate!)}
الوقت: $selectedTime
سعر الكشف: ${widget.doctor['consultation_price'] ?? '0'} دينار عراقي

تم إرسال هذا الحجز من تطبيق العيادة.
''';

      // إرسال البريد الإلكتروني
      await send(message, smtpServer);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال تفاصيل الحجز بنجاح')),
      );

      Navigator.pop(context, true);
    } on SmtpClientAuthenticationException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في بيانات البريد الإلكتروني: ${e.message}')),
      );
    } on SocketException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الاتصال بالإنترنت: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ غير متوقع: ${e.toString()}')),
      );
    } finally {
      setState(() => isBooking = false);
    }
  }

  bool _validatePhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    return phoneRegex.hasMatch(phone);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      locale: Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        selectedTime = null;
      });
    }
  }

  Future<void> _confirmBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحجز'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من حجز الموعد التالي؟'),
            SizedBox(height: 16),
            _buildBookingSummary(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('تأكيد الحجز'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await sendBookingEmail();
    }
  }

  Widget _buildBookingSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryRow('الطبيب:', widget.doctor['name']),
        _buildSummaryRow('المريض:', _nameController.text),
        _buildSummaryRow('الهاتف:', _phoneController.text),
        _buildSummaryRow('التاريخ:',
            selectedDate != null
                ? DateFormat('EEEE, dd MMM yyyy', 'ar').format(selectedDate!)
                : 'غير محدد'),
        _buildSummaryRow('الوقت:', selectedTime ?? 'غير محدد'),
        _buildSummaryRow('سعر الكشف:',
            '${widget.doctor['consultation_price'] ?? '0'} دينار عراقي'),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('حجز موعد'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDoctorInfoCard(),
              SizedBox(height: 24),
              _buildPatientForm(),
              SizedBox(height: 24),
              _buildDateSelector(),
              SizedBox(height: 24),
              _buildTimeDropdown(),
              if (errorMessage != null) ...[
                SizedBox(height: 16),
                Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ],
              SizedBox(height: 32),
              _buildBookingButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorInfoCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'معلومات الطبيب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Divider(),
            SizedBox(height: 8),
            _buildInfoRow(Icons.medical_services, 'الطبيب:', widget.doctor['name']),
            SizedBox(height: 8),
            _buildInfoRow(Icons.local_hospital, 'التخصص:', widget.doctor['specialization'] ?? 'غير محدد'),
            SizedBox(height: 8),
            _buildInfoRow(Icons.business, 'العيادة:', widget.doctor['clinic_name'] ?? 'غير محدد'),
            SizedBox(height: 8),
            _buildInfoRow(Icons.attach_money, 'سعر الكشف:',
                '${widget.doctor['consultation_price'] ?? '0'} دينار عراقي'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: '$label ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلومات المريض',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'الاسم الكامل',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'الرجاء إدخال الاسم' : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'رقم الهاتف',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.phone),
            hintText: 'مثال: 9647712345678',
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'الرجاء إدخال رقم الهاتف';
            if (!_validatePhoneNumber(value!)) return 'رقم الهاتف يجب أن يكون بين 10 إلى 15 رقمًا';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تاريخ الموعد',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _selectDate(context),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 50), backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, color: Colors.white),
              SizedBox(width: 8),
              Text(
                selectedDate == null
                    ? 'اختر التاريخ'
                    : DateFormat('EEEE, dd MMM yyyy', 'ar').format(selectedDate!),
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'وقت الموعد',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedTime,
          items: defaultTimes.map((time) => DropdownMenuItem(
            value: time,
            child: Text(time),
          )).toList(),
          onChanged: (value) => setState(() => selectedTime = value),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            labelText: 'اختر الوقت',
            prefixIcon: Icon(Icons.access_time),
          ),
          validator: (value) => value == null ? 'الرجاء اختيار الوقت' : null,
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildBookingButton() {
    return Center(
      child: ElevatedButton(
        onPressed: isBooking ? null : _confirmBooking,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 50), backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isBooking
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 8),
            Text('جاري الحجز...', style: TextStyle(fontSize: 18)),
          ],
        )
            : Text('تأكيد الحجز', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}