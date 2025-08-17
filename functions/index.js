/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onRequest, onCall } = require("firebase-functions/v2/https");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require('nodemailer');
// const fetch = require('node-fetch'); // Removed for Node.js 18+ global fetch support
admin.initializeApp();

const Razorpay = require('razorpay');


// Replace with your Razorpay keys
const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || 'rzp_test_PLACEHOLDER',
  key_secret: process.env.RAZORPAY_KEY_SECRET || 'PLACEHOLDER_SECRET'
});

exports.createRazorpayOrder = onRequest({ region: 'asia-south1' }, async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }
  try {
    const { amount } = req.body;
    if (!amount) {
      return res.status(400).json({ error: 'Amount is required' });
    }
    const order = await razorpay.orders.create({
      amount: amount, // amount in paise
      currency: 'INR',
      payment_capture: 1
    });
    console.log('Razorpay order response:', order);
    if (!order || !order.id) {
      // Razorpay did not return a valid order
      return res.status(500).json({ error: 'Failed to create order with Razorpay', details: order });
    }
    res.status(200).json(order);
  } catch (err) {
    console.error('Razorpay order creation error:', err);
    res.status(500).json({ error: err.message || 'Unknown error', details: err });
  }
});

// Set the region to Mumbai (asia-south1)
exports.sendNotification = onDocumentCreated({
  document: "notifications/{notificationId}",
  region: "asia-south1"
}, async (event) => {
  const snap = event.data;
  if (!snap) {
    console.log("No data in notification event");
    return;
  }
  const notification = snap.data();
  console.log("Processing notification:", notification);

  try {
    // Get the user's FCM token
    const userDoc = await admin.firestore()
      .collection("users")
      .doc(notification.user_id)
      .get();

    const userData = userDoc.data();
    const fcmToken = userData && userData.fcm_token ? userData.fcm_token : null;

    console.log("User data:", userData);
    console.log("FCM token:", fcmToken);

    if (!fcmToken) {
      console.log("No FCM token found for user:", notification.user_id);
      return null;
    }

    // Prepare the notification message
    const message = {
      token: fcmToken,
      notification: {
        title: notification.title || 'Notification',
        body: notification.body || '',
      },
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          sound: "default",
          defaultSound: true,
          defaultVibrateTimings: true,
          defaultLightSettings: true,
          icon: "@mipmap/ic_launcher",
          color: "#4CAF50",
          clickAction: "FLUTTER_NOTIFICATION_CLICK"
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    console.log("Sending notification message:", message);

    // Send the notification
    const response = await admin.messaging().send(message);
    console.log("Successfully sent notification:", response);

    return null;
  } catch (error) {
    console.error("Error sending notification:", error);
    return null;
  }
});

// Function to delete all test notifications
exports.deleteTestNotifications = onRequest({
  region: "asia-south1"
}, async (req, res) => {
  try {
    const notificationsRef = admin.firestore().collection('notifications');
    const snapshot = await notificationsRef.get();
    
    const batch = admin.firestore().batch();
    let count = 0;
    
    snapshot.forEach(doc => {
      batch.delete(doc.ref);
      count++;
    });
    
    await batch.commit();
    
    res.json({ 
      success: true, 
      message: `Successfully deleted ${count} test notifications` 
    });
  } catch (error) {
    console.error('Error deleting notifications:', error);
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Configure nodemailer with your email service credentials
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'sahilgupta02468@gmail.com',
    pass: 'yshb bgvw treg mthg',
  },
});

exports.sendVerificationCode = onCall(
  { region: 'asia-south1' },
  async (data, context) => {
    console.log('Received data:', data);
    // For v2 functions, data is the payload directly
    const email = data.email;
    const code = data.code;
    if (!email || !code) {
      console.error('Missing email or code:', { email, code });
      throw new Error('Email and code are required');
    }
    const mailOptions = {
      from: 'Super Fruit Center <sahilgupta02468@gmail.com>',
      to: email,
      subject: 'Your Super Fruit Center Verification Code',
      text: `Your verification code is: ${code}`,
      html: `<p>Your verification code is: <b>${code}</b></p>`,
    };
    try {
      await transporter.sendMail(mailOptions);
      return { success: true };
    } catch (error) {
      console.error('Error sending verification email:', error);
      throw new Error('Failed to send verification email: ' + error.message);
    }
  }
);

// Helper function to detect Hindi
function isHindi(text) {
  return /[\u0900-\u097F]/.test(text);
}

exports.deepseekSuggestor = onRequest({ region: 'asia-south1' }, async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { orderSummary, peopleCount, userMessage } = req.body;
  if (!orderSummary && !userMessage) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  // If orderSummary is empty, return a friendly general fruit recommendation
  if (!orderSummary || orderSummary.trim() === '') {
    return res.json({
      answer: `Here are some healthy fruits you can add to your daily life for a balanced diet:\n\n- Apples: Great for fiber and vitamin C\n- Bananas: Good for energy and potassium\n- Oranges: Excellent source of vitamin C\n- Papaya: Rich in vitamin A and digestive enzymes\n- Berries: Packed with antioxidants\n- Watermelon: Hydrating and refreshing\n- Pomegranate: Good for heart health\n\nTry to include a variety of fruits in your meals for the best nutrition! If you have any specific questions, feel free to ask!`,
      success: true,
      timestamp: new Date().toISOString(),
      fallback: false
    });
  }

  // Get OpenRouter API key from env/config
  const apiKey = process.env.OPENROUTER_API_KEY || process.env.DEEPSEEK_API_KEY || functions.config().deepseek?.api_key;
  if (!apiKey) {
    console.error('OPENROUTER_API_KEY not set in environment variables');
    return res.status(500).json({ 
      error: 'OPENROUTER_API_KEY not configured. Please set it using: firebase functions:config:set deepseek.api_key="YOUR_API_KEY"' 
    });
  }

  // Language instruction for the prompt
  let languageInstruction = '';
  if (isHindi(userMessage)) {
    languageInstruction = '\nIMPORTANT: Answer ONLY in Hindi. Do not use English words or sentences.';
  } else {
    languageInstruction = '\nIMPORTANT: Answer ONLY in English. Do not use Hindi or other languages.';
  }

  // Build the prompt
  const prompt = `You are a fruit and nutrition expert for Indian users.\n\nCONTEXT:\n- User's fruit order history: ${orderSummary}\n- Number of people in household: ${peopleCount}\n\nUSER QUESTION: ${userMessage}\n\nPlease provide a helpful, personalized response that:\n1. Acknowledges their order history and preferences\n2. Analyzes the nutritional value of fruits in their orders (calculate vitamins, minerals, fiber, etc.)\n3. Gives practical fruit recommendations based on their question\n4. Considers Indian fruit availability and seasonal factors\n5. Suggests specific fruits with brief nutritional benefits\n6. Keeps the response conversational and friendly\n7. Limits response to 2-3 sentences for mobile readability\n\nIMPORTANT: Calculate nutrition values yourself based on the fruit names mentioned in their order history. Don't ask for nutrition data - provide it based on your knowledge of fruits.\n\nIf the user asks about specific fruits, provide detailed information about taste, nutrition, and best consumption practices.${languageInstruction}`;

  try {
    const openRouterRes = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
        'HTTP-Referer': 'https://your-site-url.com', // Optional, replace with your site
        'X-Title': 'Super Fruit Center', // Optional, replace with your app/site name
      },
      body: JSON.stringify({
        model: 'deepseek/deepseek-r1-0528:free', // updated model ID for DeepSeek R1 0528 (free)
        messages: [
          { role: 'system', content: 'You are a knowledgeable fruit and nutrition expert specializing in Indian fruits and dietary recommendations. You can calculate nutritional values of fruits based on their names.' },
          { role: 'user', content: prompt }
        ],
        temperature: 0.7,
        max_tokens: 1000,
        top_p: 0.8
      })
    });

    if (!openRouterRes.ok) {
      const errorText = await openRouterRes.text();
      console.error('OpenRouter API error:', errorText);
      // Provide a fallback response when API fails
      const fallbackResponse = `Based on your order history (${orderSummary}), here are some personalized fruit recommendations:\n\n🍎 **For Vitamin C**: Oranges, strawberries, and kiwis are excellent choices. Your recent orders show you enjoy fresh fruits, so try adding more citrus fruits to your diet.\n\n🍌 **For Energy**: Bananas and apples provide natural energy and are great for daily consumption.\n\n🥭 **Seasonal Picks**: Mangoes and watermelons are perfect for the current season and provide excellent hydration.\n\n💡 **Tip**: Consider adding more variety to your fruit intake for balanced nutrition. Each fruit offers unique health benefits!`;
      return res.json({ 
        answer: fallbackResponse,
        success: true,
        timestamp: new Date().toISOString(),
        fallback: true
      });
    }

    const openRouterData = await openRouterRes.json();
    let answer = '';
    if (openRouterData.choices && openRouterData.choices.length > 0) {
      answer = (openRouterData.choices[0].message.content || '').trim();
      // Remove <think>...</think> blocks
      answer = answer.replace(/<think>[\s\S]*?<\/think>/gi, '').trim();
    }
    if (!answer) {
      return res.json({
        answer: "Sorry, I couldn't generate a suggestion right now. Please try again or ask a different question!",
        success: true,
        timestamp: new Date().toISOString(),
        fallback: true
      });
    }
    return res.json({
      answer,
      success: true,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error calling OpenRouter:', error);
    return res.status(500).json({ 
      error: 'Failed to call OpenRouter', 
      details: error.message 
    });
  }
});

