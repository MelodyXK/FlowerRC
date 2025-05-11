import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import '../controllers/search_controller.dart';
import '../providers/theme_provider.dart';

class SearchScreen extends StatelessWidget {
  final controller = Get.put(FlowerSearchController());

  Future<void> _showModelSelectionDialog(BuildContext context) async {
    String? newModel = controller.selectedModel.value;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          '选择模型',
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text('MobileNetV3', style: Theme.of(context).textTheme.bodyLarge),
                subtitle: Text('适合低性能设备，速度快', style: Theme.of(context).textTheme.bodyMedium),
                value: 'mobilenetv3',
                groupValue: newModel,
                onChanged: (value) => setState(() => newModel = value!),
                activeColor: Theme.of(context).primaryColor,
              ),
              RadioListTile<String>(
                title: Text('DenseNet121', style: Theme.of(context).textTheme.bodyLarge),
                subtitle: Text('中准确率，计算需求较高', style: Theme.of(context).textTheme.bodyMedium),
                value: 'densenet121',
                groupValue: newModel,
                onChanged: (value) => setState(() => newModel = value!),
                activeColor: Theme.of(context).primaryColor,
              ),
              RadioListTile<String>(
                title: Text('EfficientNetV2', style: Theme.of(context).textTheme.bodyLarge),
                subtitle: Text('高准确率，适合复杂场景', style: Theme.of(context).textTheme.bodyMedium),
                value: 'efficientnetv2',
                groupValue: newModel,
                onChanged: (value) => setState(() => newModel = value!),
                activeColor: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).scale(
          begin: Offset(0.9, 0.9),
          end: Offset(1.0, 1.0),
          curve: Curves.easeOut,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: Theme.of(context).textTheme.bodyLarge),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.changeModel(newModel!);
            },
            child: Text('确认', style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(themeProvider.theme == AppTheme.light ? 'assets/images/white.jpg' : 'assets/images/black.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Obx(() => Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.75,
                child: controller.isCameraInitialized.value
                    ? CameraPreview(controller.cameraController!).animate().fadeIn(duration: 500.ms)
                    : Center(child: CircularProgressIndicator()),
              ),
              Container(
                height: MediaQuery.of(context).size.height * 0.25,
                width: double.infinity,
                color: Theme.of(context).cardColor,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      right: 20,
                      top: 20,
                      child: GestureDetector(
                        onTap: controller.isModelLoading.value ? null : () => _showModelSelectionDialog(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).cardColor,
                                Theme.of(context).cardColor.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).shadowColor.withOpacity(0.2),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            controller.selectedModel.value == 'mobilenetv3'
                                ? 'MobileNetV3'
                                : controller.selectedModel.value == 'densenet121'
                                ? 'DenseNet121'
                                : 'EfficientNetV2',
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms).scale(
                        begin: Offset(0.8, 0.8),
                        end: Offset(1.0, 1.0),
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ),
                    ),
                    Positioned(
                      child: GestureDetector(
                        onTap: controller.takePicture,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 100),
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).cardColor,
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).shadowColor.withOpacity(0.2),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 40,
                      child: GFButton(
                        onPressed: controller.pickImageFromGallery,
                        text: '图库',
                        icon: Icon(Icons.photo_library, color: Theme.of(context).iconTheme.color),
                        shape: GFButtonShape.pills,
                        type: GFButtonType.transparent,
                        textStyle: Theme.of(context).textTheme.bodyLarge,
                      ).animate().fadeIn(delay: 200.ms),
                    ),
                  ],
                ),
              ),
            ],
          )),
        ),
      ],
    );
  }
}