part of 'detour_screen.dart';

extension _DetourPreferencesUi on _DetourScreenState {
  Widget _buildPreferencesCard() {
    return _buildSectionCard(
      title: 'TRIP PREFERENCES',
      trailing: IconButton(
        onPressed: () {
          _updateState(() {
            _showPreferences = !_showPreferences;
          });
        },
        icon: Icon(
          _showPreferences
              ? Icons.expand_less
              : Icons.expand_more,
          color: const Color(0xFFD4AF37),
        ),
      ),
      child: Column(
        children: [
          _buildPreferenceSummary(),
          if (_showPreferences) ...[
            const SizedBox(height: 18),
            _buildPreferenceControls(),
          ],
        ],
      ),
    );
  }

  Widget _buildPreferenceSummary() {
    return Row(
      children: [
        Expanded(
          child: _preferenceSummaryItem(
            Icons.alt_route,
            '${_preferences.maximumDetourKm.toStringAsFixed(0)} km',
            'MAX DETOUR',
          ),
        ),
        Expanded(
          child: _preferenceSummaryItem(
            Icons.star_outline,
            _preferences.minimumRating.toStringAsFixed(1),
            'MIN RATING',
          ),
        ),
        Expanded(
          child: _preferenceSummaryItem(
            Icons.pin_drop_outlined,
            '${_preferences.maximumStops}',
            'MAX STOPS',
          ),
        ),
      ],
    );
  }

  Widget _preferenceSummaryItem(
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
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
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

  Widget _buildPreferenceControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MAXIMUM ACCEPTABLE DETOUR',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        Slider(
          value: _preferences.maximumDetourKm.clamp(1, 100),
          min: 1,
          max: 100,
          divisions: 99,
          activeColor: const Color(0xFFD4AF37),
          inactiveColor: Colors.white12,
          label:
              '${_preferences.maximumDetourKm.toStringAsFixed(0)} km',
          onChanged: (value) {
            _updatePreferences(
              _preferences.copyWith(
                maximumDetourKm: value,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        const Text(
          'MINIMUM DINING UNHINGED RATING',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        Slider(
          value: _preferences.minimumRating.clamp(0, 5),
          min: 0,
          max: 5,
          divisions: 10,
          activeColor: const Color(0xFFD4AF37),
          inactiveColor: Colors.white12,
          label: _preferences.minimumRating.toStringAsFixed(1),
          onChanged: (value) {
            _updatePreferences(
              _preferences.copyWith(
                minimumRating: value,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        const Text(
          'MAXIMUM NUMBER OF STOPS',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        DropdownButtonFormField<int>(
          initialValue: _preferences.maximumStops,
          dropdownColor: const Color(0xFF1C1C1E),
          style: const TextStyle(
            color: Colors.white,
          ),
          decoration: _preferenceInputDecoration(),
          items: const [
            DropdownMenuItem(
              value: 1,
              child: Text('1 stop'),
            ),
            DropdownMenuItem(
              value: 2,
              child: Text('2 stops'),
            ),
            DropdownMenuItem(
              value: 3,
              child: Text('3 stops'),
            ),
            DropdownMenuItem(
              value: 4,
              child: Text('4 stops'),
            ),
            DropdownMenuItem(
              value: 5,
              child: Text('5 stops'),
            ),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }

            _updatePreferences(
              _preferences.copyWith(
                maximumStops: value,
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        _buildSwitchTile(
          title: 'Open now only',
          subtitle: 'Only consider venues currently open.',
          value: _preferences.openNowOnly,
          onChanged: (value) {
            _updatePreferences(
              _preferences.copyWith(
                openNowOnly: value,
              ),
            );
          },
        ),
        _buildSwitchTile(
          title: 'Avoid visited or saved',
          subtitle:
              'Skip places you have already saved or visited.',
          value: _preferences.avoidVisitedOrSaved,
          onChanged: (value) {
            _updatePreferences(
              _preferences.copyWith(
                avoidVisitedOrSaved: value,
              ),
            );
          },
        ),
        _buildSwitchTile(
          title: 'Allow overnight stops',
          subtitle:
              'Allow the future route planner to consider overnight stops.',
          value: _preferences.allowOvernightStops,
          onChanged: (value) {
            _updatePreferences(
              _preferences.copyWith(
                allowOvernightStops: value,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        const Text(
          'ROUTE PREFERENCE',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<DetourRoutePreference>(
          segments: const [
            ButtonSegment(
              value: DetourRoutePreference.flexible,
              label: Text('Flexible'),
              icon: Icon(
                Icons.alt_route,
              ),
            ),
            ButtonSegment(
              value: DetourRoutePreference.strict,
              label: Text('Strict'),
              icon: Icon(
                Icons.route,
              ),
            ),
          ],
          selected: {
            _preferences.routePreference,
          },
          onSelectionChanged: (selection) {
            _updatePreferences(
              _preferences.copyWith(
                routePreference: selection.first,
              ),
            );
          },
          style: ButtonStyle(
            foregroundColor:
                WidgetStateProperty.resolveWith(
              (states) {
                if (states.contains(
                  WidgetState.selected,
                )) {
                  return const Color(0xFF0D0D0F);
                }

                return Colors.white70;
              },
            ),
            backgroundColor:
                WidgetStateProperty.resolveWith(
              (states) {
                if (states.contains(
                  WidgetState.selected,
                )) {
                  return const Color(0xFFD4AF37);
                }

                return const Color(0xFF0D0D0F);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'PREFERRED CATEGORIES',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        _buildCategorySelector(),
      ],
    );
  }

  Widget _buildCategorySelector() {
    const categories = [
      'Restaurant',
      'Brewery',
      'Bar',
      'Cocktail',
      'Distillery',
      'Café',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map(
        (category) {
          final selected = _preferences.preferredCategories.contains(
            category,
          );

          return FilterChip(
            label: Text(category),
            selected: selected,
            onSelected: (value) {
              final updated = Set<String>.from(
                _preferences.preferredCategories,
              );

              if (value) {
                updated.add(category);
              } else {
                updated.remove(category);
              }

              _updatePreferences(
                _preferences.copyWith(
                  preferredCategories: updated,
                ),
              );
            },
            selectedColor: const Color(0xFFD4AF37),
            checkmarkColor: const Color(0xFF0D0D0F),
            backgroundColor: const Color(0xFF0D0D0F),
            side: const BorderSide(
              color: Colors.white10,
            ),
            labelStyle: TextStyle(
              color: selected
                  ? const Color(0xFF0D0D0F)
                  : Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
        ),
      ),
      value: value,
      activeThumbColor: const Color(0xFF0D0D0F),
      activeTrackColor: const Color(0xFFD4AF37),
      inactiveThumbColor: Colors.white54,
      inactiveTrackColor: Colors.white12,
      onChanged: onChanged,
    );
  }

  InputDecoration _preferenceInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF0D0D0F),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.white10,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.white10,
        ),
      ),
    );
  }
}