exports.notifyAdminsOnNewOrder = onDocumentCreated({
  document: "orders/{orderId}",
  region: "asia-south1"
}, async (event) => {
  const snap = event.data;
  if (!snap) {
    console.log("No data in order event");
    return;
  }
  const order = snap.data();
  console.log("[notifyAdminsOnNewOrder] Initial order data:", order);
  if (!order || !order.address) {
    console.log("Order or address missing");
    return;
  }

  // Wait for Firestore to finish writing (10 seconds)
  console.log("[notifyAdminsOnNewOrder] Waiting 10 seconds before re-fetching order...");
  await new Promise(resolve => setTimeout(resolve, 10000));

  // Re-fetch the order document to ensure address fields are present
  const refreshedSnap = await snap.ref.get();
  const refreshedOrder = refreshedSnap.data();
  console.log("[notifyAdminsOnNewOrder] Refetched order data:", refreshedOrder);
  const refreshedAddress = refreshedOrder.address || {};
  console.log("[notifyAdminsOnNewOrder] Refetched address:", refreshedAddress);
  const name = refreshedAddress.name || "";
  const flatNo = refreshedAddress.flatNo || "";
  const buildingName = refreshedAddress.buildingName || "";

  // Compose notification body
  const notificationBody = `Order from ${name}, Flat: ${flatNo}, Building: ${buildingName}`;
  console.log("[notifyAdminsOnNewOrder] Notification body:", notificationBody);

  // Send to all admins via topic (data-only payload)
  const message = {
    topic: "admin_orders",
    data: {
      title: "New Order Received",
      body: notificationBody,
      name,
      flat_no: flatNo,
      building_name: buildingName,
      order_id: event.params.orderId,
      persistent: "true",
      order_status: refreshedOrder.payment_status || "pending",
    },
    android: {
      priority: "high",
      notification: {
        channelId: "admin_high_importance_channel",
        // No sound field here; sound is handled in the app
      },
    },
    apns: {
      payload: {
        aps: {
          // No sound field here; sound is handled in the app
        },
      },
    },
  };

  console.log("[notifyAdminsOnNewOrder] Final notification message:", message);

  try {
    await admin.messaging().send(message);
    console.log("Successfully sent admin order notification:", message);
  } catch (error) {
    console.error("Error sending admin order notification:", error);
  }
});
