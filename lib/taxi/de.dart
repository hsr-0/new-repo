import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
// ✅ إضافة نظام الكاش للخرائط المجانية
import 'package:flutter_map_cache/flutter_map_cache.dart' as fmc;

import 'cash.dart';

// --- (الواجهة الرئيسية): تجمع بين الإدخال اليدوي وخيار الخريطة ---
class DestinationSelectionScreen extends StatefulWidget {
  final LatLng initialPickup;
  const DestinationSelectionScreen({super.key, required this.initialPickup});

  @override
  State<DestinationSelectionScreen> createState() => _DestinationSelectionScreenState();
}

class _DestinationSelectionScreenState extends State<DestinationSelectionScreen> {
  // بيانات نقطة الانطلاق والوصول
  late LatLng _pickupLocation;
  Map<String, dynamic>? _destinationData;

  // المتحكمات النصية
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pickupLocation = widget.initialPickup;
    // تعيين نقطة الانطلاق الأولية كنص
    _pickupController.text = "موقعي الحالي (محدد تلقائياً)";
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  // دالة موحدة لفتح شاشة الخريطة، تحدد إذا كنا نختار نقطة الانطلاق أم الوصول
  Future<void> _openMapPicker({required bool isPickingUp}) async {
    final initialPoint = isPickingUp
        ? _pickupLocation
        : (_destinationData != null
        ? LatLng(_destinationData!['lat'], _destinationData!['lng'])
        : _pickupLocation);

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLocation: initialPoint,
          appBarTitle: isPickingUp ? 'حدد نقطة الانطلاق' : 'حدد نقطة الوصول',
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (isPickingUp) {
          // تحديث بيانات ومتحكم نقطة الانطلاق
          _pickupLocation = LatLng(result['lat'], result['lng']);
          _pickupController.text = result['name'];
        } else {
          // تحديث بيانات ومتحكم نقطة الوصول
          _destinationData = result;
          _destinationController.text = result['name'];
        }
      });
    }
  }

  void _confirmSelection() {
    // التحقق من أن المستخدم أدخل وجهة
    if (_destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء تحديد وجهة على الخريطة أو كتابتها")),
      );
      return;
    }

    // في حال كتب المستخدم نصاً فقط للوجهة
    if (_destinationData == null && _destinationController.text.isNotEmpty) {
      _destinationData = {
        'name': _destinationController.text,
        'lat': 0.0,
        'lng': 0.0,
      };
    }

    // إرجاع البيانات النهائية للشاشة السابقة
    Navigator.of(context).pop({
      'pickup': _pickupLocation,
      'destination': _destinationData,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديد الرحلة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- حقل نقطة الانطلاق (قابل للتعديل بالضغط) ---
            TextField(
              controller: _pickupController,
              readOnly: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.my_location, color: Colors.green),
                labelText: 'نقطة الانطلاق',
                hintText: 'اضغط للتغيير من الخريطة',
              ),
              onTap: () => _openMapPicker(isPickingUp: true),
            ),
            const SizedBox(height: 16),
            // --- حقل الوجهة (يمكن الكتابة فيه) ---
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.flag_outlined, color: Colors.red),
                labelText: 'إلى أين تريد أن تذهب؟',
              ),
              onChanged: (value) {
                // عند الكتابة، يتم الاعتماد على النص المكتوب
                setState(() => _destinationData = null);
              },
            ),
            const SizedBox(height: 24),
            // --- زر فتح الخريطة للوجهة ---
            ListTile(
              leading: const Icon(Icons.map_outlined, color: Colors.blue),
              title: const Text('أو حدد الوجهة من الخريطة'),
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              onTap: () => _openMapPicker(isPickingUp: false),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmSelection,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('تأكيد الوجهة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 🔥 شاشة اختيار الموقع من الخريطة - تم تعديلها لاستخدام الخرائط المجانية
// ============================================================================
class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;
  final String appBarTitle;

  const MapPickerScreen({
    super.key,
    required this.initialLocation,
    required this.appBarTitle,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late final MapController _mapController;
  Map<String, dynamic>? _selectedData;
  final _addressController = TextEditingController();
  bool _isGeocoding = false;

  // متغير لتجنب كثرة الطلبات عند التحريك السريع
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // جلب العنوان للموقع الأولي عند الفتح
    _fetchAddress(widget.initialLocation);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _addressController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ✅ دالة لتنسيق العنوان وإظهار الجزء المهم فقط
  String _shortenAddress(String longAddress) {
    if (longAddress.isEmpty) return 'مكان غير معروف';

    List<String> parts = longAddress.split(',').map((e) => e.trim()).toList();

    // تنظيف العنوان من الأرقام الطويلة واسم الدولة
    parts.removeWhere((part) =>
    part.contains(RegExp(r'^\d{5,}$')) ||
        part.toLowerCase() == 'iraq' ||
        part.toLowerCase() == 'العراق'
    );

    // إزالة التكرار
    var distinctParts = <String>[];
    for (var part in parts) {
      if (!distinctParts.contains(part)) distinctParts.add(part);
    }

    return distinctParts.take(3).join(', ');
  }

  // ✅ جلب العنوان من خدمة Nominatim المجانية (تم إصلاح الرابط)
  Future<void> _fetchAddress(LatLng point) async {
    if (!mounted) return;

    setState(() => _isGeocoding = true);

    try {
      // ✅ تم إصلاح الرابط: إزالة المسافات الزائدة بين lat= والإحداثيات
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&accept-language=ar'
      );

      final response = await http.get(
          url,
          headers: {'User-Agent': 'com.beytei.taxi'} // مطلوب من Nominatim
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final longAddress = data['display_name'] as String? ?? 'مكان غير معروف';
        final shortAddress = _shortenAddress(longAddress);

        if (mounted) {
          setState(() {
            _addressController.text = shortAddress;
            _selectedData = {
              'name': shortAddress,
              'lat': point.latitude,
              'lng': point.longitude
            };
          });
        }
      } else {
        print('❌ Nominatim Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Geocoding Exception: $e');
      if (mounted) _addressController.text = "خطأ في جلب العنوان";
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appBarTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: () {
                // العودة للموقع الأولي
                _mapController.move(widget.initialLocation, 16);
                _fetchAddress(widget.initialLocation);
              },
              tooltip: 'العودة لموقعي',
            ),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // ✅ الخريطة باستخدام flutter_map وخرائط OpenFreeMap المجانية
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation,
              initialZoom: 16.0,
              maxZoom: 18.0,
              minZoom: 10.0,
              backgroundColor: const Color(0xFFE5E5E5),

              // 🔥 عند توقف حركة الخريطة، اجلب العنوان تلقائياً
              onMapEvent: (MapEvent event) {
                if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                    if (!mounted) return;
                    final center = _mapController.camera.center;
                    _fetchAddress(center);
                  });
                }
              },
            ),
            children: [
              // ✅ طبقة البلاطات - الخرائط المجانية مع نظام الكاش
              TileLayer(
                // 🔥 رابط OpenFreeMap Liberty (نفس الستايل المطلوب)
                urlTemplate: 'https://tiles.openfreemap.org/styles/liberty/{z}/{x}/{y}.png',


                userAgentPackageName: 'com.beytei.taxi',

                // إعدادات السلاسة والأداء
                panBuffer: 2,
                keepBuffer: 5,


              ),
            ],
          ),

          // ✅ أيقونة الدبوس الثابتة في منتصف الشاشة
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: Icon(
              Icons.location_pin,
              size: 50,
              color: Colors.red.shade700,
              shadows: const [
                Shadow(color: Colors.white, blurRadius: 10),
              ],
            ),
          ),

          // ✅ الكارت السفلي مع حقل العنوان وزر التأكيد
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // حقل عرض العنوان
                      TextField(
                        controller: _addressController,
                        readOnly: true,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'جاري تحديد الموقع...',
                          border: InputBorder.none,
                          prefixIcon: _isGeocoding
                              ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2)
                              )
                          )
                              : const Icon(Icons.map, color: Colors.green),
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),

                      // 🔥 زر التأكيد - يجلب العنوان إذا لزم الأمر ثم يغلق الشاشة
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            // 1. نجلب مركز الخريطة الحالي
                            final center = _mapController.camera.center;

                            // 2. إذا كان العنوان قديماً أو غير موجود، نجلبه فوراً
                            if (_selectedData == null ||
                                _selectedData!['lat'] != center.latitude ||
                                _selectedData!['lng'] != center.longitude) {

                              setState(() => _isGeocoding = true);
                              await _fetchAddress(center);
                            }

                            // 3. نغلق الشاشة ونرسل البيانات للشاشة السابقة
                            if (mounted && _selectedData != null) {
                              Navigator.of(context).pop(_selectedData);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.amber[700],
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isGeocoding
                              ? const Text('جاري تحديد العنوان...')
                              : const Text(
                              'تأكيد هذا الموقع',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
