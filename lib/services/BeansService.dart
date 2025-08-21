import 'dart:convert';
import '../ApiClient.dart';

class BeansService {
  BeansService(this.api);
  final ApiClient api;

  Future<List<Map<String, dynamic>>> list() async {
    final res = await api.get('/beans');
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    }
    throw Exception('Beans list failed: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, dynamic>> create({
    required String name,
    String? origin,
    String? roastLevel,
    DateTime? roastDate,
    int? weight,
    String? notes,
  }) async {
    final res = await api.post('/beans', {
      'name': name,
      if (origin != null) 'origin': origin,
      if (roastLevel != null) 'roastLevel': roastLevel,
      if (roastDate != null) 'roastDate': roastDate.toIso8601String(),
      if (weight != null) 'weight': weight,
      if (notes != null) 'notes': notes,
    });
    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Create bean failed: ${res.statusCode} ${res.body}');
  }
}
