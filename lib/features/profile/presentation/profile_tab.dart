import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/navigation/glass_dock.dart';
import '../../../app/theme/app_palettes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/theme_providers.dart';
import '../../../app/widgets/bento_card.dart';
import '../../../app/widgets/content_frame.dart';
import '../../auth/application/auth_providers.dart';
import '../application/profile_providers.dart';
import '../domain/animal_avatar.dart';
import '../domain/profile_details.dart';
import 'widgets/animal_avatar_view.dart';

/// The member's identity: what the circle calls them, the animal that marks
/// them on the map, and the account controls.
class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key, required this.currentUserId});

  final String currentUserId;

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  late final TextEditingController _nameController;
  late final FocusNode _nameFocus;

  String? _draftAvatarId;
  String? _nameError;
  bool _savingName = false;
  bool _savingAvatar = false;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nameFocus = FocusNode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _saveName(ProfileDetails profile) async {
    final name = _nameController.text.trim();
    setState(() {
      _savingName = true;
      _nameError = null;
    });

    final error = await ref
        .read(profileControllerProvider(widget.currentUserId).notifier)
        .updateDisplayName(name);

    if (!mounted) return;
    setState(() {
      _savingName = false;
      _nameError = error;
    });
    if (error == null) {
      _nameController.text = name;
      _nameFocus.unfocus();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name saved.')));
    }
  }

  Future<void> _saveAvatar(String avatarId) async {
    setState(() => _savingAvatar = true);
    final error = await ref
        .read(profileControllerProvider(widget.currentUserId).notifier)
        .updateAvatar(avatarId);
    if (!mounted) return;
    setState(() => _savingAvatar = false);
    if (error == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Avatar updated.')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your circle will still see your last shared location for a few '
          'minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final profileAsync = ref.watch(
      profileControllerProvider(widget.currentUserId),
    );
    final email = ref.watch(authSessionProvider).value?.email;

    ref.listen(profileControllerProvider(widget.currentUserId), (
      previous,
      next,
    ) {
      final profile = next.value;
      if (profile == null) return;
      final previousProfile = previous?.value;
      final avatarChanged =
          previousProfile == null ||
          previousProfile.avatarId != profile.avatarId;
      if (avatarChanged && _draftAvatarId == previousProfile?.avatarId) {
        _draftAvatarId = profile.avatarId;
      }
      if (!_nameFocus.hasFocus &&
          (previousProfile == null ||
              previousProfile.displayName != profile.displayName)) {
        _nameController.text = profile.displayName;
      }
      setState(() {});
    });

    final profile = profileAsync.value;
    if (profile == null) {
      if (profileAsync.hasError) {
        return SafeArea(
          child: _ProfileError(
            onRetry: () =>
                ref.invalidate(profileControllerProvider(widget.currentUserId)),
          ),
        );
      }
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    if (!_hydrated) {
      _hydrated = true;
      _nameController.text = profile.displayName;
      _draftAvatarId = profile.avatarId;
    }

    final selectedAvatarId = _draftAvatarId ?? profile.avatarId;
    final trimmedName = _nameController.text.trim();
    final nameDirty = trimmedName != profile.displayName;
    final canSaveName =
        !_savingName &&
        nameDirty &&
        trimmedName.isNotEmpty &&
        trimmedName.length <= maxDisplayNameLength;
    final avatarDirty = selectedAvatarId != profile.avatarId;

    return SafeArea(
      bottom: false,
      child: ContentFrame(
        maxWidth: ContentWidths.profile,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xxl + ShellDock.contentInset(context),
          ),
          children: [
            Row(
              children: [
                Container(
                  width: 86,
                  height: 86,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surfaceContainerLowest,
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.16),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: AnimalAvatarView(
                    avatarId: selectedAvatarId,
                    size: 80,
                    fallbackInitials: profile.displayName.isEmpty
                        ? '?'
                        : profile.displayName.substring(0, 1).toUpperCase(),
                    animate: true, // Animate header avatar
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your profile',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AnimalAvatar.byId(selectedAvatarId).name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionLabel(
              title: 'Display name',
              helper: 'Your circle sees this everywhere.',
            ),
            const SizedBox(height: AppSpacing.sm),
            BentoCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const ValueKey('profile-name-field'),
                    controller: _nameController,
                    focusNode: _nameFocus,
                    maxLength: maxDisplayNameLength,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() => _nameError = null),
                    onSubmitted: (_) {
                      if (canSaveName) _saveName(profile);
                    },
                    decoration: InputDecoration(
                      hintText: 'How should the crew call you?',
                      errorText: _nameError,
                      counterText:
                          '${_nameController.text.characters.length}/'
                          '$maxDisplayNameLength',
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      key: const ValueKey('profile-name-save'),
                      onPressed: canSaveName ? () => _saveName(profile) : null,
                      child: _savingName
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save name'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionLabel(
              title: 'Choose your animal',
              helper: 'This portrait marks you on the live map.',
            ),
            const SizedBox(height: AppSpacing.sm),
            BentoCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 620 ? 5 : 4;
                      final tileWidth =
                          (constraints.maxWidth -
                              AppSpacing.sm * (columns - 1)) /
                          columns;
                      return Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.md,
                        children: [
                          for (final avatar in AnimalAvatar.catalog)
                            SizedBox(
                              width: tileWidth,
                              child: _AvatarTile(
                                avatar: avatar,
                                selected: avatar.id == selectedAvatarId,
                                onTap: () =>
                                    setState(() => _draftAvatarId = avatar.id),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      key: const ValueKey('profile-avatar-save'),
                      onPressed: avatarDirty && !_savingAvatar
                          ? () => _saveAvatar(selectedAvatarId)
                          : null,
                      icon: _savingAvatar
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Save avatar'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionLabel(
              title: 'Appearance',
              helper: 'Pick a theme that fits your style.',
            ),
            const SizedBox(height: AppSpacing.sm),
            const _ThemePickerCompact(),
            const SizedBox(height: AppSpacing.xl),
            _SectionLabel(title: 'Account'),
            const SizedBox(height: AppSpacing.sm),
            BentoCard(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email',
                    value: email ?? 'Signed in',
                  ),
                  Divider(
                    height: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  _DetailRow(
                    icon: Icons.eco_outlined,
                    label: 'Pathfinder since',
                    value: DateFormat.yMMMM().format(profile.createdAt),
                  ),
                  Divider(
                    height: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: scheme.error,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Sign out of this device',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        TextButton(
                          key: const ValueKey('profile-sign-out'),
                          onPressed: _signOut,
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemePickerCompact extends ConsumerWidget {
  const _ThemePickerCompact();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(appThemeProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BentoCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppPalettes.all.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final palette = AppPalettes.all[index];
                return _ThemeTileCompact(
                  palette: palette,
                  selected: palette.id == selected,
                  onTap: () =>
                      ref.read(appThemeProvider.notifier).select(palette.id),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showFullThemePicker(context, ref),
              icon: Icon(
                Icons.palette_outlined,
                size: 16,
                color: scheme.primary,
              ),
              label: const Text('View all themes'),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullThemePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) =>
            _ThemePickerSheet(scrollController: scrollController),
      ),
    );
  }
}

class _ThemePickerSheet extends ConsumerWidget {
  const _ThemePickerSheet({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(appThemeProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                'Choose your theme',
                style: theme.textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 620 ? 3 : 2;
                  final tileWidth =
                      (constraints.maxWidth - AppSpacing.md * (columns - 1)) /
                      columns;
                  final tileHeight = tileWidth * 1.1;
                  return GridView.builder(
                    controller: scrollController,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: tileWidth / tileHeight,
                    ),
                    itemCount: AppPalettes.all.length,
                    itemBuilder: (context, index) {
                      final palette = AppPalettes.all[index];
                      return _ThemeTileFullPreview(
                        palette: palette,
                        selected: palette.id == selected,
                        onTap: () {
                          ref
                              .read(appThemeProvider.notifier)
                              .select(palette.id);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeTileCompact extends StatelessWidget {
  const _ThemeTileCompact({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentScheme = theme.colorScheme;

    // Use the theme's light scheme for the preview
    final previewScheme = palette.light;

    return Semantics(
      button: true,
      selected: selected,
      label: '${palette.id.label} theme',
      child: InkWell(
        key: ValueKey('theme-${palette.id.name}'),
        borderRadius: BorderRadius.circular(AppRadius.tile),
        onTap: onTap,
        child: Container(
          width: 85,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.tile),
            border: Border.all(
              color: selected
                  ? currentScheme.primary
                  : currentScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mini UI Preview
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.tile - 1),
                  ),
                  child: _MiniUIPreview(scheme: previewScheme),
                ),
              ),
              // Theme name and check
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? currentScheme.primaryContainer
                      : currentScheme.surfaceContainerHigh,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppRadius.tile - 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        palette.id.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? currentScheme.onPrimaryContainer
                              : currentScheme.onSurface,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: currentScheme.primary,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeTileFullPreview extends StatelessWidget {
  const _ThemeTileFullPreview({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentScheme = theme.colorScheme;

    // Use the theme's light scheme for the preview
    final previewScheme = palette.light;

    return Semantics(
      button: true,
      selected: selected,
      label: '${palette.id.label} theme',
      child: InkWell(
        key: ValueKey('theme-full-${palette.id.name}'),
        borderRadius: BorderRadius.circular(AppRadius.tile),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.tile),
            border: Border.all(
              color: selected
                  ? currentScheme.primary
                  : currentScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Check in top-right corner
              Expanded(
                child: Stack(
                  children: [
                    // Mini UI Preview
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.tile - 1),
                      ),
                      child: SizedBox.expand(
                        child: _MiniUIPreview(scheme: previewScheme),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentScheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: currentScheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Theme name and tagline
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? currentScheme.primaryContainer
                      : currentScheme.surfaceContainerHigh,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppRadius.tile - 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      palette.id.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? currentScheme.onPrimaryContainer
                            : currentScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      palette.id.tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: selected
                            ? currentScheme.onPrimaryContainer.withValues(
                                alpha: 0.75,
                              )
                            : currentScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A mini UI mockup showing what the theme looks like with actual surfaces,
/// chat bubbles, and text elements.
class _MiniUIPreview extends StatelessWidget {
  const _MiniUIPreview({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top bar placeholder
          Container(
            height: 8,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Incoming message bubble (surface card)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 50),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 20,
                          height: 2,
                          decoration: BoxDecoration(
                            color: scheme.onSurface.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Outgoing message bubble (primary)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 45),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 25,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: scheme.onPrimary.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 18,
                          height: 2,
                          decoration: BoxDecoration(
                            color: scheme.onPrimary.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom bar / composer placeholder
          const SizedBox(height: 4),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const SizedBox(width: 3),
                Expanded(
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, this.helper});

  final String title;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        if (helper != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              helper!,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.avatar,
    required this.selected,
    required this.onTap,
  });

  final AnimalAvatar avatar;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      key: ValueKey('avatar-${avatar.id}'),
      borderRadius: BorderRadius.circular(AppRadius.tile),
      onTap: onTap,
      child: Semantics(
        selected: selected,
        button: true,
        label: avatar.name,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? scheme.primaryContainer
                      : Colors.transparent,
                  border: Border.all(
                    color: selected ? scheme.primary : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimalAvatarView(
                      avatarId: avatar.id,
                      animate: selected, // Animate only selected tile
                    ),
                    if (selected)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primary,
                            border: Border.all(
                              color: scheme.surfaceContainerLowest,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 11,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              avatar.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9.5,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  key: ValueKey('profile-detail-$label'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_off_outlined, size: 34),
          const SizedBox(height: AppSpacing.md),
          const Text('Could not open your profile.'),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
