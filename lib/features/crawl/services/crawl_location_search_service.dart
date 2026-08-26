import '../models/crawl_location_search_result.dart';
import 'location_search_provider.dart';

class CrawlLocationSearchService {
  CrawlLocationSearchService({
    required LocationSearchProvider provider,
  }) : _provider = provider;

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