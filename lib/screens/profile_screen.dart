import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../utils/notification_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fruit_store_user_app/screens/enhanced_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fruit_store_user_app/utils/responsive_utils.dart';
import 'dart:async';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  int _selectedAvatar = 0; // 0-7: different avatar types
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String? _phone;
  String? _email;
  String? _userId;
  bool _loading = true;
  bool _editMode = false;
  bool _avatarSelectionMode = false; // New state for avatar selection only

  // Avatar options with different styles
  static const List<Map<String, dynamic>> _avatarOptions = [
    {'id': 0, 'icon': Icons.person, 'name': 'Default', 'color': Colors.blue},
    {'id': 1, 'icon': Icons.face, 'name': 'Happy', 'color': Colors.orange},
    {'id': 2, 'icon': Icons.emoji_emotions, 'name': 'Smile', 'color': Colors.green},
    {'id': 3, 'icon': Icons.sentiment_satisfied, 'name': 'Friendly', 'color': Colors.green},
    {'id': 4, 'icon': Icons.psychology, 'name': 'Smart', 'color': Colors.indigo},
    {'id': 5, 'icon': Icons.sports_esports, 'name': 'Gamer', 'color': Colors.red},
    {'id': 6, 'icon': Icons.fitness_center, 'name': 'Athlete', 'color': Colors.teal},
    {'id': 7, 'icon': Icons.music_note, 'name': 'Artist', 'color': Colors.pink},
    {'id': 8, 'icon': Icons.school, 'name': 'Student', 'color': Colors.amber},
    {'id': 9, 'icon': Icons.work, 'name': 'Professional', 'color': Colors.brown},
    {'id': 10, 'icon': Icons.favorite, 'name': 'Lover', 'color': Colors.pink},
    {'id': 11, 'icon': Icons.star, 'name': 'VIP', 'color': Colors.yellow},
  ];

  @override
  void initState() {
    super.initState();
    _loadCachedUserData();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  void didPush() {
    _loadUserData();
  }

  @override
  void didPopNext() {
    _loadUserData();
  }

  Future<void> _loadCachedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedName = prefs.getString('user_name');
    final cachedAvatar = prefs.getInt('user_avatar');
    if (cachedName != null) {
      if (cachedName.contains(' ')) {
        final parts = cachedName.split(' ');
        _firstNameController.text = parts.first;
        _lastNameController.text = parts.sublist(1).join(' ');
      } else {
        _firstNameController.text = cachedName;
      }
    }
    if (cachedAvatar != null && cachedAvatar >= 0 && cachedAvatar <= 11) {
      _selectedAvatar = cachedAvatar;
    }
    // Do NOT set _loading = false here. Let _loadUserData control loading state.
  }

  Future<void> _loadUserData() async {
    setState(() { _loading = true; });
    await Future.delayed(const Duration(milliseconds: 500)); // Artificial delay for shimmer
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _loading = false; });
      return;
    }
    await user.reload();
    _userId = user.uid;
    _phone = user.phoneNumber;
    _email = user.email;
    // Fetch Firestore user profile
    final doc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      final name = (data['name'] ?? '').toString().trim();
      if (name.contains(' ')) {
        final parts = name.split(' ');
        _firstNameController.text = parts.first;
        _lastNameController.text = parts.sublist(1).join(' ');
      } else {
        _firstNameController.text = name;
      }
      // Load avatar selection (handle both old 0-1 range and new 0-11 range)
      final avatarValue = data['avatar'] ?? 0;
      if (avatarValue is int && avatarValue >= 0 && avatarValue <= 11) {
        _selectedAvatar = avatarValue;
      } else {
        _selectedAvatar = 0; // Default to first avatar if invalid value
      }
      // Save to cache
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('user_name', name);
      prefs.setInt('user_avatar', _selectedAvatar);
      
      // Initialize notification service
      if (mounted) {
        final notificationProvider = context.read<NotificationProvider>();
        await notificationProvider.initialize();
        await notificationProvider.updateUserToken();
      }
    } else {
      // Initialize notification service even if user document doesn't exist
      if (mounted) {
        final notificationProvider = context.read<NotificationProvider>();
        await notificationProvider.initialize();
        await notificationProvider.updateUserToken();
      }
    }
    
    setState(() {
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (_userId == null) return;
    final name = (_firstNameController.text + ' ' + _lastNameController.text).trim();
    final user = FirebaseAuth.instance.currentUser;
    // Update display name in Firebase Auth
    if (user != null) {
      await user.updateDisplayName(name);
    }
    await FirebaseFirestore.instance.collection('users').doc(_userId).set({
      'name': name,
      'avatar': _selectedAvatar,
      'phone': _phone,
      'email': _email,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated!'),
          duration: Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _updatePhone() async {
    final phoneController = TextEditingController();
    final otpController = TextEditingController();
    String? verificationId;
    bool otpSent = false;
    bool loading = false;
    bool resendEnabled = false;
    int resendSeconds = 30;
    Timer? resendTimer;

    void startResendTimer(StateSetter setState) {
      resendEnabled = false;
      resendSeconds = 30;
      resendTimer?.cancel();
      resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          resendSeconds--;
          if (resendSeconds <= 0) {
            resendEnabled = true;
            resendTimer?.cancel();
          }
        });
      });
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Update Mobile Number', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'New Mobile Number',
                      prefixText: '+91 ',
                    ),
                    enabled: !otpSent && !loading,
                  ),
                  if (otpSent) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'OTP'),
                      autofillHints: const [AutofillHints.oneTimeCode],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                if (!otpSent)
                        Expanded(
                          child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            setState(() => loading = true);
                            await FirebaseAuth.instance.verifyPhoneNumber(
                              phoneNumber: '+91${phoneController.text}',
                                      verificationCompleted: (PhoneAuthCredential credential) async {},
                              verificationFailed: (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: ${e.message}')),
                                );
                                setState(() => loading = false);
                              },
                              codeSent: (vId, _) {
                                verificationId = vId;
                                setState(() {
                                  otpSent = true;
                                  loading = false;
                                });
                                        startResendTimer(setState);
                              },
                              codeAutoRetrievalTimeout: (vId) {
                                verificationId = vId;
                              },
                            );
                          },
                    child: loading ? const CircularProgressIndicator() : const Text('Send OTP'),
                          ),
                  ),
                if (otpSent)
                        Expanded(
                          child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            if (verificationId == null) return;
                            setState(() => loading = true);
                            try {
                              final credential = PhoneAuthProvider.credential(
                                verificationId: verificationId!,
                                smsCode: otpController.text,
                              );
                              final user = FirebaseAuth.instance.currentUser;
                              await user?.updatePhoneNumber(credential);
                              await FirebaseFirestore.instance.collection('users').doc(user?.uid).set({
                                'phone': '+91${phoneController.text}',
                              }, SetOptions(merge: true));
                              if (mounted) {
                                Navigator.of(context).pop();
                                _loadUserData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Success! Your phone number is now updated and verified.'), backgroundColor: Colors.green,),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                              );
                            }
                            setState(() => loading = false);
                          },
                    child: loading ? const CircularProgressIndicator() : const Text('Verify OTP'),
                  ),
                        ),
                      if (otpSent)
                        const SizedBox(width: 12),
                      if (otpSent)
                        OutlinedButton(
                          onPressed: resendEnabled
                              ? () async {
                                  setState(() => loading = true);
                                  await FirebaseAuth.instance.verifyPhoneNumber(
                                    phoneNumber: '+91${phoneController.text}',
                                    verificationCompleted: (PhoneAuthCredential credential) async {},
                                    verificationFailed: (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: ${e.message}')),
                                      );
                                      setState(() => loading = false);
                                    },
                                    codeSent: (vId, _) {
                                      verificationId = vId;
                                      setState(() {
                                        loading = false;
                                        resendEnabled = false;
                                      });
                                      startResendTimer(setState);
                                    },
                                    codeAutoRetrievalTimeout: (vId) {
                                      verificationId = vId;
                                    },
                                  );
                                }
                              : null,
                          child: resendEnabled
                              ? const Text('Resend OTP')
                              : Text('Resend in $resendSeconds s'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                  child: const Text('Cancel'),
                    ),
                ),
              ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateEmail() async {
    final emailController = TextEditingController(text: _email ?? '');
    final passwordController = TextEditingController();
    bool loading = false;
    final oldUid = FirebaseAuth.instance.currentUser?.uid;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Email'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'New Email'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Current Password'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () async {
                          setState(() => loading = true);
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;
                            // Re-authenticate
                            final cred = EmailAuthProvider.credential(
                              email: user.email!,
                              password: passwordController.text,
                            );
                            await user.reauthenticateWithCredential(cred);
                            await user.updateEmail(emailController.text);
                            final newUid = FirebaseAuth.instance.currentUser?.uid;
                            if (oldUid != null && newUid != null && oldUid != newUid) {
                              await FirebaseFirestore.instance.collection('users').doc(oldUid).delete();
                            }
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                              'email': emailController.text,
                            }, SetOptions(merge: true));
                            if (mounted) {
                              Navigator.of(context).pop();
                              _loadUserData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Email updated!'),
                                  duration: Duration(milliseconds: 800),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                duration: Duration(milliseconds: 800),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          setState(() => loading = false);
                        },
                  child: loading ? const CircularProgressIndicator() : const Text('Update'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAvatarIcon() {
    final selectedAvatarData = _avatarOptions.firstWhere(
      (avatar) => avatar['id'] == _selectedAvatar,
      orElse: () => _avatarOptions[0],
    );
    
    return Icon(
      selectedAvatarData['icon'],
      size: ResponsiveUtils.responsiveIconSize(context, baseSize: 80),
      color: selectedAvatarData['color'],
    );
  }

  Widget _buildAvatarSelectionGrid() {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Avatar',
            style: TextStyle(
              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveUtils.isTablet(context) ? 6 : 4,
              crossAxisSpacing: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8),
              mainAxisSpacing: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8),
              childAspectRatio: ResponsiveUtils.isTablet(context) ? 1.0 : 0.8,
            ),
            itemCount: _avatarOptions.length,
            itemBuilder: (context, index) {
              final avatar = _avatarOptions[index];
              final isSelected = _selectedAvatar == avatar['id'];
              
              return GestureDetector(
                onTap: () async {
                  setState(() {
                    _selectedAvatar = avatar['id'];
                  });
                  // Auto-save the avatar selection
                  await _saveAvatarSelection();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 8),
                    ),
                    border: isSelected 
                      ? Border.all(
                          color: Theme.of(context).primaryColor,
                          width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 2),
                        )
                      : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        avatar['icon'],
                        size: ResponsiveUtils.responsiveIconSize(context, baseSize: 24),
                        color: avatar['color'],
                      ),
                      SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 2)),
                      Text(
                        avatar['name'],
                        style: TextStyle(
                          fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 8),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveAvatarSelection() async {
    if (_userId == null) return;
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'avatar': _selectedAvatar,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avatar updated to ${_avatarOptions[_selectedAvatar]['name']}!'),
            duration: Duration(milliseconds: 500),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving avatar: $e'),
            duration: Duration(milliseconds: 500),
            backgroundColor: Colors.red,
          ),
    );
      }
    }
  }

  bool get _isPhoneVerified => _phone != null && _phone!.isNotEmpty;

  Widget _buildProfileBody() {
    return RefreshIndicator(
              onRefresh: () async {
                await _loadUserData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Column(
                    key: ValueKey(_loading.toString() + _editMode.toString() + _avatarSelectionMode.toString()),
                    children: [
                      SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 24)),
                      if (!_isPhoneVerified)
                        Padding(
                          padding: ResponsiveUtils.responsivePadding(
                            context,
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Container(
                            padding: ResponsiveUtils.responsivePadding(context),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 12),
                              ),
                              border: Border.all(
                                color: Colors.orange,
                                width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning,
                                  color: Colors.orange,
                                  size: ResponsiveUtils.responsiveIconSize(context, baseSize: 28),
                                ),
                                SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
                                Expanded(
                                  child: Text(
                                    'Your phone number is not verified. Please verify your number from your profile to use all features.',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                      fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 15),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Profile Card
                      Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 500),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 24),
                              ),
                            ),
                            margin: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
                            ),
                            child: Padding(
                              padding: ResponsiveUtils.responsivePadding(
                                context,
                                horizontal: 24,
                                vertical: 32,
                              ),
                              child: Column(
                                children: [
                                  // Avatar with edit overlay
                                  Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      Column(
                                        children: [
                                          TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 0.8, end: 1),
                                            duration: const Duration(milliseconds: 600),
                                            curve: Curves.elasticOut,
                                            builder: (context, scale, child) {
                                              return Transform.scale(
                                                scale: scale,
                                                child: child,
                                              );
                                            },
                                            child: CircleAvatar(
                                              radius: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 48),
                                              backgroundColor: Colors.grey[200],
                                              child: _buildAvatarIcon(),
                                            ),
                                          ),
                                          SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                                          Text(
                                            _avatarOptions[_selectedAvatar]['name'],
                                            style: TextStyle(
                                              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                                              fontWeight: FontWeight.w500,
                                              color: _avatarOptions[_selectedAvatar]['color'],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Positioned(
                                        bottom: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 32),
                                        right: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 4),
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _avatarSelectionMode = !_avatarSelectionMode;
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: EdgeInsets.all(
                                              ResponsiveUtils.responsiveSpacing(context, baseSpacing: 6),
                                            ),
                                            child: Icon(
                                              _avatarSelectionMode ? Icons.close : Icons.edit,
                                              color: Colors.white,
                                              size: ResponsiveUtils.responsiveIconSize(context, baseSize: 20),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                                  TextField(
                                    controller: _firstNameController,
                                    enabled: _editMode,
                                    decoration: InputDecoration(
                                      labelText: 'First Name',
                                      prefixIcon: Icon(
                                        Icons.person,
                                        size: ResponsiveUtils.responsiveIconSize(context),
                                      ),
                                      labelStyle: TextStyle(
                                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
                                  TextField(
                                    controller: _lastNameController,
                                    enabled: _editMode,
                                    decoration: InputDecoration(
                                      labelText: 'Last Name',
                                      prefixIcon: Icon(
                                        Icons.person_outline,
                                        size: ResponsiveUtils.responsiveIconSize(context),
                                      ),
                                      labelStyle: TextStyle(
                                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
                                  // Avatar Selection Grid (only in avatar selection mode)
                                  if (_avatarSelectionMode) _buildAvatarSelectionGrid(),
                                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
                                  // Email
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.email,
                                        size: ResponsiveUtils.responsiveIconSize(context, baseSize: 18),
                                        color: Colors.grey,
                                      ),
                                      SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                                      Expanded(
                                        child: Text(
                                          _email ?? '-',
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (_editMode)
                                        TextButton(
                                          onPressed: _updateEmail,
                                          child: Text(
                                            'Edit',
                                            style: TextStyle(
                                              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                                  // Phone
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        size: ResponsiveUtils.responsiveIconSize(context, baseSize: 18),
                                        color: Colors.grey,
                                      ),
                                      SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                                      Expanded(
                                        child: Text(
                                          _phone ?? '-',
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (_editMode)
                                        TextButton(
                                          onPressed: _updatePhone,
                                          child: Text(
                                            'Edit',
                                            style: TextStyle(
                                              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 24)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 32)),
                      if (!_editMode && !_avatarSelectionMode)
                        Padding(
                          padding: ResponsiveUtils.responsivePadding(
                            context,
                            horizontal: 32,
                          ),
                          child: ElevatedButton.icon(
                            icon: Icon(
                              Icons.edit,
                              size: ResponsiveUtils.responsiveIconSize(context),
                            ),
                            label: Text(
                              'Edit Details',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              minimumSize: Size.fromHeight(
                                ResponsiveUtils.responsiveButtonHeight(context),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 24),
                                ),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _editMode = true;
                                _avatarSelectionMode = false;
                              });
                            },
                          ),
                        ),
                      if (_editMode && !_avatarSelectionMode)
                        Padding(
                          padding: ResponsiveUtils.responsivePadding(
                            context,
                            horizontal: 32,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: Icon(
                                    Icons.save,
                                    size: ResponsiveUtils.responsiveIconSize(context),
                                  ),
                                  label: Text(
                                    'Save',
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF4CAF50),
                                    foregroundColor: Colors.white,
                                    minimumSize: Size.fromHeight(
                                      ResponsiveUtils.responsiveButtonHeight(context),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 24),
                                      ),
                                    ),
                                  ),
                                  onPressed: () async {
                                    await _submit();
                                    setState(() {
                                      _editMode = false;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: Icon(
                                    Icons.cancel,
                                    size: ResponsiveUtils.responsiveIconSize(context),
                                  ),
                                  label: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    minimumSize: Size.fromHeight(
                                      ResponsiveUtils.responsiveButtonHeight(context),
                                    ),
                                    side: BorderSide(
                                      color: Colors.red,
                                      width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 1),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 24),
                                      ),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _editMode = false;
                                    });
                                    _loadUserData();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Logout button always below edit buttons
                      Padding(
                        padding: ResponsiveUtils.responsivePadding(
                          context,
                          horizontal: 32,
                          vertical: 8,
                        ),
                        child: ElevatedButton.icon(
                          icon: Icon(
                            Icons.logout,
                            size: ResponsiveUtils.responsiveIconSize(context),
                          ),
                          label: Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: Size.fromHeight(
                              ResponsiveUtils.responsiveButtonHeight(context),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 24),
                              ),
                            ),
                          ),
                          onPressed: () async {
                            final shouldLogout = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  'Confirm Logout',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 18),
                                  ),
                                ),
                                content: Text(
                                  'Are you sure you want to log out?',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: Text(
                                      'Logout',
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (shouldLogout == true) {
                              await FirebaseAuth.instance.signOut();
                              if (mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      // Skeleton loader while loading
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Profile',
            style: TextStyle(
              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 20),
            ),
          ),
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: Padding(
          padding: ResponsiveUtils.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 80),
                      height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 80),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
                    Container(
                      width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 180),
                      height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 20),
                      color: Colors.white,
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                    Container(
                      width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 120),
                      height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
                      color: Colors.white,
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 24)),
                    Container(
                      width: double.infinity,
                      height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 40),
                      color: Colors.white,
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
                    Container(
                      width: double.infinity,
                      height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 40),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 20),
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // No leading/back button
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          const NotificationPermissionBanner(),
          Expanded(
            child: _buildProfileBody(),
          ),
        ],
      ),
    );
  }
} 