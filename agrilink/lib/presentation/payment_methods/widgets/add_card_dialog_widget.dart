import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AddCardDialogWidget extends StatefulWidget {
  final Function(Map<String, dynamic>)? onCardAdded;

  const AddCardDialogWidget({
    Key? key,
    this.onCardAdded,
  }) : super(key: key);

  @override
  State<AddCardDialogWidget> createState() => _AddCardDialogWidgetState();
}

class _AddCardDialogWidgetState extends State<AddCardDialogWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: 90.h,
          maxWidth: 90.w,
        ),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildCreditCardWidget(),
              _buildForm(),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'credit_card',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 6.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              'Add Credit/Debit Card',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: CustomIconWidget(
              iconName: 'close',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 5.w,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardWidget() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: CreditCardWidget(
        cardNumber: cardNumber,
        expiryDate: expiryDate,
        cardHolderName: cardHolderName,
        cvvCode: cvvCode,
        showBackView: isCvvFocused,
        obscureCardNumber: true,
        obscureCardCvv: true,
        isHolderNameVisible: true,
        cardBgColor: AppTheme.lightTheme.colorScheme.primary,
        backgroundImage: null,
        isSwipeGestureEnabled: true,
        onCreditCardWidgetChange: (CreditCardBrand creditCardBrand) {},
        customCardTypeIcons: <CustomCardTypeIcon>[],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            CreditCardForm(
              formKey: _formKey,
              obscureCvv: true,
              obscureNumber: true,
              cardNumber: cardNumber,
              cvvCode: cvvCode,
              isHolderNameVisible: true,
              isCardNumberVisible: true,
              isExpiryDateVisible: true,
              cardHolderName: cardHolderName,
              expiryDate: expiryDate,
              inputConfiguration: InputConfiguration(
                cardNumberDecoration: InputDecoration(
                  labelText: 'Card Number',
                  hintText: 'XXXX XXXX XXXX XXXX',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'credit_card',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 5.w,
                    ),
                  ),
                ),
                expiryDateDecoration: InputDecoration(
                  labelText: 'Expiry Date',
                  hintText: 'MM/YY',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'calendar_today',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 5.w,
                    ),
                  ),
                ),
                cvvCodeDecoration: InputDecoration(
                  labelText: 'CVV',
                  hintText: 'XXX',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'lock',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 5.w,
                    ),
                  ),
                ),
                cardHolderDecoration: InputDecoration(
                  labelText: 'Card Holder Name',
                  hintText: 'John Doe',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'person',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 5.w,
                    ),
                  ),
                ),
              ),
              onCreditCardModelChange: (CreditCardModel creditCardModel) {
                setState(() {
                  cardNumber = creditCardModel.cardNumber;
                  expiryDate = creditCardModel.expiryDate;
                  cardHolderName = creditCardModel.cardHolderName;
                  cvvCode = creditCardModel.cvvCode;
                  isCvvFocused = creditCardModel.isCvvFocused;
                });
              },
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'security',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 4.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Your card information is encrypted and secure',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: ElevatedButton(
              onPressed: isLoading ? null : _addCard,
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
                  : Text('Add Card'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      final cardData = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'type': 'card',
        'displayName': _getCardBrand(cardNumber),
        'lastFour': cardNumber
            .replaceAll(' ', '')
            .substring(cardNumber.replaceAll(' ', '').length - 4),
        'expiryDate': expiryDate,
        'holderName': cardHolderName,
        'isVerified': true,
        'isDefault': false,
      };

      if (widget.onCardAdded != null) {
        widget.onCardAdded!(cardData);
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Card added successfully'),
          backgroundColor: AppTheme.getSuccessColor(true),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add card. Please try again.'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _getCardBrand(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(' ', '');
    if (cleanNumber.startsWith('4')) {
      return 'Visa';
    } else if (cleanNumber.startsWith('5') || cleanNumber.startsWith('2')) {
      return 'Mastercard';
    } else if (cleanNumber.startsWith('3')) {
      return 'American Express';
    } else {
      return 'Credit Card';
    }
  }
}
