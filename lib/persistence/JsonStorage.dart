import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

/// A simple generic JSON file store for any model T.
class JsonStorage<T> {
  final String filename;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;

  JsonStorage({
    required this.filename,
    required this.fromJson,
    required this.toJson,
  });

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$filename');
  }

  /// Load all items, or return [] if file is missing/corrupt.
  Future<List<T>> loadAll() async {
    try {
      final file = await _file;
      if (!await file.exists()) return [];
      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList
          .cast<Map<String, dynamic>>()
          .map(fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Overwrite the file with exactly this list.
  Future<void> saveAll(List<T> items) async {
    final file = await _file;
    final jsonList = items.map(toJson).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  /// Clear the file (becomes an empty list `[]`).
  Future<void> clear() async {
    final file = await _file;
    await file.writeAsString(jsonEncode(<dynamic>[]));
  }
}
