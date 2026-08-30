enum DetourRoutePreference {
  flexible,
  strict,
}

class DetourPreferences {
  const DetourPreferences({
    this.maximumDetourKm = 10,
    this.preferredCategories = const {},
    this.minimumRating = 0,
    this.maximumStops = 3,
    this.allowOvernightStops = false,
    this.avoidVisitedOrSaved = false,
    this.openNowOnly = false,
    this.routePreference = DetourRoutePreference.flexible,
  });

  final double maximumDetourKm;
  final Set<String> preferredCategories;
  final double minimumRating;
  final int maximumStops;
  final bool allowOvernightStops;
  final bool avoidVisitedOrSaved;
  final bool openNowOnly;
  final DetourRoutePreference routePreference;

  DetourPreferences copyWith({
    double? maximumDetourKm,
    Set<String>? preferredCategories,
    double? minimumRating,
    int? maximumStops,
    bool? allowOvernightStops,
    bool? avoidVisitedOrSaved,
    bool? openNowOnly,
    DetourRoutePreference? routePreference,
  }) {
    return DetourPreferences(
      maximumDetourKm:
          maximumDetourKm ?? this.maximumDetourKm,
      preferredCategories:
          preferredCategories ?? this.preferredCategories,
      minimumRating:
          minimumRating ?? this.minimumRating,
      maximumStops:
          maximumStops ?? this.maximumStops,
      allowOvernightStops:
          allowOvernightStops ??
              this.allowOvernightStops,
      avoidVisitedOrSaved:
          avoidVisitedOrSaved ??
              this.avoidVisitedOrSaved,
      openNowOnly:
          openNowOnly ?? this.openNowOnly,
      routePreference:
          routePreference ?? this.routePreference,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maximumDetourKm': maximumDetourKm,
      'preferredCategories':
          preferredCategories.toList(),
      'minimumRating': minimumRating,
      'maximumStops': maximumStops,
      'allowOvernightStops':
          allowOvernightStops,
      'avoidVisitedOrSaved':
          avoidVisitedOrSaved,
      'openNowOnly': openNowOnly,
      'routePreference':
          routePreference.name,
    };
  }

  factory DetourPreferences.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawCategories =
        json['preferredCategories'];

    final categories = rawCategories is List
        ? rawCategories
            .whereType<String>()
            .toSet()
        : <String>{};

    final rawRoutePreference =
        json['routePreference']?.toString();

    final routePreference =
        DetourRoutePreference.values
            .where(
              (value) =>
                  value.name == rawRoutePreference,
            )
            .firstOrNull ??
        DetourRoutePreference.flexible;

    return DetourPreferences(
      maximumDetourKm:
          (json['maximumDetourKm'] as num?)
                  ?.toDouble() ??
              10,
      preferredCategories: categories,
      minimumRating:
          (json['minimumRating'] as num?)
                  ?.toDouble() ??
              0,
      maximumStops:
          (json['maximumStops'] as num?)?.toInt() ??
              3,
      allowOvernightStops:
          json['allowOvernightStops'] as bool? ??
              false,
      avoidVisitedOrSaved:
          json['avoidVisitedOrSaved'] as bool? ??
              false,
      openNowOnly:
          json['openNowOnly'] as bool? ??
              false,
      routePreference: routePreference,
    );
  }
}