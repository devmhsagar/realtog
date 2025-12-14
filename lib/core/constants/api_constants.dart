class ApiConstants {
  static const String baseUrl = "https://basic-nodejs-backend.onrender.com";

  // Auth endpoints
  static const String loginUrl = "/auth/login";
  static const String registerUrl = "/auth/register";
  static const String currentUserUrl = "/auth/me";
  static const String googleAuthUrl = "/auth/google";
  static const String googleAuthCallbackUrl = "/auth/google";
  static const String googleAuthUrlById = "/auth/google/mobile";
  static const String googleAuthSuccessUrl = "/auth/google/success";
  static const String googleAuthFailureUrl = "/auth/google/failure";
  static const String forgotPasswordUrl = "/auth/forgot-password";
  static const String resetPasswordUrl = "/auth/reset-password";
  static const String verifyOtpUrl = "/otp/verify";

  // Pricing endpoints
  static const String pricingUrl = "/pricing";

  // Order endpoints
  static const String ordersUrl = "/orders";

  // Messaging endpoints
  static const String messagesUrl = "/messages/user-admin/messages";
}
