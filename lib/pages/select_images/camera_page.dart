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

  double _roll = 0.0;
  double _pitch = 0.0;

  static const double _levelThreshold = 2.0;
  static const double _verticalLevelTarget = -90.0;
  static const double _verticalLevelThreshold = 10.0;

  bool _isLowLight = false;
  bool _showLowLightWarning = true;
  DateTime? _lastBrightnessCheck;
  static const double _lowLightThreshold = 0.60;

  // Zoom
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;

  // 🔥 Exposure (NEW)
  double _currentExposure = 0.0;
  double _minExposure = 0.0;
  double _maxExposure = 0.0;
  bool _showExposureBar = false;
  Timer? _exposureTimer;

  // Grid
  bool _showGrid = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initializeCamera();
    _startSensorListening();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras ??= await availableCameras();
      final rearCamera =
      _cameras!.firstWhere((c) => c.lensDirection == CameraLensDirection.back);

      await _controller?.dispose();

      _controller = CameraController(
        rearCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup:
        Platform.isAndroid ? ImageFormatGroup.jpeg : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();

      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();
      _currentZoom = _minZoom < 1.0 ? _minZoom : 1.0;

      await _controller!.setZoomLevel(_currentZoom);

      // 🔥 Exposure init
      _minExposure = await _controller!.getMinExposureOffset();
      _maxExposure = await _controller!.getMaxExposureOffset();

      setState(() => _isInitialized = true);
      _startBrightnessMonitoring();
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  void _toggleExposureBar() {
    setState(() => _showExposureBar = true);

    _exposureTimer?.cancel();
    _exposureTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showExposureBar = false);
    });
  }

  void _startBrightnessMonitoring() {
    _controller?.startImageStream((image) {
      final now = DateTime.now();
      if (_lastBrightnessCheck == null ||
          now.difference(_lastBrightnessCheck!).inMilliseconds > 500) {
        _lastBrightnessCheck = now;
        final brightness = _calculateBrightness(image);
        if (mounted) {
          setState(() {
            _isLowLight = brightness < _lowLightThreshold;
          });
        }
      }
    });
  }

  double _calculateBrightness(CameraImage image) {
    final plane = image.planes.first;
    int sum = 0;
    for (int i = 0; i < plane.bytes.length; i += 20) {
      sum += plane.bytes[i];
    }
    return (sum / (plane.bytes.length / 20)) / 255.0;
  }

  void _startSensorListening() {
    _accelerometerSubscription =
        accelerometerEventStream().listen((event) {
          final roll =
              atan2(event.y, sqrt(event.x * event.x + event.z * event.z)) *
                  180 /
                  pi;

          final pitch =
              atan2(-event.x, sqrt(event.y * event.y + event.z * event.z)) *
                  180 /
                  pi;

          if (mounted) {
            setState(() {
              _roll = roll;
              _pitch = pitch;
            });
          }
        });
  }

  bool get _isLevel => _roll.abs() < _levelThreshold;

  bool get _isVerticalLevel =>
      (_pitch - _verticalLevelTarget).abs() <= _verticalLevelThreshold;

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final image = await _controller!.takePicture();
      await _popWithOrientationRestore(image);
    } catch (e) {
      debugPrint("Capture error: $e");
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _popWithOrientationRestore([dynamic result]) async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    if (mounted) Navigator.pop(context, result);
  }

  @override
  void dispose() {
    _exposureTimer?.cancel();
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
    return GestureDetector(
      onTap: () => setState(() => _showExposureBar = false),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isInitialized
            ? Stack(
          children: [
            // 🔥 3:2 FORMAT FIX
            Positioned.fill(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 3 / 2,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),

            if (_showGrid)
              Positioned.fill(child: CustomPaint(painter: _GridPainter())),

            // 🔥 Level Indicator (Tap to open exposure)
            Positioned.fill(
              child: Center(
                child: GestureDetector(
                  onTap: _toggleExposureBar,
                  child: _HorizonLevelIndicator(
                    roll: _roll,
                    pitch: _pitch,
                    isLevel: _isLevel,
                    isVerticalLevel: _isVerticalLevel,
                  ),
                ),
              ),
            ),


            if (_showExposureBar)
              Positioned(
                top: MediaQuery.of(context).size.height / 2 - 100,
                left: MediaQuery.of(context).size.width / 2 + 50,
                child: Container(
                  height: 200,
                  width: 40,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Slider(
                      value: _currentExposure.clamp(_minExposure, _maxExposure),
                      min: _minExposure,
                      max: _maxExposure,
                      activeColor: Colors.orange,
                      onChanged: (value) async {
                        setState(() {
                          _currentExposure = value;
                        });
                        await _controller!.setExposureOffset(value);
                      },
                    ),
                  ),
                ),
              ),

            // Close Button
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _popWithOrientationRestore,
              ),
            ),

            // Capture Button
            Positioned(
              right: 20,
              top: 55,
              child: GestureDetector(
                onTap: _captureImage,
                child: Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Icon(Icons.camera_alt,
                      color: AppColors.primary, size: 12.sp),
                ),
              ),
            ),
          // Low light message (Original design restored)
            if (_isLowLight && _showLowLightWarning)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          "Low light detected. Increase room lighting.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      Positioned(
                        top: -8,
                        right: -4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showLowLightWarning = false;
                            });
                          },
                          child: Container(
                            width: 10.w,
                            height: 10.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.close,
                              size: 8.sp,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Zoom
            Positioned(
              right: 20,
              bottom: 80,
              child: Column(
                children: [
                  RotatedBox(
                    quarterTurns: 3,
                    child: SizedBox(
                      width: 120,
                      child: Slider(
                        value:
                        _currentZoom.clamp(_minZoom, _maxZoom),
                        min: _minZoom,
                        max: _maxZoom,
                        activeColor: AppColors.primary,
                        onChanged: (value) async {
                          setState(() {
                            _currentZoom = value;
                          });
                          await _controller!
                              .setZoomLevel(value);
                        },
                      ),
                    ),
                  ),
                  Text(
                    "${_currentZoom.toStringAsFixed(1)}x",
                    style:
                    const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        )
            : const Center(
            child:
            CircularProgressIndicator(color: AppColors.primary)),
      ),
    );
  }
}
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
    final circleSize = 60.0;
    final horizontalColor =
    isLevel ? Colors.green : Colors.red;
    final verticalColor =
    isVerticalLevel ? Colors.orange : Colors.red;

    final rollRadians = roll * pi / 180;
    final pitchRadians = pitch * pi / 180;

    return Center(
      child: Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: horizontalColor, width: 2),
        ),
        child: Stack(
          children: [
            Center(
              child: Transform.rotate(
                angle: pi + rollRadians,
                child: Container(
                  width: circleSize,
                  height: 2,
                  color: horizontalColor,
                ),
              ),
            ),
            Center(
              child: Transform.rotate(
                angle: pitchRadians,
                child: Container(
                  width: circleSize,
                  height: 2,
                  color: verticalColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1;

    canvas.drawLine(
        Offset(size.width / 3, 0),
        Offset(size.width / 3, size.height),
        paint);

    canvas.drawLine(
        Offset(size.width * 2 / 3, 0),
        Offset(size.width * 2 / 3, size.height),
        paint);

    canvas.drawLine(
        Offset(0, size.height / 3),
        Offset(size.width, size.height / 3),
        paint);

    canvas.drawLine(
        Offset(0, size.height * 2 / 3),
        Offset(size.width, size.height * 2 / 3),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
