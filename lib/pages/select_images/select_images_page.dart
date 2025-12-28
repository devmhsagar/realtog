import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/reusable_appbar.dart';

class SelectImagesPage extends ConsumerStatefulWidget {
  final String pricingPlanId;
  final double basePrice;
  final bool hasDecluttering;
  final int declutteringPrice;
  final double totalPrice;
  final int maxImages;

  const SelectImagesPage({
    super.key,
    required this.pricingPlanId,
    required this.basePrice,
    required this.hasDecluttering,
    required this.declutteringPrice,
    required this.totalPrice,
    required this.maxImages,
  });

  @override
  ConsumerState<SelectImagesPage> createState() => _SelectImagesPageState();
}

class _SelectImagesPageState extends ConsumerState<SelectImagesPage> {
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = [];

  Future<void> _pickImageFromCamera() async {
    if (_selectedImages.length >= widget.maxImages) {
      _showMaxImagesReachedDialog();
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100, // No compression - raw file
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing image: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_selectedImages.length >= widget.maxImages) {
      _showMaxImagesReachedDialog();
      return;
    }

    try {
      final int remainingSlots = widget.maxImages - _selectedImages.length;
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 100, // No compression - raw file
      );

      if (images.isNotEmpty) {
        setState(() {
          // Only add images up to the max limit
          final int imagesToAdd = images.length > remainingSlots
              ? remainingSlots
              : images.length;
          _selectedImages.addAll(images.take(imagesToAdd));

          // Show warning if user selected more than allowed
          if (images.length > remainingSlots) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Only $remainingSlots image(s) added. Maximum ${widget.maxImages} images allowed.',
                ),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting images: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showMaxImagesReachedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maximum Images Reached'),
        content: Text(
          'You can only select up to ${widget.maxImages} images for this package.',
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

  void _navigateToPayment() {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one image'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Pass file paths instead of XFile objects for navigation
    final imagePaths = _selectedImages.map((image) => image.path).toList();

    context.push(
      '/payment',
      extra: {
        'pricingPlanId': widget.pricingPlanId,
        'basePrice': widget.basePrice,
        'hasDecluttering': widget.hasDecluttering,
        'declutteringPrice': widget.declutteringPrice,
        'totalPrice': widget.totalPrice,
        'selectedImagePaths': imagePaths,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusableAppBar(
        title: 'Selected: ${_selectedImages.length}/${widget.maxImages}',
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Image grid
            Expanded(
              child: _selectedImages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 64.sp,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No images selected',
                            style: TextStyle(
                              fontSize: 18.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Capture or select images to get started',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.all(16.w),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8.w,
                        mainAxisSpacing: 8.h,
                        childAspectRatio: 1,
                      ),
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: Image.file(
                                File(_selectedImages[index].path),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4.h,
                              right: 4.w,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 16.sp,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 4.h,
                              left: 4.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: AppColors.textLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            // Camera and Gallery buttons container
            Container(
              padding: EdgeInsets.all(16.w),
              color: AppColors.appBarTitleBackground,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectedImages.length >= widget.maxImages
                          ? null
                          : _pickImageFromCamera,
                      icon: Icon(Icons.camera_alt, size: 20.sp),
                      label: const Text('Camera'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textLight,
                        side: BorderSide(color: AppColors.textLight),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectedImages.length >= widget.maxImages
                          ? null
                          : _pickImageFromGallery,
                      icon: Icon(Icons.photo_library, size: 20.sp),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textLight,
                        side: BorderSide(color: AppColors.textLight),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Continue to Payment button
            Container(
              padding: EdgeInsets.all(16.w),
              color: AppColors.surface,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _navigateToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textLight,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Continue to Payment',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
