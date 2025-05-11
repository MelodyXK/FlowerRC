import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import '../controllers/recognition_history_controller.dart';
import '../database/database_helper.dart';
import '../models/flower.dart';
import '../screens/recycle_bin_screen.dart';
import '../screens/flower_detail.dart';
import '../providers/theme_provider.dart';
import 'package:intl/intl.dart';

class RecognitionHistoryScreen extends StatelessWidget {
  final controller = Get.put(RecognitionHistoryController());
  bool _isDialogOpening = false; // 防抖标志

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    return DateFormat('yyyy年MM月dd日 HH:mm').format(dateTime);
  }

  void _showActionDialog(BuildContext context, int id, String? currentNote) {
    if (_isDialogOpening) {
      print('ActionDialog blocked: _isDialogOpening=$_isDialogOpening');
      return;
    }
    _isDialogOpening = true;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Theme.of(context).cardColor,
        title: Text('操作', style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold)),
        content: Text('请选择对该识别记录的操作'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: GFButton(
                  onPressed: () {
                    Get.close(1);
                    Future.delayed(Duration(milliseconds: 100), () {
                      print('Calling _showNoteDialog for id=$id');
                      _showNoteDialog(context, id, currentNote);
                    });
                  },
                  text: currentNote == null || currentNote.isEmpty ? '添加备注' : '编辑备注',
                  type: GFButtonType.outline,
                  color: Theme.of(context).primaryColor,
                  textColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: GFButton(
                  onPressed: () async {
                    await controller.softDeleteRecord(id);
                    Get.close(1);
                  },
                  text: '删除',
                  color: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GFButton(
                onPressed: () => Get.close(1),
                text: '取消',
                type: GFButtonType.transparent,
                textColor: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey[600],
              ),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 100.ms).scale(begin: Offset(0.8, 0.8)),
      barrierDismissible: true,
      name: 'ActionDialog',
    ).whenComplete(() {
      print('ActionDialog closed, resetting _isDialogOpening');
      _isDialogOpening = false;
    });
  }

  void _showNoteDialog(BuildContext context, int id, String? currentNote) {
    if (_isDialogOpening) {
      print('NoteDialog blocked: _isDialogOpening=$_isDialogOpening');
      return;
    }
    _isDialogOpening = true;

    final noteController = TextEditingController(text: currentNote ?? '');
    controller.noteInput.value = currentNote ?? '';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          currentNote == null || currentNote.isEmpty ? '添加备注' : '编辑备注',
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: '输入备注（最多200字）',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
          ),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          GFButton(
            onPressed: () {
              print('Cancel button pressed, closing keyboard');
              FocusScope.of(context).unfocus();
              Get.close(1);
            },
            text: '取消',
            type: GFButtonType.outline,
            color: Theme.of(context).primaryColor,
            textColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
          ),
          GFButton(
            onPressed: () async {
              print('Save button pressed, closing keyboard');
              FocusScope.of(context).unfocus();
              final newNote = noteController.text.trim();
              await controller.updateNote(id, newNote.isEmpty ? null : newNote);
              print('Note saved, delaying dialog close');
              Future.delayed(Duration(milliseconds: 100), () {
                Get.close(1);
              });
            },
            text: '保存',
            color: Theme.of(context).primaryColor,
          ),
        ],
      ).animate().fadeIn(duration: 100.ms).scale(begin: Offset(0.8, 0.8)),
      barrierDismissible: true,
      name: 'NoteDialog',
    ).whenComplete(() {
      print('NoteDialog closed, delaying noteController dispose');
      Future.delayed(Duration(milliseconds: 200), () {
        print('Disposing noteController: ${noteController.hashCode}');
        noteController.dispose();
      });
      _isDialogOpening = false;
    });
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
            title: Text('识别记录'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  Get.to(() => RecycleBinScreen())?.then((_) => controller.loadRecords());
                },
                tooltip: '查看回收站',
              ),
            ],
          ),
          body: Obx(() => controller.isLoading.value
              ? Center(child: CircularProgressIndicator())
              : controller.records.isEmpty
              ? Center(child: Text('暂无识别记录', style: Theme.of(context).textTheme.bodyLarge))
              : AnimationLimiter(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: controller.records.length,
              itemBuilder: (context, index) {
                final record = controller.records[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildRecordCard(context, record),
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

  Widget _buildRecordCard(BuildContext context, Map<String, dynamic> record) {
    return FutureBuilder<Flower?>(
      future: Flower.fromFlowerId(record['top1_flowerid']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return GFCard(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.symmetric(vertical: 8),
            content: Center(child: CircularProgressIndicator()),
          );
        }
        final flower = snapshot.data;
        final modelUsed = record['model_used'] ?? '未知模型';
        final confidence = record['top1_confidence'] != null ? (record['top1_confidence'] as double) * 100 : null;
        final note = record['note'] as String?;

        return GestureDetector(
          onTap: flower != null
              ? () => Get.to(() => FlowerDetailScreen(flower: flower))
              : null,
          onLongPress: () => _showActionDialog(context, record['id'], note),
          child: GFCard(
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
                      if (note != null && note.isNotEmpty) ...[
                        SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showNoteDialog(context, record['id'], note),
                          child: Row(
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
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}