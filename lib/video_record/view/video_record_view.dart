import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:video_submission/video_record/controller/video_record_controller.dart' show VideoRecordController;

class VideoRecordView extends StatelessWidget {
  const VideoRecordView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VideoRecordController());

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Obx(() => Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black),
                    ),
                    child: controller.isCameraInitialized.value
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CameraPreview(controller.cameraController!),
                          )
                        : Center(child: CircularProgressIndicator()),
                  )),
              Positioned(
                top: 10,
                left: 10,
                child: Obx(() => controller.isRecording.value
                    ? Text(
                        '${controller.recordingTime.value} sec',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          backgroundColor: Colors.black54,
                        ),
                      )
                    : SizedBox.shrink()),
              ),
              Positioned(
                top: 250,
                left: 80,
                child: Obx(() => controller.isVideoSaved.value
                    ? InkWell(
                        onTap: controller.resetState,
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.close, size: 24),
                        ),
                      )
                    : SizedBox.shrink()),
              ),
              Positioned(
                top: 250,
                left: 150,
                right: 150,
                child: Obx(() => Stack(
                      alignment: Alignment.center,
                      children: [
                        if (controller.isRecording.value)
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: controller.recordingTime.value / 180,
                              strokeWidth: 4,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.red),
                            ),
                          ),
                        InkWell(
                          onTap: () {
                            if (controller.isRecording.value) {
                              controller.stopRecording();
                            } else if (controller.isVideoSaved.value) {
                              controller.saveVideo();
                            } else {
                              controller.startRecording();
                            }
                          },
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Center(
                              child: InkWell(
                                onTap: () {
                                  if (controller.isRecording.value) {
                                    controller.stopRecording();
                                  } else if (controller.isVideoSaved.value) {
                                    controller.saveVideo();
                                  } else {
                                    controller.startRecording();
                                  }
                                },
                                child: Icon(
                                  controller.isVideoSaved.value
                                      ? Icons.check
                                      : controller.isRecording.value
                                          ? Icons.stop
                                          : Icons.video_camera_front_outlined,
                                  size: 34,
                                  color: controller.isRecording.value
                                      ? Colors.red
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}