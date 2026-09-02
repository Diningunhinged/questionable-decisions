// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

class ApiConfig {
  ApiConfig._();

  static const String baseUrl =
      'https://www.diningunhinged.ca';

  static const String nearbyEndpoint =
      '/api/nearby.json';

  static const String detourEndpoint =
      '/api/detour.json';

  static const Duration requestTimeout =
      Duration(seconds: 15);
}
