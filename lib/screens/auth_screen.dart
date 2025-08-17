import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../utils/responsive_utils.dart';

class AuthScreen extends StatefulWidget {
  final bool isRegister;
  
  const AuthScreen({super.key, required this.isRegister});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  String? _verificationId;
  bool _isPhoneAuth = true;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isCodeSent = false;
  bool _isVerifyingCode = false;
  bool _emailVerified = false;
  String? _registeredEmail;
  String? _registeredUid;
  
  // Remove OTP auto-fill variables
  // Remove: Timer? _otpTimer; bool _isListeningForOtp = false; String? _lastOtpFromSms;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _verificationCodeController.dispose();
    // Remove _stopOtpAutoFill();
    super.dispose();
  }

  // Remove Enhanced OTP auto-fill functionality
  // Remove: void _startOtpAutoFill() { if (_isListeningForOtp) return; setState(() { _isListeningForOtp = true; }); _checkClipboardForOtp(); _listenForSmsOtp(); _otpTimer = Timer.periodic(const Duration(seconds: 2), (timer) { _checkClipboardForOtp(); }); }
  // Remove: void _stopOtpAutoFill() { _otpTimer?.cancel(); setState(() { _isListeningForOtp = false; }); }
  // Remove: Future<void> _checkClipboardForOtp() async { try { final clipboardData = await Clipboard.getData(Clipboard.kTextPlain); if (clipboardData?.text != null) { final text = clipboardData!.text!; // Look for 6-digit OTP pattern final otpMatch = RegExp(r'\b\d{6}\b').firstMatch(text); if (otpMatch != null) { final otp = otpMatch.group(0)!; if (otp != _lastOtpFromSms) { _lastOtpFromSms = otp; setState(() { _otpController.text = otp; }); // Auto-verify OTP after a short delay Future.delayed(const Duration(milliseconds: 500), () { if (mounted && _otpController.text == otp) { _verifyOTP(); } }); } } } } catch (e) { // Ignore clipboard errors } }
  // Remove: Future<void> _listenForSmsOtp() async { // Request SMS permission on Android if (await Permission.sms.request().isGranted) { // This is a simplified implementation // In a real app, you might want to use a more sophisticated SMS listener // For now, we'll rely on clipboard detection and manual input } }
  // Remove: // Manual OTP paste functionality Future<void> _pasteOtpFromClipboard() async { try { final clipboardData = await Clipboard.getData(Clipboard.kTextPlain); if (clipboardData?.text != null) { final text = clipboardData!.text!; // Look for 6-digit OTP pattern final otpMatch = RegExp(r'\b\d{6}\b').firstMatch(text); if (otpMatch != null) { final otp = otpMatch.group(0)!; setState(() { _otpController.text = otp; }); // Auto-verify after paste Future.delayed(const Duration(milliseconds: 500), () { if (mounted && _otpController.text == otp) { _verifyOTP(); } }); ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('OTP pasted successfully!'), backgroundColor: Color(0xFF4CAF50), duration: Duration(milliseconds: 1500), ), ); } else { ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('No valid OTP found in clipboard'), backgroundColor: Colors.orange, duration: Duration(milliseconds: 1500), ), ); } } } catch (e) { ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text('Error accessing clipboard: $e'), backgroundColor: Colors.red, duration: const Duration(milliseconds: 1500), ), ); } }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91${_phoneController.text}',
        verificationCompleted: (PhoneAuthCredential credential) async {
            await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('OTP verification failed: ${e.message}'), backgroundColor: Colors.red, duration: Duration(milliseconds: 1500)),
            );
            setState(() => _isLoading = false);
        },
        codeSent: (String verificationId, int? resendToken) {
            setState(() {
              _verificationId = verificationId;
              _otpSent = true;
              _isLoading = false;
            });
            // Start OTP auto-fill when code is sent
            // _startOtpAutoFill(); // Removed
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent! Check your SMS or clipboard'), backgroundColor: Color(0xFF4CAF50), duration: Duration(milliseconds: 1500)),
            );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
            setState(() => _verificationId = verificationId);
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
        await _logAuthError('sendOTP', e);
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending OTP: $e'), backgroundColor: Colors.red, duration: Duration(milliseconds: 1500)),
        );
        setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    if (_verificationId == null) return;
    setState(() => _isLoading = true);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text,
      );
      await _signInWithCredential(credential);
      // Stop OTP auto-fill after successful verification
      // _stopOtpAutoFill(); // Removed
    } catch (e) {
        await _logAuthError('verifyOTP', e);
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP. Please check and try again.'), backgroundColor: Colors.red, duration: Duration(milliseconds: 1500)),
        );
        setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      await _logAuthError('signInWithEmail', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign in failed: $e'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 1500),
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      // Create user profile in Firestore if not exists
      final userDoc = FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid);
      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) {
        await userDoc.set({
          'phone': _phoneController.text,
          'name': _nameController.text,
          'email': _emailController.text.isNotEmpty ? _emailController.text : null,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      await _logAuthError('signInWithCredential', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $e'), backgroundColor: Colors.red, duration: Duration(milliseconds: 1500)),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User cancelled
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      // If new user, create Firestore profile
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user!.displayName ?? '',
          'email': userCredential.user!.email ?? '',
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      await _logAuthError('signInWithGoogle', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed: $e'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 1500),
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  void _showManualOTPDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual OTP Entry'),
        content: const Text(
          'If you didn\'t receive the OTP automatically, please check your SMS messages and enter the 6-digit code manually.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Create user profile in Firestore if not exists
      final userDoc = FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid);
      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) {
        await userDoc.set({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text.isNotEmpty ? _phoneController.text : null,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      await _logAuthError('signUpWithEmail', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign up failed: $e'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 1500),
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  // Add Firestore error logging helper
  Future<void> _logAuthError(String context, dynamic error) async {
    try {
      await FirebaseFirestore.instance.collection('auth_errors').add({
        'context': context,
        'error': error.toString(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF81C784), // fallback for gradient
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4CAF50),
              Color(0xFF66BB6A),
              Color(0xFF81C784),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
          child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.responsiveMaxWidth(context),
                ),
                child: Padding(
                  padding: ResponsiveUtils.responsivePadding(
                    context,
                    vertical: 24,
                    horizontal: 24,
                    verticalTablet: 32,
                    horizontalTablet: 32,
                    verticalLarge: 40,
                    horizontalLarge: 40,
                  ),
            child: Form(
              key: _formKey,
              child: Column(
                      mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section
                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 40)),
                  Container(
                    padding: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 20)),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 20)),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 1.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          widget.isRegister ? Icons.person_add : Icons.login,
                          size: ResponsiveUtils.responsiveIconSize(context, baseSize: 60),
                          color: Colors.white,
                        ),
                        SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
                        Text(
                          widget.isRegister ? 'Create Account' : 'Welcome Back',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 28),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                        Text(
                          widget.isRegister 
                            ? 'Join Super Fruit Center today'
                            : 'Sign in to your account',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                            color: Colors.white70,
                            fontWeight: FontWeight.w300,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 40)),

                  // Authentication Method Toggle (moved above name/password fields)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 12)),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 1.2),
                      ),
                    ),
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Phone'),
                          icon: Icon(Icons.phone),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Email'),
                          icon: Icon(Icons.email),
                        ),
                      ],
                      selected: {_isPhoneAuth},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          _isPhoneAuth = newSelection.first;
                          _otpSent = false;
                                _otpController.clear();
                                _verificationId = null;
                                _isLoading = false;
                                _emailController.clear();
                                _passwordController.clear();
                        });
                        // Stop OTP auto-fill when switching auth methods
                        // _stopOtpAutoFill(); // Removed
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.white;
                            }
                            return Colors.transparent;
                          },
                        ),
                        foregroundColor: MaterialStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(MaterialState.selected)) {
                              return const Color(0xFF4CAF50);
                            }
                            return Colors.white;
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 20)),

                  if (widget.isRegister) ...[
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 20)),
                  ],

                  if (_isPhoneAuth) ...[
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      prefixText: '+91 ',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length != 10) {
                          return 'Please enter a valid 10-digit phone number';
                        }
                        return null;
                      },
                    ),
                    if (_otpSent) ...[
                      SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 20)),
                      // OTP Auto-fill indicator
                      // if (_isListeningForOtp) // Removed
                      //   Container( // Removed
                      //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Removed
                      //     margin: const EdgeInsets.only(bottom: 8), // Removed
                      //     decoration: BoxDecoration( // Removed
                      //       color: Colors.green.withOpacity(0.2), // Removed
                      //       borderRadius: BorderRadius.circular(8), // Removed
                      //       border: Border.all(color: Colors.green.withOpacity(0.5)), // Removed
                      //     ), // Removed
                      //     child: Row( // Removed
                      //       children: [ // Removed
                      //         const Icon(Icons.auto_awesome, color: Colors.green, size: 16), // Removed
                      //         const SizedBox(width: 8), // Removed
                      //         const Text( // Removed
                      //           'Auto-fill enabled - checking for OTP', // Removed
                      //           style: TextStyle(color: Colors.green, fontSize: 12), // Removed
                      //         ), // Removed
                      //       ], // Removed
                      //     ), // Removed
                      //   ), // Removed
                      _buildTextField(
                        controller: _otpController,
                        label: 'OTP',
                        icon: Icons.lock_open,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the OTP';
                          }
                          if (value.length != 6) {
                            return 'OTP must be 6 digits';
                          }
                          return null;
                        },
                        autofocus: true,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // if (_isListeningForOtp) // Removed
                            //   Tooltip( // Removed
                            //     message: 'Auto-fill is active', // Removed
                            //     child: const Icon( // Removed
                            //       Icons.auto_awesome, // Removed
                            //       color: Colors.green, // Removed
                            //       size: 20, // Removed
                            //     ), // Removed
                            //   ), // Removed
                          ],
                        ),
                        onChanged: (value) {
                          // Auto-verify when 6 digits are entered
                          // if (value.length == 6) { // Removed
                          //   // Add a small delay to allow user to complete typing // Removed
                          //   Future.delayed(const Duration(milliseconds: 500), () { // Removed
                          //     if (mounted && _otpController.text.length == 6 && !_isLoading) { // Removed
                          //       _verifyOTP(); // Removed
                          //     } // Removed
                          //   }); // Removed
                          // } // Removed
                        },
                      ),
                      SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
                      // Manual OTP entry help text
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16), vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 8)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.white70, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Copy OTP from SMS and paste here, or it will auto-fill. Enter 6 digits to auto-verify.',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                      // Manual verify button
                      // if (_otpController.text.length == 6) // Removed
                      Container(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _sendOTP,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Resend OTP'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 8)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 20)),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock,
                      obscureText: _obscurePassword,
                            suffixIcon: Tooltip(
                              message: _obscurePassword ? 'Show password' : 'Hide password',
                              child: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                                onPressed: _isLoading ? null : () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                              ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 20)),
                  ],
                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 32)),

                  // Remember Me (only for sign-in)
                  if (!widget.isRegister) ...[
                    Row(
                      children: [
                              Checkbox(
                              value: _rememberMe,
                              onChanged: (val) {
                                setState(() {
                                  _rememberMe = val ?? false;
                                });
                              },
                              activeColor: Colors.white,
                              checkColor: Color(0xFF4CAF50),
                        ),
                        Text(
                          'Remember Me',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
                  ],

                  // Submit Button
                  Container(
                    height: ResponsiveUtils.responsiveButtonHeight(context, baseHeight: 56),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 28)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 10),
                          offset: Offset(0, ResponsiveUtils.responsiveSpacing(context, baseSpacing: 5)),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (
                              widget.isRegister
                                ? (
                                    _isPhoneAuth
                                      ? (_otpSent ? _verifyOTP : _sendOTP)
                                      : _signUpWithEmail
                                  )
                                : (
                                    _isPhoneAuth
                                      ? (_otpSent ? _verifyOTP : _sendOTP)
                                      : _signInWithEmail
                                  )
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4CAF50),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 28)),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: ResponsiveUtils.responsiveIconSize(context, baseSize: 24),
                              height: ResponsiveUtils.responsiveIconSize(context, baseSize: 24),
                              child: CircularProgressIndicator(
                                strokeWidth: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 2),
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                              ),
                            )
                          : Text(
                              _isPhoneAuth
                                  ? (widget.isRegister ? (_otpSent ? 'Verify OTP' : 'Send OTP') : (_otpSent ? 'Verify OTP' : 'Send OTP'))
                                  : (widget.isRegister ? 'Create Account' : 'Sign In'),
                              style: TextStyle(
                                fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 18),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 24)),

                  // Google Sign-In Button (moved above Back to Welcome)
                        Tooltip(
                          message: 'Sign in with your Google account',
                          child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      minimumSize: Size.fromHeight(ResponsiveUtils.responsiveButtonHeight(context, baseHeight: 48)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 24)),
                      ),
                    ),
                    icon: Image.asset(
                      'assets/google_logo.png',
                      height: ResponsiveUtils.responsiveIconSize(context, baseSize: 24),
                      width: ResponsiveUtils.responsiveIconSize(context, baseSize: 24),
                    ),
                    label: Text(
                      'Sign in with Google',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                      ),
                    ),
                    onPressed: _isLoading ? null : _signInWithGoogle,
                          ),
                  ),
                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
                  // Back to Welcome
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Back to Welcome',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? prefixText,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    bool autofocus = false,
    List<String>? autofillHints,
    void Function(String)? onChanged,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        autofocus: autofocus,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          prefixText: prefixText,
          prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white.withOpacity(0.10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 12)),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 12)),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 12)),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.45), width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 1.5)),
          ),
        ),
        autofillHints: autofillHints,
      ),
    );
  }
} 