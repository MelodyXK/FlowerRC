import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import '../controllers/recycle_bin_controller.dart';
import '../providers/theme_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class RecycleBinScreen extends StatelessWidget {
  final controller = Get.put(RecycleBinController());

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    return DateFormat('yyyy年MM月dd日 HH:mm').format(dateTime);
  }

  void _showRestoreDialog(BuildContext context, int id) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Theme.of(context).cardColor,
        title: Text('恢复记录', style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold)),
        content: Text('确定要恢复这条识别记录吗？'),
        actions: [
          GFButton(
            onPressed: () => Get.close(1),
            text: '取消',
            type: GFButtonType.outline,
            color: Theme.of(context).primaryColor,
            textColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
          ),
          GFButton(
            onPressed: () async {
              await controller.restoreRecord(id);
              Get.close(1); // 明确关闭当前对话框
            },
            text: '恢复',
            color: Colors.green,
          ),
        ],
      ).animate().fadeIn(duration: 200.ms).scale(begin: Offset(0.8, 0.8)),
      barrierDismissible: true,
    );
  }

  void _showPermanentDeleteDialog(BuildContext context, int id) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Theme.of(context).cardColor,
        title: Text('永久删除', style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold)),
        content: Text('确定要永久删除这条识别记录吗？此操作不可撤销。'),
        actions: [
          GFButton(
            onPressed: () => Get.close(1),
            text: '取消',
            type: GFButtonType.outline,
            color: Theme.of(context).primaryColor,
            textColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
          ),
          GFButton(
            onPressed: () async {
              await controller.permanentlyDeleteRecord(id);
              Get.close(1); // 明确关闭当前对话框
            },
            text: '永久删除',
            color: Colors.red,
          ),
        ],
      ).animate().fadeIn(duration: 200.ms).scale(begin: Offset(0.8, 0.8)),
      barrierDismissible: true,
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
          appBar: AppBar(
            title: Text('回收站'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
          ),
          body: Obx(() => controller.isLoading.value
              ? Center(child: CircularProgressIndicator())
              : controller.deletedRecords.isEmpty
              ? Center(child: Text('回收站为空', style: Theme.of(context).textTheme.bodyLarge))
              : AnimationLimiter(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: controller.deletedRecords.length,
              itemBuilder: (context, index) {
                final record = controller.deletedRecords[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildDeletedRecordCard(context, record),
                    ),
                  ),
                );
              },
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildDeletedRecordCard(BuildContext context, Map<String, dynamic> record) {
    final flower = controller.flowerCache[record['top1_flowerid']];
    final modelUsed = record['model_used'] ?? '未知模型';
    final confidence = record['top1_confidence'] != null ? (record['top1_confidence'] as double) * 100 : null;
    final note = record['note'] as String?;
    final deletedAt = record['deleted_at'] != null ? _formatTimestamp(record['deleted_at']) : '未知时间';

    return GFCard(
      elevation: 4,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 8),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.file(
              File(record['image_path']),
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 150,
                color: Theme.of(context).cardColor.withOpacity(0.5),
                child: Icon(Icons.image_not_supported, color: Theme.of(context).iconTheme.color),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flower?.name ?? '未知花卉 (${record['top1_flowerid']})',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '识别时间: ${_formatTimestamp(record['timestamp'])}',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  '使用模型: ${modelUsed == 'mobilenetv3' ? 'MobileNetV3' : modelUsed == 'efficientnetv2' ? 'EfficientNetV2' : modelUsed}',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 14),
                ),
                if (confidence != null) ...[
                  SizedBox(height: 4),
                  Text(
                    '置信度: ${confidence.toStringAsFixed(2)}%',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
                SizedBox(height: 4),
                Text(
                  '删除时间: $deletedAt',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 14),
                ),
                if (note != null && note.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.note,
                        size: 20,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium!.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GFButton(
                      onPressed: () => _showRestoreDialog(context, record['id']),
                      text: '恢复',
                      color: Colors.green,
                      type: GFButtonType.outline,
                    ),
                    SizedBox(width: 8),
                    GFButton(
                      onPressed: () => _showPermanentDeleteDialog(context, record['id']),
                      text: '永久删除',
                      color: Colors.red,
                      type: GFButtonType.outline,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}