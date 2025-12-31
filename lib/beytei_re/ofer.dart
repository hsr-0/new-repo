
import 'package:flutter/material.dart';




class Offer {
  final int id;             // رقم العرض
  final int restaurantId;   // رقم المطعم (عشان لما نضغط البنر نروح له)
  final String title;       // العنوان: عرض الكنتاكي العائلي
  final String description; // التفاصيل: 6 قطع، بيبسي، صاج...
  final String imageUrl;    // رابط الصورة
  final double price;       // السعر: 16000

  Offer({
    required this.id,
    required this.restaurantId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
  });
}

class ModernOfferCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback onTap;      // عند الضغط على البطاقة (للتنقل)
  final VoidCallback onOrderNow; // عند الضغط على زر "أطلب الآن"

  const ModernOfferCard({
    Key? key,
    required this.offer,
    required this.onTap,
    required this.onOrderNow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(10), // مسافة خارجية
        width: 320, // عرض البطاقة
        height: 220, // ارتفاع البطاقة
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), // زوايا دائرية ناعمة
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)), // ظل خفيف
          ],
          image: DecorationImage(
            image: NetworkImage(offer.imageUrl),
            fit: BoxFit.cover, // الصورة تغطي كامل البطاقة
          ),
        ),
        child: Stack(
          children: [
            // 1. طبقة سوداء شفافة لكي يظهر النص بوضوح
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1), // شفاف من الأعلى
                    Colors.black.withOpacity(0.9), // أسود غامق من الأسفل
                  ],
                ),
              ),
            ),

            // 2. النصوص والتفاصيل
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end, // المحتوى في الأسفل
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان
                  Text(
                    offer.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  // التفاصيل (6 قطع، بيبسي...)
                  Text(
                    offer.description,
                    maxLines: 2, // سطرين فقط والباقي نقط ...
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      height: 1.4, // تباعد بين الأسطر
                    ),
                  ),

                  const SizedBox(height: 15),

                  // السطر الأخير: السعر وزر الطلب
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // السعر بتصميم مميز
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2), // خلفية ذهبية شفافة
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber), // إطار ذهبي
                        ),
                        child: Text(
                          "${offer.price.toStringAsFixed(0)} د.ع",
                          style: const TextStyle(
                            color: Colors.amber, // لون ذهبي
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),

                      // زر أطلب الآن
                      ElevatedButton(
                        onPressed: onOrderNow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: const StadiumBorder(), // شكل كبسولة
                        ),
                        child: const Text("أطلب الآن 🛒", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // شريط "عرض خاص" في الزاوية العلوية
            Positioned(
              top: 15,
              right: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("عرض نار 🔥", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
