import 'package:get/get.dart';
import '../database/database_helper.dart';
import '../models/flower.dart';

class FlowerDetailController extends GetxController {
  final Flower flower;
  var isFavorite = false.obs;
  var isDescriptionExpanded = false.obs;

  FlowerDetailController(this.flower);

  @override
  void onInit() {
    super.onInit();
    checkFavoriteStatus();
  }

  Future<void> checkFavoriteStatus() async {
    isFavorite.value = await DatabaseHelper.instance.isFavorite(flower.flowerId);
  }

  Future<void> toggleFavorite() async {
    if (isFavorite.value) {
      await DatabaseHelper.instance.removeFavorite(flower.flowerId);
    } else {
      await DatabaseHelper.instance.addFavorite(flower);
    }
    isFavorite.value = !isFavorite.value;
  }

  void toggleDescription() {
    isDescriptionExpanded.value = !isDescriptionExpanded.value;
  }
}