part of 'detour_screen.dart';

extension _DetourDestinationUi on _DetourScreenState {
  Widget _buildRouteCard() {
    return _buildSectionCard(
      title: 'ROUTE',
      child: Column(
        children: [
          _buildStartingLocation(),
          const SizedBox(height: 14),
          _buildSwapButton(),
          const SizedBox(height: 14),
          _buildDestinationField(),
        ],
      ),
    );
  }

  Widget _buildStartingLocation() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'STARTING LOCATION',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color:
                const Color(0xFF0D0D0F),
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white10,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.my_location,
                color:
                    Color(0xFFD4AF37),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _startingPoint ==
                        null
                    ? const Text(
                        'Choose a starting point',
                        style: TextStyle(
                          color:
                              Colors.white38,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      )
                    : Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            _startingPoint!
                                .name,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          if (_startingPoint!
                                  .address !=
                              null)
                            Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                top: 2,
                              ),
                              child: Text(
                                _startingPoint!
                                    .address!,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              if (_loadingCurrentLocation)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                        Color(0xFFD4AF37),
                  ),
                )
              else
                IconButton(
                  tooltip:
                      'Use current location',
                  onPressed:
                      _useCurrentLocation,
                  icon: const Icon(
                    Icons.gps_fixed,
                    color:
                        Color(0xFFD4AF37),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwapButton() {
    return Align(
      alignment: Alignment.center,
      child: IconButton(
        tooltip: 'Swap locations',
        onPressed:
            _startingPoint == null ||
                    _destination == null
                ? null
                : _swapLocations,
        icon: const Icon(
          Icons.swap_vert,
          color:
              Color(0xFFD4AF37),
        ),
      ),
    );
  }

  Widget _buildDestinationField() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'DESTINATION',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller:
              _destinationController,
          focusNode:
              _destinationFocusNode,
          style: const TextStyle(
            color: Colors.white,
          ),
          decoration:
              InputDecoration(
            hintText:
                'Where are you going?',
            hintStyle:
                const TextStyle(
              color: Colors.white38,
            ),
            prefixIcon:
                const Icon(
              Icons.location_on_outlined,
              color:
                  Color(0xFFD4AF37),
            ),
            suffixIcon:
                _searching
                    ? const Padding(
                        padding:
                            EdgeInsets.all(
                          14,
                        ),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Color(0xFFD4AF37),
                          ),
                        ),
                      )
                    : _destinationController
                            .text
                            .isNotEmpty
                        ? IconButton(
                            onPressed:
                                _clearDestination,
                            icon:
                                const Icon(
                              Icons.close,
                              color:
                                  Colors.white54,
                            ),
                          )
                        : null,
            filled: true,
            fillColor:
                const Color(0xFF0D0D0F),
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Colors.white10,
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Colors.white10,
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Color(0xFFD4AF37),
              ),
            ),
          ),
          onChanged:
              _searchDestination,
          onSubmitted: (_) =>
              _searchDestinationPlaces(
            _destinationController
                .text,
          ),
        ),
        if (_destination != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color:
                  const Color(0xFF0D0D0F),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              border: Border.all(
                color: const Color(
                  0xFFD4AF37,
                ).withValues(
                  alpha: 0.35,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.flag,
                  color:
                      Color(0xFFD4AF37),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        _destination!
                            .name,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      if (_destination!
                              .address !=
                          null)
                        Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            top: 2,
                          ),
                          child: Text(
                            _destination!
                                .address!,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed:
                      _clearDestination,
                  icon: const Icon(
                    Icons.close,
                    color:
                        Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResults() {
    return _buildSectionCard(
      title: 'SEARCH RESULTS',
      child: Column(
        children: [
          for (var index = 0;
              index <
                  _searchResults.length;
              index++) ...[
            _buildSearchResultTile(
              _searchResults[index],
            ),
            if (index !=
                _searchResults.length - 1)
              const Divider(
                color: Colors.white10,
                height: 1,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResultTile(
    CrawlLocationSearchResult result,
  ) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 6,
      ),
      leading: const Icon(
        Icons.location_on_outlined,
        color:
            Color(0xFFD4AF37),
      ),
      title: Text(
        result.name,
        maxLines: 1,
        overflow:
            TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: result.address == null
          ? null
          : Text(
              result.address!,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
              ),
            ),
      onTap: () =>
          _selectSearchResult(
        result,
      ),
    );
  }

  Widget _buildDestinationLists() {
    if (_loadingDestinations) {
      return const SizedBox(
        height: 80,
        child: Center(
          child:
              CircularProgressIndicator(
            color:
                Color(0xFFD4AF37),
          ),
        ),
      );
    }

    final hasRecent =
        recentDetourDestinations
            .isNotEmpty;

    final hasSaved =
        savedDetourDestinations
            .isNotEmpty;

    if (!hasRecent && !hasSaved) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (hasRecent)
          _buildDestinationSection(
            title:
                'RECENT DESTINATIONS',
            destinations:
                recentDetourDestinations,
            showClearRecent: true,
          ),
        if (hasRecent && hasSaved)
          const SizedBox(height: 14),
        if (hasSaved)
          _buildDestinationSection(
            title:
                'SAVED DESTINATIONS',
            destinations:
                savedDetourDestinations,
          ),
      ],
    );
  }

  Widget _buildDestinationSection({
    required String title,
    required List<DetourEndpoint>
        destinations,
    bool showClearRecent = false,
  }) {
    return _buildSectionCard(
      title: title,
      trailing: showClearRecent
          ? TextButton(
              onPressed:
                  _clearRecentDestinations,
              style:
                  TextButton.styleFrom(
                foregroundColor:
                    Colors.white54,
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                minimumSize:
                    Size.zero,
                tapTargetSize:
                    MaterialTapTargetSize
                        .shrinkWrap,
              ),
              child: const Text(
                'CLEAR RECENT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            )
          : null,
      child: Column(
        children: [
          for (var index = 0;
              index <
                  destinations.length;
              index++) ...[
            _buildDestinationTile(
              destinations[index],
            ),
            if (index !=
                destinations.length - 1)
              const Divider(
                color: Colors.white10,
                height: 1,
              ),
          ],
        ],
      ),
    );
  }

  Future<void>
      _clearRecentDestinations() async {
    await clearRecentDetourDestinations();

    if (!mounted) {
      return;
    }

    _updateState(() {});
  }

  Widget _buildDestinationTile(
    DetourEndpoint destination,
  ) {
    final saved =
        isSavedDetourDestination(
      destination,
    );

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 3,
      ),
      leading: Icon(
        saved
            ? Icons.bookmark
            : Icons.history,
        color:
            const Color(0xFFD4AF37),
      ),
      title: Text(
        destination.name,
        maxLines: 1,
        overflow:
            TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle:
          destination.address == null
              ? null
              : Text(
                  destination.address!,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white38,
                    fontSize: 12,
                  ),
                ),
      trailing: IconButton(
        tooltip: saved
            ? 'Remove saved destination'
            : 'Save destination',
        onPressed: () =>
            _toggleSavedDestination(
          destination,
        ),
        icon: Icon(
          saved
              ? Icons.bookmark
              : Icons.bookmark_border,
          color:
              const Color(0xFFD4AF37),
        ),
      ),
      onTap: () =>
          _selectDestination(
        destination,
      ),
    );
  }
}