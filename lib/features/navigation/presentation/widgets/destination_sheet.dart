import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/config/mapbox_config.dart';
import '../../../../core/utils/time_format.dart';
import '../../../circle/domain/circle_member.dart';
import '../../../location/application/telemetry_providers.dart';
import '../../application/navigation_providers.dart';
import '../../domain/navigation_failure.dart';
import '../../domain/place_suggestion.dart';
import '../destination_picker_screen.dart';

Future<void> showDestinationSheet(
  BuildContext context, {
  required String circleId,
  required String currentUserId,
  required List<CircleMember> members,
  required ValueChanged<CircleMember> onMemberTap,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DestinationSheet(
      circleId: circleId,
      currentUserId: currentUserId,
      members: members,
      onMemberTap: onMemberTap,
    ),
  );
}

/// Picks the one place the circle is heading to, or ends the current trip.
class DestinationSheet extends ConsumerStatefulWidget {
  const DestinationSheet({
    super.key,
    required this.circleId,
    required this.currentUserId,
    required this.members,
    required this.onMemberTap,
  });

  final String circleId;
  final String currentUserId;
  final List<CircleMember> members;
  final ValueChanged<CircleMember> onMemberTap;

  @override
  ConsumerState<DestinationSheet> createState() => _DestinationSheetState();
}

class _DestinationSheetState extends ConsumerState<DestinationSheet> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<PlaceSuggestion> _results = const [];
  bool _searching = false;
  bool _saving = false;
  String? _error;
  int _searchRun = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final clean = value.trim();
    if (clean.length < 2) {
      _searchRun++;
      setState(() {
        _results = const [];
        _searching = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
    });
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _search(clean),
    );
  }

  Future<void> _search(String query) async {
    final run = ++_searchRun;
    final gateway = ref.read(navigationGatewayProvider);
    final reading =
        ref.read(telemetryControllerProvider(widget.currentUserId)).lastReading;

    try {
      final results = await gateway.searchPlaces(
        query,
        proximity: reading?.point,
      );
      if (!mounted || run != _searchRun) return;
      setState(() {
        _results = results;
        _searching = false;
        _error = results.isEmpty ? 'No places matched that search.' : null;
      });
    } on NavigationFailure catch (failure) {
      if (!mounted || run != _searchRun) return;
      setState(() {
        _searching = false;
        _results = const [];
        _error = failure.message;
      });
    }
  }

  Future<void> _choose(PlaceSuggestion place) async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(navigationRepositoryProvider(widget.circleId)).setDestination(
            label: place.label,
            latitude: place.latitude,
            longitude: place.longitude,
            setBy: widget.currentUserId,
          );
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Everyone is heading to ${place.label}.')),
      );
    } on NavigationFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _chooseOnMap() async {
    final picked = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => DestinationPickerScreen(
          circleId: widget.circleId,
          currentUserId: widget.currentUserId,
          members: widget.members,
          onMemberTap: widget.onMemberTap,
        ),
      ),
    );
    if (!mounted || picked != true) return;
    Navigator.of(context).pop();
  }

  Future<void> _endNavigation() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(navigationRepositoryProvider(widget.circleId))
          .clearDestination();
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Navigation ended.')));
    } on NavigationFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final navigation = ref.watch(navigationControllerProvider(widget.circleId));
    final destination = navigation.destination;
    final myRoute = navigation.routeFor(widget.currentUserId);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Group destination', style: theme.textTheme.titleLarge),
            const SizedBox(height: 3),
            Text(
              destination == null
                  ? 'Pick one place and everyone routes to it together.'
                  : 'The whole circle routes to the same place.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (destination != null) ...[
              const SizedBox(height: 16),
              _ActiveDestination(
                label: destination.label,
                latitude: destination.latitude,
                longitude: destination.longitude,
                etaLabel: myRoute == null
                    ? null
                    : '${formatRouteEta(myRoute.plan.duration)} · '
                        '${formatRouteDistance(myRoute.plan.distanceMeters)}',
                onEnd: _saving ? null : _endNavigation,
              ),
            ],
            const SizedBox(height: 16),
            if (!MapboxConfig.isConfigured)
              const _MapboxSetupHint()
            else ...[
              TextField(
                controller: _query,
                enabled: !_saving,
                textInputAction: TextInputAction.search,
                textCapitalization: TextCapitalization.words,
                onChanged: _onQueryChanged,
                decoration: InputDecoration(
                  hintText: destination == null
                      ? 'Search for a place'
                      : 'Change destination',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _chooseOnMap,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Choose on map'),
                ),
              ),
              if (_results.isNotEmpty) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final place = _results[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.place_outlined,
                          size: 20,
                          color: scheme.primary,
                        ),
                        title: Text(
                          place.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        onTap: _saving ? null : () => _choose(place),
                      );
                    },
                  ),
                ),
              ],
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _ActiveDestination extends StatelessWidget {
  const _ActiveDestination({
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.etaLabel,
    required this.onEnd,
  });

  final String label;
  final double latitude;
  final double longitude;
  final String? etaLabel;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_rounded, size: 20, color: scheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  etaLabel ?? 'Waiting for your route',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: onEnd,
            child: Text(
              'End',
              style: TextStyle(color: scheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapboxSetupHint extends StatelessWidget {
  const _MapboxSetupHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.key_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text('Routing needs a Mapbox token', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add your public pk. token to mapbox.env.json, then start the app '
            'with --dart-define-from-file=mapbox.env.json. You will still see '
            'destinations the crew shares.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
