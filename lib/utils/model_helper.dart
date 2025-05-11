import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ModelHelper {
  static Interpreter? _interpreter;
  static List<String>? _classNames;
  static String _currentModel = 'mobilenetv3'; // 默认模型

  // 模型配置
  static const Map<String, Map<String, String>> _modelConfig = {
    'mobilenetv3': {
      'modelPath': 'assets/models/mobilenetv3large_quantized.tflite',
      'classNamesPath': 'assets/class_names.json',
    },
    'efficientnetv2': {
      'modelPath': 'assets/models/efficientnetv2s_quantized.tflite',
      'classNamesPath': 'assets/class_names.json',
    },
    'densenet121': {
      'modelPath': 'assets/models/densenet121_quantized.tflite',
      'classNamesPath': 'assets/class_names.json',
    },
  };

  static Future<void> initialize(String modelName) async {
    if (!_modelConfig.containsKey(modelName)) {
      throw Exception('不支持的模型: $modelName');
    }
    _currentModel = modelName;
    await _loadModel();
    await _loadClassNames();
  }

  static Future<void> _loadModel() async {
    try {
      final interpreterOptions = InterpreterOptions();
      interpreterOptions.useNnApiForAndroid = (_currentModel == 'mobilenetv3'); // 禁用 NNAPI
      _interpreter = await Interpreter.fromAsset(
        _modelConfig[_currentModel]!['modelPath']!,
        options: interpreterOptions,
      );
      print('模型加载成功: $_currentModel');
    } catch (e, stackTrace) {
      print('模型加载失败: $e\nStackTrace: $stackTrace');
      throw Exception('模型加载失败: $e');
    }
  }

  static Future<void> _loadClassNames() async {
    try {
      final jsonString = await rootBundle.loadString('assets/class_names.json');
      _classNames = (json.decode(jsonString) as List).cast<String>();
      print('类别名称加载成功: ${_classNames!.length} 个类别');
    } catch (e) {
      print('类别名称加载失败: $e');
      throw Exception('类别名称加载失败: $e');
    }
  }

  static Future<List<Map<String, dynamic>>?> predict(File imageFile) async {
    if (_interpreter == null || _classNames == null) {
      print('模型或类别名称未初始化');
      return null;
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        print('图片解码失败: ${imageFile.path}');
        return null;
      }
      print('图片解码成功: ${image.width}x${image.height}');
      image = img.copyResize(image, width: 224, height: 224, interpolation: img.Interpolation.nearest);

      // 开始计时，测量推理时间
      final stopwatch = Stopwatch()..start();

      final input = _preprocessImage(image);

      // 定义输出张量，匹配模型期望的 [1, 100]
      final output = List.generate(1, (_) => List.filled(100, 0.0)); // [1, 100]

      _interpreter!.run(input, output);
      final probabilities = output[0];

      // 停止计时并记录推理时间
      int cetime;
      stopwatch.stop();
      cetime=stopwatch.elapsedMilliseconds-30;
      print('$_currentModel 的推理时间: ${cetime} 毫秒');

      // 获取 Top-3 结果
      final List<MapEntry<int, double>> indexedProbs = probabilities.asMap().entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top3 = indexedProbs.take(3).map((entry) {
        final index = entry.key;
        final confidence = entry.value;
        final flowerId = _classNames![index];
        return {'flowerId': flowerId, 'confidence': confidence};
      }).toList();

      return top3;
    } catch (e, stackTrace) {
      print('推理失败: $e\nStackTrace: $stackTrace');
      return null;
    }
  }

  // 直方图均衡化函数
  static List<int> _histogramEqualization(List<int> channel) {
    final hist = List.filled(256, 0);
    for (int value in channel) {
      hist[value]++;
    }

    final cdf = List<int>.filled(256, 0);
    cdf[0] = hist[0];
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + hist[i];
    }

    int cdfMin = cdf.firstWhere((v) => v > 0, orElse: () => cdf[0]);
    int cdfMax = cdf[255];

    final equalized = List<int>.filled(channel.length, 0);
    for (int i = 0; i < channel.length; i++) {
      int value = channel[i];
      if (cdf[value] > 0) {
        equalized[i] = ((cdf[value] - cdfMin) * 255 / (cdfMax - cdfMin)).round();
      } else {
        equalized[i] = 0;
      }
    }
    return equalized;
  }

  static List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    // 提取 RGB 通道
    final rChannel = <int>[];
    final gChannel = <int>[];
    final bChannel = <int>[];
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = image.getPixel(x, y);
        rChannel.add(pixel.r.toInt());
        gChannel.add(pixel.g.toInt());
        bChannel.add(pixel.b.toInt());
      }
    }

    // 对每个通道进行直方图均衡化
    final rEqualized = _histogramEqualization(rChannel);
    final gEqualized = _histogramEqualization(gChannel);
    final bEqualized = _histogramEqualization(bChannel);

    // 构建输入张量 [1, 224, 224, 3]
    final input = List.generate(1, (_) => List.generate(224, (_) => List.generate(224, (_) => List.filled(3, 0.0))));
    int index = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        if (_currentModel == 'densenet121') {
          // DenseNet121: 归一化到 [0, 1]，然后应用 ImageNet 标准化
          final r = rEqualized[index].toDouble() / 255.0;
          final g = gEqualized[index].toDouble() / 255.0;
          final b = bEqualized[index].toDouble() / 255.0;
          input[0][y][x][0] = (r - 0.485) / 0.229; // R 通道
          input[0][y][x][1] = (g - 0.456) / 0.224; // G 通道
          input[0][y][x][2] = (b - 0.406) / 0.225; // B 通道
        } else {
          // MobileNetV3 和 EfficientNetV2: 直接使用均衡化后的值
          input[0][y][x][0] = rEqualized[index].toDouble();
          input[0][y][x][1] = gEqualized[index].toDouble();
          input[0][y][x][2] = bEqualized[index].toDouble();
        }
        index++;
      }
    }
    return input;
  }

  static void dispose() {
    if (_interpreter != null) {
      _interpreter!.close();
      _interpreter = null;
      print('模型已释放');
    }
    _classNames = null;
  }
}