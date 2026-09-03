part of 'detour_screen.dart';

extension _DetourStopsAndTrackingUi on _DetourScreenState {
  Widget _buildDetourStops() {
    final stopCount =
        _preferences.maximumStops.clamp(1, 5);

    if (_editingRoute) {
      return _buildEditingStops(stopCount);
    }

    final stops = _optimizedStops;

    return _buildSectionCard(
      title: 'OPTIMIZED STOPS',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${stops.length}/$stopCount',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed:
                _planning ? null : _startEditingRoute,
            style: TextButton.styleFrom(
              foregroundColor:
                  const Color(0xFFD4AF37),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              minimumSize: Size.zero,
              tapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'EDIT ROUTE',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0;
              index < stops.length;
              index++) ...[
            _buildDetourStopTile(
              stops[index],
              index + 1,
            ),
            if (index != stops.length - 1)
              const Divider(
                color: Colors.white10,
                height: 1,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditingStops(int stopCount) {
    return _buildSectionCard(
      title: 'EDIT ROUTE',
      trailing: Text(
        '${_editingStops.length}/$stopCount',
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      child: Column(
        children: [
          if (_editingStops.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _editingStops.length,
              onReorderItem: _reorderEditingStops,
              itemBuilder: (context, index) {
                final stop = _editingStops[index];

                return _buildEditableStopTile(
                  stop,
                  index,
                  key: ValueKey(
                    'detour-edit-${stop.placeId}',
                  ),
                );
              },
            ),
          if (_editingStops.isNotEmpty)
            const Divider(
              color: Colors.white10,
              height: 1,
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  _planning ||
                          _editingStops.length >= stopCount
                      ? null
                      : _showAddStopDialog,
              icon: const Icon(Icons.add),
              label: Text(
                _editingStops.length >= stopCount
                    ? 'MAXIMUM STOPS REACHED'
                    : 'ADD STOP',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(0xFFD4AF37),
                side: const BorderSide(
                  color: Color(0xFFD4AF37),
                ),
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(
            color: Colors.white10,
            height: 1,
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Drag stops to choose your own order.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _planning
                          ? null
                          : _cancelEditingRoute,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(
                      color: Colors.white24,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed:
                      _planning
                          ? null
                          : _rebuildEditedRoute,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFD4AF37),
                    foregroundColor:
                        const Color(0xFF0D0D0F),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                  child: _planning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Color(0xFF0D0D0F),
                          ),
                        )
                      : const Text(
                          'REBUILD ROUTE',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableStopTile(
    DetourVenue candidate,
    int index, {
    required Key key,
  }) {
    final rating = candidate.diningUnhingedRating;

    final ratingText =
        rating?.toStringAsFixed(1);

    return ListTile(
      key: key,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 6,
      ),
      leading: ReorderableDragStartListener(
        index: index,
        child: const Icon(
          Icons.drag_handle,
          color: Colors.white38,
        ),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor:
                const Color(0xFF0D0D0F),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              candidate.name,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      subtitle: ratingText == null
          ? null
          : Padding(
              padding:
                  const EdgeInsets.only(left: 42),
              child: Text(
                'Dining Unhinged rating: '
                '$ratingText',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ),
      trailing: IconButton(
        tooltip: 'Remove stop',
        onPressed: _planning
            ? null
            : () => _removeEditingStop(index),
        icon: const Icon(
          Icons.close,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _buildDetourStopTile(
    DetourVenue candidate,
    int stopNumber,
  ) {
    final rating =
        candidate.diningUnhingedRating;

    final ratingText =
        rating?.toStringAsFixed(1);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 6,
      ),
      leading: CircleAvatar(
        backgroundColor:
            const Color(0xFF0D0D0F),
        child: Text(
          '$stopNumber',
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      title: Text(
        candidate.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: ratingText == null
          ? null
          : Text(
              'Dining Unhinged rating: '
              '$ratingText',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
      trailing: const Icon(
        Icons.alt_route,
        color: Color(0xFFD4AF37),
      ),
    );
  }

  Widget _buildDetourTrackingActions() {
    return _buildSectionCard(
      title: _detourCompleted
          ? 'DETOUR COMPLETE'
          : _detourActive
              ? 'DETOUR ACTIVE'
              : 'START THIS DETOUR',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          if (_detourActive) ...[
            Row(
              children: [
                const Icon(
                  Icons.navigation,
                  color: Color(0xFFD4AF37),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _nextDetourTargetLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (_distanceToNextStopMeters !=
                    null)
                  Text(
                    _formatTrackingDistance(
                      _distanceToNextStopMeters!,
                    ),
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _detourPosition == null
                  ? 'Waiting for GPS position...'
                  : 'Live location tracking is active.',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _stopDetour,
                icon: const Icon(Icons.stop),
                label: const Text(
                  'STOP DETOUR',
                ),
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      Colors.white70,
                  side: const BorderSide(
                    color: Colors.white24,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _planning
                        ? null
                        : _startDetour,
                icon: const Icon(
                  Icons.navigation,
                ),
                label: const Text(
                  'START DETOUR',
                ),
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFD4AF37),
                  foregroundColor:
                      const Color(0xFF0D0D0F),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanButton() {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed:
            _planning
                ? null
                : _planDetour,
        style:
            FilledButton.styleFrom(
          backgroundColor:
              const Color(0xFFD4AF37),
          foregroundColor:
              const Color(0xFF0D0D0F),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
        icon: _planning
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(
                    0xFF0D0D0F,
                  ),
                ),
              )
            : const Icon(
                Icons.alt_route,
              ),
        label: Text(
          _planning
              ? 'CALCULATING ROUTE...'
              : 'PLAN MY DETOUR',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color:
                        Color(0xFFD4AF37),
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}