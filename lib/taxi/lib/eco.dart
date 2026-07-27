import 'package:pusher_client/pusher_client.dart';

/// متغير عام باسم 'echo' ليتوافق مع الكود
PusherClient? echo;

void initEchoService() {
  if (echo != null) return;

  echo = PusherClient(
    'nyxiq8d6adwi1aeupyz6', // مفتاحك الحقيقي
    PusherOptions(
      host: 'taxi.beytei.com',
      encrypted: true,
      cluster: 'mt1',
    ),
  );

  print("✅ تم تهيئة اتصال Echo (Reverb) بنجاح");
}