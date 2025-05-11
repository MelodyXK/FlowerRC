import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import '../controllers/favorites_controller.dart';
import '../models/flower.dart';
import '../screens/flower_detail.dart';
import '../providers/theme_provider.dart';

class FavoritesScreen extends StatelessWidget {
  final controller = Get.put(FavoritesController());

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
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
              appBar: AppBar(
                title: Text('我的收藏'),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: Obx(() => controller.isLoading.value
                  ? Center(child: CircularProgressIndicator())
                  : controller.favorites.isEmpty
                  ? Center(child: Text('暂无收藏', style: Theme.of(context).textTheme.bodyLarge))
                  : AnimationLimiter(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: controller.favorites.length,
                  itemBuilder: (context, index) {
                    final favorite = controller.favorites[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildFavoriteCard(context, favorite),
                        ),
                      ),
                    );
                  },
                ),
              )),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFavoriteCard(BuildContext context, Map<String, dynamic> favorite) {
    return GFCard(
      elevation: 4,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 8),
      content: InkWell(
        onTap: () async {
          final flower = await Flower.fromFlowerId(favorite['flowerid']);
          if (flower != null) {
            Get.to(() => FlowerDetailScreen(flower: flower));
          }
        },
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
              child: Image.asset(
                favorite['image_path'],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  height: 100,
                  color: Theme.of(context).cardColor.withOpacity(0.5),
                  child: Icon(Icons.image_not_supported, color: Theme.of(context).iconTheme.color),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  favorite['name'],
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}