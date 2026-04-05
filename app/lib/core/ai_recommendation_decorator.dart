import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/listing.dart';
import 'recommendation_system.dart';

class AIRecommendationDecorator implements ItemRecommendation {
  final ItemRecommendation base;
  final String apiUrl;
  final String userId;

  AIRecommendationDecorator(this.base, {required this.apiUrl, required this.userId});


  @override
  List<Listing> getItems() {
    return base.getItems();
  }

  Future<List<Listing>> getRecommendedItems() async {
    final items = base.getItems();
    final ids = await fetchRecommendedIds(items);
    return items.where((item) => ids.contains(item.id)).toList();
  }

  Future<List<String>> fetchRecommendedIds(List<Listing> items) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'items': items.map((e) => e.toJson()).toList(),
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['recommendedIds'] ?? []);
    } else {
      throw Exception('Failed to fetch recommendations');
    }
  }
}
