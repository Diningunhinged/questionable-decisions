enum CrawlSize {
  responsible,
  questionable,
  unhinged,
  seeYouTomorrow,
}

enum CrawlCategory {
  breweries,
  cocktailBars,
  restaurants,
  distilleries,
  wine,
  coffee,
  surpriseMe,
  anyCategory,
}

enum DistanceUnit {
  metric,
  imperial,
}

class CrawlConfiguration {
  final CrawlSize size;
  final Set<CrawlCategory> categories;
  final double walkingDistanceMeters;
  final DistanceUnit distanceUnit;

  const CrawlConfiguration({
    this.size = CrawlSize.questionable,
    this.categories = const {
      CrawlCategory.anyCategory,
    },
    this.walkingDistanceMeters = 2000,
    this.distanceUnit = DistanceUnit.metric,
  });

  int get stopCount {
    switch (size) {
      case CrawlSize.responsible:
        return 2;
      case CrawlSize.questionable:
        return 3;
      case CrawlSize.unhinged:
        return 4;
      case CrawlSize.seeYouTomorrow:
        return 5;
    }
  }

  double get walkingDistanceKm {
    return walkingDistanceMeters / 1000;
  }

  double get walkingDistanceMiles {
    return walkingDistanceMeters / 1609.344;
  }

  double get displayedWalkingDistance {
    switch (distanceUnit) {
      case DistanceUnit.metric:
        return walkingDistanceKm;
      case DistanceUnit.imperial:
        return walkingDistanceMiles;
    }
  }

  String get walkingDistanceUnitLabel {
    switch (distanceUnit) {
      case DistanceUnit.metric:
        return 'km';
      case DistanceUnit.imperial:
        return 'mi';
    }
  }

  CrawlConfiguration copyWith({
    CrawlSize? size,
    Set<CrawlCategory>? categories,
    double? walkingDistanceMeters,
    DistanceUnit? distanceUnit,
  }) {
    return CrawlConfiguration(
      size: size ?? this.size,
      categories: categories ?? this.categories,
      walkingDistanceMeters:
          walkingDistanceMeters ?? this.walkingDistanceMeters,
      distanceUnit:
          distanceUnit ?? this.distanceUnit,
    );
  }
}