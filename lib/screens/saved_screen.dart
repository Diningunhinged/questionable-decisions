import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/crawl/models/saved_crawl.dart';
import '../features/crawl/services/saved_store.dart';
import '../models/nearby_result.dart';
import 'crawl_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  bool _loadingCrawls = true;

  @override
  void initState() {
    super.initState();
    _loadCrawls();
  }

  Future<void> _loadCrawls() async {
    await loadSavedCrawls();

    if (!mounted) {
      return;
    }

    setState(() {
      _loadingCrawls = false;
    });
  }

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

  Future<void> _startSavedCrawl(
    SavedCrawl crawl,
  ) async {
    if (crawl.stops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This saved crawl has no stops.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CrawlScreen(
          configuration: crawl.configuration,
          manualStops: List<NearbyResult>.from(
            crawl.stops,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSavedCrawl(
    SavedCrawl crawl,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text(
            'DELETE CRAWL?',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Delete "${crawl.name}" from Saved Crawls?',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Color(0xFF0D0D0F),
              ),
              child: const Text(
                'DELETE',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await deleteSavedCrawl(crawl.id);

    if (!mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${crawl.name}" deleted.',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return '${months[date.month - 1]} '
        '${date.day}, '
        '${date.year}';
  }

  String _configurationSummary(SavedCrawl crawl) {
    final distance = crawl.configuration.distanceUnit.name ==
            'imperial'
        ? '${crawl.configuration.walkingDistanceMiles.toStringAsFixed(1)} mi'
        : '${crawl.configuration.walkingDistanceKm.toStringAsFixed(1)} km';

    return '${crawl.stops.length} stops · $distance · '
        '${crawl.startingPoint.name}';
  }

  Widget _savedCrawlCard(SavedCrawl crawl) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF333337),
        ),
      ),
      child: InkWell(
        onTap: () => _startSavedCrawl(crawl),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            10,
            14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      crawl.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Color(0xFFD4AF37),
                    ),
                    color: const Color(0xFF1C1C1E),
                    onSelected: (value) {
                      if (value == 'start') {
                        _startSavedCrawl(crawl);
                      } else if (value == 'duplicate') {
                        _duplicateCrawl(crawl);
                      } else if (value == 'delete') {
                        _deleteSavedCrawl(crawl);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'start',
                        child: Text(
                          'START CRAWL',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Text(
                          'DUPLICATE',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'DELETE',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(crawl.plannedDate),
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _configurationSummary(crawl),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _startSavedCrawl(crawl),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            const Color(0xFFD4AF37),
                        side: const BorderSide(
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      child: const Text(
                        'START CRAWL',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () =>
                        _deleteSavedCrawl(crawl),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white38,
                    ),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _duplicateCrawl(
    SavedCrawl crawl,
  ) async {
    await duplicateSavedCrawl(crawl);

    if (!mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${crawl.name} Copy" saved.',
        ),
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

  Widget _buildSavedPlaces(
    List<NearbyResult> saved,
  ) {
    if (saved.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          children: [
            Icon(
              Icons.bookmark_border,
              size: 48,
              color: Color(0xFFD4AF37),
            ),
            SizedBox(height: 14),
            Text(
              'Nothing questionable saved yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Save places while making questionable decisions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        28,
      ),
      itemCount: saved.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final result = saved[index];

        return InkWell(
          onTap: () =>
              _openSavedReview(context, result),
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
                    borderRadius:
                        BorderRadius.circular(10),
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.title,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = List<NearbyResult>.from(
      savedNearbyResults,
    );

    final crawls = List<SavedCrawl>.from(
      savedCrawls,
    )..sort(
        (a, b) => a.plannedDate.compareTo(
          b.plannedDate,
        ),
      );

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
      body: _loadingCrawls
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD4AF37),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFFD4AF37),
              backgroundColor:
                  const Color(0xFF1C1C1E),
              onRefresh: _loadCrawls,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  28,
                ),
                children: [
                  if (crawls.isNotEmpty) ...[
                    const Text(
                      'SAVED CRAWLS',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...crawls.map(
                      (crawl) => Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 14,
                        ),
                        child: _savedCrawlCard(crawl),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const Text(
                    'SAVED PLACES',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSavedPlaces(saved),
                ],
              ),
            ),
    );
  }
}
