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

  Future<void> delete(String id) async {
    final res = await api.delete('/beans/$id');
    if (res.statusCode != 204) {
      throw Exception('Delete failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<Map<String, dynamic>> update(
  String id, {
  String? name,
  String? origin,
  String? roastLevel,
  DateTime? roastDate,
  int? weight,
  String? notes,
  bool includeNulls = false,
}) async {
  if (id.trim().isEmpty) throw ArgumentError('update: id is empty');

  final body = <String, dynamic>{};
  void put(String k, dynamic v) {
    if (includeNulls) body[k] = v;
    else if (v != null) body[k] = v;
  }
  put('name', name);
  put('origin', origin);
  put('roastLevel', roastLevel);
  put('roastDate', roastDate?.toIso8601String());
  put('weight', weight);
  put('notes', notes);
  if (body.isEmpty) throw ArgumentError('No fields to update.');

  final path = '/beans/${Uri.encodeComponent(id)}';

  // Try PATCH first; if 404/405, fall back to PUT
  var res = await api.patch(path, body);
  if (res.statusCode == 404 || res.statusCode == 405) {
    res = await api.put(path, body);   // add put() to ApiClient if you don’t have it
  }

  if (res.statusCode == 200) {
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
  throw Exception('Update bean failed: ${res.statusCode} ${res.body}');
}


}
