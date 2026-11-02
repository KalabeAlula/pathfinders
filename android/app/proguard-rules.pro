# Flutter and its plugins ship their own consumer rules. The Maps SDK loads
# renderer and style classes through the Android embedding, so keep its
# public surface intact for release builds.
-keep class com.mapbox.** { *; }
-dontwarn com.mapbox.**
