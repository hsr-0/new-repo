import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/method.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/url_container.dart';
import 'package:cosmetic_store/taxi/lib/data/services/api_client.dart';

/// A five-minute, passenger-approved fare increase only; server decides the price.
class RideFareIncreaseCard extends StatefulWidget {
  final String rideId;
  const RideFareIncreaseCard({super.key, required this.rideId});
  @override
  State<RideFareIncreaseCard> createState() => _RideFareIncreaseCardState();
}
class _RideFareIncreaseCardState extends State<RideFareIncreaseCard> {
  Timer? _timer;
  bool _busy = false, _available = false;
  double _amount = 0;
  int _version = 0;
  List<int> _choices = [];
  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  Future<void> _load() async {
    if (_busy || !Get.isRegistered<ApiClient>()) return;
    _busy = true;
    try {
      final response = await Get.find<ApiClient>().request(
        UrlContainer.baseUrl + 'ride/dispatch/' + widget.rideId,
        Method.getMethod, null, passHeader: true);
      if (response.statusCode != 200) return;
      final data = response.responseJson['data'];
      if (!mounted || data is! Map) return;
      setState(() {
        _available = data['can_increase_fare'] == true;
        _amount = double.tryParse(data['amount'].toString()) ?? 0;
        _version = int.tryParse(data['price_version'].toString()) ?? 0;
        _choices = data['increase_choices'] is List
          ? (data['increase_choices'] as List).map((v) => int.tryParse(v.toString()) ?? 0)
              .where((v) => v > 0).toList() : [];
      });
    } catch (_) {} finally { _busy = false; }
  }
  Future<void> _increase(int delta) async {
    if (_busy) return;
    _busy = true;
    try {
      final response = await Get.find<ApiClient>().request(
        UrlContainer.baseUrl + 'ride/dispatch/' + widget.rideId + '/increase',
        Method.postMethod, {'increase_amount': delta, 'price_version': _version},
        passHeader: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        response.statusCode == 200 && response.responseJson['status'] == 'success'
          ? 'تم تحديث الأجرة وإعادة إرسال الطلب للسائقين' : 'تعذر تحديث الأجرة. حدّث الطلب وأعد المحاولة')));
    } catch (_) {} finally {
      _busy = false;
      await _load();
    }
  }
  @override
  Widget build(BuildContext context) {
    if (!_available || _choices.isEmpty) return const SizedBox.shrink();
    return Material(elevation: 5, borderRadius: BorderRadius.circular(14),
      child: Padding(padding: const EdgeInsets.all(12), child: Column(
        mainAxisSize: MainAxisSize.min, children: [
          const Text('ما زلنا نبحث عن سائق', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('الأجرة الحالية ' + _amount.toStringAsFixed(0) + ' د.ع. الزيادة اختيارية.'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final x in _choices.take(3))
              OutlinedButton(onPressed: _busy ? null : () => _increase(x),
                child: Text('+ ' + x.toString() + ' د.ع')),
          ]),
        ],
      )));
  }
}
