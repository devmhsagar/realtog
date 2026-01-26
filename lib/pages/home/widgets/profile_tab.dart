import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../providers/auth_provider.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  Future<void> _handleProfilePictureUpdate() async {
    final ImagePicker imagePicker = ImagePicker();
    final AuthService authService = AuthService();

    // Show bottom sheet with options
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Text(
                'Select Profile Picture',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text(
                'Take Photo',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primary),
              title: Text(
                'Choose from Gallery',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      // Pick image
      final XFile? image = await imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (!context.mounted) return;

      // Close loading indicator
      Navigator.of(context).pop();

      if (image == null) return;

      // Upload image
      final result = await authService.updateProfilePicture(image);

      if (!context.mounted) return;

      result.fold(
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppColors.error,
            ),
          );
        },
        (profilePictureUrl) {
          // Invalidate profile data to refresh with new picture
          ref.invalidate(profileDataProvider);

          // Show success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile picture updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        // Close loading indicator if still open
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileDataProvider);

    return SafeArea(
      child: profileAsync.when(
        data: (profileUser) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Center(
                      child: _ProfileAvatar(
                        profilePicture: profileUser.profilePicture,
                        name: profileUser.name,
                        onTap: _handleProfilePictureUpdate,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    _ProfileMenuItem(
                      icon: Icons.person_outline,
                      label: 'Name',
                      value: profileUser.name,
                    ),
                    SizedBox(height: 8.h),
                    _ProfileMenuItem(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: profileUser.email,
                    ),
                    SizedBox(height: 8.h),
                    _ProfileMenuItem(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: profileUser.phone,
                    ),
                    SizedBox(height: 8.h),
                    _ProfileMenuItem(
                      icon: Icons.verified_user_outlined,
                      label: 'Email Verified',
                      value: profileUser.emailVerified ? 'Yes' : 'No',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to logout?',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true && context.mounted) {
                      await ref.read(authNotifierProvider.notifier).logout();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textLight,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
              SizedBox(height: 16.h),
              Text(
                'Failed to load profile',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(profileDataProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textLight,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatefulWidget {
  final String? profilePicture;
  final String name;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.profilePicture,
    required this.name,
    required this.onTap,
  });

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar> {
  bool _imageError = false;

  @override
  Widget build(BuildContext context) {
    final hasValidImage = widget.profilePicture != null &&
        widget.profilePicture!.isNotEmpty &&
        !_imageError;

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 40.r,
            backgroundColor: AppColors.primary,
            backgroundImage: hasValidImage
                ? NetworkImage(widget.profilePicture!)
                : null,
            child: !hasValidImage
                ? Text(
                    widget.name.isNotEmpty
                        ? widget.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  )
                : null,
            onBackgroundImageError: (exception, stackTrace) {
              if (mounted) {
                setState(() {
                  _imageError = true;
                });
              }
            },
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.background,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.camera_alt,
                size: 16.sp,
                color: AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 24.sp),
        title: Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      ),
    );
  }
}
