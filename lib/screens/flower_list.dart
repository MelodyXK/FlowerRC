import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../controllers/flower_list_controller.dart';
import '../models/flower.dart';
import '../screens/flower_detail.dart';
import '../providers/theme_provider.dart';

class FlowerListScreen extends StatelessWidget {
  final controller = Get.put(FlowerListController());

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
          appBar: AppBar(
            title: Text('花卉图鉴'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(60.0),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '搜索花卉',
                    hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                    prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                    suffixIcon: controller.searchQuery.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: Theme.of(context).iconTheme.color),
                      onPressed: () {
                        controller.onSearchChanged('');
                        FocusScope.of(context).unfocus();
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                    border: Theme.of(context).inputDecorationTheme.border,
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                  onChanged: controller.onSearchChanged,
                ),
              ),
            ),
          ),
          body: Obx(() => controller.isLoading.value
              ? Center(child: CircularProgressIndicator())
              : controller.filteredFlowers.isEmpty && controller.searchQuery.isNotEmpty
              ? Center(child: Text('无匹配结果', style: Theme.of(context).textTheme.bodyLarge))
              : ListView.builder(
            itemCount: controller.filteredFlowers.length,
            itemBuilder: (context, index) {
              final flower = controller.filteredFlowers[index];
              return _buildFlowerCard(context, flower);
            },
          )),
        ),
      ],
    );
  }

  Widget _buildFlowerCard(BuildContext context, Flower flower) {
    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.to(() => FlowerDetailScreen(flower: flower)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                flower.imagePath,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: Theme.of(context).cardColor.withOpacity(0.5),
                  child: Center(child: Icon(Icons.image_not_supported, color: Theme.of(context).iconTheme.color)),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    flower.name,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    flower.scientificName,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (flower.family != null) _buildChip(context, label: '科：${flower.family}'),
                      if (flower.genus != null) _buildChip(context, label: '属：${flower.genus}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, {required String label}) {
    return Chip(
      label: Text(label),
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
        fontSize: 12,
      ),
    );
  }
}