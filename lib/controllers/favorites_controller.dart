import 'package:get/get.dart';
import '../database/database_helper.dart';

class FavoritesController extends GetxController {
  var favorites = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    isLoading.value = true;
    favorites.value = await DatabaseHelper.instance.getFavorites();
    isLoading.value = false;
  }
}