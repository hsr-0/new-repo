import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:cosmetic_store/taxi/lib/data/controller/home/home_controller.dart';

/// Anonymous, approximate vehicle positions only; no driver IDs exposed.
class NearbyDriversMap extends StatefulWidget {
  final HomeController controller;
  const NearbyDriversMap({super.key, required this.controller});
  @override
  State<NearbyDriversMap> createState() => _NearbyDriversMapState();
}
class _NearbyDriversMapState extends State<NearbyDriversMap> {
  ml.MapLibreMapController? _map;
  Timer? _timer;
  final List<ml.Symbol> _pins = [];
  bool _ready = false, _busy = false, _icons = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
  }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  Future<Uint8List> _asset(String path) async {
    final x = await rootBundle.load(path);
    return x.buffer.asUint8List();
  }
  Future<void> _refresh() async {
    if (!mounted || _busy) return;
    _busy = true;
    try {
      final pickup = widget.controller.selectedLocations.isNotEmpty
          ? widget.controller.selectedLocations.first : null;
      final lat = pickup?.latitude ?? widget.controller.currentPosition?.latitude;
      final lng = pickup?.longitude ?? widget.controller.currentPosition?.longitude;
      if (lat == null || lng == null) return;
      await widget.controller.fetchNearbyDrivers(lat, lng);
      await _map?.animateCamera(ml.CameraUpdate.newLatLng(ml.LatLng(lat, lng)));
      await _draw();
    } finally { _busy = false; }
  }
  Future<void> _draw() async {
    if (_map == null || !_ready) return;
    for (final old in _pins) { try { await _map!.removeSymbol(old); } catch (_) {} }
    _pins.clear();
    if (!_icons) {
      try {
        await _map!.addImage('beytei_car', await _asset('assets/images/car.png'));
        await _map!.addImage('beytei_tuktuk', await _asset('assets/images/tuktuk.png'));
        _icons = true;
      } catch (_) {}
    }
    if (!_icons) return;
    for (final raw in widget.controller.nearbyDrivers) {
      if (raw is! Map) continue;
      final lat = double.tryParse(raw['lat'].toString());
      final lng = double.tryParse(raw['lng'].toString());
      if (lat == null || lng == null) continue;
      try {
        _pins.add(await _map!.addSymbol(ml.SymbolOptions(
          geometry: ml.LatLng(lat, lng),
          iconImage: raw['service_id'].toString() == '1' ? 'beytei_tuktuk' : 'beytei_car',
          iconSize: 0.18,
        )));
      } catch (_) {}
    }
  }
  @override
  Widget build(BuildContext context) {
    final pickup = widget.controller.selectedLocations.isNotEmpty
        ? widget.controller.selectedLocations.first : null;
    final lat = pickup?.latitude ?? widget.controller.currentPosition?.latitude ?? 32.9;
    final lng = pickup?.longitude ?? widget.controller.currentPosition?.longitude ?? 45.1;
    return ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox(height: 260,
      child: Stack(children: [
        ml.MapLibreMap(
          styleString: 'https://tiles.openfreemap.org/styles/liberty',
          initialCameraPosition: ml.CameraPosition(target: ml.LatLng(lat, lng), zoom: 13.5),
          onMapCreated: (c) => _map = c,
          onStyleLoadedCallback: () async { _ready = true; await _draw(); },
          myLocationEnabled: true, compassEnabled: false,
        ),
        const Positioned(top: 12, left: 12, right: 12, child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(12))),
            child: Padding(padding: EdgeInsets.all(10),
              child: Text('المركبات القريبة منك • مواقع تقريبية',
                textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
          ),
        )),
      ]),
    )));
  }
}
