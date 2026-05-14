# ── Flutter ─────────────────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── Google Mobile Ads ────────────────────────────────────────────────────────
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# ── WorkManager ──────────────────────────────────────────────────────────────
-keep class androidx.work.** { *; }
-keep class com.google.gson.** { *; }
-keepnames class androidx.work.impl.** { *; }

# ── Billing / IAP ────────────────────────────────────────────────────────────
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# ── General ──────────────────────────────────────────────────────────────────
-dontwarn org.xmlpull.v1.**
-keep class org.xmlpull.v1.** { *; }
