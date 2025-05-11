import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import '../controllers/flower_detail_controller.dart';
import '../models/flower.dart';
import '../providers/theme_provider.dart';

class FlowerDetailScreen extends StatelessWidget {
  final Flower flower;
  FlowerDetailScreen({Key? key, required this.flower}) : super(key: key) {
    Get.put(FlowerDetailController(flower));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return GetBuilder<FlowerDetailController>(
      builder: (controller) => Stack(
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
              title: Text(flower.name),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                Obx(() => IconButton(
                  icon: Icon(controller.isFavorite.value ? Icons.favorite : Icons.favorite_border),
                  color: controller.isFavorite.value ? Colors.red : null,
                  onPressed: controller.toggleFavorite,
                  tooltip: controller.isFavorite.value ? '取消收藏' : '添加到收藏',
                ).animate().scale(duration: 200.ms)),
              ],
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroImage(context, flower),
                  SizedBox(height: 24),
                  _buildScientificInfo(context, flower),
                  _buildSection(context, '基本特征', [
                    if (flower.alias != null) _buildInfoItem(context, '别名', flower.alias!),
                    if (flower.family != null) _buildInfoItem(context, '科', flower.family!),
                    if (flower.genus != null) _buildInfoItem(context, '属', flower.genus!),
                  ]),
                  _buildSection(context, '分布信息', [
                    if (flower.distribution != null) _buildIndentedInfoItem(context, '分布地区', flower.distribution!),
                  ]),
                  _buildSection(context, '形态特征', [
                    if (flower.morphology != null) _buildIndentedInfoItem(context, '形态描述', flower.morphology!),
                  ]),
                  _buildSection(context, '应用价值', [
                    if (flower.usage != null) _buildIndentedInfoItem(context, '主要用途', flower.usage!),
                  ]),
                  _buildDescriptionSection(context, controller, flower),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context, Flower flower) {
    return Hero(
      tag: 'flower-${flower.flowerId}',
      child: GFCard(
        elevation: 4,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.zero,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            flower.imagePath,
            width: double.infinity,
            height: 280,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 280,
              color: Theme.of(context).cardColor.withOpacity(0.5),
              child: Center(child: Icon(Icons.image_not_supported, color: Theme.of(context).iconTheme.color)),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildScientificInfo(BuildContext context, Flower flower) {
    return GFCard(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Table(
        columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(3)},
        children: [
          _buildTableRow(context, '学名', flower.scientificName),
          _buildTableRow(context, '花期', flower.bloomSeason),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final validChildren = children.where((w) => w != null).toList();
    if (validChildren.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 20, bottom: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
            ),
          ),
        ),
        ...validChildren,
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildInfoItem(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$title：',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(child: Text(content, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }

  Widget _buildIndentedInfoItem(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$title：',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              content.split('\n').map((para) => '　　$para').join('\n'),
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(BuildContext context, String title, String content) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text(content, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context, FlowerDetailController controller, Flower flower) {
    return GFCard(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: controller.toggleDescription,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Text(
                    '详细描述',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
                    ),
                  ),
                  Spacer(),
                  Obx(() => AnimatedRotation(
                    duration: Duration(milliseconds: 200),
                    turns: controller.isDescriptionExpanded.value ? 0.5 : 0,
                    child: Icon(
                      Icons.expand_more,
                      size: 28,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  )),
                ],
              ),
            ),
          ),
          Obx(() => AnimatedSize(
            duration: Duration(milliseconds: 200),
            child: controller.isDescriptionExpanded.value ? _buildIndentedText(context, flower.description) : SizedBox.shrink(),
          )),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildIndentedText(BuildContext context, String text) {
    final paragraphs = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((para) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontSize: 16,
                height: 1.6,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
              ),
              children: [
                TextSpan(
                  text: '　　',
                  style: TextStyle(letterSpacing: 2),
                ),
                TextSpan(text: para.trim()),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}