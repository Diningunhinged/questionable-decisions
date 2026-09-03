part of 'detour_screen.dart';

extension _DetourTracking on _DetourScreenState {
  Future<void> _startDetour() async {
    final route = _route;
    final destination = _destination;

    if (route == null ||
        destination == null ||
        !route.isValid ||
        !destination.isValid) {
      _showMessage(
        'Calculate a valid detour before starting.',
      );
      return;
    }

    if (_detourActive) {
      return;
    }

    try {
      _updateState(() {
        _detourActive = true;
        _detourPosition = null;
        _distanceToNextStopMeters = null;
        _activeStopIndex = 0;
        _detourProximityNotificationSent = false;
        _detourCompleted = false;
      });

      await DetourLocationTrackingService.start(
        onPosition: _handleDetourPosition,
        onError: (error) {
          if (!mounted) {
            return;
          }

          _showMessage(
            'Detour location tracking error: $error',
          );
        },
      );

      if (!mounted) {
        await DetourLocationTrackingService.stop();
        return;
      }

      _showMessage(
        'Detour started. GPS tracking is active.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      await DetourLocationTrackingService.stop();

      _updateState(() {
        _detourActive = false;
        _detourPosition = null;
        _distanceToNextStopMeters = null;
        _activeStopIndex = 0;
        _detourProximityNotificationSent = false;
      });

      _showMessage(
        'Could not start Detour tracking: $error',
      );
    }
  }

  Future<void> _stopDetour() async {
    await DetourLocationTrackingService.stop();

    if (!mounted) {
      return;
    }

    _updateState(() {
      _detourActive = false;
      _detourPosition = null;
      _distanceToNextStopMeters = null;
      _activeStopIndex = 0;
      _detourProximityNotificationSent = false;
      _detourCompleted = false;
    });

    _showMessage(
      'Detour tracking stopped.',
    );
  }

  void _handleDetourPosition(Position position) {
    if (!_detourActive) {
      return;
    }

    final target = _nextDetourTarget;

    if (target == null) {
      debugPrint(
        'DETOUR LOCATION: Received position but no active target.',
      );
      return;
    }

    debugPrint(
      'DETOUR LOCATION HANDLER: '
      '${position.latitude}, ${position.longitude}',
    );

    final distanceMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      target.latitude,
      target.longitude,
    );

    if (!mounted) {
      return;
    }

    _updateState(() {
      _detourPosition = position;
      _distanceToNextStopMeters = distanceMeters;
    });

    if (!_detourProximityNotificationSent &&
        distanceMeters <=
            _DetourScreenState._encounterDistanceMeters) {
      _detourProximityNotificationSent = true;

      debugPrint(
        'DETOUR PROXIMITY: ${target.name} within '
        '${_DetourScreenState._encounterDistanceMeters} m',
      );

      NotificationService.showDetourEncounter(
        title: target.name,
        distanceMeters: distanceMeters,
      );
    }

    if (distanceMeters <=
        _DetourScreenState._arrivalDistanceMeters) {
      _handleDetourArrival();
    }
  }

  Future<void> _handleDetourArrival() async {
    if (!_detourActive) {
      return;
    }

    if (_activeStopIndex < _optimizedStops.length) {
      final stop = _optimizedStops[_activeStopIndex];
      final stopNumber = _activeStopIndex + 1;

      _updateState(() {
        _activeStopIndex += 1;
        _distanceToNextStopMeters = null;
        _detourProximityNotificationSent = false;
      });

      _showMessage(
        'ARRIVED AT STOP $stopNumber: ${stop.name}',
      );
      return;
    }

    _detourActive = false;
    await DetourLocationTrackingService.stop();

    if (!mounted) {
      return;
    }

    _updateState(() {
      _detourCompleted = true;
      _distanceToNextStopMeters = null;
      _detourProximityNotificationSent = false;
    });

    _showMessage(
      'DETOUR COMPLETE. You made it.',
    );
  }

  DetourEndpoint? get _nextDetourTarget {
    if (_activeStopIndex < _optimizedStops.length) {
      final stop = _optimizedStops[_activeStopIndex];

      return DetourEndpoint(
        name: stop.name,
        address: stop.address,
        latitude: stop.latitude,
        longitude: stop.longitude,
      );
    }

    return _destination;
  }

  String get _nextDetourTargetLabel {
    if (_activeStopIndex < _optimizedStops.length) {
      return 'STOP ${_activeStopIndex + 1}';
    }

    return 'DESTINATION';
  }

  String _formatTrackingDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}