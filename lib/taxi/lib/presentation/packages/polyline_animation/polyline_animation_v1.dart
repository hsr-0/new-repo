import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'; // ✅ مكتبة Mapbox
import 'package:latlong2/latlong.dart'; // ✅ للإبقاء على توافق البيانات
import 'package:cosmetic_store/taxi/lib/core/utils/my_color.dart';

class PolylineAnimator {
  final Map<String, Timer> _polylinesTimers = {};

  // تخزين مراجع الخطوط النشطة
  final Map<String, PolylineAnnotation> _activeAnnotations = {};

  void animatePolyline(
      List<LatLng> points,
      String id,
      Color color,
      Color backgroundColor,
      PolylineAnnotationManager? annotationManager,
      ) async {
    if (annotationManager == null || points.isEmpty) return;

    _polylinesTimers[id]?.cancel();

    // ✅ تصحيح 1: تحويل النقاط إلى List<Position> مباشرة
    // لأن LineString يحتاج Position وليس Point
    List<Position> allMapboxPositions = points.map((e) {
      return Position(e.longitude, e.latitude); // Longitude, Latitude
    }).toList();

    String borderId = '${id}_border';
    String backgroundId = '${id}_background';
    String foregroundId = '${id}_foreground';

    // --- 1. رسم الحدود (Border) ---
    var borderOptions = PolylineAnnotationOptions(
      geometry: LineString(coordinates: allMapboxPositions), // ✅ الآن يقبلها لأنها Positions
      lineColor: MyColor.primaryColor.value,
      lineWidth: 5.0,
      lineOpacity: 1.0,
    );
    await annotationManager.create(borderOptions);

    // --- 2. رسم الخلفية (Background) ---
    var backgroundOptions = PolylineAnnotationOptions(
      geometry: LineString(coordinates: allMapboxPositions),
      lineColor: backgroundColor.value,
      lineWidth: 4.0,
      lineOpacity: 1.0,
    );
    await annotationManager.create(backgroundOptions);

    // --- 3. الخط المتحرك (Animation) ---
    var movingOptions = PolylineAnnotationOptions(
      geometry: LineString(coordinates: []), // يبدأ فارغاً
      lineColor: color.value,
      lineWidth: 4.0,
      lineOpacity: 1.0,
    );

    PolylineAnnotation movingAnnotation = await annotationManager.create(movingOptions);
    _activeAnnotations[foregroundId] = movingAnnotation;

    // --- المؤقت (Timer) ---
    int forwardIndex = 0;
    int backwardIndex = -1;

    // ✅ تصحيح 2: القائمة المستخدمة للرسم يجب أن تكون Positions
    List<Position> currentPositions = [];

    Timer timer = Timer.periodic(const Duration(milliseconds: 50), (Timer timer) async {
      if (_activeAnnotations[foregroundId] == null) {
        timer.cancel();
        return;
      }

      // إضافة نقطة جديدة
      if (forwardIndex < allMapboxPositions.length) {
        currentPositions.add(allMapboxPositions[forwardIndex]);
        forwardIndex++;
      }

      // حذف من الخلف (تأثير الذيل)
      if (forwardIndex > allMapboxPositions.length / 2 && backwardIndex < forwardIndex - 1) {
        backwardIndex = (backwardIndex == -1) ? 0 : backwardIndex;
        if (backwardIndex < forwardIndex) {
          if (currentPositions.isNotEmpty) {
            currentPositions.removeAt(0);
          }
          backwardIndex++;
        }
      }

      // إعادة التكرار
      if (backwardIndex >= forwardIndex - 1) {
        forwardIndex = 0;
        backwardIndex = -1;
        currentPositions.clear();
      }

      // 🔥 تحديث الرسم
      // ✅ تصحيح 3: إسناد LineString مباشرة (بدون .toJson)
      movingAnnotation.geometry = LineString(coordinates: currentPositions);

      await annotationManager.update(movingAnnotation);

    });

    _polylinesTimers[id] = timer;
  }

  void dispose() {
    _polylinesTimers.forEach((id, timer) {
      timer.cancel();
    });
    _polylinesTimers.clear();
    _activeAnnotations.clear();
  }
}