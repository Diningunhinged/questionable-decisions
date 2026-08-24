import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/nearby_result.dart';

class DiningUnhingedApi {
  // Replace this with your actual Dining Unhinged website URL.
  static const String baseUrl = 'https://www.diningunhinged.ca';

  static const String nearbyEndpoint = '/api/nearby.json';

  static Future<List<NearbyResult>> fetchNearbyResults() async {
    final uri = Uri.parse('$baseUrl$nearbyEndpoint');

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Dining Unhinged API returned ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw const FormatException(
        'Dining Unhinged API returned an unexpected response.',
      );
    }

    return decoded
        .map(
          (item) => NearbyResult.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}