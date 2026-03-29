# Flutter default keep rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# OkHttp3 — referenced by uCrop (image_cropper) for optional download feature.
# Keep the interface so R8 does not fail when it sees the reference.
-keep interface okhttp3.Call { *; }
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# uCrop
-dontwarn com.yalantis.ucrop.**
-keep class com.yalantis.ucrop.** { *; }
