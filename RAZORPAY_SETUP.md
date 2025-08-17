# Razorpay Payment Integration Setup

This guide will help you set up Razorpay payment integration for the Super Fruit Center app.

## Prerequisites

1. A Razorpay account (sign up at https://razorpay.com/)
2. Your Razorpay API keys

## Step 1: Get Your Razorpay API Keys

1. Log in to your Razorpay Dashboard: https://dashboard.razorpay.com/
2. Go to **Settings** → **API Keys**
3. Generate a new key pair or use existing ones
4. Copy your **Key ID** and **Key Secret**

## Step 2: Configure the App

1. Open `lib/config/razorpay_config.dart`
2. Replace the placeholder values with your actual API keys:

```dart
// For testing (use these keys for development)
static const String testKeyId = 'rzp_test_YOUR_ACTUAL_TEST_KEY_ID';
static const String testKeySecret = 'YOUR_ACTUAL_TEST_KEY_SECRET';

// For production (use these keys when publishing to app store)
static const String liveKeyId = 'rzp_live_YOUR_ACTUAL_LIVE_KEY_ID';
static const String liveKeySecret = 'YOUR_ACTUAL_LIVE_KEY_SECRET';
```

## Step 3: Test the Integration

1. Make sure `isProduction` is set to `false` in `razorpay_config.dart`
2. Run the app and try placing an order
3. Use Razorpay's test card numbers for testing:
   - **Card Number**: 4111 1111 1111 1111
   - **Expiry**: Any future date
   - **CVV**: Any 3 digits
   - **Name**: Any name

## Step 4: Production Deployment

When you're ready to go live:

1. Set `isProduction` to `true` in `razorpay_config.dart`
2. Make sure you're using your live API keys
3. Test thoroughly with real payment methods
4. Deploy to the app store

## Important Notes

- **Never commit your API keys to version control**
- **Test thoroughly in test mode before going live**
- **Keep your Key Secret secure and never expose it in client-side code**
- **Monitor your Razorpay dashboard for payment analytics**

## Troubleshooting

### Payment Fails
- Check if your API keys are correct
- Verify you're using test keys for testing and live keys for production
- Check Razorpay dashboard for error logs

### App Crashes
- Ensure you've added the Razorpay dependency correctly
- Check if the payment service is properly initialized
- Verify all required permissions are added to Android manifest

## Security Best Practices

1. **Server-side verification**: Always verify payments on your server
2. **Webhook integration**: Set up webhooks for payment status updates
3. **Signature verification**: Verify payment signatures to prevent fraud
4. **Error handling**: Implement proper error handling for failed payments

## Support

- Razorpay Documentation: https://razorpay.com/docs/
- Razorpay Support: https://razorpay.com/support/
- Flutter Package: https://pub.dev/packages/razorpay_flutter 