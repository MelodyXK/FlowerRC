import 'package:get/get.dart';
import '../database/database_helper.dart';

class RecognitionHistoryController extends GetxController {
  var records = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var noteInput = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadRecords();
  }

  Future<void> loadRecords() async {
    isLoading.value = true;
    try {
      records.value = await DatabaseHelper.instance.getRecognitionHistory();
    } catch (e) {
      Get.snackbar('错误', '加载记录失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> softDeleteRecord(int id) async {
    try {
      await DatabaseHelper.instance.softDeleteRecord(id);
      await loadRecords();
    } catch (e) {
      Get.snackbar('错误', '删除记录失败: $e');
    }
  }

  Future<void> updateNote(int id, String? note) async {
    try {
      await DatabaseHelper.instance.updateNote(id, note);
      await loadRecords();
    } catch (e) {
      Get.snackbar('错误', '更新备注失败: $e');
    }
  }

  @override
  void onClose() {
    noteInput.value = '';
    super.onClose();
  }
}