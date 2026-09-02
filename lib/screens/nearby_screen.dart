// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/nearby_result.dart';
import '../services/dining_unhinged_api.dart';
import '../services/location_service.dart';
import '../features/crawl/services/saved_store.dart';
import '../widgets/nearby_result_card.dart';

class NearbyScreen extends StatefulWidget {
  final VoidCallback? onDecisionCommitted;

  const NearbyScreen({
    super.key,
    this.onDecisionCommitted,
  });

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  bool _loading = false;
  String? _error;

  List<NearbyResult> _allResults = [];
  List<NearbyResult> _results = [];

  double _radiusKm = 25;

  static const List<double> _radiusOptions = [
    5,
    10,
    25,
    50,
  ];

  Future<void> _loadNearby() async {
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });

    try {
      debugPrint('LOCATION: Starting location request');

      final position =
          await LocationService.getCurrentLocation();

      debugPrint(
        'LOCATION: Current position = '
        '${position.latitude}, ${position.longitude}',
      );

      final results =
          await DiningUnhingedApi().fetchNearbyResults();

      debugPrint(
        'DINING UNHINGED: Received ${results.length} results',
      );

      final nearbyResults = <NearbyResult>[];

      for (final result in results) {
        final location = result.venue.location;

        if (location == null || !location.isValid) {
          debugPrint(
            'Skipping ${result.venue.name}: '
            'no valid location',
          );
          continue;
        }

        final distanceMeters =
            Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          location.latitude!,
          location.longitude!,
        );

        final distanceKm = distanceMeters / 1000;

        result.distanceKm = distanceKm;

        debugPrint(
          '${result.venue.name}: '
          '${distanceKm.toStringAsFixed(2)} km',
        );

        nearbyResults.add(result);
      }

      nearbyResults.sort(
        (a, b) =>
            (a.distanceKm ?? double.infinity)
                .compareTo(
          b.distanceKm ?? double.infinity,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _allResults = nearbyResults;
        _applyRadiusFilter();
        _loading = false;
      });
    } on LocationPermissionException catch (e) {
      debugPrint(
        'LOCATION PERMISSION ERROR: ${e.message}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = e.message;
      });
    } on LocationServiceException catch (e) {
      debugPrint(
        'LOCATION SERVICE ERROR: ${e.message}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e, stackTrace) {
      debugPrint('NEARBY ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error =
            "We couldn't find the questionable decisions.";
      });
    }
  }

  void _applyRadiusFilter() {
    _results = _allResults.where((result) {
      final distance = result.distanceKm;

      if (distance == null) {
        return false;
      }

      return distance <= _radiusKm;
    }).toList();
  }

  void _changeRadius(double radius) {
    setState(() {
      _radiusKm = radius;
      _applyRadiusFilter();
    });
  }

  String _formatDistance(double? distanceKm) {
    if (distanceKm == null) {
      return '';
    }

    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }

    return '${distanceKm.toStringAsFixed(1)} km';
  }

  NearbyResult? _chooseRandomVenue() {
    if (_results.isEmpty) {
      return null;
    }

    final weightedResults = <NearbyResult>[];

    for (final result in _results) {
      final distance =
          result.distanceKm ?? _radiusKm;

      final weight = max(
        1,
        ((_radiusKm - distance + 1) * 10).round(),
      );

      for (var i = 0; i < weight; i++) {
        weightedResults.add(result);
      }
    }

    if (weightedResults.isEmpty) {
      return _results[
          Random().nextInt(_results.length)];
    }

    return weightedResults[
        Random().nextInt(weightedResults.length)];
  }

  void _makeTheDecision() {
    if (_results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'There is nothing questionable within the selected radius.',
          ),
        ),
      );
      return;
    }

    final decision = _chooseRandomVenue();

    if (decision == null) {
      return;
    }

    _showDecisionDialog(decision);
  }

  void _showDecisionDialog(
    NearbyResult decision,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _DecisionDialog(
          result: decision,
          distance: _formatDistance(
            decision.distanceKm,
          ),
          onRollAgain: () {
            Navigator.of(dialogContext).pop();

            Future.delayed(
              const Duration(milliseconds: 150),
              () {
                if (mounted) {
                  _makeTheDecision();
                }
              },
            );
          },
          onLetsGo: () async {
            try {
              await saveNearbyResult(decision);

              if (!mounted) {
                return;
              }

              Navigator.of(dialogContext).pop();

              widget.onDecisionCommitted?.call();
            } catch (error, stackTrace) {
              debugPrint(
                'NEARBY SAVE ERROR: $error',
              );
              debugPrint(
                'NEARBY SAVE STACK TRACE: $stackTrace',
              );

              if (!mounted) {
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Couldn\'t save that questionable decision.',
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFFD4AF37),
        backgroundColor: const Color(0xFF1C1C1E),
        onRefresh: _loadNearby,
        child: CustomScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                24,
                20,
                24,
                32,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 4,
                        bottom: 20,
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 140,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Text(
                    'QUESTIONABLE',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(
                          color:
                              const Color(0xFFD4AF37),
                          letterSpacing: 4,
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'DECISIONS NEARBY',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Find somewhere worth making a questionable decision.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          _loading
                              ? null
                              : _loadNearby,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(
                                  0xFF0D0D0F,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons
                                  .location_searching,
                            ),
                      label: Text(
                        _loading
                            ? 'SEARCHING...'
                            : 'FIND SOMETHING NEARBY',
                      ),
                      style:
                          FilledButton.styleFrom(
                        backgroundColor:
                            const Color(
                          0xFFD4AF37,
                        ),
                        foregroundColor:
                            const Color(
                          0xFF0D0D0F,
                        ),
                        disabledBackgroundColor:
                            const Color(
                          0xFFD4AF37,
                        ),
                        disabledForegroundColor:
                            const Color(
                          0xFF0D0D0F,
                        ),
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 16,
                        ),
                        textStyle:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          _results.isEmpty ||
                                  _loading
                              ? null
                              : _makeTheDecision,
                      icon: const Icon(
                        Icons.casino_outlined,
                      ),
                      label: const Text(
                        'MAKE THE DECISION FOR ME',
                      ),
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            const Color(
                          0xFFD4AF37,
                        ),
                        side: const BorderSide(
                          color: Color(
                            0xFFD4AF37,
                          ),
                        ),
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 16,
                        ),
                        textStyle:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_allResults.isNotEmpty)
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SEARCH RADIUS',
                          style: TextStyle(
                            color:
                                Color(0xFFD4AF37),
                            fontSize: 12,
                            fontWeight:
                                FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 44,
                          child:
                              ListView.separated(
                            scrollDirection:
                                Axis.horizontal,
                            itemCount:
                                _radiusOptions
                                    .length,
                            separatorBuilder:
                                (context, index) =>
                                    const SizedBox(
                              width: 8,
                            ),
                            itemBuilder:
                                (context, index) {
                              final radius =
                                  _radiusOptions[
                                      index];

                              final selected =
                                  radius ==
                                      _radiusKm;

                              return ChoiceChip(
                                label: Text(
                                  '${radius.toInt()} km',
                                ),
                                selected:
                                    selected,
                                onSelected: (_) {
                                  _changeRadius(
                                    radius,
                                  );
                                },
                                selectedColor:
                                    const Color(
                                  0xFFD4AF37,
                                ),
                                backgroundColor:
                                    const Color(
                                  0xFF1C1C1E,
                                ),
                                labelStyle:
                                    TextStyle(
                                  color: selected
                                      ? const Color(
                                          0xFF0D0D0F,
                                        )
                                      : Colors
                                          .white70,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                                side: BorderSide(
                                  color: selected
                                      ? const Color(
                                          0xFFD4AF37,
                                        )
                                      : Colors
                                          .white12,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF1C1C1E,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        border: Border.all(
                          color: Colors.redAccent
                              .withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.location_off,
                            color:
                                Colors.redAccent,
                            size: 32,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextButton(
                            onPressed:
                                _loadNearby,
                            child: const Text(
                              'TRY AGAIN',
                              style: TextStyle(
                                color: Color(
                                  0xFFD4AF37,
                                ),
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!_loading &&
                      _error == null &&
                      _allResults.isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        vertical: 24,
                      ),
                      child: Text(
                        'Tap the button and let the questionable decisions begin.',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  if (_allResults.isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 16,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${_results.length} nearby',
                            style:
                                const TextStyle(
                              color:
                                  Colors.white60,
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'within ${_radiusKm.toInt()} km',
                            style:
                                const TextStyle(
                              color: Color(
                                0xFFD4AF37,
                              ),
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ]),
              ),
            ),
            if (_results.isNotEmpty)
              SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  32,
                ),
                sliver: SliverList(
                  delegate:
                      SliverChildBuilderDelegate(
                    (context, index) {
                      final result =
                          _results[index];

                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 18,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            NearbyResultCard(
                              result: result,
                            ),
                            if (result.distanceKm !=
                                null)
                              Padding(
                                padding:
                                    const EdgeInsets
                                        .only(
                                  left: 8,
                                  top: 6,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons
                                          .near_me_outlined,
                                      size: 15,
                                      color: Color(
                                        0xFFD4AF37,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      _formatDistance(
                                        result
                                            .distanceKm,
                                      ),
                                      style:
                                          const TextStyle(
                                        color: Colors
                                            .white54,
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    childCount:
                        _results.length,
                  ),
                ),
              ),
            if (!_loading &&
                _error == null &&
                _allResults.isNotEmpty &&
                _results.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_off,
                          size: 52,
                          color: Color(
                            0xFFD4AF37,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Nothing questionable nearby.',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try expanding the search radius.',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color:
                                Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DecisionDialog extends StatelessWidget {
  final NearbyResult result;
  final String distance;
  final VoidCallback onRollAgain;
  final Future<void> Function() onLetsGo;

  const _DecisionDialog({
    required this.result,
    required this.distance,
    required this.onRollAgain,
    required this.onLetsGo,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor:
          const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.casino,
                size: 54,
                color: Color(0xFFD4AF37),
              ),
              const SizedBox(height: 14),
              const Text(
                'THE DECISION',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 13,
                  fontWeight:
                      FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 18),
              if (result.heroImage != null)
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  child: Image.network(
                    result.heroImage!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stack) {
                      return Container(
                        height: 180,
                        color: const Color(
                          0xFF0D0D0F,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.restaurant,
                            size: 52,
                            color: Color(
                              0xFFD4AF37,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (result.heroImage != null)
                const SizedBox(height: 18),
              Text(
                result.venue.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (result.category != null &&
                  result.category!.isNotEmpty)
                Text(
                  result.category!,
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star,
                    color:
                        Color(0xFFD4AF37),
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    result.rating
                        .toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 18),
                  const Icon(
                    Icons.near_me,
                    color:
                        Color(0xFFD4AF37),
                    size: 18,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    distance,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onLetsGo,
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFFD4AF37,
                    ),
                    foregroundColor:
                        const Color(
                      0xFF0D0D0F,
                    ),
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    "LET'S FUCKING GO",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed:
                      onRollAgain,
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(
                      0xFFD4AF37,
                    ),
                    side: const BorderSide(
                      color: Color(
                        0xFFD4AF37,
                      ),
                    ),
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    'NOPE. ROLL AGAIN.',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop();
                },
                child: const Text(
                  'I HAVE REGRETS',
                  style: TextStyle(
                    color:
                        Colors.white38,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
