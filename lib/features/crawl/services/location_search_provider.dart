import '../models/crawl_location_search_result.dart';

abstract class LocationSearchProvider {
  Future<List<CrawlLocationSearchResult>> search(
    String query,
  );
}