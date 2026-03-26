import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  // Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Store verification ID for OTP
  static String? _verificationId;
  static int? _resendToken;

  // ==================== PHONE AUTHENTICATION ====================

  /// Send OTP to phone number
  /// [phoneNumber] format: +6281234567890
  static Future<Map<String, dynamic>> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        
        // Called when verification is done automatically (auto-retrieve SMS)
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto sign-in (Android only)
          await _auth.signInWithCredential(credential);
        },
        
        // Called when verification fails
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage = _getErrorMessage(e.code);
          onError(errorMessage);
        },
        
        // Called when code is sent to phone
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        
        // Called when auto-retrieval timeout
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        
        forceResendingToken: _resendToken,
      );
      
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Verify OTP code
  static Future<Map<String, dynamic>> verifyOTP({
    required String otp,
    String? verificationId,
  }) async {
    try {
      final vid = verificationId ?? _verificationId;
      
      if (vid == null) {
        return {'success': false, 'error': 'Verification ID not found. Please request OTP again.'};
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: vid,
        smsCode: otp,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      return {
        'success': true,
        'user': userCredential.user,
        'isNewUser': userCredential.additionalUserInfo?.isNewUser ?? false,
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Resend OTP
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

  // ==================== SIGN OUT ====================

  /// Sign out current user
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // ==================== ANONYMOUS AUTH ====================

  /// Sign in anonymously (for testing/guest mode)
  static Future<Map<String, dynamic>> signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      return {'success': true, 'user': userCredential.user};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== HELPER METHODS ====================

  /// Format phone number to E.164 format
  static String formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // If starts with 0, replace with +62 (Indonesia)
    if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    }
    
    // If doesn't start with country code, add +62
    if (!digits.startsWith('62')) {
      digits = '62$digits';
    }
    
    return '+$digits';
  }

  /// Get user-friendly error message
  static String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Nomor telepon tidak valid';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti';
      case 'invalid-verification-code':
        return 'Kode OTP salah';
      case 'session-expired':
        return 'Sesi expired. Silakan minta OTP baru';
      case 'quota-exceeded':
        return 'Kuota SMS habis. Hubungi admin';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet';
      default:
        return 'Terjadi kesalahan: $code';
    }
  }
}
