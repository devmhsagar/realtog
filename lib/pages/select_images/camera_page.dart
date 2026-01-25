import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    // Set orientation to landscape for camera page
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initializeCamera();
    _startSensorListening();
  }

  Future<void> _initializeCamera() async {
    try {
      if (_cameras == null) {
        _cameras = await availableCameras();
        if (_cameras == null || _cameras!.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No cameras available'),
                backgroundColor: AppColors.error,
              ),
            );
            _popWithOrientationRestore();
          }
          return;
        }
      }

      // Find rear camera
      CameraDescription? rearCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.back) {
          rearCamera = camera;
          break;
        }
      }

      if (rearCamera == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rear camera not available'),
              backgroundColor: AppColors.error,
            ),
          );
          _popWithOrientationRestore();
        }
        return;
      }

      // Dispose previous controller if exists
      await _controller?.dispose();

      _controller = CameraController(
        rearCamera,
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
        if (!_isInitialized) {
          _popWithOrientationRestore();
        }
      }
    }
  }

  void _startSensorListening() {
    try {
      _accelerometerSubscription = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          if (mounted) {
            // Calculate roll and pitch for landscape orientation
            // In landscape mode, axes are rotated:
            // - Roll (left/right tilt): rotation around forward axis - use Y and Z
            // - Pitch (forward/backward tilt): rotation around side axis - use X and Z
            // When level in landscape: X ≈ -9.8 (gravity down), Y ≈ 0, Z ≈ 0
            
            // Roll: left/right tilt (rotation around forward/backward axis)
            // Positive roll = tilted right, Negative roll = tilted left
            final rollRadians = atan2(event.y, sqrt(event.x * event.x + event.z * event.z));
            
            // Pitch: forward/backward tilt (rotation around left/right axis)
            // Positive pitch = tilted forward, Negative pitch = tilted backward
            final pitchRadians = atan2(-event.x, sqrt(event.y * event.y + event.z * event.z));
            
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
        await _popWithOrientationRestore(image);
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

  /// Restores portrait orientation and pops the route
  Future<void> _popWithOrientationRestore([dynamic result]) async {
    // Restore portrait orientation before navigation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // Wait a frame to ensure orientation is applied
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  void dispose() {
    // Restore portrait orientation when leaving camera page (fallback)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _accelerometerSubscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _popWithOrientationRestore();
        }
      },
      child: Scaffold(
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
                      onPressed: () => _popWithOrientationRestore(),
                      icon: Icon(
                        Icons.close,
                        color: AppColors.textLight,
                        size: 14.sp,
                      ),
                      padding: EdgeInsets.all(8.w),
                      constraints: const BoxConstraints(),
                    ),
                    // Level status indicator
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: _isLevel
                            ? AppColors.success.withOpacity(0.8)
                            : AppColors.error.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isLevel ? Icons.check_circle : Icons.trending_flat,
                            color: AppColors.textLight,
                            size: 8.sp,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            _isLevel ? 'Level' : '${_roll.toStringAsFixed(1)}°',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 6.sp,
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
                child: Center(
                  child: GestureDetector(
                    onTap: _isCapturing ? null : _captureImage,
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCapturing
                            ? AppColors.textSecondary
                            : AppColors.textLight,
                        border: Border.all(
                          color: AppColors.textLight,
                          width: 2.w,
                        ),
                      ),
                      child: _isCapturing
                          ? Padding(
                              padding: EdgeInsets.all(10.w),
                              child: const CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 3,
                              ),
                            )
                          : Icon(
                              Icons.camera_alt,
                              color: AppColors.primary,
                              size: 16.sp,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
    // Calculate offset for horizontal line based on roll (in landscape mode)
    // Positive roll = tilted right = line moves right
    // Negative roll = tilted left = line moves left
    final circleSize = 30.0;
    final maxOffset = circleSize * 0.4; // Maximum offset within circle
    final horizontalOffset = (roll / 90.0) * maxOffset;
    
    // Calculate offset for vertical line based on pitch (in landscape mode)
    // Positive pitch = tilted forward = line moves down
    // Negative pitch = tilted backward = line moves up
    final verticalOffset = (pitch / 90.0) * maxOffset;

    final lineColor = isLevel ? AppColors.success : AppColors.error;

    return IgnorePointer(
      child: Center(
        child: Container(
          width: circleSize.w,
          height: circleSize.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: lineColor,
              width: 1.w,
            ),
          ),
          child: ClipOval(
            child: Stack(
              children: [
                // Center dot
                Center(
                  child: Container(
                    width: 4.w,
                    height: 4.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: lineColor,
                    ),
                  ),
                ),
                // Horizontal line (inside circle, moves left/right based on roll)
                Center(
                  child: Transform.translate(
                    offset: Offset(horizontalOffset, 0),
                    child: Container(
                      width: circleSize.w,
                      height: 1.h,
                      decoration: BoxDecoration(
                        color: lineColor,
                      ),
                    ),
                  ),
                ),
                // Vertical line (inside circle, moves up/down based on pitch)
                Center(
                  child: Transform.translate(
                    offset: Offset(0, verticalOffset),
                    child: Container(
                      width: 1.w,
                      height: circleSize.w,
                      decoration: BoxDecoration(
                        color: lineColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

