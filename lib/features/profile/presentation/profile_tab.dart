import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/widgets/bento_card.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name saved.')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Avatar updated.')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
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

    ref.listen(profileControllerProvider(widget.currentUserId), (previous, next) {
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
            onRetry: () => ref.invalidate(
              profileControllerProvider(widget.currentUserId),
            ),
          ),
        );
      }
      return const SafeArea(
        child: Center(child: CircularProgressIndicator()),
      );
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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xxl,
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
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: AnimalAvatar.catalog.length,
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: AppSpacing.md,
                            crossAxisSpacing: AppSpacing.sm,
                            childAspectRatio: 0.82,
                          ),
                      itemBuilder: (context, index) {
                        final avatar = AnimalAvatar.catalog[index];
                        return _AvatarTile(
                          avatar: avatar,
                          selected: avatar.id == selectedAvatarId,
                          onTap: () =>
                              setState(() => _draftAvatarId = avatar.id),
                        );
                      },
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
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
          children: [
            Expanded(
              child: AspectRatio(
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
                      AnimalAvatarView(avatarId: avatar.id, size: 56),
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
