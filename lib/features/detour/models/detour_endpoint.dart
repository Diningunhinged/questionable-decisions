// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

class DetourEndpoint {
  const DetourEndpoint({
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String? address;
  final double latitude;
  final double longitude;

  bool get isValid {
    return name.trim().isNotEmpty &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  DetourEndpoint copyWith({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return DetourEndpoint(
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory DetourEndpoint.fromJson(
    Map<String, dynamic> json,
  ) {
    return DetourEndpoint(
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      latitude:
          (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude:
          (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}
