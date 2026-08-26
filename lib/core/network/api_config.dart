class ApiConfig {
  ApiConfig._();

  static const String baseUrl =
      'https://www.diningunhinged.ca';

  static const String nearbyEndpoint =
      '/api/nearby.json';

  static const Duration requestTimeout =
      Duration(seconds: 15);
}