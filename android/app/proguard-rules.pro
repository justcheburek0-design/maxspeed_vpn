# MaxSpeed VPN — ProGuard Rules
# Keep all application classes and members used by reflection or serialization

# Keep the application class
-keep class com.maxspeed.vpn.MaxSpeedApp { *; }

# Keep all model/data classes used in JSON serialization
-keep class com.maxspeed.vpn.data.model.** { *; }
-keep class com.maxspeed.vpn.data.dto.** { *; }

# Keep Retrofit interfaces and service classes
-keep interface com.maxspeed.vpn.data.api.** { *; }
-keep class com.maxspeed.vpn.data.api.** { *; }

# Keep Gson serialization
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep OkHttp and Okio
-dontwarn okhttp3.**
-dontwarn okio.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Keep WireGuard tunnel classes
-keep class com.maxspeed.vpn.tunnel.** { *; }
-keep class com.wireguard.android.** { *; }
-dontwarn com.wireguard.android.**

# Keep OpenVPN classes
-keep class com.maxspeed.vpn.openvpn.** { *; }
-keep class org.openvpn.** { *; }
-dontwarn org.openvpn.**

# Keep billing / in-app purchase classes
-keep class com.android.billingclient.** { *; }
-keep class com.maxspeed.vpn.billing.** { *; }

# Keep Firebase / Crashlytics
-keep class com.google.firebase.** { *; }
-keep class com.crashlytics.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.crashlytics.**

# Keep SharedPreferences helpers
-keep class com.maxspeed.vpn.preferences.** { *; }

# Keep broadcast receivers and services declared in manifest
-keep class com.maxspeed.vpn.service.** { *; }
-keep class com.maxspeed.vpn.receiver.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# General Android rules
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Remove debug and verbose logs in release builds
-assumenosideeffects class android.util.Log {
    public static int d(...);
    public static int v(...);
    public static int i(...);
}

# Suppress warnings for third-party libraries
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
