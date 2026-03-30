# ============================================================
# TAMBAHKAN DEPENDENCIES INI KE pubspec.yaml KAMU
# ============================================================

# Tambahkan di bawah "dependencies:"
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase (kemungkinan sudah ada)
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  firebase_database: ^10.4.0  # Untuk Realtime Database
  
  # UI Components (optional tapi recommended)
  # pinput: ^3.0.1  # Untuk OTP input yang lebih bagus (optional)


# ============================================================
# SETELAH EDIT pubspec.yaml, JALANKAN:
# ============================================================
# flutter pub get


# ============================================================
# STRUKTUR FILE YANG PERLU DITAMBAHKAN:
# ============================================================
#
# lib/
# ├── services/
# │   └── auth_service.dart       ← COPY dari folder ini
# ├── screens/
# │   ├── splash_screen.dart      ← COPY dari folder ini
# │   ├── login_screen.dart       ← COPY dari folder ini
# │   └── otp_screen.dart         ← COPY dari folder ini
# ├── widgets/
# │   └── auth_widgets.dart       ← COPY dari folder ini
# └── main.dart                   ← UPDATE routing (lihat main_example.dart)
#
# ============================================================


# ============================================================
# CARA PAKAI:
# ============================================================
#
# 1. Copy semua file dari folder ini ke project kamu
#
# 2. Update main.dart kamu dengan routes:
#    - '/' → SplashScreen
#    - '/login' → LoginScreen  
#    - '/dashboard' → DashboardScreen (yang sudah ada)
#
# 3. Import auth_service di dashboard untuk logout:
#    import 'services/auth_service.dart';
#    
#    // Untuk logout:
#    await AuthService.signOut();
#    Navigator.pushReplacementNamed(context, '/login');
#
# 4. Run: flutter pub get
#
# 5. Run: flutter run
#
# ============================================================
