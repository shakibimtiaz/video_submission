
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class VideoRecordController extends GetxController {
  CameraController? cameraController;
  RxBool isCameraInitialized = false.obs;
  RxBool isRecording = false.obs;
  RxBool isVideoSaved = false.obs;
  RxInt recordingTime = 0.obs;
  Timer? recordingTimer;
  final maxRecordingTime = 180;  
  String? videoPath;

  @override
  void onInit() {
    super.onInit();
    requestPermissions().then((_) => initializeCamera());
  }

  Future<bool> requestPermissions() async {
    bool hasCameraPermission = false;
    bool hasAudioPermission = false;
    bool hasStoragePermission = false;

    // Request camera permission
    if (await Permission.camera.isDenied) {
      var status = await Permission.camera.request();
      hasCameraPermission = status.isGranted;
    } else {
      hasCameraPermission = await Permission.camera.isGranted;
    }

    if (await Permission.microphone.isDenied) {
      var status = await Permission.microphone.request();
      hasAudioPermission = status.isGranted;
    } else {
      hasAudioPermission = await Permission.microphone.isGranted;
    }

     if (await Permission.storage.isDenied) {
      var status = await Permission.storage.request();
      hasStoragePermission = status.isGranted;
    } else {
      hasStoragePermission = await Permission.storage.isGranted;
    }

     if (Platform.isAndroid) {
      var sdkInt = await DeviceInfoPlugin().androidInfo.then((info) => info.version.sdkInt);
      if (sdkInt >= 30 && !hasStoragePermission) {
        if (await Permission.manageExternalStorage.isDenied) {
          var status = await Permission.manageExternalStorage.request();
          hasStoragePermission = status.isGranted;
        } else {
          hasStoragePermission = await Permission.manageExternalStorage.isGranted;
        }
      }
    }

     if (!hasCameraPermission || !hasAudioPermission || !hasStoragePermission) {
      if (Get.isSnackbarOpen == false) {
        Get.rawSnackbar(
          title: 'Permissions Required',
          message: 'Please grant camera, audio, and storage permissions',
          duration: const Duration(seconds: 5),
          onTap: (_) => openAppSettings(),
        );
      }
    }

    return hasCameraPermission && hasAudioPermission && hasStoragePermission;
  }

  Future<void> initializeCamera() async {
    // Skip initialization if permissions are not granted
    if (!await requestPermissions()) {
      if (Get.isSnackbarOpen == false) {
        Get.rawSnackbar(
          title: 'Error',
          message: 'Camera cannot be used without permissions',
          duration: const Duration(seconds: 5),
          onTap: (_) => openAppSettings(),
        );
      }
      return;
    }

    try {
       final cameras = await availableCameras().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Camera initialization timed out'),
      );

       final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => throw Exception('No front camera found'),
      );

      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: true,
      );

       await cameraController!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Camera controller initialization timed out'),
      );

      isCameraInitialized.value = true;
      if (Get.isSnackbarOpen == false) {
        Get.rawSnackbar(
          title: 'Success',
          message: 'Front camera initialized successfully',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize front camera: $e');
      }
      isCameraInitialized.value = false;
      if (Get.isSnackbarOpen == false) {
        Get.rawSnackbar(
          title: 'Error',
          message: 'Failed to initialize camera: $e',
          duration: const Duration(seconds: 5),
          onTap: (_) => openAppSettings(),
        );
      }
    }
  }

  Future<void> startRecording() async {
    if (!isCameraInitialized.value || isRecording.value) return;

    try {
      final tempDir = await getTemporaryDirectory();
      videoPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';

      await cameraController!.startVideoRecording();
      isRecording.value = true;
      recordingTime.value = 0;

      recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        recordingTime.value++;
        if (recordingTime.value >= maxRecordingTime) {
          stopRecording();
        }
      });
      if (kDebugMode) {
        print("Recording started");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to start recording: $e");
      }
      if (Get.isSnackbarOpen == false) {
        Get.rawSnackbar(
          title: 'Error',
          message: 'Failed to start recording',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> stopRecording() async {
    if (!isRecording.value) return;

    try {
      final videoFile = await cameraController!.stopVideoRecording();
      isRecording.value = false;
      recordingTimer?.cancel();

       final file = File(videoPath!);
      await file.writeAsBytes(await videoFile.readAsBytes());
      isVideoSaved.value = true;
    } catch (e) {
      if (kDebugMode) {
        print("Failed to stop recording: $e");
      }
      if (Get.isSnackbarOpen == false) {
        Get.rawSnackbar(
          title: 'Error',
          message: 'Failed to stop recording',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> saveVideo() async {
    if (!isVideoSaved.value || videoPath == null) return;

    try {
  
      bool hasPermission = await requestPermissions();

      String folderPath;
      String successMessage;

      if (hasPermission && Platform.isAndroid) {
        var sdkInt = await DeviceInfoPlugin().androidInfo.then((info) => info.version.sdkInt);
        if (sdkInt >= 30 && await Permission.manageExternalStorage.isGranted) {
          folderPath = '/storage/emulated/0/Shakib Recorder';
          successMessage = 'Video saved successfully to Shakib Recorder';
        } else {
          folderPath = '/storage/emulated/0/Movies/Shakib Recorder';
          successMessage = 'Video saved successfully to Movies/Shakib Recorder';
        }
      } else {
          final directory = await getExternalStorageDirectory();
        folderPath = '${directory!.path}/Shakib Recorder';
        successMessage = 'Video saved successfully to app storage';
      }

       final folder = Directory(folderPath);
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final newPath = '$folderPath/video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await File(videoPath!).copy(newPath);
      resetState();

      if (Get.isSnackbarOpen == false) {
        Get.rawSnackbar(
          title: 'Success',
          message: successMessage,
          duration: const Duration(seconds: 3),
        );
      }
      if (kDebugMode) {
        print("Video saved to $newPath");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to save video: $e");
      }
      if (Get.isSnackbarOpen == false) {
        Get.rawSnackbar(
          title: 'Error',
          message: 'Failed to save video: $e',
          duration: const Duration(seconds: 5),
          onTap: (_) => openAppSettings(),
        );
      }
    }
  }

  void resetState() {
    isRecording.value = false;
    isVideoSaved.value = false;
    recordingTime.value = 0;
    videoPath = null;
    recordingTimer?.cancel();
  }

  @override
  void onClose() {
    cameraController?.dispose();
    recordingTimer?.cancel();
    super.onClose();
  }
}
