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
  StreamSubscription<CameraImage>? _imageStreamSubscription;
  double _roll = 0.0; // Rotation around Z-axis (horizon tilt)
  double _pitch = 0.0; // Rotation around X-axis (forward/backward tilt)
  static const double _levelThreshold = 2.0; // Degrees considered "level"
  static const double _verticalLevelTarget =
      -90.0; // Target pitch for vertical level in landscape (negative value)
  static const double _verticalLevelThreshold =
      10.0; // Degrees considered "vertically level" (wider range for detection)
  bool _isLowLight = false;
  static const double _lowLightThreshold =
      0.15; // Brightness threshold (0.0 to 1.0)
  DateTime? _lastBrightnessCheck;

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
        _startBrightnessMonitoring();
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

  void _startBrightnessMonitoring() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      _controller!.startImageStream((CameraImage image) {
        // Check brightness every 500ms to avoid performance issues
        final now = DateTime.now();
        if (_lastBrightnessCheck == null ||
            now.difference(_lastBrightnessCheck!).inMilliseconds > 500) {
          _lastBrightnessCheck = now;
          _checkBrightness(image);
        }
      });
    } catch (e) {
      debugPrint('Error starting image stream: $e');
    }
  }

  void _checkBrightness(CameraImage image) {
    try {
      final brightness = _calculateBrightness(image);
      if (mounted) {
        setState(() {
          _isLowLight = brightness < _lowLightThreshold;
        });
      }
    } catch (e) {
      debugPrint('Error checking brightness: $e');
    }
  }

  double _calculateBrightness(CameraImage image) {
    // Calculate average brightness from the image
    // For YUV420 format (Android), use Y plane
    // For BGRA8888 format (iOS), calculate from RGB

    if (image.format.group == ImageFormatGroup.yuv420) {
      // Android: Use Y plane (luminance)
      final yPlane = image.planes[0];
      final bytes = yPlane.bytes;
      int sum = 0;

      // Sample every 10th pixel for performance
      for (int i = 0; i < bytes.length; i += 10) {
        sum += bytes[i];
      }

      final avg = sum / (bytes.length / 10);
      return avg / 255.0; // Normalize to 0.0-1.0
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      // iOS: Calculate luminance from RGB
      final plane = image.planes[0];
      final bytes = plane.bytes;
      int sum = 0;
      int count = 0;

      // Sample every 40th pixel (BGRA = 4 bytes per pixel, so every 10th pixel)
      for (int i = 0; i < bytes.length - 3; i += 40) {
        // Extract RGB values (BGRA format)
        final b = bytes[i];
        final g = bytes[i + 1];
        final r = bytes[i + 2];

        // Calculate luminance using standard formula
        final luminance = (0.299 * r + 0.587 * g + 0.114 * b);
        sum += luminance.toInt();
        count++;
      }

      if (count > 0) {
        final avg = sum / count;
        return avg / 255.0; // Normalize to 0.0-1.0
      }
    }

    return 0.5; // Default if format not recognized
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
            final rollRadians = atan2(
              event.y,
              sqrt(event.x * event.x + event.z * event.z),
            );

            // Pitch: forward/backward tilt (rotation around left/right axis)
            // Positive pitch = tilted forward, Negative pitch = tilted backward
            final pitchRadians = atan2(
              -event.x,
              sqrt(event.y * event.y + event.z * event.z),
            );

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
    if (!_isInitialized ||
        _controller == null ||
        !_controller!.value.isInitialized) {
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

  // Check if vertical is level
  // In landscape mode, when device is level (not tilted forward/backward),
  // the pitch calculation gives -90° (negative value)
  bool get _isVerticalLevel {
    // Check if pitch is close to -90° (expected when level in landscape)
    final diffFromNeg90 = (_pitch - _verticalLevelTarget).abs();
    final isNearNeg90 = diffFromNeg90 <= _verticalLevelThreshold;

    // Also check if pitch is in the lower range (-90° to -80°) - near minimum clamp
    final isInLowerRange = _pitch <= (-90.0 + _verticalLevelThreshold);

    // Debug: Check console to see actual pitch values
    // debugPrint('Pitch: $_pitch, diffFromNeg90: $diffFromNeg90, isNearNeg90: $isNearNeg90, isInLowerRange: $isInLowerRange');

    return isNearNeg90 || isInLowerRange;
  }

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
    _imageStreamSubscription?.cancel();
    _controller?.stopImageStream();
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
                Positioned.fill(child: CameraPreview(_controller!))
              else
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),

              // Horizon level indicator
              if (_isInitialized)
                Positioned.fill(
                  child: _HorizonLevelIndicator(
                    roll: _roll,
                    pitch: _pitch,
                    isLevel: _isLevel,
                    isVerticalLevel: _isVerticalLevel,
                  ),
                ),

              // Low light warning message
              if (_isInitialized && _isLowLight)
                Positioned(
                  top: 80.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 32.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.textLight,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Text(
                              'Low light detected. Please increase the room lighting.',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Top bar with close button
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
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
                    mainAxisAlignment: MainAxisAlignment.start,
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
                  padding: EdgeInsets.symmetric(
                    vertical: 32.h,
                    horizontal: 16.w,
                  ),
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
  final bool isVerticalLevel;

  const _HorizonLevelIndicator({
    required this.roll,
    required this.pitch,
    required this.isLevel,
    required this.isVerticalLevel,
  });

  @override
  Widget build(BuildContext context) {
    final circleSize = 30.0;
    // Horizontal line and circle use green when level, red when not
    final horizontalLineColor = isLevel ? AppColors.success : AppColors.error;
    // Vertical line uses yellow only when vertically level (pitch ≈ 90°), red otherwise
    final verticalLineColor = isVerticalLevel
        ? AppColors.warning
        : AppColors.error;

    // Convert roll and pitch to radians for rotation
    // In landscape mode:
    // - Roll (left/right tilt) rotates the horizontal line for horizontal confirmation
    // - Pitch (forward/backward tilt) rotates the vertical line for vertical confirmation
    final rollRadians = roll * pi / 180.0;
    final pitchRadians = pitch * pi / 180.0;
    // Horizontal line: starts at 180 degrees (horizontal), then rotates by roll
    // 180° = pi radians = horizontal line pointing left
    final horizontalLineAngle = pi + rollRadians;
    // Vertical line: starts at 90 degrees (vertical), then rotates by pitch
    // 90° = pi/2 radians = vertical line pointing down
    // In landscape mode, when device is level, pitch calculation gives ~90° (not 0°)
    // So we use pitch directly: when pitch = 90° (level), line is at 90° (vertical)
    // When pitch deviates from 90°, the line rotates accordingly
    final verticalLineAngle =
        pitchRadians; // pitch already accounts for landscape orientation

    return IgnorePointer(
      child: Center(
        child: Container(
          width: circleSize.w,
          height: circleSize.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: horizontalLineColor, width: 1.w),
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
                      color: horizontalLineColor,
                    ),
                  ),
                ),
                // Horizontal line (starts at 180 degrees, rotates based on roll - for horizontal/roll confirmation)
                Center(
                  child: Transform.rotate(
                    angle: horizontalLineAngle,
                    child: Container(
                      width: circleSize.w,
                      height: 1.h,
                      decoration: BoxDecoration(color: horizontalLineColor),
                    ),
                  ),
                ),
                // Vertical line (starts at 90 degrees, rotates based on pitch - for vertical/pitch confirmation)
                // Yellow when level, red when not
                Center(
                  child: Transform.rotate(
                    angle: verticalLineAngle,
                    child: Container(
                      width: circleSize.w,
                      height: 1.5.h, // Slightly thicker for visibility
                      decoration: BoxDecoration(color: verticalLineColor),
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
