import 'dart:async';
import 'package:get/get.dart';
import '../database/database_helper.dart';
import '../models/flower.dart';

class FlowerListController extends GetxController {
  var flowers = <Flower>[].obs;
  var filteredFlowers = <Flower>[].obs;
  var searchQuery = ''.obs;
  var isLoading = true.obs;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    loadFlowers();
  }

  Future<void> loadFlowers() async {
    isLoading.value = true;
    flowers.value = await DatabaseHelper.instance.getAllFlowers();
    filteredFlowers.value = flowers;
    isLoading.value = false;
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 300), () async {
      searchQuery.value = query.trim();
      if (searchQuery.isEmpty) {
        filteredFlowers.value = flowers;
      } else {
        filteredFlowers.value = await DatabaseHelper.instance.searchFlowers(searchQuery.value);
      }
    });
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}