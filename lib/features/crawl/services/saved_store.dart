import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_crawl.dart';
import '../../../models/nearby_result.dart';

const _savedNearbyKey = 'saved_nearby_v1';
const _savedCrawlsKey = 'saved_crawls_v1';

final List<NearbyResult> savedNearbyResults = [];

bool _nearbyLoaded = false;

bool isSavedNearbyResult(NearbyResult result) {
  return savedNearbyResults.any(
    (saved) =>
        saved.type == result.type &&
        saved.slug == result.slug,
  );
}

Future<void> loadSavedNearbyResults() async {
  if (_nearbyLoaded) {
    return;
  }

  final preferences =
      await SharedPreferences.getInstance();

  final raw =
      preferences.getString(_savedNearbyKey);

  savedNearbyResults.clear();

  if (raw != null && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        savedNearbyResults.addAll(
          decoded
              .whereType<Map>()
              .map(
                (value) => NearbyResult.fromJson(
                  value.cast<String, dynamic>(),
                ),
              ),
        );
      }
    } catch (_) {
      savedNearbyResults.clear();
    }
  }

  _nearbyLoaded = true;
}

Future<void> saveNearbyResult(
  NearbyResult result,
) async {
  await loadSavedNearbyResults();

  if (isSavedNearbyResult(result)) {
    return;
  }

  savedNearbyResults.add(result);

  await _persistSavedNearbyResults();
}

Future<void> removeSavedNearbyResult(
  NearbyResult result,
) async {
  await loadSavedNearbyResults();

  savedNearbyResults.removeWhere(
    (saved) =>
        saved.type == result.type &&
        saved.slug == result.slug,
  );

  await _persistSavedNearbyResults();
}

Future<bool> toggleSavedNearbyResult(
  NearbyResult result,
) async {
  await loadSavedNearbyResults();

  if (isSavedNearbyResult(result)) {
    await removeSavedNearbyResult(result);
    return false;
  }

  await saveNearbyResult(result);
  return true;
}

Future<void> _persistSavedNearbyResults() async {
  final preferences =
      await SharedPreferences.getInstance();

  await preferences.setString(
    _savedNearbyKey,
    jsonEncode(
      savedNearbyResults
          .map(_nearbyResultToJson)
          .toList(),
    ),
  );
}

Map<String, dynamic> _nearbyResultToJson(
  NearbyResult result,
) {
  return {
    'type': result.type,
    'category': result.category,
    'title': result.title,
    'slug': result.slug,
    'rating': result.rating,
    'heroImage': result.heroImage,
    'venue': {
      'name': result.venue.name,
      'city': result.venue.city,
      'province': result.venue.province,
      'cuisine': result.venue.cuisine,
      'featured': result.venue.featured,
      'googleMaps': result.venue.googleMaps,
      'location':
          result.venue.location == null
              ? null
              : {
                  'lat':
                      result.venue.location!.latitude,
                  'lng':
                      result.venue.location!.longitude,
                },
    },
  };
}

final List<SavedCrawl> savedCrawls = [];

bool _crawlsLoaded = false;

Future<void> loadSavedCrawls() async {
  if (_crawlsLoaded) {
    return;
  }

  final preferences =
      await SharedPreferences.getInstance();

  final raw =
      preferences.getString(_savedCrawlsKey);

  savedCrawls.clear();

  if (raw != null && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        savedCrawls.addAll(
          decoded
              .whereType<Map>()
              .map(
                (value) =>
                    SavedCrawl.fromJson(
                  value.cast<String, dynamic>(),
                ),
              ),
        );
      }
    } catch (_) {
      savedCrawls.clear();
    }
  }

  _crawlsLoaded = true;
}

Future<void> saveCrawl(
  SavedCrawl crawl,
) async {
  await loadSavedCrawls();

  final existingIndex =
      savedCrawls.indexWhere(
    (saved) => saved.id == crawl.id,
  );

  if (existingIndex >= 0) {
    savedCrawls[existingIndex] = crawl;
  } else {
    savedCrawls.add(crawl);
  }

  await _persistSavedCrawls();
}

Future<void> deleteSavedCrawl(
  String id,
) async {
  await loadSavedCrawls();

  savedCrawls.removeWhere(
    (crawl) => crawl.id == id,
  );

  await _persistSavedCrawls();
}

Future<void> duplicateSavedCrawl(
  SavedCrawl crawl,
) async {
  await saveCrawl(
    SavedCrawl(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      name: '${crawl.name} Copy',
      plannedDate: crawl.plannedDate,
      configuration: crawl.configuration,
      startingPoint: crawl.startingPoint,
      stops: List<NearbyResult>.from(
        crawl.stops,
      ),
    ),
  );
}

Future<void> _persistSavedCrawls() async {
  final preferences =
      await SharedPreferences.getInstance();

  await preferences.setString(
    _savedCrawlsKey,
    jsonEncode(
      savedCrawls
          .map((crawl) => crawl.toJson())
          .toList(),
    ),
  );
}
