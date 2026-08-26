import 'package:flutter/material.dart';

import '../models/crawl_location_search_result.dart';
import '../services/crawl_location_search_service.dart';
import '../services/nominatim_location_search_provider.dart';

class CrawlLocationSearch extends StatefulWidget {
  final ValueChanged<CrawlLocationSearchResult>
      onLocationSelected;

  const CrawlLocationSearch({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<CrawlLocationSearch> createState() =>
      _CrawlLocationSearchState();
}

class _CrawlLocationSearchState
    extends State<CrawlLocationSearch> {
  final TextEditingController _controller =
      TextEditingController();

  late final CrawlLocationSearchService
      _searchService;

  List<CrawlLocationSearchResult> _results =
      const [];

  bool _isSearching = false;

  String? _error;

  @override
  void initState() {
    super.initState();

    _searchService =
        CrawlLocationSearchService(
      provider:
          const NominatimLocationSearchProvider(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();

    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
      _results = const [];
    });

    try {
      final results =
          await _searchService.search(query);

      if (!mounted) {
        return;
      }

      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSearching = false;
        _error = error.toString();
        _results = const [];
      });
    }
  }

  void _selectLocation(
    CrawlLocationSearchResult result,
  ) {
    widget.onLocationSelected(result);

    FocusScope.of(context).unfocus();

    setState(() {
      _controller.text = result.name;
      _results = const [];
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          style: const TextStyle(
            color: Colors.white,
          ),
          textInputAction:
              TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            hintText:
                'Search for a starting location',
            hintStyle: const TextStyle(
              color: Colors.white38,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xFFD4AF37),
            ),
            suffixIcon: IconButton(
              onPressed:
                  _isSearching ? null : _search,
              icon: const Icon(
                Icons.arrow_forward,
              ),
              color: const Color(0xFFD4AF37),
            ),
            filled: true,
            fillColor:
                const Color(0xFF1C1C1E),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Colors.white10,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFD4AF37),
              ),
            ),
          ),
        ),
        if (_isSearching) ...[
          const SizedBox(height: 14),
          const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFD4AF37),
              ),
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
        ],
        if (!_isSearching &&
            _error == null &&
            _controller.text.trim().isNotEmpty &&
            _results.isEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'No locations found.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ],
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white10,
              ),
            ),
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < _results.length;
                  index++
                )
                  _resultTile(
                    _results[index],
                    isLast:
                        index ==
                            _results.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _resultTile(
    CrawlLocationSearchResult result, {
    required bool isLast,
  }) {
    return InkWell(
      onTap: () {
        _selectLocation(result);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(
                    color: Colors.white10,
                  ),
                ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: Color(0xFFD4AF37),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    result.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (result.address != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      result.address!,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white30,
            ),
          ],
        ),
      ),
    );
  }
}