import 'dart:math';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml; // ✅ حرف L كابيتال

class MarkerAnimator {
  // 1. دالة حساب الزاوية (Bearing) لتدوير مقدمة السيارة نحو الشارع
  static double calculateBearing(ml.LatLng start, ml.LatLng end) {
    double lat1 = start.latitude * pi / 180;
    double lng1 = start.longitude * pi / 180;
    double lat2 = end.latitude * pi / 180;
    double lng2 = end.longitude * pi / 180;

    double dLon = lng2 - lng1;
    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    double bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  // 2. دالة الأنيميشن لتحريك الأيقونة بنعومة (الانزلاق)
  static void animateMarker({
    required ml.MapLibreMapController mapController,
    required ml.Symbol symbol,
    required ml.LatLng oldPosition,
    required ml.LatLng newPosition,
    required TickerProvider vsync,
  }) {
    // إذا لم تتغير النقطة، لا داعي للتحريك
    if (oldPosition.latitude == newPosition.latitude && oldPosition.longitude == newPosition.longitude) return;

    // حساب دوران السيارة
    double bearing = calculateBearing(oldPosition, newPosition);

    // تجهيز مؤقت الحركة (مدة الانزلاق ثانية ونصف لتكون ناعمة جداً)
    AnimationController animController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1500),
    );

    Animation<double> animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: animController,
      curve: Curves.linear,
    ));

    // تنفيذ الحركة إطاراً بإطار
    animController.addListener(() {
      double v = animation.value;
      double lng = v * newPosition.longitude + (1 - v) * oldPosition.longitude;
      double lat = v * newPosition.latitude + (1 - v) * oldPosition.latitude;

      // تحديث موقع ودوران السيارة في الخريطة
      mapController.updateSymbol(
        symbol,
        ml.SymbolOptions(
          geometry: ml.LatLng(lat, lng),
          iconRotate: bearing, // توجيه مقدمة السيارة
        ),
      );
    });

    // تنظيف المؤقت عند انتهاء الحركة لمنع استنزاف الرام
    animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animController.dispose();
      }
    });

    animController.forward();
  }
}