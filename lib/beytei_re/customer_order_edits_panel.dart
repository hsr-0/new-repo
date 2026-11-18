import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Show ONLY "غير متوفر" for products reported unavailable.
/// No courier proposal, explanation, price, proof or review is shown to customers.
/// Laravel verifies that the current WP user owns this exact order.
class CustomerOrderEditsPanel extends StatefulWidget {
  final int sourceOrderId;
  final String? wpJwt;
  final ValueChanged<int?>? onTotalChanged;
  const CustomerOrderEditsPanel({
    super.key,
    required this.sourceOrderId,
    this.wpJwt,
    this.onTotalChanged,
  });

  @override
  State<CustomerOrderEditsPanel> createState() => _CustomerOrderEditsPanelState();
}

class _CustomerOrderEditsPanelState extends State<CustomerOrderEditsPanel> {
  List<String> _unavailable = const [];
  Timer? _poll;
  int? _latestConfirmed;

  @override
  void initState() {
    super.initState();
    _load();
    // Only while an order screen is open; never background polling.
    _poll = Timer.periodic(const Duration(seconds: 25), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CustomerOrderEditsPanel old) {
    super.didUpdateWidget(old);
    if (old.sourceOrderId != widget.sourceOrderId || old.wpJwt != widget.wpJwt) {
      setState(() { _unavailable = const []; _latestConfirmed = null; });
      widget.onTotalChanged?.call(null);
      _load();
    }
  }

  Future<void> _load() async {
    final token = widget.wpJwt;
    if (widget.sourceOrderId <= 0 || token == null || token.isEmpty) {
      if (mounted) setState(() => _unavailable = const []);
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('https://de.beytei.com/api/beytei/customer/v42/orders/' +
            widget.sourceOrderId.toString() + '/edits'),
        headers: {
          'Authorization': 'Bearer ' + token,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        if (mounted) setState(() => _unavailable = const []);
        return;
      }
      final data = jsonDecode(response.body);
      if (data is! Map || data['success'] != true ||
          data['financial_effect'] != 'applied_in_laravel' ||
          data['unavailable_items'] is! List) {
        if (mounted) setState(() => _unavailable = const []);
        return;
      }
      final names = (data['unavailable_items'] as List)
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList(growable: false);
      final changed = data['has_applied_changes'] == true;
      final amount = changed
          ? int.tryParse((data['total_to_collect_iqd'] ?? '').toString())
          : null;
      if (mounted) {
        setState(() => _unavailable = names);
        if (_latestConfirmed != amount) {
          _latestConfirmed = amount;
          widget.onTotalChanged?.call(amount);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _unavailable = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unavailable.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Column(
        children: [
          for (final item in _unavailable)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Expanded(child: Text(item,
                      style: const TextStyle(fontWeight: FontWeight.w500))),
                  const SizedBox(width: 8),
                  const Chip(
                    label: Text('غير متوفر'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
