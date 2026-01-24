# --- قواعد التطبيق الحديث (TIKA & XML) ---
-keep class org.apache.tika.** { *; }
-keep class javax.xml.stream.XMLResolver.** { *; }
-dontwarn javax.xml.stream.XMLInputFactory
-dontwarn javax.xml.stream.XMLResolver
-dontwarn org.osgi.**
-dontwarn aQute.bnd.annotation.**

# --- قواعد تطبيق منصة بيتي (بوابات الدفع والتشفير) ---
-dontwarn com.google.errorprone.annotations.CanIgnoreReturnValue
-dontwarn com.google.errorprone.annotations.CheckReturnValue
-dontwarn com.google.errorprone.annotations.Immutable
-dontwarn com.google.errorprone.annotations.RestrictedApi
-dontwarn javax.annotation.Nullable
-dontwarn javax.annotation.concurrent.GuardedBy
-dontwarn org.bouncycastle.jce.provider.BouncyCastleProvider
-dontwarn org.bouncycastle.pqc.jcajce.provider.BouncyCastlePQCProvider
-keep class org.xmlpull.v1.** { *; }

# قواعد Stripe
-dontwarn com.stripe.**
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider

# قواعد Razorpay
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-keepclasseswithmembers class * {
  public void onPayment*(...);
}

# إعدادات عامة للحماية والتوافق
-keepattributes *Annotation*
-ignorewarnings
-optimizations !method/inlining/