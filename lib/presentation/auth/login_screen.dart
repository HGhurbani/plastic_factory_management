// plastic_factory_management/lib/presentation/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/core/services/auth_service.dart';
import 'package:plastic_factory_management/presentation/routes/app_router.dart'; // استخدام المسارات

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signInWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.homeRoute); // الانتقال إلى الشاشة الرئيسية
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message; // رسالة الخطأ من Firebase
      });
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.loginErrorGeneric; // رسالة خطأ عامة
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _quickSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signInOrCreate(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.homeRoute);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.loginErrorGeneric;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.loginTitle),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // يمكنك إضافة شعار أو أيقونة هنا
              // Image.asset('assets/logo.png', height: 100),
              // SizedBox(height: 48),

              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: appLocalizations.emailHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                textAlign: TextAlign.right, // لمحاذاة النص للغة العربية
                textDirection: TextDirection.rtl, // لاتجاه الكتابة من اليمين لليسار
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: appLocalizations.passwordHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                textAlign: TextAlign.right, // لمحاذاة النص للغة العربية
                textDirection: TextDirection.rtl, // لاتجاه الكتابة من اليمين لليسار
              ),
              SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              _isLoading
                  ? CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: Text(
                            appLocalizations.signInButton,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _quickSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: Text(
                            appLocalizations.quickSignInButton,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}