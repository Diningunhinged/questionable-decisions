import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/nearby_result.dart';
import '../services/saved_store.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  Future<void> _openSavedReview(
    BuildContext context,
    NearbyResult result,
  ) async {
    final section = result.isDrink ? 'drinks' : 'venues';

    final url = Uri.parse(
      'https://www.diningunhinged.ca/$section/${result.slug}',
    );

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the Dining Unhinged review.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the Dining Unhinged review.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = List<NearbyResult>.from(savedNearbyResults);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0F),
        elevation: 0,
        title: const Text(
          'SAVED',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
      body: saved.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 56,
                      color: Color(0xFFD4AF37),
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Nothing questionable saved yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Roll the dice. Find somewhere questionable. '
                      'Then hit LET\'S FUCKING GO.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              itemCount: saved.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final result = saved[index];

                return InkWell(
                  onTap: () => _openSavedReview(context, result),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF333337),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (result.heroImage != null &&
                            result.heroImage!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              result.heroImage!,
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _savedPlaceholder(),
                            ),
                          )
                        else
                          _savedPlaceholder(),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                result.category ??
                                    (result.isDrink
                                        ? 'Drink'
                                        : 'Restaurant'),
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              if (result.distanceKm != null)
                                Text(
                                  '${result.distanceKm!.toStringAsFixed(1)} km away',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFFD4AF37),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _savedPlaceholder() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0F),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.restaurant,
        color: Color(0xFFD4AF37),
        size: 30,
      ),
    );
  }
}

