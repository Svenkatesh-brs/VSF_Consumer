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
  'http://10.172.129.117:3000';
      // 'http://10.163.147.117:3000';
      
      

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
// NOTIFICATION API
// ============================================================

static const String registerNotificationDevice =
    '/api/v1/consumer/notifications/device';
}