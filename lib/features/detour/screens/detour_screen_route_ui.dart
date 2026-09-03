part of 'detour_screen.dart';

extension _DetourRouteUi on _DetourScreenState {
  Widget _buildRouteResult() {
    final route = _route;

    if (route == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildSectionCard(
          title: 'ROUTE CALCULATED',
          child: Row(
            children: [
              Expanded(
                child: _routeSummaryItem(
                  Icons.route,
                  _formatDistance(
                    route.distanceKilometers,
                  ),
                  'DRIVING DISTANCE',
                ),
              ),
              Expanded(
                child: _routeSummaryItem(
                  Icons.schedule_outlined,
                  _formatDuration(
                    route.durationMinutes,
                  ),
                  'EST. DRIVE TIME',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _buildDetourMap(route),
      ],
    );
  }

  Widget _buildDetourMap(DetourRoute route) {
    final routePoints = route.geometry
        .where((point) => point.length == 2)
        .map(
          (point) => LatLng(
            point[0],
            point[1],
          ),
        )
        .toList();

    if (routePoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final markers = <Marker>{};

    final startingPoint = _startingPoint;
    if (startingPoint != null) {
      markers.add(
        Marker(
          markerId: const MarkerId(
            'detour_start',
          ),
          position: LatLng(
            startingPoint.latitude,
            startingPoint.longitude,
          ),
          infoWindow: const InfoWindow(
            title: 'START',
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    for (var index = 0;
        index < _optimizedStops.length;
        index++) {
      final stop = _optimizedStops[index];

      markers.add(
        Marker(
          markerId: MarkerId(
            'detour_stop_$index',
          ),
          position: LatLng(
            stop.latitude,
            stop.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'STOP ${index + 1}',
            snippet: stop.name,
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow,
          ),
        ),
      );
    }

    final destination = _destination;
    if (destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId(
            'detour_destination',
          ),
          position: LatLng(
            destination.latitude,
            destination.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'DESTINATION',
            snippet: destination.name,
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    final polyline = Polyline(
      polylineId: const PolylineId(
        'detour_optimized_route',
      ),
      points: routePoints,
      width: 6,
      color: const Color(0xFFD4AF37),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 360,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: routePoints.first,
            zoom: 12,
          ),
          onMapCreated: (controller) {
            _detourMapController = controller;
            _fitDetourMap(routePoints);
          },
          markers: markers,
          polylines: {polyline},
          gestureRecognizers:
              <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
          zoomControlsEnabled: false,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          mapToolbarEnabled: false,
          compassEnabled: true,
        ),
      ),
    );
  }

  Future<void> _fitDetourMap(
    List<LatLng> points,
  ) async {
    final controller = _detourMapController;

    if (controller == null || points.isEmpty) {
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      if (point.latitude < minLat) {
        minLat = point.latitude;
      }

      if (point.latitude > maxLat) {
        maxLat = point.latitude;
      }

      if (point.longitude < minLng) {
        minLng = point.longitude;
      }

      if (point.longitude > maxLng) {
        maxLng = point.longitude;
      }
    }

    if ((maxLat - minLat).abs() < 0.001 &&
        (maxLng - minLng).abs() < 0.001) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          points.first,
          15,
        ),
      );
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(
        minLat,
        minLng,
      ),
      northeast: LatLng(
        maxLat,
        maxLng,
      ),
    );

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          50,
        ),
      );
    } catch (_) {
      await Future<void>.delayed(
        const Duration(milliseconds: 250),
      );

      if (!mounted ||
          _detourMapController != controller) {
        return;
      }

      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          50,
        ),
      );
    }
  }

  Widget _routeSummaryItem(
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFFD4AF37),
          size: 22,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  String _formatDistance(
    double kilometers,
  ) {
    if (kilometers < 10) {
      return '${kilometers.toStringAsFixed(1)} km';
    }

    return '${kilometers.toStringAsFixed(0)} km';
  }

  String _formatDuration(
    double minutes,
  ) {
    final totalMinutes =
        minutes.round();

    final hours =
        totalMinutes ~/ 60;

    final remainingMinutes =
        totalMinutes % 60;

    if (hours == 0) {
      return '$remainingMinutes min';
    }

    if (remainingMinutes == 0) {
      return '$hours hr';
    }

    return '$hours hr '
        '$remainingMinutes min';
  }
}