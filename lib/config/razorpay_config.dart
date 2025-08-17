class RazorpayConfig {
  // IMPORTANT: Never commit actual API keys to version control
  // Use environment variables or secure configuration management
  
  // For testing (use these keys for development)
  static const String testKeyId = 'rzp_test_PLACEHOLDER';
  static const String testKeySecret = 'PLACEHOLDER_SECRET';
  
  // For production (use these keys when publishing to app store)
  static const String liveKeyId = 'rzp_live_PLACEHOLDER';
  static const String liveKeySecret = 'PLACEHOLDER_SECRET';
  
  // Set this to true for production, false for testing
  static const bool isProduction = false;
  
  // Get the appropriate key based on environment
  static String get keyId => isProduction ? liveKeyId : testKeyId;
  static String get keySecret => isProduction ? liveKeySecret : testKeySecret;
  
  // Check if API keys are properly configured
  static bool get isConfigured => 
      keyId != 'rzp_test_PLACEHOLDER' && 
      keySecret != 'PLACEHOLDER_SECRET';
} 