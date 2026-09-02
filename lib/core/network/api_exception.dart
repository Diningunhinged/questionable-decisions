// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException ($statusCode): $message';
    }

    return 'ApiException: $message';
  }
}
