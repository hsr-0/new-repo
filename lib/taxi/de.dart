import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

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
    final initialPoint = isPickingUp ? _pickupLocation : (_destinationData != null ? LatLng(_destinationData!['lat'], _destinationData!['lng']) : _pickupLocation);

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

// --- (شاشة الخريطة): الواجهة التفاعلية التي يتم فتحها ---
class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;
  final String appBarTitle;
  const MapPickerScreen({super.key, required this.initialLocation, required this.appBarTitle});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late final MapController _mapController;
  Map<String, dynamic>? _selectedData;
  final _addressController = TextEditingController();
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchAddress(widget.initialLocation);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _shortenAddress(String longAddress) {
    if (longAddress.isEmpty) return 'مكان غير معروف';
    List<String> parts = longAddress.split(',').map((e) => e.trim()).toList();
    parts.removeWhere((part) => part.contains(RegExp(r'^\d{5,}$')) || part.toLowerCase() == 'iraq' || part.toLowerCase() == 'العراق');
    var distinctParts = <String>[];
    for (var part in parts) {
      if (!distinctParts.contains(part)) distinctParts.add(part);
    }
    return distinctParts.take(3).join(', ');
  }

  Future<void> _fetchAddress(LatLng point) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&accept-language=ar');
      final response = await http.get(url, headers: {'User-Agent': 'com.beytei.taxi'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final longAddress = data['display_name'] as String? ?? 'مكان غير معروف';
        final shortAddress = _shortenAddress(longAddress);
        if (mounted) {
          _addressController.text = shortAddress;
          _selectedData = {'name': shortAddress, 'lat': point.latitude, 'lng': point.longitude};
        }
      }
    } catch (e) {
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.gps_fixed),
              onPressed: () {
                final centerPoint = _mapController.camera.center;
                _fetchAddress(centerPoint);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم تثبيت العنوان"), backgroundColor: Colors.green),
                );
              },
              tooltip: 'تثبيت العنوان المحدد تحت الدبوس',
            ),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: widget.initialLocation, initialZoom: 16.0),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.beytei.taxi',
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: Icon(Icons.location_pin, size: 50, color: Colors.red.shade700),
          ),
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
                      TextField(
                        controller: _addressController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'حرك الخريطة وثبت الموقع...',
                          prefixIcon: _isGeocoding
                              ? const Padding(padding: EdgeInsets.all(14.0), child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.flag_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_selectedData != null) {
                              Navigator.of(context).pop(_selectedData);
                            }
                          },
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('تأكيد هذا الموقع'),
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