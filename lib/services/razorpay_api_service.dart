import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../config/razorpay_config.dart';

class RazorpayApiService {
  static const String _baseUrl = 'https://api.razorpay.com/v1';
  // TODO: Make this configurable via environment variables
  static const String _functionUrl = 'https://createrazorpayorder-ibt4bk6ntq-el.a.run.app';
  
  // Verify payment signature
  static bool verifyPaymentSignature({
    required String orderId,
    required String paymentId,
    required String signature,
  }) {
    try {
      final text = '$orderId|$paymentId';
      final expectedSignature = _generateHmacSha256(text, RazorpayConfig.keySecret);
      return signature == expectedSignature;
    } catch (e) {
      return false;
    }
  }

  // Generate HMAC SHA256 signature
  static String _generateHmacSha256(String text, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(text);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  // Get payment details
  static Future<Map<String, dynamic>> getPaymentDetails(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payments/$paymentId'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('${RazorpayConfig.keyId}:${RazorpayConfig.keySecret}'))}',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get payment details: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting payment details: $e');
    }
  }

  // Create payment link for web-based payment
  static Future<Map<String, dynamic>> createPaymentLink({
    required double amount,
    required String currency,
    required String description,
    required String customerName,
    required String customerEmail,
    required String customerContact,
  }) async {
    try {
      print('Creating payment link...'); // Debug log
      print('Amount: $amount, Currency: $currency'); // Debug log
      print('Description: $description'); // Debug log
      
      final requestBody = {
        'amount': (amount * 100).toInt(),
        'currency': currency,
        'description': description,
        'reference_id': DateTime.now().millisecondsSinceEpoch.toString(),
        'callback_url': 'https://your-app.com/payment/callback', // TODO: Make configurable
        'callback_method': 'get',
        'notes': {
          'customer_name': customerName,
          'customer_email': customerEmail,
        },
        'notify': {
          'sms': true,
          'email': true,
        },
      };
      
      print('Payment link request body: $requestBody'); // Debug log
      
      final response = await http.post(
        Uri.parse('$_baseUrl/payment_links'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('${RazorpayConfig.keyId}:${RazorpayConfig.keySecret}'))}',
        },
        body: jsonEncode(requestBody),
      );

      print('Payment link response status: ${response.statusCode}'); // Debug log
      print('Payment link response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Payment link created successfully: ${responseData['id']}'); // Debug log
        return responseData;
      } else {
        print('Failed to create payment link: ${response.body}'); // Debug log
        throw Exception('Failed to create payment link: ${response.body}');
      }
    } catch (e) {
      print('Error creating payment link: $e'); // Debug log
      throw Exception('Error creating payment link: $e');
    }
  }

  // Get payment link status
  static Future<String> getPaymentLinkStatus(String paymentLinkId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payment_links/$paymentLinkId'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('${RazorpayConfig.keyId}:${RazorpayConfig.keySecret}'))}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Payment link status response: $data'); // Debug log
        return data['status'] ?? 'unknown';
      } else {
        print('Failed to get payment link status: ${response.body}'); // Debug log
        throw Exception('Failed to get payment link status: ${response.body}');
      }
    } catch (e) {
      print('Error getting payment link status: $e'); // Debug log
      throw Exception('Error getting payment link status: $e');
    }
  }

  static Future<String> createOrder(double amount) async {
    try {
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': (amount * 100).toInt()}), // amount in paise
      );
      print('Razorpay order creation response status: \\${response.statusCode}'); // Debug log
      print('Razorpay order creation response body: \\${response.body}'); // Debug log
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id']; // Razorpay order ID
      } else {
        throw Exception('Failed to create Razorpay order: \\${response.body}');
      }
    } catch (e) {
      print('Exception in createOrder: \\${e.toString()}'); // Debug log
      rethrow;
    }
  }
} 