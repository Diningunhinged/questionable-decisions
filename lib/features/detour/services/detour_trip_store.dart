import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/detour_trip.dart';

const _currentTripKey =
    'detour_current_trip_v1';

const _savedTripsKey =
    'detour_saved_trips_v1';

DetourTrip? currentDetourTrip;

final List<DetourTrip> savedDetourTrips = [];

bool _loaded = false;

Future<void> loadDetourTrips() async {
  if (_loaded) {
    return;
  }

  final preferences =
      await SharedPreferences.getInstance();

  currentDetourTrip = null;
  savedDetourTrips.clear();

  final currentRaw =
      preferences.getString(
    _currentTripKey,
  );

  if (currentRaw != null &&
      currentRaw.trim().isNotEmpty) {
    try {
      final decoded =
          jsonDecode(currentRaw);

      if (decoded is Map) {
        final trip =
            DetourTrip.fromJson(
          decoded.cast<
              String,
              dynamic>(),
        );

        if (trip.isValid) {
          currentDetourTrip = trip;
        }
      }
    } catch (_) {
      currentDetourTrip = null;
    }
  }

  final savedRaw =
      preferences.getString(
    _savedTripsKey,
  );

  if (savedRaw != null &&
      savedRaw.trim().isNotEmpty) {
    try {
      final decoded =
          jsonDecode(savedRaw);

      if (decoded is List) {
        for (final value in decoded) {
          if (value is! Map) {
            continue;
          }

          try {
            final trip =
                DetourTrip.fromJson(
              value.cast<
                  String,
                  dynamic>(),
            );

            if (trip.isValid) {
              savedDetourTrips.add(
                trip,
              );
            }
          } catch (_) {
            // Ignore malformed saved trips.
          }
        }
      }
    } catch (_) {
      savedDetourTrips.clear();
    }
  }

  _sortTrips();

  _loaded = true;
}

Future<void> saveCurrentDetourTrip(
  DetourTrip trip,
) async {
  await loadDetourTrips();

  if (!trip.isValid) {
    return;
  }

  currentDetourTrip = trip;

  await _persistTrips();
}

Future<void> updateCurrentDetourTrip(
  DetourTrip trip,
) async {
  await saveCurrentDetourTrip(
    trip,
  );
}

Future<void> clearCurrentDetourTrip() async {
  await loadDetourTrips();

  currentDetourTrip = null;

  final preferences =
      await SharedPreferences.getInstance();

  await preferences.remove(
    _currentTripKey,
  );
}

Future<void> saveTripToSavedTrips(
  DetourTrip trip,
) async {
  await loadDetourTrips();

  if (!trip.isValid) {
    return;
  }

  savedDetourTrips.removeWhere(
    (saved) => saved.id == trip.id,
  );

  savedDetourTrips.insert(
    0,
    trip,
  );

  await _persistTrips();
}

Future<void> removeSavedDetourTrip(
  String tripId,
) async {
  await loadDetourTrips();

  savedDetourTrips.removeWhere(
    (trip) => trip.id == tripId,
  );

  await _persistTrips();
}

Future<void> clearAllSavedDetourTrips() async {
  await loadDetourTrips();

  savedDetourTrips.clear();

  await _persistTrips();
}

DetourTrip? findDetourTrip(
  String tripId,
) {
  for (final trip in savedDetourTrips) {
    if (trip.id == tripId) {
      return trip;
    }
  }

  return null;
}

void _sortTrips() {
  savedDetourTrips.sort(
    (first, second) =>
        second.updatedAt.compareTo(
      first.updatedAt,
    ),
  );
}

Future<void> _persistTrips() async {
  final preferences =
      await SharedPreferences.getInstance();

  final current =
      currentDetourTrip;

  if (current == null) {
    await preferences.remove(
      _currentTripKey,
    );
  } else {
    await preferences.setString(
      _currentTripKey,
      jsonEncode(
        current.toJson(),
      ),
    );
  }

  await preferences.setString(
    _savedTripsKey,
    jsonEncode(
      savedDetourTrips
          .map(
            (trip) => trip.toJson(),
          )
          .toList(),
    ),
  );
}