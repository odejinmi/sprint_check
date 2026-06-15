# Proguard rules for sprint_check SDK

# Keep GetX classes
-keep class com.getx.** { *; }

# Keep ML Kit classes
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep Flutter Face API classes
-keep class com.regula.** { *; }

# Keep Dio classes
-keep class com.dio.** { *; }

# Ignore Play Core warnings (referenced by Flutter embedding for deferred components)
-dontwarn com.google.android.play.core.**

# Preserve Line Numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
