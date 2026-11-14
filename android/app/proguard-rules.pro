# Flutter 엔진 및 플러그인 브리지 클래스 보존
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.engine.FlutterJNI { *; }
-keep class io.flutter.embedding.engine.FlutterJNI$** { *; }

# 미사용 Deferred Components(Play Core) 참조 경고 억제
-dontwarn com.google.android.play.core.**

# 앱 메인 액티비티 보존
-keep class com.grepiu.yeoju_cy_manager.MainActivity { *; }

# flutter_secure_storage 암호화 알고리즘 Enum 이름 보존 (SharedPreferences 키 호환성)
-keep class com.it_nomads.fluttersecurestorage.ciphers.** { *; }

# 난독화 강화: 난독화된 클래스를 단일 패키지로 재배치
-repackageclasses 'o'

# 스택트레이스 역난독화(Play Console mapping.txt)를 위한 줄 번호 보존 및 원본 파일명 은닉
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# 릴리즈 빌드에서 디버그/상세 로그 제거
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
}
