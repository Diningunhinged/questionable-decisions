import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/detour_trip.dart';

const _savedDetourTripsKey = 'saved_detour_trips_v1';

final List<DetourTrip> savedDetourTrips = [];

bool _loaded = false;

Future<void> loadSavedDetourTrips() async {
  if (_loaded) {
    return;
  }

  final preferences = await SharedPreferences.getInstance();
  final raw = preferences.getString(_savedDetourTripsKey);

  savedDetourTrips.clear();

  if (raw != null && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        savedDetourTrips.addAll(
          decoded
              .whereType<Map>()
              .map(
                (value) => DetourTrip.fromJson(
                  value.cast<String, dynamic>(),
                ),
              )
              .where((trip) => trip.isValid),
        );
      }
    } catch (_) {
      savedDetourTrips.clear();
    }
  }

  _loaded = true;
}

Future<void> saveDetourTrip(DetourTrip trip) async {
  await loadSavedDetourTrips();

  if (!trip.isValid) {
    return;
  }

  final existingIndex = savedDetourTrips.indexWhere(
    (saved) => saved.id == trip.id,
  );

  if (existingIndex >= 0) {
    savedDetourTrips[existingIndex] = trip;
  } else {
    savedDetourTrips.insert(0, trip);
  }

  await _persistSavedDetourTrips();
}

Future<void> deleteSavedDetourTrip(String id) async {
  await loadSavedDetourTrips();

  savedDetourTrips.removeWhere(
    (trip) => trip.id == id,
  );

  await _persistSavedDetourTrips();
}

Future<void> _persistSavedDetourTrips() async {
  final preferences = await SharedPreferences.getInstance();

  await preferences.setString(
    _savedDetourTripsKey,
    jsonEncode(
      savedDetourTrips.map((trip) => trip.toJson()).toList(),
    ),
  );
}
