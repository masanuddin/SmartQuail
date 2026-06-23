// Auth Service - Firebase Phone Auth + Anonymous Auth
// ✅ Dipakai oleh: login_screen, otp_screen, splash_screen, settings_screen
// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Simpan verificationId untuk OTP
  static String _verificationId = '';

  // ════════════════════════════════════════════
  //  GETTERS
  // ════════════════════════════════════════════

  /// Stream auth state (untuk AuthWrapper di main.dart)
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// User yang sedang login
  static User? get currentUser => _auth.currentUser;

  /// Apakah sudah login
  static bool get isLoggedIn => _auth.currentUser != null;

  /// Apakah user tamu (anonymous)
  static bool get isGuest => _auth.currentUser?.isAnonymous ?? true;

  // ════════════════════════════════════════════
  //  FORMAT NOMOR TELEPON
  // ════════════════════════════════════════════

  /// Format nomor ke +62xxx
  static String formatPhoneNumber(String phone) {
    phone = phone.trim().replaceAll(RegExp(r'[^\d]'), '');

    // Hapus leading 0
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }
    // Hapus leading 62
    if (phone.startsWith('62')) {
      phone = phone.substring(2);
    }

    return '+62$phone';
  }

  // ════════════════════════════════════════════
  //  PHONE AUTH - KIRIM OTP
  // ════════════════════════════════════════════

  static Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 120),

        // Auto-verify (Android saja)
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);
          } catch (e) {
            onError('Auto-verification gagal: ${e.toString()}');
          }
        },

        // Verifikasi gagal
        verificationFailed: (FirebaseAuthException e) {
          String message;
          switch (e.code) {
            case 'invalid-phone-number':
              message = 'Nomor telepon tidak valid';
              break;
            case 'too-many-requests':
              message = 'Terlalu banyak percobaan. Coba lagi nanti.';
              break;
            case 'quota-exceeded':
              message = 'Kuota SMS habis. Coba lagi besok.';
              break;
            default:
              message = 'Error: ${e.message ?? e.code}';
          }
          onError(message);
        },

        // Kode OTP terkirim
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent(verificationId);
        },

        // Timeout auto-verify
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      onError('Gagal mengirim OTP: ${e.toString()}');
    }
  }

  // ════════════════════════════════════════════
  //  PHONE AUTH - VERIFIKASI OTP
  // ════════════════════════════════════════════

  static Future<Map<String, dynamic>> verifyOTP({
    required String otp,
    String? verificationId,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId ?? _verificationId,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      return {
        'success': true,
        'user': userCredential.user,
        'isNewUser': userCredential.additionalUserInfo?.isNewUser ?? false,
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-verification-code':
          message = 'Kode OTP salah. Coba lagi.';
          break;
        case 'session-expired':
          message = 'Sesi expired. Kirim ulang kode OTP.';
          break;
        default:
          message = 'Verifikasi gagal: ${e.message ?? e.code}';
      }
      return {'success': false, 'error': message};
    } catch (e) {
      return {'success': false, 'error': 'Error: ${e.toString()}'};
    }
  }

  // ════════════════════════════════════════════
  //  PHONE AUTH - KIRIM ULANG OTP
  // ════════════════════════════════════════════

  static Future<void> resendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    await sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
    );
  }

  // ════════════════════════════════════════════
  //  ANONYMOUS AUTH (Tamu)
  // ════════════════════════════════════════════

  static Future<Map<String, dynamic>> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return {
        'success': true,
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': 'Login tamu gagal: ${e.message ?? e.code}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error: ${e.toString()}',
      };
    }
  }

  // ════════════════════════════════════════════
  //  SIGN OUT
  // ════════════════════════════════════════════

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('[AuthService] Sign out error: $e');
    }
  }
}