import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/crawl_starting_point.dart';

class CrawlMapPickerScreen extends StatefulWidget {
  const CrawlMapPickerScreen({
    super.key,
    this.initialStartingPoint,
  });

  final CrawlStartingPoint? initialStartingPoint;

  @override
  State<CrawlMapPickerScreen> createState() =>
      _CrawlMapPickerScreenState();
}

class _CrawlMapPickerScreenState
    extends State<CrawlMapPickerScreen> {
  static const LatLng _defaultLocation = LatLng(
    53.2780,
    -110.0050,
  );

  late LatLng _selectedLocation;

  @override
  void initState() {
    super.initState();

    final startingPoint =
        widget.initialStartingPoint;

    _selectedLocation = startingPoint == null
        ? _defaultLocation
        : LatLng(
            startingPoint.latitude,
            startingPoint.longitude,
          );
  }

  void _updateSelectedLocation(
    CameraPosition position,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedLocation = position.target;
    });
  }

  void _confirmLocation() {
    final startingPoint = CrawlStartingPoint(
      name: 'Dropped Pin',
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
    );

    if (!startingPoint.isValid) {
      return;
    }

    Navigator.of(context).pop(
      startingPoint,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose Starting Point',
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 14,
            ),
            onCameraMove: _updateSelectedLocation,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          const Center(
            child: IgnorePointer(
              child: Icon(
                Icons.location_pin,
                size: 50,
                color: Colors.red,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: Card(
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Selected Starting Point',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Latitude: '
                        '${_selectedLocation.latitude.toStringAsFixed(6)}',
                      ),
                      Text(
                        'Longitude: '
                        '${_selectedLocation.longitude.toStringAsFixed(6)}',
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _confirmLocation,
                          child: const Text(
                            'USE THIS LOCATION',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}