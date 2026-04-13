import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;
import 'package:latlong2/latlong.dart' as ll;

class PolylineAnimator {
  final Map<String, ml.Line> _bgLines = {};
  final Map<String, ml.Line> _fgLines = {};
  Timer? _animationTimer;

  // ✅ استخدام الطريقة الحديثة لتحويل الألوان إلى Hex
  String _colorToHex(Color color) {
    return "#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}";
  }

  // ===========================================================================
  // 1. الدالة الثابتة (في حال أردت رسم مسار عادي بدون حركة)
  // ===========================================================================
  void drawSolidPolyline(
      List<ll.LatLng> points,
      String id,
      Color color,
      Color backgroundColor,
      ml.MapLibreMapController? mapController, {
        Function(Set<ap.Polyline>)? onUpdateApple,
      }) async {

    if (points.isEmpty) return;

    // --- iOS ---
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

    // --- Android ---
    if (mapController == null) return;
    List<ml.LatLng> mlPoints = points.map((e) => ml.LatLng(e.latitude, e.longitude)).toList();

    _clearLinesForId(mapController, id);

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

  // ===========================================================================
  // 2. الدالة السحرية للأنيميشن (المسار المتحرك كما في أوبر)
  // ===========================================================================
  void animatePolyline(
      List<ll.LatLng> points,
      String id,
      Color animateColor,      // لون الخط المتحرك (مثل الأصفر)
      Color backgroundColor,   // اللون الخلفي الثابت (مثل البنفسجي)
      ml.MapLibreMapController? mapController, {
        Function(Set<ap.Polyline>)? onUpdateApple,
      }) async {

    if (points.isEmpty) return;

    // إيقاف أي أنيميشن سابق لتجنب التداخل
    _animationTimer?.cancel();

    // -------------------------------------------------------------------------
    // 🍎 iOS Implementation (Apple Maps)
    // -------------------------------------------------------------------------
    if (Platform.isIOS) {
      if (onUpdateApple == null) return;
      List<ap.LatLng> applePoints = points.map((e) => ap.LatLng(e.latitude, e.longitude)).toList();

      int currentIndex = 0;
      // المسافة التي يغطيها الخط المتحرك (عدد النقاط)
      int segmentLength = (applePoints.length * 0.15).toInt().clamp(5, 20);

      _animationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (currentIndex >= applePoints.length) {
          currentIndex = 0; // إعادة دورة الأنيميشن من البداية
        }

        List<ap.LatLng> animatedSegment = [];
        int end = (currentIndex + segmentLength).clamp(0, applePoints.length);
        animatedSegment = applePoints.sublist(currentIndex, end);

        Set<ap.Polyline> polylines = {};

        // الخط الثابت
        polylines.add(ap.Polyline(
          polylineId: ap.PolylineId('${id}_bg'),
          points: applePoints,
          color: backgroundColor,
          width: 6,
          jointType: ap.JointType.round,
        ));

        // الخط المتحرك
        if (animatedSegment.isNotEmpty) {
          polylines.add(ap.Polyline(
            polylineId: ap.PolylineId('${id}_fg'),
            points: animatedSegment,
            color: animateColor,
            width: 4,
            jointType: ap.JointType.round,
          ));
        }

        onUpdateApple(polylines);
        currentIndex++;
      });
      return;
    }

    // -------------------------------------------------------------------------
    // 🤖 Android Implementation (MapLibre)
    // -------------------------------------------------------------------------
    if (mapController == null) return;
    List<ml.LatLng> mlPoints = points.map((e) => ml.LatLng(e.latitude, e.longitude)).toList();

    _clearLinesForId(mapController, id);

    // رسم الخط الخلفي الثابت مرة واحدة
    ml.Line bgLine = await mapController.addLine(
      ml.LineOptions(
        geometry: mlPoints,
        lineColor: _colorToHex(backgroundColor),
        lineWidth: 6.0,
        lineOpacity: 1.0,
        lineJoin: "round",
      ),
    );
    _bgLines[id] = bgLine;

    // تهيئة الخط المتحرك بنقطة البداية فقط
    ml.Line fgLine = await mapController.addLine(
      ml.LineOptions(
        geometry: [mlPoints.first, mlPoints.first], // نقطة وهمية للبداية
        lineColor: _colorToHex(animateColor),
        lineWidth: 4.0,
        lineOpacity: 1.0,
        lineJoin: "round",
      ),
    );
    _fgLines[id] = fgLine;

    int currentIndex = 0;
    int segmentLength = (mlPoints.length * 0.15).toInt().clamp(5, 20);

    // تشغيل مؤقت لتحديث هندسة الخط المتحرك بسرعة
    _animationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) async {
      if (currentIndex >= mlPoints.length) {
        currentIndex = 0;
      }

      int end = (currentIndex + segmentLength).clamp(0, mlPoints.length);
      List<ml.LatLng> animatedSegment = mlPoints.sublist(currentIndex, end);

      if (animatedSegment.length > 1) {
        // تحديث الخط المتحرك بدلاً من مسحه وإضافته لضمان الأداء العالي
        await mapController.updateLine(
          fgLine,
          ml.LineOptions(geometry: animatedSegment),
        );
      }
      currentIndex++;
    });
  }

  // ===========================================================================
  // دوال التنظيف والحذف
  // ===========================================================================
  void _clearLinesForId(ml.MapLibreMapController mapController, String id) async {
    if (_bgLines.containsKey(id)) {
      await mapController.removeLine(_bgLines[id]!);
      _bgLines.remove(id);
    }
    if (_fgLines.containsKey(id)) {
      await mapController.removeLine(_fgLines[id]!);
      _fgLines.remove(id);
    }
  }

  void clearPolylines(ml.MapLibreMapController? mapController) async {
    _animationTimer?.cancel();
    if (mapController != null) {
      for (var line in _bgLines.values) { await mapController.removeLine(line); }
      for (var line in _fgLines.values) { await mapController.removeLine(line); }
    }
    _bgLines.clear();
    _fgLines.clear();
  }
}