import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodFactsService {
  final String _baseUrl = 'https://world.openfoodfacts.org/api/v0/product';

  Future<Map<String, dynamic>?> getProductFromBarcode(String barcode) async {
    if (barcode.isEmpty) return null;

    try {
      final url = Uri.parse('$_baseUrl/$barcode.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 1) { // 1 means found
          final product = data['product'];
          final nutriments = product['nutriments'];

          return {
            'description': product['product_name'] ?? 'Unknown Product',
            // Try to get per serving first, then per 100g
            'carbs': (nutriments['carbohydrates_serving'] ?? nutriments['carbohydrates_100g'])?.toString() ?? '0',
            'calories': (nutriments['energy-kcal_serving'] ?? nutriments['energy-kcal_100g'])?.toString() ?? '0',
          };
        }
      }
    } catch (e) {
      print('Exception fetching barcode: $e');
    }
    return null;
  }
}