import 'package:hive/hive.dart';
import 'package:v60pal/models/beans.dart';

@HiveType(typeId: 0)
class JournalEntry extends HiveObject {
  @HiveField(0)
  String rating;

  @HiveField(1)
  int waterTemp;

  @HiveField(2)
  int timeTaken;

  @HiveField(3)
  String grindSetting;

  @HiveField(4)
  String notes;

  @HiveField(5)
  Beans beans;

  JournalEntry({
    required this.rating,
    required this.waterTemp,
    required this.timeTaken,
    required this.grindSetting,
    required this.notes,
    required this.beans,
  });
}

