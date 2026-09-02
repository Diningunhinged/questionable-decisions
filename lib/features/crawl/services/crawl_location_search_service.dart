// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

import '../models/crawl_location_search_result.dart';
import 'location_search_provider.dart';

class CrawlLocationSearchService {
  CrawlLocationSearchService({
  required this._provider,
});

  final LocationSearchProvider _provider;

  Future<List<CrawlLocationSearchResult>> search(
    String query,
  ) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return const [];
    }

    return _provider.search(normalizedQuery);
  }
}
