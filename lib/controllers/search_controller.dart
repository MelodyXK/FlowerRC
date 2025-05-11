import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/model_helper.dart';
import '../database/database_helper.dart';
import '../screens/result_screen.dart';

class FlowerSearchController extends GetxController {
  CameraController? cameraController;
  var isCameraInitialized = false.obs;
  var isModelLoading = false.obs;
  var selectedModel = 'mobilenetv3'.obs;
  final ImagePicker picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
    initializeModel();
  }

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      cameraController = CameraController(cameras.first, ResolutionPreset.low);
      await cameraController!.initialize();
      isCameraInitialized.value = true;
    } catch (e) {
      Get.snackbar('错误', '相机初始化失败: $e');
    }
  }

  Future<void> initializeModel() async {
    isModelLoading.value = true;
    try {
      await ModelHelper.initialize(selectedModel.value);
    } catch (e) {
      Get.snackbar('错误', '模型初始化失败: $e');
    } finally {
      isModelLoading.value = false;
    }
  }

  Future<void> takePicture() async {
    if (isModelLoading.value) {
      Get.snackbar('提示', '模型正在加载，请稍后');
      return;
    }
    try {
      final image = await cameraController!.takePicture();
      final predictions = await ModelHelper.predict(File(image.path));
      if (predictions != null) {
        await DatabaseHelper.instance.addRecognitionRecord(
          imagePath: image.path,
          predictions: predictions,
          modelUsed: selectedModel.value,
        );
        Get.off(() => ResultScreen(predictions: predictions, imagePath: image.path));
      } else {
        Get.snackbar('错误', '无法识别图片：模型未正确加载');
      }
    } catch (e) {
      Get.snackbar('错误', '拍照失败：$e');
    }
  }

  Future<void> pickImageFromGallery() async {
    if (isModelLoading.value) {
      Get.snackbar('提示', '模型正在加载，请稍后');
      return;
    }
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final predictions = await ModelHelper.predict(File(pickedFile.path));
        if (predictions != null) {
          await DatabaseHelper.instance.addRecognitionRecord(
            imagePath: pickedFile.path,
            predictions: predictions,
            modelUsed: selectedModel.value,
          );
          Get.off(() => ResultScreen(predictions: predictions, imagePath: pickedFile.path));
        } else {
          Get.snackbar('错误', '无法识别图片：模型未正确加载');
        }
      }
    } catch (e) {
      Get.snackbar('错误', '选择图片失败：$e');
    }
  }

  Future<void> changeModel(String newModel) async {
    if (newModel != selectedModel.value) {
      isModelLoading.value = true;
      try {
        ModelHelper.dispose();
        selectedModel.value = newModel;
        await ModelHelper.initialize(selectedModel.value);
      } catch (e) {
        Get.snackbar('错误', '模型切换失败，将使用默认模型');
        selectedModel.value = 'mobilenetv3';
        await ModelHelper.initialize(selectedModel.value);
      } finally {
        isModelLoading.value = false;
      }
    }
  }

  @override
  void onClose() {
    cameraController?.dispose();
    ModelHelper.dispose();
    super.onClose();
  }
}