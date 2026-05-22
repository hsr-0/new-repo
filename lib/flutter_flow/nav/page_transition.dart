import 'package:flutter/material.dart';

/// 1. تعريف أنواع الانتقالات لتطابق المكتبة القديمة
enum PageTransitionType {
  fade,
  rightToLeft,
  leftToRight,
  upToDown,
  downToUp,
  scale,
  size,
  rightToLeftWithFade,
  leftToRightWithFade,
}

/// 2. الكلاس الرئيسي البديل
class PageTransition<T> extends PageRouteBuilder<T> {
  final Widget child;
  final PageTransitionType type;
  final Alignment? alignment;
  final Duration duration;
  final Duration reverseDuration;

  PageTransition({
    required this.child,
    required this.type,
    this.alignment,
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration = const Duration(milliseconds: 300),
    super.settings,
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionDuration: duration,
    reverseTransitionDuration: reverseDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {

      // تحديد نقطة البداية بناءً على النوع
      Offset begin = Offset.zero;

      switch (type) {
        case PageTransitionType.rightToLeft:
          begin = const Offset(1.0, 0.0);
          break;
        case PageTransitionType.leftToRight:
          begin = const Offset(-1.0, 0.0);
          break;
        case PageTransitionType.downToUp:
          begin = const Offset(0.0, 1.0);
          break;
        case PageTransitionType.upToDown:
          begin = const Offset(0.0, -1.0);
          break;
        case PageTransitionType.fade:
          return FadeTransition(opacity: animation, child: child);
        case PageTransitionType.scale:
          return ScaleTransition(
            alignment: alignment ?? Alignment.center,
            scale: animation,
            child: child,
          );
        case PageTransitionType.size:
          return Align(
            alignment: alignment ?? Alignment.center,
            child: SizeTransition(
              sizeFactor: animation,
              child: child,
            ),
          );
        case PageTransitionType.rightToLeftWithFade:
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        case PageTransitionType.leftToRightWithFade:
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
      }

      // الافتراضي للانزلاق (Slide)
      return SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        ),
        child: child,
      );
    },
  );
}