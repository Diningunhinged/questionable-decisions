// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

import '../models/crawl_location_search_result.dart';
import 'location_search_provider.dart';

class EmptyLocationSearchProvider
    implements LocationSearchProvider {
  const EmptyLocationSearchProvider();

  @override
  Future<List<CrawlLocationSearchResult>> search(
    String query,
  ) async {
    return const [];
  }
}
