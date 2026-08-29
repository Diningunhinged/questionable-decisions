import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/nearby_result.dart';
import '../models/saved_crawl.dart';

const _savedCrawlsKey = 'saved_crawls_v1';

final List<NearbyResult> savedNearbyResults = [];

bool isSavedNearbyResult(NearbyResult result) {
  return savedNearbyResults.any(
    (saved) => saved.type == result.type && saved.slug == result.slug,
  );
}

void saveNearbyResult(NearbyResult result) {
  if (!isSavedNearbyResult(result)) {
    savedNearbyResults.add(result);
  }
}

final List<SavedCrawl> savedCrawls = [];

bool _crawlsLoaded = false;

Future<void> loadSavedCrawls() async {
  if (_crawlsLoaded) {
    return;
  }

  final preferences = await SharedPreferences.getInstance();
  final raw = preferences.getString(_savedCrawlsKey);

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
                    SavedCrawl.fromJson(value.cast<String, dynamic>()),
              ),
        );
      }
    } catch (_) {
      savedCrawls.clear();
    }
  }

  _crawlsLoaded = true;
}

Future<void> saveCrawl(SavedCrawl crawl) async {
  await loadSavedCrawls();

  final existingIndex =
      savedCrawls.indexWhere((saved) => saved.id == crawl.id);

  if (existingIndex >= 0) {
    savedCrawls[existingIndex] = crawl;
  } else {
    savedCrawls.add(crawl);
  }

  await _persistSavedCrawls();
}

Future<void> deleteSavedCrawl(String id) async {
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
          .map(
            (crawl) => crawl.toJson(),
          )
          .toList(),
    ),
  );
}