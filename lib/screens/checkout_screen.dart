import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/address.dart';
import '../services/address_service.dart';
import '../services/cart_service.dart';
import '../services/payment_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/notification_utils.dart';
import '../utils/responsive_utils.dart';
import '../services/razorpay_api_service.dart';
import '../screens/enhanced_dashboard.dart';
import '../screens/order_details_screen.dart';
import '../screens/orders_screen.dart';
import 'package:shimmer/shimmer.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? _selectedAddressId;
  late PaymentService _paymentService;
  bool _isProcessingPayment = false;
  bool _showAddressForm = false;
  Address? _editingAddress;
  final TextEditingController _addressNameController = TextEditingController();
  final TextEditingController _flatNoController = TextEditingController();
  final TextEditingController _buildingNameController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _addressPhoneController = TextEditingController();
  String? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    _addressNameController.dispose();
    _flatNoController.dispose();
    _buildingNameController.dispose();
    _landmarkController.dispose();
    _addressPhoneController.dispose();
    super.dispose();
  }

  void _startAddAddress() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _editingAddress = null;
      _addressNameController.text = '';
      _flatNoController.text = '';
      _buildingNameController.text = '';
      _landmarkController.text = '';
      _addressPhoneController.text = user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty
          ? user.phoneNumber!.replaceFirst('+91', '')
          : '';
      _showAddressForm = true;
    });
  }

  void _startEditAddress(Address address) {
    setState(() {
      _editingAddress = address;
      _addressNameController.text = address.name;
      _flatNoController.text = address.flatNo;
      _buildingNameController.text = address.buildingName;
      _landmarkController.text = address.landmark ?? '';
      _addressPhoneController.text = address.phone ?? '';
      _showAddressForm = true;
    });
  }

  Future<void> _saveAddress() async {
    try {
      // Validate required fields
      if (_addressNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a name')),
        );
        return;
      }
      if (_flatNoController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter flat/house number')),
        );
        return;
      }
      if (_buildingNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter building name')),
        );
        return;
      }
      if (_addressPhoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a phone number')),
        );
        return;
      }
      if (_addressPhoneController.text.trim().length != 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number must be 10 digits')),
        );
        return;
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final addressService = AddressService(user.uid);
      final newAddress = Address(
        id: _editingAddress?.id ?? '',
        name: _addressNameController.text.trim(),
        phone: _addressPhoneController.text.trim(),
        flatNo: _flatNoController.text.trim(),
        buildingName: _buildingNameController.text.trim(),
        landmark: _landmarkController.text.trim().isEmpty ? null : _landmarkController.text.trim(),
      );
      print('Saving address: ' + newAddress.toJson().toString()); // Debug log
      if (_editingAddress != null) {
        await addressService.updateAddress(newAddress);
        print('Address updated successfully'); // Debug log
      } else {
        final docRef = await addressService.addAddressWithId(newAddress);
        await docRef.update({'id': docRef.id});
        print('Address added successfully'); // Debug log
      }
      setState(() {
        _showAddressForm = false;
        _editingAddress = null;
        _addressNameController.clear();
        _flatNoController.clear();
        _buildingNameController.clear();
        _landmarkController.clear();
        _addressPhoneController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Address saved successfully!')),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error saving address: ' + e.toString()); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving address: ' + e.toString())),
      );
    }
  }

  void _cancelAddressForm() {
    setState(() {
      _showAddressForm = false;
      _editingAddress = null;
      _addressNameController.clear();
      _flatNoController.clear();
      _buildingNameController.clear();
      _landmarkController.clear();
      _addressPhoneController.clear();
    });
  }

  void _showLoadingDialog(BuildContext context, {String message = 'Processing your order...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Flexible(child: Text(message, style: const TextStyle(fontSize: 16))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final cart = Provider.of<CartService>(context);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }
    final addressService = AddressService(user.uid);
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              'Checkout',
              style: TextStyle(
                fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 20),
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: ResponsiveUtils.responsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stepper/Progress Indicator
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
                        horizontal: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStepCircle(context, 0, !_showAddressForm && _selectedAddressId == null ? StepState.editing : StepState.complete, 'Address'),
                          _buildStepLine(),
                          _buildStepCircle(context, 1, _selectedAddressId != null ? StepState.editing : StepState.indexed, 'Summary'),
                          _buildStepLine(),
                          _buildStepCircle(context, 2, _isProcessingPayment ? StepState.editing : StepState.indexed, 'Payment'),
                        ],
                      ),
                    ),
                    // Address Section
                    Padding(
                      padding: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Delivery Address', 
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 18),
                            )
                          ),
                          TextButton(
                            onPressed: _showAddressForm ? null : _startAddAddress,
                            child: Text(
                              'Add New',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_showAddressForm)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
                        vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 18)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12),
                              offset: Offset(0, ResponsiveUtils.responsiveSpacing(context, baseSpacing: 4)),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 20)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Add/Edit Address',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 18)
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 18)),
                              TextField(
                                controller: _addressNameController,
                                decoration: InputDecoration(
                                  labelText: 'Name',
                                  labelStyle: TextStyle(
                                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
                              TextField(
                                controller: _flatNoController,
                                decoration: InputDecoration(
                                  labelText: 'Flat/House No.',
                                  labelStyle: TextStyle(
                                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
                              TextField(
                                controller: _buildingNameController,
                                decoration: InputDecoration(
                                  labelText: 'Building Name',
                                  labelStyle: TextStyle(
                                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
                              TextField(
                                controller: _landmarkController,
                                decoration: InputDecoration(
                                  labelText: 'Landmark (optional)',
                                  labelStyle: TextStyle(
                                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
                              TextField(
                                controller: _addressPhoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  labelStyle: TextStyle(
                                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 20)),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _saveAddress,
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 12)),
                                        ),
                                      ),
                                      child: Text(
                                        'Save',
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _cancelAddressForm,
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 12)),
                                        ),
                                      ),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 260,
                    child: StreamBuilder<List<Address>>(
                      stream: addressService.getAddresses(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final addresses = snapshot.data ?? [];
                        if (addresses.isEmpty) {
                          return const Center(child: Text('No addresses found. Add one!'));
                        }
                        const double addressCardHeight = 92.0; // Approximate height of one address card
                        final double boxHeight = addresses.length <= 3
                          ? addresses.length * addressCardHeight
                          : 3 * addressCardHeight;
                        return Container(
                          height: boxHeight,
                          child: ListView.builder(
                            physics: addresses.length > 3 ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                          itemCount: addresses.length,
                          itemBuilder: (context, index) {
                            final address = addresses[index];
                            return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                              child: ListTile(
                                leading: Radio<String>(
                                  value: address.id,
                                  groupValue: _selectedAddressId,
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedAddressId = val;
                                    });
                                  },
                                ),
                                title: Text(
                                  address.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(address.flatNo),
                                    Text(address.buildingName),
                                    if ((address.landmark ?? '').isNotEmpty)
                                      Text('Landmark: ${address.landmark}'),
                                    if (address.phone.isNotEmpty)
                                        Text('Phone: ${address.phone}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _startEditAddress(address),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        await addressService.deleteAddress(address.id);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          ),
                        );
                      },
                    ),
                  ),
                  // Order Summary
                  Padding(
                    padding: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 18))
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Order Summary', 
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 18),
                              )
                            ),
                            if (cart.items.isEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 24)),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.shopping_cart_outlined, 
                                      size: ResponsiveUtils.responsiveIconSize(context, baseSize: 48), 
                                      color: Colors.grey[400]
                                    ),
                                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
                                    Text(
                                      'Your cart is empty.', 
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16)
                                      )
                                    ),
                                  ],
                                ),
                              ),
                            ...cart.items.map((item) => ListTile(
                              title: Text(
                                '${item.name} (${item.amount} × ${item.quantity}, ${item.unitPriceDisplay})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                                ),
                              ),
                              trailing: Text(
                                '₹${(item.totalPrice ?? 0).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16)
                                ),
                              ),
                            )),
                            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                            // Delivery Fee Logic
                            Builder(
                              builder: (context) {
                                final total = cart.getTotal();
                                int deliveryFee = 0;
                                String feeLabel = '';
                                if (total < 500) {
                                  deliveryFee = 40;
                                  feeLabel = '₹40';
                                } else if (total < 1000) {
                                  deliveryFee = 20;
                                  feeLabel = '₹20';
                                } else {
                                  deliveryFee = 0;
                                  feeLabel = 'Free';
                                }
                                final totalWithFee = total + deliveryFee;
                                double onlineFee = 0;
                                if (_selectedPaymentMethod == 'online') {
                                  onlineFee = totalWithFee * 0.02;
                                }
                                final grandTotal = totalWithFee + onlineFee;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Subtotal
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Subtotal', 
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                          )
                                        ),
                                        Text(
                                          '₹${total.toStringAsFixed(2)}', 
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                          )
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                                    // Delivery Fee
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Delivery Fee', 
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                          )
                                        ),
                                        Text(
                                          feeLabel, 
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                          )
                                        ),
                                      ],
                                    ),
                                    // Online Payment Fee (if applicable)
                                    if (_selectedPaymentMethod == 'online') ...[
                                      SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Online Payment Fee (2%)', 
                                            style: TextStyle(
                                              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black54,
                                            )
                                          ),
                                          Text(
                                            '₹${onlineFee.toStringAsFixed(2)}', 
                                            style: TextStyle(
                                              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black54,
                                            )
                                          ),
                                        ],
                                      ),
                                    ],
                                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                                    const Divider(thickness: 2),
                                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total', 
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 18),
                                            fontWeight: FontWeight.bold,
                                          )
                                        ),
                                        Text(
                                          '₹${grandTotal.toStringAsFixed(2)}', 
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 18),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          )
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 24)),
                                    // Payment Method Selection
                                    Text(
                                      'Select Payment Method', 
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                      )
                                    ),
                                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
                                    _buildPaymentOption('Cash on Delivery', Icons.money, 'cod'),
                                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 10)),
                                    _buildPaymentOption('Online Payment (Coming Soon)', Icons.credit_card, 'online', isComingSoon: true),
                                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
                                    ElevatedButton(
                                      onPressed: _selectedAddressId == null || _selectedPaymentMethod == null || _isProcessingPayment
                                          ? null
                                          : () async {
                                              final user = FirebaseAuth.instance.currentUser;
                                              if (user == null || user.phoneNumber == null || user.phoneNumber!.isEmpty) {
                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (context) => AlertDialog(
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                    title: Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.all(8),
                                                          decoration: BoxDecoration(
                                                            color: Colors.orange[100],
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: Icon(
                                                            Icons.phone_android,
                                                            color: Colors.orange[700],
                                                            size: 24,
                                                          ),
                                                        ),
                                                        SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
                                                        Expanded(
                                                          child: Text(
                                                            'Phone Verification Required',
                                                            style: TextStyle(
                                                              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 20),
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.black87,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'To ensure secure delivery and order tracking, we need to verify your phone number.',
                                                          style: TextStyle(
                                                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                                            color: Colors.black87,
                                                            height: 1.4,
                                                          ),
                                                        ),
                                                        SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
                                                        Container(
                                                          padding: const EdgeInsets.all(12),
                                                          decoration: BoxDecoration(
                                                            color: Colors.blue[50],
                                                            borderRadius: BorderRadius.circular(12),
                                                            border: Border.all(color: Colors.blue[200]!),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons.info_outline,
                                                                color: Colors.blue[700],
                                                                size: 20,
                                                              ),
                                                              SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                                                              Expanded(
                                                                child: Text(
                                                                  'Verified phone numbers help us:\n• Contact you about your order\n• Send delivery updates\n• Ensure secure transactions',
                                                                  style: TextStyle(
                                                                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                                                                    color: Colors.black87,
                                                                    height: 1.3,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        style: TextButton.styleFrom(
                                                          foregroundColor: Colors.grey[600],
                                                        ),
                                                        child: Text('Cancel'),
                                                      ),
                                                      ElevatedButton.icon(
                                                        onPressed: () {
                                                          Navigator.of(context).popUntil((route) => route.isFirst);
                                                          Navigator.of(context).pushReplacementNamed('/dashboard', arguments: 3);
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Almost done! For security, please verify your phone number in the Profile tab (bottom right) before placing your order.',
                                                                style: TextStyle(fontSize: 15),
                                                              ),
                                                              backgroundColor: Colors.blue[700],
                                                              duration: Duration(seconds: 4),
                                                            ),
                                                          );
                                                        },
                                                        icon: Icon(Icons.person, size: ResponsiveUtils.responsiveIconSize(context, baseSize: 18)),
                                                        label: Text('Go to Profile'),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.orange[600],
                                                          foregroundColor: Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 20), vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
                                                        ),
                                                      ),
                                                    ],
                                                    actionsPadding: EdgeInsets.fromLTRB(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 20), 0, ResponsiveUtils.responsiveSpacing(context, baseSpacing: 20), ResponsiveUtils.responsiveSpacing(context, baseSpacing: 20)),
                                                  ),
                                                );
                                                return;
                                              }
                                              final confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: Text('Confirm Order'),
                                                  content: Text('Are you sure you want to place this order? Once placed, the order cannot be cancelled.'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      child: Text('Cancel'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () => Navigator.pop(context, true),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.green,
                                                        foregroundColor: Colors.white,
                                                      ),
                                                      child: Text('Confirm'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirmed != true) return;
                                              if (_selectedPaymentMethod == 'cod') {
                                                setState(() => _isProcessingPayment = true);
                                                await _createOrder('COD', 'pending');
                                                setState(() => _isProcessingPayment = false);
                                              } else if (_selectedPaymentMethod == 'online') {
                                                // Show coming soon message for online payments
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Row(
                                                      children: [
                                                        Icon(Icons.info, color: Colors.white),
                                                        SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
                                                        Expanded(
                                                          child: Text(
                                                            'Online payments coming soon! Please use Cash on Delivery for now.',
                                                            style: TextStyle(fontSize: 16),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    backgroundColor: Colors.blue[700],
                                                    behavior: SnackBarBehavior.floating,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                    margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 24), vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
                                                    duration: Duration(seconds: 4),
                                                  ),
                                                );
                                                // Reset payment method to COD
                                                setState(() {
                                                  _selectedPaymentMethod = 'cod';
                                                });
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        textStyle: TextStyle(fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 18), fontWeight: FontWeight.bold),
                                        elevation: 2,
                                      ),
                                      child: Text(_selectedPaymentMethod == 'cod' ? 'Place Order' : _selectedPaymentMethod == 'online' ? 'Pay & Place Order' : 'Continue'),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isProcessingPayment && _selectedPaymentMethod == 'cod')
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Container(
                color: Colors.white.withOpacity(0.85),
                child: Center(
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: ResponsiveUtils.responsiveWidth(context, baseWidth: 120),
                      height: ResponsiveUtils.responsiveHeight(context, baseHeight: 120),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(Icons.shopping_bag, size: ResponsiveUtils.responsiveIconSize(context, baseSize: 64), color: Colors.orange),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _createOrder(String paymentId, String paymentStatus) async {
    try {
      print('Starting order creation...'); // Debug log
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User is null, cannot create order'); // Debug log
        return;
      }
      print('User ID: ${user.uid}'); // Debug log
      
      final addressService = AddressService(user.uid);
      final cart = Provider.of<CartService>(context, listen: false);
      // Get selected address
      final addresses = await addressService.getAddresses().first;
      final selectedAddress = addresses.firstWhere((a) => a.id == _selectedAddressId);
      print('Selected address: ${selectedAddress.name}'); // Debug log
      
      // Prepare order data
      final total = cart.getTotal();
      int deliveryFee = 0;
      if (total < 500) {
        deliveryFee = 40;
      } else if (total < 1000) {
        deliveryFee = 20;
      } else {
        deliveryFee = 0;
      }
      final totalWithFee = total + deliveryFee;
      final orderData = {
        'user_id': user.uid,
        'address': selectedAddress.toJson(),
        'total_amount': totalWithFee,
        'delivery_fee': deliveryFee,
        'payment_status': paymentStatus,
        'payment_id': paymentId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'items': cart.items.map((item) => {
          'product_id': item.productId,
          'name': item.name,
          'quantity': item.quantity,
          'displayPrice': item.price,
          'numericPrice': double.tryParse(item.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
          'imageUrls': item.imageUrls,
          'amount': item.amount,
          'unit': item.unit,
          'unitPrice': item.unitPrice,
          'unitPriceDisplay': item.unitPriceDisplay,
          'totalPrice': item.totalPrice,
        }).toList(),
        if (_selectedPaymentMethod == 'online')
          'processing_fee': (totalWithFee * 0.02),
      };
      print('Order data prepared: ${orderData.toString()}'); // Debug log
      
      // Save order to Firestore
      final orderDocRef = await FirebaseFirestore.instance.collection('orders').add(orderData);
      final orderId = orderDocRef.id;
      print('Order created with ID: $orderId'); // Debug log
      
      // Send payment notification with the actual order ID
      if (paymentStatus == 'paid') {
        print('Sending payment notification...'); // Debug log
        try {
          double notificationAmount;
          if (_selectedPaymentMethod == 'online') {
            // Include product total + delivery fee + processing fee
            final total = cart.getTotal();
            int deliveryFee = 0;
            if (total < 500) {
              deliveryFee = 40;
            } else if (total < 1000) {
              deliveryFee = 20;
            } else {
              deliveryFee = 0;
            }
            final totalWithFee = total + deliveryFee;
            final onlineFee = totalWithFee * 0.02;
            notificationAmount = totalWithFee + onlineFee;
          } else {
            // COD: only product total + delivery fee
            final total = cart.getTotal();
            int deliveryFee = 0;
            if (total < 500) {
              deliveryFee = 40;
            } else if (total < 1000) {
              deliveryFee = 20;
            } else {
              deliveryFee = 0;
            }
            notificationAmount = total + deliveryFee;
          }
          await NotificationUtils.sendPaymentNotification(
            userId: user.uid,
            orderId: orderId,
            paymentStatus: 'successful',
            amount: notificationAmount,
          );
          print('Payment notification sent successfully'); // Debug log
        } catch (notificationError) {
          print('Error sending notification: $notificationError'); // Debug log
          // Don't fail the order creation if notification fails
        }
      }
      
      // Send notification to user
      await NotificationUtils.sendOrderUpdateNotification(
        userId: user.uid,
        orderId: orderId,
        orderStatus: paymentStatus,
        additionalMessage: 'Your order has been placed successfully!'
      );
      // Send notification to admin (assuming admin userId is 'admin' or fetch from Firestore)
      await NotificationUtils.sendGeneralNotification(
        userId: 'admin',
        title: 'New Order Placed',
        message: 'A new order #$orderId has been placed by \\${user.email ?? user.uid}',
        data: {'order_id': orderId},
        persistent: true,
      );
      
      // Clear cart
      cart.clearCart();
      print('Cart cleared'); // Debug log
      
      setState(() {
        _isProcessingPayment = false;
      });
      
      if (mounted) {
        // Fetch the order from Firestore to get the correct Timestamp and data
        final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
        final fetchedOrderData = orderDoc.data();
        if (fetchedOrderData != null) {
          Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
              builder: (_) => const OrderSuccessScreen(),
                      ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('Error in _createOrder: $e'); // Debug log
      setState(() {
        _isProcessingPayment = false;
      });
      
      // Show more detailed error message
      String errorMessage = 'Error creating order: ${e.toString()}';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permission denied. Please try again or contact support.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 500),
        ),
      );
    }
  }

  Widget _buildStepCircle(BuildContext context, int step, StepState state, String label) {
    Color color;
    IconData icon;
    switch (state) {
      case StepState.complete:
        color = Theme.of(context).colorScheme.primary;
        icon = Icons.check;
        break;
      case StepState.editing:
        color = Colors.orange;
        icon = Icons.edit;
        break;
      default:
        color = Colors.grey[300]!;
        icon = Icons.circle;
    }
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        height: 2,
        color: Colors.grey[300],
      ),
    );
  }

  Widget _buildPaymentOption(String label, IconData icon, String value, {bool isComingSoon = false}) {
    return InkWell(
      onTap: isComingSoon ? null : () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 14), horizontal: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
        decoration: BoxDecoration(
          color: isComingSoon 
              ? Colors.grey[100] 
              : (_selectedPaymentMethod == value ? Colors.green[50] : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isComingSoon 
                ? Colors.grey[400]! 
                : (_selectedPaymentMethod == value ? Colors.green : Colors.grey[300]!),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              color: isComingSoon 
                  ? Colors.grey[400] 
                  : (_selectedPaymentMethod == value ? Colors.green : Colors.grey[600]), 
              size: ResponsiveUtils.responsiveIconSize(context, baseSize: 24)
            ),
            SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 14)),
            Expanded(
              child: Text(
                label, 
                style: TextStyle(
                  fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 15), 
                  fontWeight: FontWeight.w500,
                  color: isComingSoon ? Colors.grey[600] : null,
                )
              )
            ),
            if (isComingSoon)
              Container(
                padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8), vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 4)),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'SOON',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 10),
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              )
            else if (_selectedPaymentMethod == value)
              Icon(Icons.check_circle, color: Colors.green, size: ResponsiveUtils.responsiveIconSize(context, baseSize: 20)),
          ],
        ),
      ),
    );
  }
} 

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({Key? key}) : super(key: key);

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> with SingleTickerProviderStateMixin {
  double _scale = 0.7;
  double _opacity = 0.0;
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    // Animate in
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _scale = 1.0;
          _opacity = 1.0;
        });
      }
    });
    // Redirect after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _canPop = true);
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
          settings: RouteSettings(arguments: 1), // 1 = Orders tab
        ),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _canPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            child: AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(milliseconds: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 80),
                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 24)),
                  Text(
                    'Order Successful!',
                    style: TextStyle(fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 28), fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
                  Text(
                    'Thank you for your purchase.',
                    style: TextStyle(fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 18), color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 