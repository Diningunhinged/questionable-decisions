import 'dart:convert';
import 'dart:math' as math;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../models/detour_venue.dart';
import '../models/dining_unhinged_review.dart';

class DiningUnhingedReviewService {
  const DiningUnhingedReviewService({required this.apiClient});
  final ApiClient apiClient;

  Future<List<DiningUnhingedReview>> fetchReviews() async {
    final response = await apiClient.get(ApiConfig.detourEndpoint);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const DiningUnhingedReviewException(
        'Dining Unhinged API returned an unexpected response.',
      );
    }
    final rawVenues = decoded['venues'];
    if (rawVenues is! List) return const [];
    return rawVenues
        .whereType<Map<String, dynamic>>()
        .map(DiningUnhingedReview.fromJson)
        .where((review) => review.isValid)
        .toList();
  }

  DiningUnhingedReview? findMatch({
    required DetourVenue venue,
    required List<DiningUnhingedReview> reviews,
  }) {
    DiningUnhingedReview? bestMatch;
    double bestScore = 0;
    for (final review in reviews) {
      final score = _matchScore(venue: venue, review: review);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = review;
      }
    }
    if (bestMatch == null || bestScore < _minimumMatchScore) return null;
    return bestMatch;
  }

  static const double _minimumMatchScore = 0.72;

  double _matchScore({required DetourVenue venue, required DiningUnhingedReview review}) {
    final nameScore = _nameSimilarity(venue.name, review.venueName ?? '');
    final distanceMeters = _distanceMeters(
      venue.latitude,
      venue.longitude,
      review.latitude,
      review.longitude,
    );
    final locationScore = _locationScore(distanceMeters);
    return (nameScore * 0.65) + (locationScore * 0.35);
  }

  double _nameSimilarity(String first, String second) {
    final normalizedFirst = _normalizeName(first);
    final normalizedSecond = _normalizeName(second);
    if (normalizedFirst.isEmpty || normalizedSecond.isEmpty) return 0;
    if (normalizedFirst == normalizedSecond) return 1;
    if (normalizedFirst.contains(normalizedSecond) || normalizedSecond.contains(normalizedFirst)) return 0.92;
    final firstWords = normalizedFirst.split(' ').toSet();
    final secondWords = normalizedSecond.split(' ').toSet();
    if (firstWords.isEmpty || secondWords.isEmpty) return 0;
    final intersection = firstWords.intersection(secondWords);
    final union = firstWords.union(secondWords);
    if (union.isEmpty) return 0;
    return intersection.length / union.length;
  }

  String _normalizeName(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  double _locationScore(double distanceMeters) {
    if (distanceMeters <= 25) return 1;
    if (distanceMeters <= 50) return 0.95;
    if (distanceMeters <= 100) return 0.85;
    if (distanceMeters <= 250) return 0.70;
    if (distanceMeters <= 500) return 0.45;
    if (distanceMeters <= 1000) return 0.20;
    return 0;
  }

  double _distanceMeters(double latitude1, double longitude1, double latitude2, double longitude2) {
    const earthRadiusMeters = 6371000.0;
    final lat1 = _degreesToRadians(latitude1);
    final lat2 = _degreesToRadians(latitude2);
    final deltaLat = _degreesToRadians(latitude2 - latitude1);
    final deltaLon = _degreesToRadians(longitude2 - longitude1);
    final a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(deltaLon / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}

class DiningUnhingedReviewException implements Exception {
  const DiningUnhingedReviewException(this.message);
  final String message;
  @override
  String toString() => message;
}
