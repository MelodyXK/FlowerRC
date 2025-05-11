import 'package:flower_recognizer/database/database_helper.dart';

class Flower {
  final String flowerId;
  final String name;
  final String scientificName;
  final String? alias;
  final String? family;
  final String? genus;
  final String description;
  final String imagePath;
  final String bloomSeason;
  final String? distribution;
  final String? morphology;
  final String? usage;

  Flower({
    required this.flowerId,
    required this.name,
    required this.scientificName,
    this.alias,
    this.family,
    this.genus,
    required this.description,
    required this.imagePath,
    required this.bloomSeason,
    this.distribution,
    this.morphology,
    this.usage,
  });

  factory Flower.fromMap(Map<String, dynamic> map) {
    return Flower(
      flowerId: map['flowerid'] as String,
      name: map['name'] as String,
      scientificName: map['scientific_name'] as String,
      alias: map['alias'] as String?,
      family: map['family'] as String?,
      genus: map['genus'] as String?,
      description: map['description'] as String,
      imagePath: map['image_path'] as String,
      bloomSeason: map['bloom_season'] as String,
      distribution: map['distribution'] as String?,
      morphology: map['morphology'] as String?,
      usage: map['usage'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'flowerid': flowerId,
      'name': name,
      'scientific_name': scientificName,
      'alias': alias,
      'family': family,
      'genus': genus,
      'description': description,
      'image_path': imagePath,
      'bloom_season': bloomSeason,
      'distribution': distribution,
      'morphology': morphology,
      'usage': usage,
    };
  }

  factory Flower.fromJson(Map<String, dynamic> json) => Flower.fromMap(json);

  static Future<Flower?> fromFlowerId(String flowerId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'flowers',
        where: 'flowerid = ?',
        whereArgs: [flowerId],
      );
      if (result.isNotEmpty) {
        return Flower.fromMap(result.first);
      }
      return null;
    } catch (e) {
      // 使用生产环境友好的日志库替代 print
      return null;
    }
  }
}