import 'package:get/get.dart';
import '../database/database_helper.dart';
import '../models/flower.dart';

class RecycleBinController extends GetxController {
  var deletedRecords = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var flowerCache = <String, Flower>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadDeletedRecords();
  }

  Future<void> loadDeletedRecords() async {
    isLoading.value = true;
    try {
      deletedRecords.value = await DatabaseHelper.instance.getDeletedRecords();
      // 预加载花卉数据
      for (var record in deletedRecords) {
        final flowerId = record['top1_flowerid'] as String;
        if (!flowerCache.containsKey(flowerId)) {
          final flower = await Flower.fromFlowerId(flowerId);
          if (flower != null) flowerCache[flowerId] = flower;
        }
      }
    } catch (e) {
      Get.snackbar('错误', '加载删除记录失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> restoreRecord(int id) async {
    try {
      await DatabaseHelper.instance.restoreRecord(id);
      await loadDeletedRecords();
      Get.snackbar('提示', '记录已恢复', duration: Duration(seconds: 2));
    } catch (e) {
      Get.snackbar('错误', '恢复记录失败: $e');
    }
  }

  Future<void> permanentlyDeleteRecord(int id) async {
    try {
      await DatabaseHelper.instance.permanentlyDeleteRecord(id);
      await loadDeletedRecords();
      Get.snackbar('提示', '记录已永久删除', duration: Duration(seconds: 2));
    } catch (e) {
      Get.snackbar('错误', '永久删除记录失败: $e');
    }
  }

  @override
  void onClose() {
    flowerCache.clear();
    super.onClose();
  }
}