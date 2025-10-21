import 'package:flutter/material.dart';

import '../core/app_export.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';

class AuthWrapperWidget extends StatefulWidget {
  final Widget child;
  final bool requireAuth;

  const AuthWrapperWidget({
    Key? key,
    required this.child,
    this.requireAuth = true,
  }) : super(key: key);

  @override
  State<AuthWrapperWidget> createState() => _AuthWrapperWidgetState();
}

class _AuthWrapperWidgetState extends State<AuthWrapperWidget> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();

    // Listen to auth state changes
    AuthService.instance.authStateChanges.listen((authState) {
      if (mounted) {
        _checkAuthStatus();
      }
    });
  }

  void _checkAuthStatus() {
    if (!widget.requireAuth) return;

    final isLoggedIn = AuthService.instance.isLoggedIn;

    if (!isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.requireAuth && !AuthService.instance.isLoggedIn) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return widget.child;
  }
}
