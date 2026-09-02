// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

import '../models/nearby_result.dart';

/// V1 saved decisions. A decision is saved when the user
/// presses "LET'S FUCKING GO".
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
