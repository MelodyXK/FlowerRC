import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import '../screens/search_screen.dart';
import '../screens/flower_list.dart';
import '../screens/recognition_history_screen.dart';
import '../screens/favorites_screen.dart';
import '../providers/theme_provider.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final cameraCardSize = screenWidth * 0.35;
    final otherCardSize = screenWidth * 0.23;

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
            title: Text('FlowerAI'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container( // 添加 leading 属性，用于显示 LOGO
              width: 40, // 调整宽度
              height: 40, // 调整高度
              padding: EdgeInsets.all(2), // 内边距// 调整 LOGO 边距
              child: Image.asset('assets/images/logo1.png'), // 替换为你的 LOGO 路径
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.collections_bookmark),
                onPressed: () => Get.to(() => FlowerListScreen()),
                tooltip: '花卉列表',
              ).animate().fadeIn(delay: 200.ms),
              IconButton(
                icon: Icon(
                  themeProvider.theme == AppTheme.light ? Icons.wb_sunny : Icons.nightlight_round,
                  color: Colors.white,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: themeProvider.theme == AppTheme.light ? '切换到暗色模式' : '切换到明亮模式',
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
          body: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                _buildFeatureCard(
                  context: context,
                  icon: Icons.camera_alt,
                  label: '相机识别',
                  onTap: () => Get.to(() => SearchScreen()),
                  cardSize: cameraCardSize,
                  iconSize: 50,
                  textSize: 18,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: _buildFeatureCard(
                        context: context,
                        icon: Icons.history,
                        label: '识别记录',
                        onTap: () => Get.to(() => RecognitionHistoryScreen()),
                        cardSize: otherCardSize,
                      ),
                    ),
                    SizedBox(width: 16),
                    Flexible(
                      child: _buildFeatureCard(
                        context: context,
                        icon: Icons.favorite,
                        label: '我的收藏',
                        onTap: () => Get.to(() => FavoritesScreen()),
                        cardSize: otherCardSize,
                      ),
                    ),
                  ],
                ),
                Spacer(),
              ],
            ),
          ),
          // floatingActionButton: FloatingActionButton(
          //   onPressed: () => Get.to(() => SearchScreen()),
          //   child: Icon(Icons.camera_alt),
          //   tooltip: '拍照识别',
          //   backgroundColor: Theme.of(context).primaryColor,
          // ).animate().scale(duration: 300.ms),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double cardSize,
    double iconSize = 40,
    double textSize = 16,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: GFCard(
        elevation: 4,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: EdgeInsets.all(12),
        content: SizedBox(
          width: cardSize,
          height: cardSize,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize, color: Theme.of(context).iconTheme.color),
              SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: textSize),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeInOut).fadeIn();
  }
}