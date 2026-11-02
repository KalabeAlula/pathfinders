import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../chat/presentation/widgets/chat_badge_button.dart';
import '../../application/map_search_providers.dart';
import '../../domain/place_suggestion.dart';
import '../venue_selection.dart';

/// Google-Maps-style search pill for the destination picker.
///
/// The list under the pill is driven by [MapSearchController], which debounces
/// typing for 300 ms and biases results toward the member's GPS fix.
class MapSearchBar extends ConsumerStatefulWidget {
  const MapSearchBar({
    super.key,
    required this.userId,
    required this.unreadCount,
    required this.onChat,
    required this.onPlaceSelected,
  });

  final String userId;
  final int unreadCount;
  final VoidCallback onChat;
  final ValueChanged<PlaceSuggestion> onPlaceSelected;

  @override
  ConsumerState<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends ConsumerState<MapSearchBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    if (!_focus.hasFocus) {
      ref.read(mapSearchControllerProvider(widget.userId).notifier).dismiss();
    }
    setState(() {});
  }

  void _choose(PlaceSuggestion place) {
    _focus.unfocus();
    ref.read(mapSearchControllerProvider(widget.userId).notifier).dismiss();
    _controller.text = place.displayName;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    widget.onPlaceSelected(place);
  }

  void _clear() {
    _controller.clear();
    ref.read(mapSearchControllerProvider(widget.userId).notifier).reset();
    _focus.requestFocus();
  }

  void _submit(String value) {
    final state = ref.read(mapSearchControllerProvider(widget.userId));
    if (state.hasResults) {
      _choose(state.results.first);
      return;
    }
    ref.read(mapSearchControllerProvider(widget.userId).notifier).search(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final search = ref.watch(mapSearchControllerProvider(widget.userId));
    final showList = _focus.hasFocus && search.isActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: scheme.surfaceContainerLowest.withValues(alpha: 0.97),
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    textInputAction: TextInputAction.search,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (value) => ref
                        .read(
                          mapSearchControllerProvider(widget.userId).notifier,
                        )
                        .search(value),
                    onSubmitted: _submit,
                    decoration: InputDecoration.collapsed(
                      hintText: 'Search places or addresses',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (search.query.isNotEmpty)
                  IconButton(
                    onPressed: _clear,
                    tooltip: 'Clear search',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  )
                else
                  const SizedBox(width: 4),
                Container(width: 1, height: 24, color: scheme.outlineVariant),
                ChatBadgeButton(
                  unreadCount: widget.unreadCount,
                  onTap: widget.onChat,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
        if (showList) ...[
          const SizedBox(height: AppSpacing.sm),
          _SuggestionsCard(state: search, onSelected: _choose),
        ],
      ],
    );
  }
}

class _SuggestionsCard extends StatelessWidget {
  const _SuggestionsCard({required this.state, required this.onSelected});

  final MapSearchState state;
  final ValueChanged<PlaceSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest.withValues(alpha: 0.98),
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.24),
      borderRadius: BorderRadius.circular(AppRadius.tile),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 310),
        child: state.loading
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Searching nearby…'),
                  ],
                ),
              )
            : state.results.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.error ?? 'No places matched that search.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: state.results.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
                itemBuilder: (context, index) {
                  final place = state.results[index];
                  return _SuggestionTile(
                    place: place,
                    onTap: () => onSelected(place),
                  );
                },
              ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.place, required this.onTap});

  final PlaceSuggestion place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final address = place.address;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                venueIcon(category: place.category, maki: place.maki),
                size: 18,
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (address != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (place.categoryLabel != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  place.categoryLabel!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
