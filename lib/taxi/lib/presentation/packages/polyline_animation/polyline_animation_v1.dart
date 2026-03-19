import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;
import 'package:latlong2/latlong.dart' as ll;
import 'package:cosmetic_store/taxi/lib/core/utils/my_color.dart';

class PolylineAnimator {
  final Map<String, Timer> _polylinesTimers = {};

  // تخزين مراجع الخطوط النشطة للأندرويد (في MapLibre نستخدم Line)
  final Map<String, ml.Line> _activeLines = {};

  // دالة مساعدة لتحويل الألوان لنسق يقبله MapLibre (Hex String)
  String _colorToHex(Color color) {
    return "#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}";
  }

  void animatePolyline(
      List<ll.LatLng> points,
      String id,
      Color color,
      Color backgroundColor,
      ml.MaplibreMapController? mapController, {
        Function(Set<ap.Polyline>)? onUpdateApple,
      }) async {

    // إلغاء أي مؤقت سابق لنفس المسار لمنع تداخل الأنيميشن
    _polylinesTimers[id]?.cancel();

    if (points.isEmpty) return;

    // -------------------------------------------------------------------------
    // 🍎 iOS Implementation (Apple Maps)
    // -------------------------------------------------------------------------
    if (Platform.isIOS) {
      if (onUpdateApple == null) return;

      List<ap.LatLng> allApplePoints = points.map((e) => ap.LatLng(e.latitude, e.longitude)).toList();

      int forwardIndex = 0;
      int backwardIndex = -1;
      List<ap.LatLng> currentPoints = [];

      Timer timer = Timer.periodic(const Duration(milliseconds: 50), (Timer timer) {
        if (forwardIndex < allApplePoints.length) {
          currentPoints.add(allApplePoints[forwardIndex]);
          forwardIndex++;
        }

        if (forwardIndex > allApplePoints.length / 2 && backwardIndex < forwardIndex - 1) {
          backwardIndex = (backwardIndex == -1) ? 0 : backwardIndex;
          if (backwardIndex < forwardIndex) {
            if (currentPoints.isNotEmpty) currentPoints.removeAt(0);
            backwardIndex++;
          }
        }

        if (backwardIndex >= forwardIndex - 1) {
          forwardIndex = 0;
          backwardIndex = -1;
          currentPoints.clear();
        }

        Set<ap.Polyline> polylines = {};

        // 1. رسم الحدود العريضة (الطبقة السفلية)
        polylines.add(ap.Polyline(
          polylineId: ap.PolylineId('${id}_border'),
          points: allApplePoints,
          color: MyColor.primaryColor,
          width: 8, // خط عريض ليتطابق مع القديم
          jointType: ap.JointType.round,
        ));

        // 2. رسم الخلفية الفاتحة (الطبقة الوسطى)
        polylines.add(ap.Polyline(
          polylineId: ap.PolylineId('${id}_bg'),
          points: allApplePoints,
          color: backgroundColor,
          width: 5,
          jointType: ap.JointType.round,
        ));

        // 3. الخط المتحرك (الطبقة العلوية)
        if (currentPoints.length >= 2) {
          polylines.add(ap.Polyline(
            polylineId: ap.PolylineId('${id}_moving'),
            points: List.from(currentPoints),
            color: color,
            width: 5,
            jointType: ap.JointType.round,
          ));
        }

        onUpdateApple(polylines);
      });

      _polylinesTimers[id] = timer;
      return;
    }

    // -------------------------------------------------------------------------
    // 🤖 Android Implementation (MapLibre)
    // -------------------------------------------------------------------------
    if (mapController == null) return;

    List<ml.LatLng> allmlPoints = points.map((e) => ml.LatLng(e.latitude, e.longitude)).toList();

    String primaryHex = _colorToHex(MyColor.primaryColor);
    String bgHex = _colorToHex(backgroundColor);
    String fgHex = _colorToHex(color);

    // --- 1. رسم الحدود (Border) ---
    await mapController.addLine(
      ml.LineOptions(
        geometry: allmlPoints,
        lineColor: primaryHex,
        lineWidth: 6.0, // زيادة السماكة قليلاً لتبدو مثل القديم
        lineOpacity: 1.0,
        lineJoin: "round", // يحافظ على انحناءات الشوارع الناعمة
      ),
    );

    // --- 2. رسم الخلفية (Background) ---
    await mapController.addLine(
      ml.LineOptions(
        geometry: allmlPoints,
        lineColor: bgHex,
        lineWidth: 5.0, // زيادة السماكة
        lineOpacity: 1.0,
        lineJoin: "round",
      ),
    );

    // --- 3. الخط المتحرك (Animation) ---
    // يجب تمرير نقطتين على الأقل لتجنب تعطل MapLibre
    ml.Line movingLine = await mapController.addLine(
      ml.LineOptions(
        geometry: [allmlPoints[0], allmlPoints[0]],
        lineColor: fgHex,
        lineWidth: 5.0, // مطابقة سماكة الخلفية
        lineOpacity: 1.0,
        lineJoin: "round",
      ),
    );

    int forwardIndex = 0;
    int backwardIndex = -1;
    List<ml.LatLng> currentMlPoints = [];

    // سرعة 50ms تعطي أنيميشن سريع ومريح للعين، مطابق للنسخة القديمة
    Timer timer = Timer.periodic(const Duration(milliseconds: 50), (Timer timer) async {

      // التأكد من أن الخط لا يزال موجوداً على الخريطة
      if (!_activeLines.containsKey(id)) {
        timer.cancel();
        return;
      }

      if (forwardIndex < allmlPoints.length) {
        currentMlPoints.add(allmlPoints[forwardIndex]);
        forwardIndex++;
      }

      if (forwardIndex > allmlPoints.length / 2 && backwardIndex < forwardIndex - 1) {
        backwardIndex = (backwardIndex == -1) ? 0 : backwardIndex;
        if (backwardIndex < forwardIndex) {
          if (currentMlPoints.isNotEmpty) currentMlPoints.removeAt(0);
          backwardIndex++;
        }
      }

      if (backwardIndex >= forwardIndex - 1) {
        forwardIndex = 0;
        backwardIndex = -1;
        currentMlPoints.clear();
      }

      List<ml.LatLng> validGeometry = currentMlPoints.length >= 2
          ? currentMlPoints
          : (currentMlPoints.isNotEmpty ? [currentMlPoints[0], currentMlPoints[0]] : [allmlPoints[0], allmlPoints[0]]);

      await mapController.updateLine(movingLine, ml.LineOptions(geometry: validGeometry));
    });

    _polylinesTimers[id] = timer;
    _activeLines[id] = movingLine;
  }

  void dispose() {
    for (var timer in _polylinesTimers.values) {
      timer.cancel();
    }
    _polylinesTimers.clear();

    // في حال أردنا إضافة كود مسح الخطوط يدوياً من الخريطة لاحقاً
    _activeLines.clear();
  }
}