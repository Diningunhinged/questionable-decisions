// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/detour_endpoint.dart';

const _savedDestinationsKey = 'detour_saved_destinations_v1';
const _recentDestinationsKey = 'detour_recent_destinations_v1';

final List<DetourEndpoint> savedDetourDestinations = [];
final List<DetourEndpoint> recentDetourDestinations = [];

bool _loaded = false;

Future<void> loadDetourDestinations() async {
  if (_loaded) {
    return;
  }

  final preferences = await SharedPreferences.getInstance();

  savedDetourDestinations.clear();
  recentDetourDestinations.clear();

  _loadList(
    preferences.getString(_savedDestinationsKey),
    savedDetourDestinations,
  );

  _loadList(
    preferences.getString(_recentDestinationsKey),
    recentDetourDestinations,
  );

  _loaded = true;
}

void _loadList(
  String? raw,
  List<DetourEndpoint> destinationList,
) {
  if (raw == null || raw.isEmpty) {
    return;
  }

  try {
    final decoded = jsonDecode(raw);

    if (decoded is List) {
      destinationList.addAll(
        decoded
            .whereType<Map>()
            .map(
              (value) => DetourEndpoint.fromJson(
                value.cast<String, dynamic>(),
              ),
            )
            .where(
              (destination) => destination.isValid,
            ),
        );
    }
  } catch (_) {
    destinationList.clear();
  }
}

bool isSavedDetourDestination(
  DetourEndpoint destination,
) {
  return savedDetourDestinations.any(
    (saved) => _sameDestination(saved, destination),
  );
}

void addRecentDetourDestination(
  DetourEndpoint destination,
) {
  if (!destination.isValid) {
    return;
  }

  recentDetourDestinations.removeWhere(
    (recent) => _sameDestination(recent, destination),
  );

  recentDetourDestinations.insert(
    0,
    destination,
  );

  if (recentDetourDestinations.length > 10) {
    recentDetourDestinations.removeRange(
      10,
      recentDetourDestinations.length,
    );
  }
}

Future<void> saveDetourDestination(
  DetourEndpoint destination,
) async {
  await loadDetourDestinations();

  if (!destination.isValid) {
    return;
  }

  savedDetourDestinations.removeWhere(
    (saved) => _sameDestination(saved, destination),
  );

  savedDetourDestinations.insert(
    0,
    destination,
  );

  await _persistDestinations();
}

Future<void> removeDetourDestination(
  DetourEndpoint destination,
) async {
  await loadDetourDestinations();

  savedDetourDestinations.removeWhere(
    (saved) => _sameDestination(saved, destination),
  );

  await _persistDestinations();
}

Future<void> recordRecentDetourDestination(
  DetourEndpoint destination,
) async {
  await loadDetourDestinations();

  if (!destination.isValid) {
    return;
  }

  addRecentDetourDestination(destination);

  await _persistDestinations();
}

bool _sameDestination(
  DetourEndpoint first,
  DetourEndpoint second,
) {
  return first.name.trim().toLowerCase() ==
          second.name.trim().toLowerCase() &&
      _sameCoordinate(
        first.latitude,
        second.latitude,
      ) &&
      _sameCoordinate(
        first.longitude,
        second.longitude,
      );
}

bool _sameCoordinate(
  double first,
  double second,
) {
  return (first - second).abs() < 0.00001;
}

Future<void> _persistDestinations() async {
  final preferences = await SharedPreferences.getInstance();

  await preferences.setString(
    _savedDestinationsKey,
    jsonEncode(
      savedDetourDestinations
          .map(
            (destination) => destination.toJson(),
          )
          .toList(),
    ),
  );

  await preferences.setString(
    _recentDestinationsKey,
    jsonEncode(
      recentDetourDestinations
          .map(
            (destination) => destination.toJson(),
          )
          .toList(),
    ),
  );
}
