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