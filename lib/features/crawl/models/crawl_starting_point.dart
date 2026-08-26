class CrawlStartingPoint {
  final String name;
  final double latitude;
  final double longitude;

  const CrawlStartingPoint({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  bool get isValid {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }
}