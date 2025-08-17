# 🔧 Configuration Guide - Fruit Store User App

## 🚨 **IMPORTANT: Security First**

Before running the app, you MUST configure the following securely:

## 1. **Environment Variables Setup**

Create a `.env` file in the root directory (add to `.gitignore`):

```bash
# Razorpay Configuration
RAZORPAY_KEY_ID=rzp_test_your_test_key_here
RAZORPAY_KEY_SECRET=your_test_secret_here

# DeepSeek AI API Configuration
DEEPSEEK_API_KEY=sk_your_deepseek_api_key_here

# App Configuration
APP_ENV=development
DEBUG_MODE=true
PAYMENT_GATEWAY_ENABLED=false
ONLINE_PAYMENTS_COMING_SOON=true
```

## 2. **Firebase Functions Configuration**

Set up your Firebase functions with secure configuration:

```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Set Razorpay configuration
firebase functions:config:set razorpay.key_id="YOUR_RAZORPAY_KEY"
firebase functions:config:set razorpay.key_secret="YOUR_RAZORPAY_SECRET"

# Set DeepSeek configuration
firebase functions:config:set deepseek.api_key="YOUR_DEEPSEEK_KEY"

# Deploy functions
firebase deploy --only functions
```

## 3. **Update Configuration Files**

### Update `lib/config/razorpay_config.dart`:

```dart
class RazorpayConfig {
  // Get keys from environment variables or secure storage
  static const String testKeyId = String.fromEnvironment('RAZORPAY_KEY_ID');
  static const String testKeySecret = String.fromEnvironment('RAZORPAY_KEY_SECRET');
  
  // Or use secure storage
  // static Future<String> get keyId async => await SecureStorage.read('razorpay_key_id');
}
```

### Update `functions/index.js`:

```javascript
const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || functions.config().razorpay?.key_id,
  key_secret: process.env.RAZORPAY_KEY_SECRET || functions.config().razorpay?.key_secret
});
```

## 4. **Secure Key Management**

### Option A: Environment Variables (Development)
```bash
export RAZORPAY_KEY_ID="your_key_here"
export RAZORPAY_KEY_SECRET="your_secret_here"
```

### Option B: Secure Storage (Production)
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureConfig {
  static const _storage = FlutterSecureStorage();
  
  static Future<String?> getRazorpayKey() async {
    return await _storage.read(key: 'razorpay_key_id');
  }
}
```

### Option C: Firebase Remote Config
```dart
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfig {
  static Future<String> getRazorpayKey() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.fetchAndActivate();
    return remoteConfig.getString('razorpay_key_id');
  }
}
```

## 5. **Build Configuration**

### Development Build:
```bash
flutter build apk --debug --dart-define=RAZORPAY_KEY_ID=your_key
```

### Production Build:
```bash
flutter build apk --release --dart-define=RAZORPAY_KEY_ID=your_production_key
```

## 6. **Verification Steps**

1. ✅ Check that no hardcoded keys exist in the codebase
2. ✅ Verify environment variables are loaded correctly
3. ✅ Test Firebase functions with new configuration
4. ✅ Verify payment flow works (currently shows "coming soon")
5. ✅ Check that sensitive data is not logged

## 7. **Common Issues & Solutions**

### Issue: "API key not configured"
**Solution**: Check environment variables and Firebase config

### Issue: "Payment gateway error"
**Solution**: Verify Razorpay keys and test mode settings

### Issue: "Firebase functions not working"
**Solution**: Check function deployment and configuration

## 8. **Security Checklist**

- [ ] No hardcoded API keys in source code
- [ ] Environment variables properly set
- [ ] Firebase functions configured securely
- [ ] API keys not exposed in logs
- [ ] Production keys different from test keys
- [ ] Keys rotated regularly
- [ ] Access logs monitored

## 9. **Next Steps After Configuration**

1. **Test the app** with the new configuration
2. **Verify offline functionality** works correctly
3. **Test notification system** with Firebase
4. **Implement online payments** when ready
5. **Add comprehensive testing**
6. **Set up monitoring and analytics**

## 🔒 **Security Reminders**

- **NEVER** commit API keys to version control
- **ALWAYS** use environment variables or secure storage
- **REGULARLY** rotate your API keys
- **MONITOR** your API usage and logs
- **TEST** your security measures regularly

---

**Need Help?** Check the troubleshooting guide or create an issue in the repository.
