import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/constants/app_colors.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _roll = 0.0; // Rotation around Z-axis (horizon tilt)
  double _pitch = 0.0; // Rotation around X-axis (forward/backward tilt)
  static const double _levelThreshold = 2.0; // Degrees considered "level"

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startSensorListening();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No cameras available'),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.jpeg
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing camera: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _startSensorListening() {
    try {
      _accelerometerSubscription = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          if (mounted) {
            // Calculate roll (horizon tilt) and pitch using accelerometer data
            // For horizon level, we mainly care about roll (left/right tilt)
            // Roll: rotation around forward axis (Y-axis) - use X and Z
            // Pitch: rotation around side axis (X-axis) - use Y and Z
            // Using atan2 to get angle in radians, then convert to degrees
            final rollRadians = atan2(event.x, sqrt(event.y * event.y + event.z * event.z));
            final pitchRadians = atan2(event.y, sqrt(event.x * event.x + event.z * event.z));
            
            final roll = (rollRadians * 180.0 / pi).clamp(-90.0, 90.0);
            final pitch = (pitchRadians * 180.0 / pi).clamp(-90.0, 90.0);

            setState(() {
              _roll = roll;
              _pitch = pitch;
            });
          }
        },
        onError: (error) {
          debugPrint('Accelerometer error: $error');
          // If sensors are not available, just keep the indicator at 0 (level)
          // The camera will still work, just without the level indicator
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Failed to start accelerometer: $e');
      // If sensors are not available, the camera will still work
      // The horizon indicator will just show as level (0 degrees)
    }
  }

  Future<void> _captureImage() async {
    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile image = await _controller!.takePicture();
      
      if (mounted) {
        Navigator.of(context).pop(image);
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing image: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  bool get _isLevel => _roll.abs() < _levelThreshold;

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview
            if (_isInitialized && _controller != null)
              Positioned.fill(
                child: CameraPreview(_controller!),
              )
            else
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),

            // Horizon level indicator
            if (_isInitialized)
              Positioned.fill(
                child: _HorizonLevelIndicator(
                  roll: _roll,
                  pitch: _pitch,
                  isLevel: _isLevel,
                ),
              ),

            // Top bar with close button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: AppColors.textLight,
                        size: 28.sp,
                      ),
                    ),
                    // Level status indicator
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: _isLevel
                            ? AppColors.success.withOpacity(0.8)
                            : AppColors.error.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isLevel ? Icons.check_circle : Icons.trending_flat,
                            color: AppColors.textLight,
                            size: 16.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            _isLevel ? 'Level' : '${_roll.toStringAsFixed(1)}°',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Capture button
                    GestureDetector(
                      onTap: _isCapturing ? null : _captureImage,
                      child: Container(
                        width: 72.w,
                        height: 72.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isCapturing
                              ? AppColors.textSecondary
                              : AppColors.textLight,
                          border: Border.all(
                            color: AppColors.textLight,
                            width: 4.w,
                          ),
                        ),
                        child: _isCapturing
                            ? Padding(
                                padding: EdgeInsets.all(20.w),
                                child: const CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 3,
                                ),
                              )
                            : Icon(
                                Icons.camera_alt,
                                color: AppColors.primary,
                                size: 32.sp,
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
    );
  }
}

/// Horizon level indicator widget
class _HorizonLevelIndicator extends StatelessWidget {
  final double roll;
  final double pitch;
  final bool isLevel;

  const _HorizonLevelIndicator({
    required this.roll,
    required this.pitch,
    required this.isLevel,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate offset for horizontal line based on roll
    // Positive roll = tilted right = line moves down
    // Negative roll = tilted left = line moves up
    final maxOffset = 100.0; // Maximum offset in pixels
    final offset = (roll / 90.0) * maxOffset;

    return IgnorePointer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Horizontal line indicator (moves up/down based on roll)
            Transform.translate(
              offset: Offset(0, offset),
              child: Container(
                width: double.infinity,
                height: 2.h,
                margin: EdgeInsets.symmetric(horizontal: 40.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      isLevel ? AppColors.success : AppColors.error,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Circle indicator with center dot (shows roll angle)
            Transform.rotate(
              angle: roll * pi / 180.0, // Rotate circle based on roll
              child: Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isLevel ? AppColors.success : AppColors.error,
                    width: 2.w,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLevel ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Vertical alignment indicator (shows pitch)
            Transform.translate(
              offset: Offset(pitch / 90.0 * 50.0, 0), // Move left/right based on pitch
              child: Container(
                width: 2.w,
                height: 100.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      isLevel ? AppColors.success : AppColors.error,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
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

