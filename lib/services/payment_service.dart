import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/razorpay_config.dart';

class PaymentService {
  Razorpay? _razorpay;
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onError;
  Function(ExternalWalletResponse)? onExternalWallet;

  PaymentService({this.onSuccess, this.onError, this.onExternalWallet}) {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess ?? _defaultOnSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, onError ?? _defaultOnError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet ?? _defaultOnExternalWallet);
  }

  void setCallbacks({
    Function(PaymentSuccessResponse)? onSuccess,
    Function(PaymentFailureResponse)? onError,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    _razorpay?.clear();
    _razorpay = Razorpay();
    if (onSuccess != null) {
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) {
        debugPrint('Razorpay EVENT_PAYMENT_SUCCESS triggered');
        onSuccess(response);
      });
    }
    if (onError != null) {
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (response) {
        debugPrint('Razorpay EVENT_PAYMENT_ERROR triggered');
        onError(response);
      });
    }
    if (onExternalWallet != null) {
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (response) {
        debugPrint('Razorpay EVENT_EXTERNAL_WALLET triggered');
        onExternalWallet(response);
      });
    }
  }

  void openCheckout({
    required double amount,
    required String orderId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) {
    // TODO: Online payments coming soon
    // For now, show a message that online payments are not yet available
    debugPrint('Online payments coming soon - amount: $amount, orderId: $orderId');
    
    // You can implement a dialog or snackbar here to show "coming soon" message
    // For now, we'll just log it
  }

  void _defaultOnSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: \\${response.paymentId}');
  }

  void _defaultOnError(PaymentFailureResponse response) {
    debugPrint('Payment Error: \\${response.code} | \\${response.message}');
  }

  void _defaultOnExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: \\${response.walletName}');
  }

  void dispose() {
    _razorpay?.clear();
  }
} 