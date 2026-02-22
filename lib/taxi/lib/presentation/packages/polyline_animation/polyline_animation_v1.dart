import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

// ✅ تصحيح الاستيراد لاستخدام MapLibre بدلاً من Mapbox
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;

// مكتبة الإحداثيات العامة
import 'package:latlong2/latlong.dart' as ll;
import 'package:cosmetic_store/taxi/lib/core/utils/my_color.dart';

class PolylineAnimator {
  final Map<String, Timer> _polylinesTimers = {};

  // تخزين مراجع الخطوط النشطة للأندرويد (في MapLibre نستخدم Line)
  final Map<String, ml.Line> _activeLines = {};

  void animatePolyline(
      List<ll.LatLng> points,
      String id,
      Color color,
      Color backgroundColor,
      ml.MaplibreMapController? mapController, {
        Function(Set<ap.Polyline>)? onUpdateApple,
      }) async {

    // إلغاء أي مؤقت سابق لنفس المسار
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

        polylines.add(ap.Polyline(
          polylineId: ap.PolylineId('${id}_bg'),
          points: allApplePoints,
          color: backgroundColor.withOpacity(0.5),
          width: 6,
        ));

        if (currentPoints.isNotEmpty) {
          polylines.add(ap.Polyline(
            polylineId: ap.PolylineId('${id}_moving'),
            points: List.from(currentPoints),
            color: color,
            width: 6,
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

    // تحويل النقاط لنسق MapLibre
    List<ml.LatLng> allmlPoints = points.map((e) => ml.LatLng(e.latitude, e.longitude)).toList();

    // 1. رسم الخلفية الثابتة
    await mapController.addLine(
      ml.LineOptions(
        geometry: allmlPoints,
        lineColor: "#${backgroundColor.value.toRadixString(16).substring(2)}",
        lineWidth: 5.0,
        lineOpacity: 0.5,
      ),
    );

    // 2. إنشاء الخط المتحرك (يبدأ بنقطة واحدة)
    ml.Line movingLine = await mapController.addLine(
      ml.LineOptions(
        geometry: [allmlPoints[0]],
        lineColor: "#${color.value.toRadixString(16).substring(2)}",
        lineWidth: 5.0,
        lineOpacity: 1.0,
      ),
    );

    int forwardIndex = 0;
    int backwardIndex = -1;
    List<ml.LatLng> currentMlPoints = [];

    Timer timer = Timer.periodic(const Duration(milliseconds: 50), (Timer timer) async {
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

      // تحديث إحداثيات الخط في MapLibre
      if (currentMlPoints.isNotEmpty) {
        await mapController.updateLine(movingLine, ml.LineOptions(geometry: currentMlPoints));
      }
    });

    _polylinesTimers[id] = timer;
    _activeLines[id] = movingLine;
  }

  void dispose() {
    for (var timer in _polylinesTimers.values) {
      timer.cancel();
    }
    _polylinesTimers.clear();
    _activeLines.clear();
  }
}