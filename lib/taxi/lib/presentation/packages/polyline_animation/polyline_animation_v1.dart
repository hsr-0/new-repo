import 'dart:io';
import 'package:flutter/material.dart';

import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;
import 'package:latlong2/latlong.dart' as ll;

class PolylineAnimator {
  final Map<String, ml.Line> _bgLines = {};
  final Map<String, ml.Line> _fgLines = {};

  // ✅ استخدام الطريقة الحديثة للألوان
  String _colorToHex(Color color) {
    return "#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}";
  }

  void drawSolidPolyline(
      List<ll.LatLng> points,
      String id,
      Color color,
      Color backgroundColor,
      ml.MapLibreMapController? mapController, { // ✅ حرف L كابيتال
        Function(Set<ap.Polyline>)? onUpdateApple,
      }) async {

    if (points.isEmpty) return;

    // -------------------------------------------------------------------------
    // 🍎 iOS Implementation (Apple Maps)
    // -------------------------------------------------------------------------
    if (Platform.isIOS) {
      if (onUpdateApple == null) return;

      List<ap.LatLng> applePoints = points.map((e) => ap.LatLng(e.latitude, e.longitude)).toList();
      Set<ap.Polyline> polylines = {};

      polylines.add(ap.Polyline(
        polylineId: ap.PolylineId('${id}_bg'),
        points: applePoints,
        color: backgroundColor,
        width: 8,
        jointType: ap.JointType.round,
        // ✅ تم إزالة startCap و endCap لمنع الأخطاء
      ));

      polylines.add(ap.Polyline(
        polylineId: ap.PolylineId('${id}_fg'),
        points: applePoints,
        color: color,
        width: 4,
        jointType: ap.JointType.round,
      ));

      onUpdateApple(polylines);
      return;
    }

    // -------------------------------------------------------------------------
    // 🤖 Android Implementation (MapLibre)
    // -------------------------------------------------------------------------
    if (mapController == null) return;

    List<ml.LatLng> mlPoints = points.map((e) => ml.LatLng(e.latitude, e.longitude)).toList();

    // مسح الخطوط القديمة لنفس المسار
    if (_bgLines.containsKey(id)) {
      await mapController.removeLine(_bgLines[id]!);
    }
    if (_fgLines.containsKey(id)) {
      await mapController.removeLine(_fgLines[id]!);
    }

    ml.Line bgLine = await mapController.addLine(
      ml.LineOptions(
        geometry: mlPoints,
        lineColor: _colorToHex(backgroundColor),
        lineWidth: 8.0,
        lineOpacity: 1.0,
        lineJoin: "round",
      ),
    );

    ml.Line fgLine = await mapController.addLine(
      ml.LineOptions(
        geometry: mlPoints,
        lineColor: _colorToHex(color),
        lineWidth: 4.0,
        lineOpacity: 1.0,
        lineJoin: "round",
      ),
    );

    _bgLines[id] = bgLine;
    _fgLines[id] = fgLine;
  }

  void clearPolylines(ml.MapLibreMapController? mapController) async {
    if (mapController != null) {
      for (var line in _bgLines.values) { await mapController.removeLine(line); }
      for (var line in _fgLines.values) { await mapController.removeLine(line); }
    }
    _bgLines.clear();
    _fgLines.clear();
  }
}