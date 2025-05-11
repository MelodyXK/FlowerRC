import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import '../models/flower.dart';
import '../screens/flower_detail.dart';
import '../providers/theme_provider.dart';

class ResultScreen extends StatelessWidget {
  final List<Map<String, dynamic>> predictions;
  final String imagePath;

  ResultScreen({required this.predictions, required this.imagePath});

  Widget _buildResultItem(BuildContext context, Map<String, dynamic> prediction) {
    final flowerId = prediction['flowerId'] as String;
    final confidence = (prediction['confidence'] as double) * 100;

    return FutureBuilder<Flower?>(
      future: Flower.fromFlowerId(flowerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        final flower = snapshot.data;
        return GFCard(
          elevation: 4,
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.all(8),
          content: InkWell(
            onTap: flower != null
                ? () => Get.to(() => FlowerDetailScreen(flower: flower))
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    flower?.imagePath ?? 'assets/images/default.jpg',
                    width: 180,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 180,
                      height: 180,
                      color: Theme.of(context).cardColor.withOpacity(0.5),
                      child: Icon(
                        Icons.image_not_supported,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  flower?.name ?? '未知花卉 ($flowerId)',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '置信度: ${confidence.toStringAsFixed(2)}%',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ).animate().slideX(begin: 0.5, end: 0, duration: 300.ms);
      },
    );
  }

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
                title: Text('识别结果'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Colors.white,
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(imagePath),
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 250,
                            color: Theme.of(context).cardColor.withOpacity(0.5),
                            child: Icon(
                              Icons.image_not_supported,
                              color: Theme.of(context).iconTheme.color,
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms),
                    SizedBox(height: 16),
                    Text(
                      'Top-3 识别结果',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(duration: 500.ms),
                    SizedBox(height: 16),
                    Container(
                      height: 330,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: AnimationLimiter(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: predictions.length,
                          itemBuilder: (context, index) {
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                horizontalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: _buildResultItem(context, predictions[index]),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}