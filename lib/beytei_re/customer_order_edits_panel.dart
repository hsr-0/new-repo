import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Read-only. Laravel verifies WP JWT ownership. Never changes money.
class CustomerOrderEditsPanel extends StatefulWidget {
  final int sourceOrderId;
  final String? wpJwt;
  const CustomerOrderEditsPanel({super.key, required this.sourceOrderId, this.wpJwt});
  @override State<CustomerOrderEditsPanel> createState() => _CustomerOrderEditsPanelState();
}

class _CustomerOrderEditsPanelState extends State<CustomerOrderEditsPanel> {
  List<Map<String, dynamic>> _items = const [];
  bool _busy = false;
  @override void initState() { super.initState(); _refresh(); }
  @override void didUpdateWidget(covariant CustomerOrderEditsPanel old) {
    super.didUpdateWidget(old);
    if (old.sourceOrderId != widget.sourceOrderId || old.wpJwt != widget.wpJwt) _refresh();
  }
  Future<void> _refresh() async {
    final jwt = widget.wpJwt;
    if (widget.sourceOrderId < 1 || jwt == null || jwt.isEmpty) {
      if (mounted) setState(() => _items = const []);
      return;
    }
    if (mounted) setState(() => _busy = true);
    try {
      final uri = Uri.parse('https://de.beytei.com/api/beytei/customer/v42/orders/' +
          widget.sourceOrderId.toString() + '/edits');
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer ' + jwt, 'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        if (mounted) setState(() => _items = const []);
        return;
      }
      final data = jsonDecode(response.body);
      if (data is! Map || data['success'] != true ||
          data['financial_effect'] != 'none_until_reconciliation') {
        if (mounted) setState(() => _items = const []);
        return;
      }
      final rows = data['edits'] is List
          ? (data['edits'] as List).whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      if (mounted) setState(() => _items = rows);
    } catch (_) {
      if (mounted) setState(() => _items = const []);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  String _action(String? a) {
    if (a == 'add_item') return 'إضافة مقترحة';
    if (a == 'remove_item') return 'إزالة مقترحة';
    if (a == 'change_price') return 'تعديل سعر مقترح';
    return 'تعديل';
  }
  String _status(String? s) {
    if (s == 'reviewed') return 'تمت مراجعة الإثبات دون تعديل مالي';
    if (s == 'rejected') return 'مرفوض';
    return 'قيد المراجعة';
  }
  @override Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    return Card(
      color: const Color(0xFFF1F7FC),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('تعديلات المندوب المقترحة',
                style: TextStyle(fontWeight: FontWeight.bold))),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _busy ? null : _refresh),
          ]),
          for (final e in _items)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(
              (e['item_name'] ?? 'منتج').toString() + ' — ' +
              _action(e['action']?.toString()) + ' (' +
              _status(e['status']?.toString()) + ')',
            )),
          const Text('هذه تعديلات للمراجعة فقط. المبلغ المؤكد لم يتغير. '
              'لا تدفع زيادة إلا بعد موافقة رسمية من المنصة.',
              style: TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }
}
