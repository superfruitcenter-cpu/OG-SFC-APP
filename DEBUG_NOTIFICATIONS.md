# Push Notification Debugging Guide

## Issue: Payment notifications are not being sent as push notifications

### Current Setup
Your app has:
1. ✅ Firebase Cloud Messaging (FCM) configured
2. ✅ Cloud Function that automatically sends push notifications when Firestore documents are created
3. ✅ FCM token storage in Firestore
4. ✅ Payment notification creation in Firestore

### Debugging Steps

#### 1. Check FCM Token Storage
- Open your app and check the console logs
- Look for: "FCM token saved to Firestore for user: [user_id]"
- Verify the token is not null

#### 2. Test Push Notifications
- Go to the Notifications screen in your app
- Tap the bug icon (🐛) in the app bar
- This will send a test push notification
- Check if you receive the notification on your device

#### 3. Check Cloud Function Deployment
Run this command in your terminal from the `functions` directory:
```bash
firebase functions:list
```
You should see `sendNotification` function deployed.

#### 4. Check Cloud Function Logs
```bash
firebase functions:log --only sendNotification
```

#### 5. Verify User Document Structure
In Firebase Console > Firestore, check that your user document has:
- `fcm_token` field with a valid token
- `last_token_update` timestamp

#### 6. Test Payment Flow
1. Complete a payment
2. Check Firestore for notification document creation
3. Check Cloud Function logs for any errors

### Common Issues and Solutions

#### Issue 1: No FCM Token
**Symptoms:** "No FCM token found for user" in logs
**Solution:** 
- Ensure notification permissions are granted
- Check if the user is logged in when token is generated
- Verify Firebase configuration

#### Issue 2: Cloud Function Not Triggered
**Symptoms:** Notification document created but no push notification
**Solution:**
- Check Cloud Function deployment status
- Verify function region matches your Firebase project
- Check function logs for errors

#### Issue 3: Permission Denied
**Symptoms:** "Permission denied" errors in Cloud Function logs
**Solution:**
- Ensure Cloud Function has proper IAM permissions
- Check Firestore security rules

### Testing Commands

#### Deploy Cloud Functions
```bash
cd functions
npm install
firebase deploy --only functions
```

#### Check Function Status
```bash
firebase functions:list
```

#### View Function Logs
```bash
firebase functions:log --only sendNotification
```

### Manual Test
You can manually test by creating a notification document in Firestore:
```javascript
// In Firebase Console > Firestore
{
  "title": "Test Notification",
  "body": "This is a test",
  "type": "test",
  "data": {},
  "user_id": "YOUR_USER_ID",
  "is_read": false,
  "created_at": Timestamp.now()
}
```

### Expected Flow
1. User completes payment
2. `sendPaymentNotification()` creates Firestore document
3. Cloud Function `sendNotification` triggers automatically
4. Function gets user's FCM token from Firestore
5. Function sends push notification via FCM
6. User receives notification on device

### Contact Support
If issues persist, check:
- Firebase Console > Functions > Logs
- Firebase Console > Cloud Messaging > Reports
- Device notification settings
- App notification permissions 