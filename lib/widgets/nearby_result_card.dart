import 'package:flutter/material.dart';

import '../models/nearby_result.dart';

class NearbyResultCard extends StatelessWidget {
  final NearbyResult result;

  const NearbyResultCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1C1C1E),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.heroImage != null)
            SizedBox(
              width: double.infinity,
              height: 190,
              child: Image.network(
                result.heroImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _imagePlaceholder();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return _imagePlaceholder(
                    loading: true,
                  );
                },
              ),
            )
          else
            _imagePlaceholder(),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        result.venue.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _TypeBadge(
                      isDrink: result.isDrink,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  result.title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Color(0xFFD4AF37),
                      size: 20,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      result.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),

                    if (result.venue.cuisine != null &&
                        result.venue.cuisine!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Text(
                        '•',
                        style: TextStyle(
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          result.venue.cuisine!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                if (result.venue.city != null ||
                    result.venue.province != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white38,
                        size: 18,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _locationText(),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // Venue detail screen will be added next.
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD4AF37),
                      side: const BorderSide(
                        color: Color(0xFFD4AF37),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                    ),
                    child: const Text(
                      'VIEW REVIEW',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _locationText() {
    final city = result.venue.city;
    final province = result.venue.province;

    if (city != null &&
        city.isNotEmpty &&
        province != null &&
        province.isNotEmpty) {
      return '$city, $province';
    }

    return city ?? province ?? '';
  }

  Widget _imagePlaceholder({
    bool loading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 190,
      color: const Color(0xFF0D0D0F),
      child: Center(
        child: loading
            ? const CircularProgressIndicator(
                color: Color(0xFFD4AF37),
              )
            : const Icon(
                Icons.restaurant,
                color: Color(0xFFD4AF37),
                size: 48,
              ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final bool isDrink;

  const _TypeBadge({
    required this.isDrink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isDrink ? 'DRINK' : 'VENUE',
        style: const TextStyle(
          color: Color(0xFF0D0D0F),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}