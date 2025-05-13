import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'database/database_helper.dart';
import 'screens/home_screen.dart';
import 'screens/flower_list.dart';
import 'screens/search_screen.dart';
import 'screens/recognition_history_screen.dart';
import 'screens/favorites_screen.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;
  } catch (e) {
    // 可替换为日志库
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return GetMaterialApp(
      title: 'FlowerAI',
      theme: themeProvider.themeData,
      home: HomeScreen(),
      routes: {
        '/list': (context) => FlowerListScreen(),
        '/search': (context) => SearchScreen(),
        '/history': (context) => RecognitionHistoryScreen(),
        '/favorites': (context) => FavoritesScreen(),
      },
      navigatorKey: Get.key, // 确保 GetX 导航稳定性
      enableLog: true, // 启用 GetX 日志
    );
  }
}
