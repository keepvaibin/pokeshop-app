import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_input.dart';
import '../../../../core/widgets/pokemon_avatar.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../shop/data/shop_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _savingIcon = false;
  bool _linkingDiscord = false;
  bool _unlinkingDiscord = false;
  bool _discordLinkStarted = false;
  late final _ProfileSettingsLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = _ProfileSettingsLifecycleObserver(
      onResumed: () {
        if (!_discordLinkStarted) return;
        ref.read(authControllerProvider.notifier).refreshUser();
        _discordLinkStarted = false;
      },
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final settings = ref.watch(storeSettingsProvider);
    final icons = ref.watch(pokemonIconsProvider);
    final user = auth.user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_firstNameController.text.isEmpty) {
      _firstNameController.text = user.firstName;
    }
    if (_lastNameController.text.isEmpty) {
      _lastNameController.text = user.lastName;
    }
    if (_nicknameController.text.isEmpty) {
      _nicknameController.text = user.nickname;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PokemonAvatar(
                      filename: user.pokemonIcon,
                      fallbackText: user.displayName,
                      size: 64,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.displayName,
                              style: AppTextStyles.heading(size: 20)),
                          const SizedBox(height: 4),
                          Text(user.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body(size: 12)),
                          const SizedBox(height: 4),
                          Text(
                              user.isAdmin
                                  ? 'Admin account'
                                  : 'Customer account',
                              style: AppTextStyles.label(
                                  color: user.isAdmin
                                      ? AppColors.pkmnBlue
                                      : AppColors.pkmnGrayDark)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (user.strikeCount > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                      '${user.strikeCount} strike${user.strikeCount == 1 ? '' : 's'} on account',
                      style: AppTextStyles.body(color: AppColors.pkmnRed)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          PkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile Picture', style: AppTextStyles.heading(size: 18)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    PokemonAvatar(
                      filename: user.pokemonIcon,
                      fallbackText: user.displayName,
                      size: 72,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        user.pokemonIcon == null
                            ? 'No profile picture selected.'
                            : 'This icon appears on My SCTCG, receipts, and admin customer views.',
                        style: AppTextStyles.body(size: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    PkButton(
                      label: user.pokemonIcon == null ? 'Add' : 'Change',
                      icon: const Icon(Icons.image_search_outlined),
                      loading: _savingIcon,
                      onPressed: _savingIcon
                          ? null
                          : () => _openPokemonPicker(icons, user.pokemonIcon),
                    ),
                    if (user.pokemonIcon != null)
                      PkButton(
                        label: 'Remove',
                        icon: const Icon(Icons.close),
                        variant: PkButtonVariant.secondary,
                        loading: _savingIcon,
                        onPressed:
                            _savingIcon ? null : () => _updatePokemonIcon(null),
                      ),
                  ],
                ),
                icons.when(
                  loading: () => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text('Loading available images...',
                        style: AppTextStyles.body(size: 12)),
                  ),
                  error: (error, stackTrace) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text('Profile images are unavailable right now.',
                        style: AppTextStyles.body(color: AppColors.pkmnRed)),
                  ),
                  data: (_) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Profile Details', style: AppTextStyles.heading(size: 18)),
                const SizedBox(height: 12),
                PkInput(controller: _firstNameController, label: 'First Name'),
                const SizedBox(height: 10),
                PkInput(controller: _lastNameController, label: 'Last Name'),
                const SizedBox(height: 10),
                PkInput(controller: _nicknameController, label: 'Nickname'),
                const SizedBox(height: 12),
                PkButton(
                  label: 'Save Profile',
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).updateProfile({
                    'first_name': _firstNameController.text,
                    'last_name': _lastNameController.text,
                    'nickname': _nicknameController.text,
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          settings.when(
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
            data: (data) => PkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Discord', style: AppTextStyles.heading(size: 18)),
                  const SizedBox(height: 8),
                  Text(
                    user.discordId == null || user.discordId!.isEmpty
                        ? 'Connect Discord so pickup coordination, reminders, and support messages reach the right account.'
                        : 'Connected as ${user.discordHandle.isEmpty ? 'Discord user' : user.discordHandle}.',
                    style: AppTextStyles.body(),
                  ),
                  const SizedBox(height: 12),
                  if (user.discordId == null || user.discordId!.isEmpty)
                    PkButton(
                      label: 'Connect Discord',
                      icon: const Icon(Icons.link),
                      loading: _linkingDiscord,
                      onPressed: _linkingDiscord ? null : _connectDiscord,
                      expand: true,
                    )
                  else
                    PkButton(
                      label: 'Disconnect Discord',
                      icon: const Icon(Icons.link_off),
                      variant: PkButtonVariant.destructive,
                      loading: _unlinkingDiscord,
                      onPressed: _unlinkingDiscord ? null : _disconnectDiscord,
                      expand: true,
                    ),
                  const SizedBox(height: 10),
                  PkButton(
                      label: 'Open Discord Invite',
                      variant: PkButtonVariant.secondary,
                      onPressed: () async {
                        final url =
                            data.ucscDiscordInvite ?? data.publicDiscordInvite;
                        if (url != null) {
                          await launchUrl(Uri.parse(url),
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      expand: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          PkButton(
            label: 'Log Out',
            variant: PkButtonVariant.destructive,
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openPokemonPicker(AsyncValue<List<PokemonIconOption>> icons,
      String? currentFilename) async {
    final values = icons.valueOrNull;
    if (values == null || values.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile images are still loading.')),
      );
      return;
    }
    final selected = await showDialog<PokemonIconOption>(
      context: context,
      builder: (context) => _PokemonIconPickerDialog(
        icons: values,
        currentFilename: currentFilename,
      ),
    );
    if (selected != null) {
      await _updatePokemonIcon(selected);
    }
  }

  Future<void> _updatePokemonIcon(PokemonIconOption? icon) async {
    setState(() => _savingIcon = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile({'pokemon_icon_id': icon?.id});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(icon == null
                ? 'Profile picture removed.'
                : 'Profile picture updated.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingIcon = false);
    }
  }

  Future<void> _connectDiscord() async {
    setState(() => _linkingDiscord = true);
    try {
      final uri = await ref
          .read(authRepositoryProvider)
          .startDiscordLink(nextPath: '/settings');
      _discordLinkStarted = true;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Finish Discord linking in the browser, then return here.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start Discord linking: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _linkingDiscord = false);
    }
  }

  Future<void> _disconnectDiscord() async {
    setState(() => _unlinkingDiscord = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile({'disconnect_discord': true});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discord disconnected.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to disconnect Discord: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _unlinkingDiscord = false);
    }
  }
}

class _ProfileSettingsLifecycleObserver extends WidgetsBindingObserver {
  _ProfileSettingsLifecycleObserver({required this.onResumed});

  final VoidCallback onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResumed();
  }
}

class _PokemonIconPickerDialog extends StatefulWidget {
  const _PokemonIconPickerDialog({
    required this.icons,
    required this.currentFilename,
  });

  final List<PokemonIconOption> icons;
  final String? currentFilename;

  @override
  State<_PokemonIconPickerDialog> createState() =>
      _PokemonIconPickerDialogState();
}

class _PokemonIconPickerDialogState extends State<_PokemonIconPickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.icons.where((icon) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) return true;
      return icon.displayName.toLowerCase().contains(query) ||
          icon.filename.toLowerCase().contains(query) ||
          icon.region.toLowerCase().contains(query);
    }).toList();
    return AlertDialog(
      title: const Text('Profile Picture'),
      content: SizedBox(
        width: 520,
        height: 460,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search Pokémon',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 86,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final icon = filtered[index];
                  final selected = icon.filename == widget.currentFilename;
                  return Tooltip(
                    message: icon.displayName,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).pop(icon),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.pkmnBlue
                                : AppColors.pkmnBorder,
                            width: selected ? 3 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: PokemonAvatar(
                            filename: icon.filename,
                            fallbackText: icon.displayName,
                            size: 58,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
