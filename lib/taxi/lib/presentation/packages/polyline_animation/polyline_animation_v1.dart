import 'dart:async';
import 'dart:io'; // ✅ لتحديد نوع النظام

import 'package:flutter/material.dart';

// ✅ استيراد المكتبات بأسماء مستعارة لتجنب تضارب الأسماء (Polyline)
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as ap;

import 'package:latlong2/latlong.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_color.dart';

class PolylineAnimator {
  final Map<String, Timer> _polylinesTimers = {};

  // تخزين مراجع الخطوط النشطة للأندرويد
  final Map<String, mb.PolylineAnnotation> _activeAnnotations = {};

  /// دالة التحريك الموحدة
  void animatePolyline(
      List<LatLng> points,
      String id,
      Color color,
      Color backgroundColor,
      mb.PolylineAnnotationManager? annotationManager, {
        // ✅ معامل جديد اختياري خاص بالآيفون لتحديث الواجهة
        Function(Set<ap.Polyline>)? onUpdateApple,
      }) async {

    // إلغاء أي مؤقت سابق لنفس المسار
    _polylinesTimers[id]?.cancel();

    if (points.isEmpty) return;

    // -------------------------------------------------------------------------
    // 🍎 iOS Implementation (Apple Maps)
    // -------------------------------------------------------------------------
    if (Platform.isIOS) {
      if (onUpdateApple == null) return; // لا يمكن التحريك بدون دالة التحديث

      // تحويل النقاط لنسق أبل
      List<ap.LatLng> allApplePoints = points.map((e) => ap.LatLng(e.latitude, e.longitude)).toList();

      int forwardIndex = 0;
      int backwardIndex = -1;
      List<ap.LatLng> currentPoints = [];

      Timer timer = Timer.periodic(const Duration(milliseconds: 50), (Timer timer) {

        // 1. منطق تحريك النقاط (نفس المنطق)
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

        // 2. إنشاء مجموعة الخطوط (Border + Main + Animation)
        Set<ap.Polyline> polylines = {};

        // الخلفية الثابتة (الطريق كاملاً)
        polylines.add(ap.Polyline(
          polylineId: ap.PolylineId('${id}_bg'),
          points: allApplePoints,
          color: backgroundColor.withOpacity(0.5),
          width: 6,
        ));

        // الخط المتحرك
        if (currentPoints.isNotEmpty) {
          polylines.add(ap.Polyline(
            polylineId: ap.PolylineId('${id}_moving'),
            points: List.from(currentPoints), // نسخة جديدة
            color: color,
            width: 6,
            jointType: ap.JointType.round,
          ));
        }

        // 3. إرسال التحديث للشاشة
        onUpdateApple(polylines);
      });

      _polylinesTimers[id] = timer;
      return;
    }

    // -------------------------------------------------------------------------
    // 🤖 Android Implementation (Mapbox)
    // -------------------------------------------------------------------------
    if (annotationManager == null) return;

    // تحويل النقاط لنسق Mapbox (Positions)
    List<mb.Position> allMapboxPositions = points.map((e) {
      return mb.Position(e.longitude, e.latitude);
    }).toList();

    String foregroundId = '${id}_foreground';

    // 1. رسم الحدود (Border)
    var borderOptions = mb.PolylineAnnotationOptions(
      geometry: mb.LineString(coordinates: allMapboxPositions),
      lineColor: MyColor.primaryColor.value,
      lineWidth: 5.0,
      lineOpacity: 1.0,
    );
    await annotationManager.create(borderOptions);

    // 2. رسم الخلفية (Background)
    var backgroundOptions = mb.PolylineAnnotationOptions(
      geometry: mb.LineString(coordinates: allMapboxPositions),
      lineColor: backgroundColor.value,
      lineWidth: 4.0,
      lineOpacity: 1.0,
    );
    await annotationManager.create(backgroundOptions);

    // 3. الخط المتحرك (البداية فارغة)
    var movingOptions = mb.PolylineAnnotationOptions(
      geometry: mb.LineString(coordinates: []),
      lineColor: color.value,
      lineWidth: 4.0,
      lineOpacity: 1.0,
    );

    mb.PolylineAnnotation movingAnnotation = await annotationManager.create(movingOptions);
    _activeAnnotations[foregroundId] = movingAnnotation;

    // المؤقت
    int forwardIndex = 0;
    int backwardIndex = -1;
    List<mb.Position> currentPositions = [];

    Timer timer = Timer.periodic(const Duration(milliseconds: 50), (Timer timer) async {
      // التحقق من أن الخط لا يزال موجوداً
      /* ملاحظة: Mapbox أحياناً يفقد المرجع عند إعادة البناء السريع،
         لذا نتحقق فقط من المؤقت */
      if (!timer.isActive) return;

      if (forwardIndex < allMapboxPositions.length) {
        currentPositions.add(allMapboxPositions[forwardIndex]);
        forwardIndex++;
      }

      if (forwardIndex > allMapboxPositions.length / 2 && backwardIndex < forwardIndex - 1) {
        backwardIndex = (backwardIndex == -1) ? 0 : backwardIndex;
        if (backwardIndex < forwardIndex) {
          if (currentPositions.isNotEmpty) currentPositions.removeAt(0);
          backwardIndex++;
        }
      }

      if (backwardIndex >= forwardIndex - 1) {
        forwardIndex = 0;
        backwardIndex = -1;
        currentPositions.clear();
      }

      // تحديث الرسم
      movingAnnotation.geometry = mb.LineString(coordinates: currentPositions);
      try {
        await annotationManager.update(movingAnnotation);
      } catch (e) {
        // تجاهل الخطأ في حال تم حذف المانجر أثناء الأنيميشن
        timer.cancel();
      }
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