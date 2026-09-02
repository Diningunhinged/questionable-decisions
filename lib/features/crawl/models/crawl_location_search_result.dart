// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

class CrawlLocationSearchResult {
  const CrawlLocationSearchResult({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String? address;
  final double latitude;
  final double longitude;

  bool get isValid =>
      name.trim().isNotEmpty &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  factory CrawlLocationSearchResult.fromNominatimJson(
    Map<String, dynamic> json,
  ) {
    final displayName =
        json['display_name']?.toString().trim() ?? '';

    final rawName =
        json['name']?.toString().trim() ?? '';

    final name = rawName.isNotEmpty
        ? rawName
        : displayName;

    final address =
        displayName.isNotEmpty ? displayName : null;

    final latitude = double.tryParse(
      json['lat']?.toString() ?? '',
    );

    final longitude = double.tryParse(
      json['lon']?.toString() ?? '',
    );

    return CrawlLocationSearchResult(
      name: name,
      address: address,
      latitude: latitude ?? 0,
      longitude: longitude ?? 0,
    );
  }
}
