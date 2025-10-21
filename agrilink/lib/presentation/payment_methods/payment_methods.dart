import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/add_card_dialog_widget.dart';
import './widgets/add_payment_method_widget.dart';
import './widgets/payment_method_card_widget.dart';
import './widgets/security_settings_widget.dart';
import './widgets/transaction_history_widget.dart';

class PaymentMethods extends StatefulWidget {
  const PaymentMethods({Key? key}) : super(key: key);

  @override
  State<PaymentMethods> createState() => _PaymentMethodsState();
}

class _PaymentMethodsState extends State<PaymentMethods> {
  bool _biometricEnabled = true;
  bool _transactionPinEnabled = false;
  bool _notificationsEnabled = true;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 1,
      'type': 'mpesa',
      'displayName': 'M-Pesa',
      'lastFour': '1234',
      'expiryDate': null,
      'isVerified': true,
      'isDefault': true,
    },
    {
      'id': 2,
      'type': 'card',
      'displayName': 'Visa',
      'lastFour': '5678',
      'expiryDate': '12/25',
      'isVerified': true,
      'isDefault': false,
    },
    {
      'id': 3,
      'type': 'paypal',
      'displayName': 'PayPal',
      'lastFour': '9012',
      'expiryDate': null,
      'isVerified': false,
      'isDefault': false,
    },
  ];

  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 1,
      'type': 'product',
      'title': 'Organic Tomatoes - 50kg',
      'subtitle': 'Green Valley Farm',
      'amount': '\$125.00',
      'status': 'Completed',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'isDebit': true,
    },
    {
      'id': 2,
      'type': 'consultation',
      'title': 'Veterinary Consultation',
      'subtitle': 'Dr. Sarah Johnson',
      'amount': '\$45.00',
      'status': 'Completed',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'isDebit': true,
    },
    {
      'id': 3,
      'type': 'subscription',
      'title': 'AgriLink Premium',
      'subtitle': 'Monthly subscription',
      'amount': '\$19.99',
      'status': 'Completed',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'isDebit': true,
    },
    {
      'id': 4,
      'type': 'product',
      'title': 'Maize Sale',
      'subtitle': 'Bulk order - City Market',
      'amount': '\$850.00',
      'status': 'Completed',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'isDebit': false,
    },
    {
      'id': 5,
      'type': 'refund',
      'title': 'Fertilizer Refund',
      'subtitle': 'Quality issue reported',
      'amount': '\$75.00',
      'status': 'Pending',
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'isDebit': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurrentPaymentMethods(),
              AddPaymentMethodWidget(
                onAddMpesa: _showAddMpesaDialog,
                onAddCard: _showAddCardDialog,
                onAddPaypal: _showAddPaypalDialog,
                onAddBank: _showAddBankDialog,
              ),
              SecuritySettingsWidget(
                biometricEnabled: _biometricEnabled,
                transactionPinEnabled: _transactionPinEnabled,
                notificationsEnabled: _notificationsEnabled,
                onBiometricChanged: (value) {
                  setState(() => _biometricEnabled = value);
                  _showBiometricSetup();
                },
                onTransactionPinChanged: (value) {
                  setState(() => _transactionPinEnabled = value);
                },
                onNotificationsChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
                onSetupPin: _showPinSetupDialog,
              ),
              TransactionHistoryWidget(
                transactions: _transactions,
                onViewAll: _navigateToTransactionHistory,
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Payment Methods',
        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: CustomIconWidget(
          iconName: 'arrow_back',
          color: AppTheme.lightTheme.colorScheme.onSurface,
          size: 6.w,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _showPaymentSettings,
          icon: CustomIconWidget(
            iconName: 'settings',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 6.w,
          ),
        ),
      ],
      elevation: 0,
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
    );
  }

  Widget _buildCurrentPaymentMethods() {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'account_balance_wallet',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Your Payment Methods',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _paymentMethods.isEmpty
              ? _buildEmptyPaymentMethods()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _paymentMethods.length,
                  itemBuilder: (context, index) {
                    final paymentMethod = _paymentMethods[index];
                    return PaymentMethodCardWidget(
                      paymentMethod: paymentMethod,
                      isDefault: paymentMethod['isDefault'] as bool,
                      onEdit: () => _editPaymentMethod(paymentMethod),
                      onDelete: () => _deletePaymentMethod(paymentMethod),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyPaymentMethods() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'credit_card_off',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 12.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'No payment methods added',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Add a payment method to start making purchases',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddMpesaDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildMpesaDialog(),
    );
  }

  void _showAddCardDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCardDialogWidget(
        onCardAdded: (cardData) {
          setState(() {
            _paymentMethods.add(cardData);
          });
        },
      ),
    );
  }

  void _showAddPaypalDialog() {
    _showComingSoonDialog('PayPal integration coming soon!');
  }

  void _showAddBankDialog() {
    _showComingSoonDialog('Bank transfer integration coming soon!');
  }

  Widget _buildMpesaDialog() {
    final TextEditingController phoneController = TextEditingController();
    bool isLoading = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'phone_android',
                color: const Color(0xFF00A651),
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Text('Add M-Pesa'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+254 700 000 000',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'phone',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 5.w,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A651).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'info',
                      color: const Color(0xFF00A651),
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'You will receive an OTP to verify your M-Pesa account',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF00A651),
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
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (phoneController.text.isEmpty) return;

                      setState(() => isLoading = true);

                      try {
                        await Future.delayed(const Duration(seconds: 2));

                        final mpesaData = {
                          'id': DateTime.now().millisecondsSinceEpoch,
                          'type': 'mpesa',
                          'displayName': 'M-Pesa',
                          'lastFour': phoneController.text
                              .substring(phoneController.text.length - 4),
                          'expiryDate': null,
                          'isVerified': true,
                          'isDefault': _paymentMethods.isEmpty,
                        };

                        this.setState(() {
                          _paymentMethods.add(mpesaData);
                        });

                        Navigator.of(context).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('M-Pesa account added successfully'),
                            backgroundColor: AppTheme.getSuccessColor(true),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to add M-Pesa account'),
                            backgroundColor:
                                AppTheme.lightTheme.colorScheme.error,
                          ),
                        );
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? SizedBox(
                      width: 4.w,
                      height: 4.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.lightTheme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Text('Add M-Pesa'),
            ),
          ],
        );
      },
    );
  }

  void _showComingSoonDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'info',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 6.w,
            ),
            SizedBox(width: 2.w),
            Text('Coming Soon'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _editPaymentMethod(Map<String, dynamic> paymentMethod) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Edit ${paymentMethod['displayName']} - Feature coming soon'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
  }

  void _deletePaymentMethod(Map<String, dynamic> paymentMethod) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Payment Method'),
        content: Text(
            'Are you sure you want to remove ${paymentMethod['displayName']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _paymentMethods.removeWhere(
                    (method) => method['id'] == paymentMethod['id']);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment method removed'),
                  backgroundColor: AppTheme.getSuccessColor(true),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showBiometricSetup() {
    if (_biometricEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Biometric authentication enabled'),
          backgroundColor: AppTheme.getSuccessColor(true),
        ),
      );
    }
  }

  void _showPinSetupDialog() {
    final TextEditingController pinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'pin',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 6.w,
            ),
            SizedBox(width: 2.w),
            Text('Setup Transaction PIN'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'Enter 4-digit PIN',
                counterText: '',
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'Confirm PIN',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text.length == 4 &&
                  pinController.text == confirmPinController.text) {
                setState(() => _transactionPinEnabled = true);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Transaction PIN setup successfully'),
                    backgroundColor: AppTheme.getSuccessColor(true),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('PINs do not match or invalid length'),
                    backgroundColor: AppTheme.lightTheme.colorScheme.error,
                  ),
                );
              }
            },
            child: Text('Setup PIN'),
          ),
        ],
      ),
    );
  }

  void _showPaymentSettings() {
    Navigator.pushNamed(context, '/user-profile');
  }

  void _navigateToTransactionHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transaction history - Feature coming soon'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
  }
}
