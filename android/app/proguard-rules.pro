# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Keep Google ML Kit classes
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Keep ML Kit Chinese text recognition
-dontwarn com.google.mlkit.vision.text.chinese.**
-keep class com.google.mlkit.vision.text.chinese.** { *; }

# Keep ML Kit Devanagari text recognition
-dontwarn com.google.mlkit.vision.text.devanagari.**
-keep class com.google.mlkit.vision.text.devanagari.** { *; }

# Keep ML Kit Japanese text recognition
-dontwarn com.google.mlkit.vision.text.japanese.**
-keep class com.google.mlkit.vision.text.japanese.** { *; }

# Keep ML Kit Korean text recognition
-dontwarn com.google.mlkit.vision.text.korean.**
-keep class com.google.mlkit.vision.text.korean.** { *; }

# Keep ML Kit Vietnamese text recognition
-dontwarn com.google.mlkit.vision.text.vietnamese.**
-keep class com.google.mlkit.vision.text.vietnamese.** { *; }

# Keep Tesseract OCR
-keep class com.googlecode.tesseract.android.** { *; }
-dontwarn com.googlecode.tesseract.android.**

# Keep Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep AWS SDK
-keep class com.amazonaws.** { *; }
-dontwarn com.amazonaws.**

# Keep file picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Google Play Core
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Kotlin
-dontwarn kotlin.**
-keep class kotlin.** { *; }
