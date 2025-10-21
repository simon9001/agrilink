
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class CameraScreenWidget extends StatefulWidget {
  final Function(XFile) onImageCaptured;

  const CameraScreenWidget({
    Key? key,
    required this.onImageCaptured,
  }) : super(key: key);

  @override
  State<CameraScreenWidget> createState() => _CameraScreenWidgetState();
}

class _CameraScreenWidgetState extends State<CameraScreenWidget> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> _initializeCamera() async {
    try {
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      final camera = kIsWeb
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first)
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first);

      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        await _applySettings();
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _applySettings() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    try {
      await _cameraController!.setFocusMode(FocusMode.auto);
      if (!kIsWeb) {
        await _cameraController!.setFlashMode(FlashMode.auto);
      }
    } catch (e) {
      debugPrint('Camera settings error: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    try {
      final XFile photo = await _cameraController!.takePicture();
      widget.onImageCaptured(photo);
    } catch (e) {
      debugPrint('Photo capture error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        widget.onImageCaptured(image);
      }
    } catch (e) {
      debugPrint('Gallery pick error: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        kIsWeb) return;

    try {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      await _cameraController!
          .setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    } catch (e) {
      debugPrint('Flash toggle error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _cameraController == null) return;

    try {
      final currentCamera = _cameraController!.description;
      final newCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection != currentCamera.lensDirection,
        orElse: () => currentCamera,
      );

      await _cameraController!.dispose();
      _cameraController = CameraController(
        newCamera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
        await _applySettings();
      }
    } catch (e) {
      debugPrint('Camera switch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview
            if (_isCameraInitialized && _cameraController != null)
              Positioned.fill(
                child: AspectRatio(
                  aspectRatio: _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),

            // Top controls
            Positioned(
              top: 2.h,
              left: 4.w,
              right: 4.w,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: CustomIconWidget(
                        iconName: 'close',
                        color: Colors.white,
                        size: 6.w,
                      ),
                    ),
                  ),
                  if (!kIsWeb)
                    GestureDetector(
                      onTap: _toggleFlash,
                      child: Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: CustomIconWidget(
                          iconName: _isFlashOn ? 'flash_on' : 'flash_off',
                          color: Colors.white,
                          size: 6.w,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 4.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery button
                  GestureDetector(
                    onTap: _pickFromGallery,
                    child: Container(
                      width: 15.w,
                      height: 15.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3.w),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: CustomIconWidget(
                        iconName: 'photo_library',
                        color: Colors.white,
                        size: 8.w,
                      ),
                    ),
                  ),

                  // Capture button
                  GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        margin: EdgeInsets.all(1.w),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  // Switch camera button
                  if (_cameras.length > 1)
                    GestureDetector(
                      onTap: _switchCamera,
                      child: Container(
                        width: 15.w,
                        height: 15.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3.w),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: CustomIconWidget(
                          iconName: 'flip_camera_ios',
                          color: Colors.white,
                          size: 8.w,
                        ),
                      ),
                    )
                  else
                    SizedBox(width: 15.w),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
