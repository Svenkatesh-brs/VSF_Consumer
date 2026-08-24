abstract class AppConstants {
  // ============================================================
  // APP
  // ============================================================

  static const String appName = 'VSF Consumer';

  // ============================================================
  // ASSETS
  // ============================================================

  static const String backgroundAsset = 'assets/bg.png';

  static const String watermarkAsset = 'assets/vsf.png';

  static const double watermarkWidth = 260.0;

  static const double watermarkOpacity = 0.06;

  // ============================================================
  // UI
  // ============================================================

  static const double formCardRadius = 22.0;

  static const double submitButtonHeight = 48.0;

  static const double submitButtonRadius = 100.0;

  // ============================================================
  // API
  // ============================================================

  static const String baseUrl =
  'http://192.168.0.109:3000';
      
      

  // ============================================================
  // AUTH API
  // ============================================================

  static const String verifyOtp =
      '/api/v1/consumer/otp/verify';

  static const String requestOtp =
      '/api/v1/consumer/otp/request';

  // ============================================================
  // HOME API
  // ============================================================

  static const String home =
      '/api/v1/consumer/customer';

  // ============================================================
  // LOAN DASHBOARD API
  // ============================================================

  static const String loanById =
      '/api/v1/consumer/loan/';

  // ============================================================
  // CONTACT UPDATE API
  // ============================================================

  static const String updatePhone =
      '/api/v1/consumer/customer/me/phone';

  static const String updateAddress =
      '/api/v1/consumer/customer/address/';

  // ============================================================
// NOTIFICATION API
// ============================================================

static const String registerNotificationDevice =
    '/api/v1/consumer/notifications/device';
}