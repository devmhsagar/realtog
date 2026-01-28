import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:realtog/core/constants/app_colors.dart';
import 'package:realtog/core/services/auth_service.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordPage({super.key, required this.email, required this.otp});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  static final _lowerCaseRegex = RegExp(r'[a-z]');
  static final _upperCaseRegex = RegExp(r'[A-Z]');
  static final _specialCharRegex = RegExp(
    r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;`~/]',
  );

  bool _hasMinLength(String value) => value.length >= 8;
  bool _hasLowerCase(String value) => _lowerCaseRegex.hasMatch(value);
  bool _hasUpperCase(String value) => _upperCaseRegex.hasMatch(value);
  bool _hasSpecialChar(String value) => _specialCharRegex.hasMatch(value);

  bool get _newPasswordIsValid =>
      _hasMinLength(_newPasswordController.text) &&
      _hasLowerCase(_newPasswordController.text) &&
      _hasUpperCase(_newPasswordController.text) &&
      _hasSpecialChar(_newPasswordController.text);

  void _onNewPasswordChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_onNewPasswordChanged);
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_onNewPasswordChanged);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authService = AuthService();
      final result = await authService.resetPassword(
        email: widget.email,
        otp: widget.otp,
        newPassword: _newPasswordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      result.fold(
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: AppColors.error),
          );
        },
        (email) {
          // Success - show success message and navigate to login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Password reset successfully. You can now login with your new password.',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          // Navigate to login page
          context.go('/login');
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title
                          Text(
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Enter your new password',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 48.h),

                          // New Password Field
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: _obscureNewPassword,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: 'Enter new password',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNewPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureNewPassword = !_obscureNewPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your new password';
                              }
                              if (!_hasMinLength(value)) {
                                return 'Password must be at least 8 characters';
                              }
                              if (!_hasLowerCase(value)) {
                                return 'Password must contain at least one lowercase letter';
                              }
                              if (!_hasUpperCase(value)) {
                                return 'Password must contain at least one uppercase letter';
                              }
                              if (!_hasSpecialChar(value)) {
                                return 'Password must contain at least one special character';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12.h),

                          // Password requirements checklist
                          _PasswordRequirementsList(
                            password: _newPasswordController.text,
                            hasMinLength: _hasMinLength(
                              _newPasswordController.text,
                            ),
                            hasLowerCase: _hasLowerCase(
                              _newPasswordController.text,
                            ),
                            hasUpperCase: _hasUpperCase(
                              _newPasswordController.text,
                            ),
                            hasSpecialChar: _hasSpecialChar(
                              _newPasswordController.text,
                            ),
                          ),
                          SizedBox(height: 20.h),

                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleResetPassword(),
                            decoration: InputDecoration(
                              hintText: 'Confirm new password',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 32.h),

                          // Reset Password Button
                          SizedBox(
                            height: 56.h,
                            child: ElevatedButton(
                              onPressed: _isLoading || !_newPasswordIsValid
                                  ? null
                                  : _handleResetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.white,
                                foregroundColor: AppColors.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                disabledBackgroundColor: AppColors.white
                                    .withValues(alpha: 0.6),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 24.h,
                                      width: 24.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.primary,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'Reset Password',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _PasswordRequirementsList extends StatelessWidget {
  const _PasswordRequirementsList({
    required this.password,
    required this.hasMinLength,
    required this.hasLowerCase,
    required this.hasUpperCase,
    required this.hasSpecialChar,
  });

  final String password;
  final bool hasMinLength;
  final bool hasLowerCase;
  final bool hasUpperCase;
  final bool hasSpecialChar;

  @override
  Widget build(BuildContext context) {
    final requirements = <({String label, bool satisfied})>[
      (label: 'At least 8 characters', satisfied: hasMinLength),
      (label: 'One uppercase letter', satisfied: hasUpperCase),
      (label: 'One lowercase letter', satisfied: hasLowerCase),
      (label: 'One special character', satisfied: hasSpecialChar),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: requirements
          .map(
            (r) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                children: [
                  Icon(
                    r.satisfied ? Icons.check_circle : Icons.circle_outlined,
                    size: 20.r,
                    color: r.satisfied
                        ? AppColors.textLight
                        : AppColors.textLight.withValues(alpha: 0.65),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    r.label,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: r.satisfied
                          ? AppColors.textLight
                          : AppColors.textLight.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
