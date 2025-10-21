import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/crop_selection_chips.dart';
import './widgets/custom_text_field.dart';
import './widgets/document_upload_button.dart';
import './widgets/farm_size_picker.dart';
import './widgets/password_strength_indicator.dart';
import './widgets/role_selection_card.dart';

class UserRegistration extends StatefulWidget {
  const UserRegistration({Key? key}) : super(key: key);

  @override
  State<UserRegistration> createState() => _UserRegistrationState();
}

class _UserRegistrationState extends State<UserRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _licenseController = TextEditingController();
  final _businessNameController = TextEditingController();

  // State variables
  String _selectedRole = '';
  String _selectedFarmSize = '';
  List<String> _selectedCrops = [];
  bool _obscurePassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;
  String? _credentialDocument;
  String? _businessDocument;

  // Mock user roles data
  final List<Map<String, dynamic>> userRoles = [
    {
      'id': 'farmer',
      'title': 'Farmer',
      'description': 'Sell your produce directly to buyers',
      'icon': 'agriculture',
    },
    {
      'id': 'veterinarian',
      'title': 'Veterinarian',
      'description': 'Provide consultation services to farmers',
      'icon': 'medical_services',
    },
    {
      'id': 'company',
      'title': 'Company',
      'description': 'Supply agricultural inputs and equipment',
      'icon': 'business',
    },
    {
      'id': 'buyer',
      'title': 'Buyer/Trader',
      'description': 'Purchase agricultural products directly',
      'icon': 'shopping_cart',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _licenseController.dispose();
    _businessNameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateLicense(String? value) {
    if (_selectedRole == 'veterinarian') {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter your veterinary license number';
      }
      if (value.trim().length < 5) {
        return 'License number must be at least 5 characters';
      }
    }
    return null;
  }

  String? _validateBusinessName(String? value) {
    if (_selectedRole == 'company') {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter your business name';
      }
      if (value.trim().length < 2) {
        return 'Business name must be at least 2 characters';
      }
    }
    return null;
  }

  void _selectRole(String roleId) {
    setState(() {
      _selectedRole = roleId;
      // Clear role-specific fields when switching roles
      _selectedFarmSize = '';
      _selectedCrops.clear();
      _licenseController.clear();
      _businessNameController.clear();
      _credentialDocument = null;
      _businessDocument = null;
    });
  }

  void _toggleCrop(String crop) {
    setState(() {
      if (_selectedCrops.contains(crop)) {
        _selectedCrops.remove(crop);
      } else {
        _selectedCrops.add(crop);
      }
    });
  }

  void _selectFarmSize(String size) {
    setState(() {
      _selectedFarmSize = size;
    });
  }

  void _uploadCredentialDocument() {
    // Simulate document upload
    setState(() {
      _credentialDocument =
          'veterinary_license_${DateTime.now().millisecondsSinceEpoch}.pdf';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document uploaded successfully'),
        backgroundColor: AppTheme.getSuccessColor(true),
      ),
    );
  }

  void _uploadBusinessDocument() {
    // Simulate document upload
    setState(() {
      _businessDocument =
          'business_registration_${DateTime.now().millisecondsSinceEpoch}.pdf';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document uploaded successfully'),
        backgroundColor: AppTheme.getSuccessColor(true),
      ),
    );
  }

  bool _isFormValid() {
    if (_selectedRole.isEmpty) return false;
    if (!_acceptTerms) return false;

    // Basic validation
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      return false;
    }

    // Role-specific validation
    if (_selectedRole == 'farmer') {
      if (_selectedFarmSize.isEmpty || _selectedCrops.isEmpty) return false;
    } else if (_selectedRole == 'veterinarian') {
      if (_licenseController.text.trim().isEmpty || _credentialDocument == null)
        return false;
    } else if (_selectedRole == 'company') {
      if (_businessNameController.text.trim().isEmpty ||
          _businessDocument == null) return false;
    }

    return true;
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isFormValid()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Account created successfully! Please verify your email.'),
          backgroundColor: AppTheme.getSuccessColor(true),
        ),
      );

      // Navigate to OTP verification or login
      Navigator.pushReplacementNamed(context, '/splash-screen');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed. Please try again.'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showUnsavedChangesDialog() {
    if (_nameController.text.isNotEmpty ||
        _emailController.text.isNotEmpty ||
        _phoneController.text.isNotEmpty ||
        _passwordController.text.isNotEmpty ||
        _selectedRole.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Unsaved Changes'),
          content: Text(
              'You have unsaved changes. Are you sure you want to go back?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildRoleSpecificFields() {
    switch (_selectedRole) {
      case 'farmer':
        return Column(
          children: [
            SizedBox(height: 3.h),
            FarmSizePicker(
              selectedSize: _selectedFarmSize,
              onSizeSelected: _selectFarmSize,
            ),
            SizedBox(height: 3.h),
            CropSelectionChips(
              selectedCrops: _selectedCrops,
              onCropToggle: _toggleCrop,
            ),
          ],
        );

      case 'veterinarian':
        return Column(
          children: [
            SizedBox(height: 3.h),
            CustomTextField(
              label: 'Veterinary License Number',
              hint: 'Enter your license number',
              controller: _licenseController,
              validator: _validateLicense,
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 3.h),
            DocumentUploadButton(
              label: 'Upload Veterinary Credentials',
              fileName: _credentialDocument,
              onTap: _uploadCredentialDocument,
              isRequired: true,
            ),
          ],
        );

      case 'company':
        return Column(
          children: [
            SizedBox(height: 3.h),
            CustomTextField(
              label: 'Business Name',
              hint: 'Enter your company name',
              controller: _businessNameController,
              validator: _validateBusinessName,
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 3.h),
            DocumentUploadButton(
              label: 'Upload Business Registration',
              fileName: _businessDocument,
              onTap: _uploadBusinessDocument,
              isRequired: true,
            ),
          ],
        );

      default:
        return SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: _showUnsavedChangesDialog,
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 6.w,
          ),
        ),
        title: Text(
          'Create Account',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(6.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Agricultural Logo
                Center(
                  child: Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: CustomIconWidget(
                      iconName: 'agriculture',
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
                      size: 12.w,
                    ),
                  ),
                ),

                SizedBox(height: 4.h),

                // Welcome Text
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Join AgriLink',
                        style: AppTheme.lightTheme.textTheme.headlineSmall
                            ?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Connect with the agricultural community',
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 4.h),

                // Role Selection
                Text(
                  'I am a...',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 2.h),

                ...userRoles
                    .map((role) => RoleSelectionCard(
                          title: role['title'],
                          description: role['description'],
                          iconName: role['icon'],
                          isSelected: _selectedRole == role['id'],
                          onTap: () => _selectRole(role['id']),
                        ))
                    .toList(),

                // Common Fields
                if (_selectedRole.isNotEmpty) ...[
                  SizedBox(height: 4.h),

                  CustomTextField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _nameController,
                    validator: _validateName,
                    keyboardType: TextInputType.name,
                  ),

                  SizedBox(height: 3.h),

                  CustomTextField(
                    label: 'Email Address',
                    hint: 'Enter your email',
                    controller: _emailController,
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  SizedBox(height: 3.h),

                  CustomTextField(
                    label: 'Phone Number',
                    hint: 'Enter your phone number',
                    controller: _phoneController,
                    validator: _validatePhone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[\d\s\-\(\)\+]')),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  CustomTextField(
                    label: 'Password',
                    hint: 'Create a strong password',
                    controller: _passwordController,
                    validator: _validatePassword,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: CustomIconWidget(
                        iconName:
                            _obscurePassword ? 'visibility' : 'visibility_off',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 5.w,
                      ),
                    ),
                  ),

                  PasswordStrengthIndicator(password: _passwordController.text),

                  // Role-specific fields
                  _buildRoleSpecificFields(),

                  SizedBox(height: 4.h),

                  // Terms and Conditions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (value) {
                          setState(() {
                            _acceptTerms = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _acceptTerms = !_acceptTerms;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.only(top: 1.5.h),
                            child: RichText(
                              text: TextSpan(
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                                children: [
                                  TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      color: AppTheme
                                          .lightTheme.colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: AppTheme
                                          .lightTheme.colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  // Create Account Button
                  SizedBox(
                    width: double.infinity,
                    height: 7.h,
                    child: ElevatedButton(
                      onPressed:
                          _isFormValid() && !_isLoading ? _createAccount : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormValid()
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.3),
                        foregroundColor: _isFormValid()
                            ? AppTheme.lightTheme.colorScheme.onPrimary
                            : AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                        elevation: _isFormValid() ? 2.0 : 0.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 6.w,
                              height: 6.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.lightTheme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              'Create Account',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                color: _isFormValid()
                                    ? AppTheme.lightTheme.colorScheme.onPrimary
                                    : AppTheme.lightTheme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Login Link
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(
                            context, '/splash-screen');
                      },
                      child: RichText(
                        text: TextSpan(
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                          children: [
                            TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 4.h),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
