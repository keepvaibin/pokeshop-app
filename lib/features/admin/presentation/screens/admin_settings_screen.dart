import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/shell/app_shell.dart';
import '../../../../core/models/api_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_input.dart';
import '../../../../core/widgets/pokemon_avatar.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../shop/data/shop_repository.dart';
import '../../data/admin_repository.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _announcementController = TextEditingController();
  final _tradeCreditController = TextEditingController();
  final _tradeCashController = TextEditingController();
  final _maxTradeCardsController = TextEditingController();
  final _webhookController = TextEditingController();
  final _ucscInviteController = TextEditingController();
  final _publicInviteController = TextEditingController();
  final _oooUntilController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxBookingsController = TextEditingController(text: '5');

  int _section = 0;
  int _dayOfWeek = 0;
  int? _editingTimeslotId;
  bool _slotActive = true;
  bool _footerNewsletter = true;
  bool _isOoo = false;
  bool _ordersDisabled = false;
  bool _payVenmo = true;
  bool _payZelle = true;
  bool _payPaypal = true;
  bool _payCash = true;
  bool _payTrade = true;
  bool _tradeInsEnabled = true;
  bool _savingStore = false;
  bool _savingControls = false;
  bool _savingTimeslot = false;
  bool _linkingDiscord = false;
  bool _unlinkingDiscord = false;
  String? _syncedSettingsKey;

  @override
  void dispose() {
    _announcementController.dispose();
    _tradeCreditController.dispose();
    _tradeCashController.dispose();
    _maxTradeCardsController.dispose();
    _webhookController.dispose();
    _ucscInviteController.dispose();
    _publicInviteController.dispose();
    _oooUntilController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _locationController.dispose();
    _maxBookingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(storeSettingsProvider);
    final slots = ref.watch(adminRecurringTimeslotsProvider);
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Store Settings')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (data) {
          _syncSettings(data);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(storeSettingsProvider);
              ref.invalidate(adminRecurringTimeslotsProvider);
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth =
                    constraints.maxWidth >= 860 ? 820.0 : double.infinity;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SectionPicker(
                              selected: _section,
                              onSelected: (value) =>
                                  setState(() => _section = value),
                            ),
                            const SizedBox(height: 12),
                            if (_section == 0) _buildStoreConfig(data),
                            if (_section == 1) _buildControls(),
                            if (_section == 2) _buildTimeslots(slots),
                            if (_section == 3) _buildProfile(auth),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoreConfig(StoreSettings settings) {
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Store Config', style: AppTextStyles.heading(size: 20)),
          const SizedBox(height: 12),
          PkInput(
            controller: _announcementController,
            label: 'Store Announcement',
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          _NumberRow(
            first: PkInput(
              controller: _tradeCreditController,
              label: 'Trade Credit %',
              keyboardType: TextInputType.number,
            ),
            second: PkInput(
              controller: _tradeCashController,
              label: 'Trade Cash %',
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: 10),
          PkInput(
            controller: _maxTradeCardsController,
            label: 'Max Trade Cards / Order',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          PkInput(controller: _webhookController, label: 'Discord Webhook URL'),
          const SizedBox(height: 10),
          PkInput(
              controller: _ucscInviteController, label: 'UCSC Discord Invite'),
          const SizedBox(height: 10),
          PkInput(
              controller: _publicInviteController,
              label: 'Public Discord Invite'),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _footerNewsletter,
            onChanged: (value) => setState(() => _footerNewsletter = value),
            title: const Text('Show footer newsletter'),
          ),
          const SizedBox(height: 8),
          PkButton(
            label: 'Save Store Config',
            loading: _savingStore,
            onPressed: _savingStore ? null : _saveStoreConfig,
            expand: true,
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Enable / Disable', style: AppTextStyles.heading(size: 20)),
          const SizedBox(height: 8),
          _SwitchLine(
            title: 'Out of office',
            subtitle: 'Shows the shop as temporarily away.',
            value: _isOoo,
            onChanged: (value) => setState(() => _isOoo = value),
          ),
          if (_isOoo) ...[
            const SizedBox(height: 8),
            PkInput(
              controller: _oooUntilController,
              label: 'OOO Until (ISO date/time)',
              hint: '2026-05-20T21:00:00Z',
            ),
          ],
          _SwitchLine(
            title: 'Disable new orders',
            subtitle: 'Stops checkout while keeping browsing available.',
            value: _ordersDisabled,
            onChanged: (value) => setState(() => _ordersDisabled = value),
          ),
          _SwitchLine(
            title: 'Trade-in submissions',
            subtitle: 'Controls standalone trade-in intake.',
            value: _tradeInsEnabled,
            onChanged: (value) => setState(() => _tradeInsEnabled = value),
          ),
          const Divider(height: 22),
          Text('Payment Methods', style: AppTextStyles.heading(size: 16)),
          _SwitchLine(
              title: 'Venmo',
              value: _payVenmo,
              onChanged: (value) => setState(() => _payVenmo = value)),
          _SwitchLine(
              title: 'Zelle',
              value: _payZelle,
              onChanged: (value) => setState(() => _payZelle = value)),
          _SwitchLine(
              title: 'PayPal',
              value: _payPaypal,
              onChanged: (value) => setState(() => _payPaypal = value)),
          _SwitchLine(
              title: 'Cash',
              value: _payCash,
              onChanged: (value) => setState(() => _payCash = value)),
          _SwitchLine(
              title: 'Trade',
              value: _payTrade,
              onChanged: (value) => setState(() => _payTrade = value)),
          const SizedBox(height: 8),
          PkButton(
            label: 'Save Controls',
            loading: _savingControls,
            onPressed: _savingControls ? null : _saveControls,
            expand: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeslots(AsyncValue<List<RecurringTimeslot>> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                  _editingTimeslotId == null ? 'Add Timeslot' : 'Edit Timeslot',
                  style: AppTextStyles.heading(size: 20)),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _dayOfWeek,
                decoration: const InputDecoration(labelText: 'Day'),
                items: [
                  for (var index = 0; index < _days.length; index += 1)
                    DropdownMenuItem(value: index, child: Text(_days[index])),
                ],
                onChanged: (value) => setState(() => _dayOfWeek = value ?? 0),
              ),
              const SizedBox(height: 10),
              _NumberRow(
                first: PkInput(
                    controller: _startTimeController,
                    label: 'Start',
                    hint: '11:30'),
                second: PkInput(
                    controller: _endTimeController,
                    label: 'End',
                    hint: '12:30'),
              ),
              const SizedBox(height: 10),
              PkInput(controller: _locationController, label: 'Location'),
              const SizedBox(height: 10),
              PkInput(
                controller: _maxBookingsController,
                label: 'Max Bookings',
                keyboardType: TextInputType.number,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _slotActive,
                onChanged: (value) => setState(() => _slotActive = value),
                title: const Text('Active'),
              ),
              Row(
                children: [
                  Expanded(
                    child: PkButton(
                      label: _editingTimeslotId == null ? 'Create' : 'Save',
                      loading: _savingTimeslot,
                      onPressed: _savingTimeslot ? null : _saveTimeslot,
                      expand: true,
                    ),
                  ),
                  if (_editingTimeslotId != null) ...[
                    const SizedBox(width: 10),
                    PkButton(
                      label: 'Cancel',
                      variant: PkButtonVariant.secondary,
                      onPressed: _resetTimeslotForm,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        slots.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => PkCard(child: Text('$error')),
          data: (items) => Column(
            children: [
              for (final slot in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TimeslotCard(
                    slot: slot,
                    onEdit: () => _editTimeslot(slot),
                    onToggle: () => _toggleTimeslot(slot),
                    onDelete: () => _deleteTimeslot(slot),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfile(AuthState auth) {
    final user = auth.user;
    if (user == null) return const PkCard(child: Text('Profile unavailable.'));
    final linked = (user.discordId ?? '').isNotEmpty;
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PokemonAvatar(
                  filename: user.pokemonIcon,
                  fallbackText: user.displayName,
                  size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName,
                        style: AppTextStyles.heading(size: 18)),
                    const SizedBox(height: 3),
                    Text(user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(size: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Discord', style: AppTextStyles.heading(size: 16)),
          const SizedBox(height: 6),
          Text(linked ? user.discordHandle : 'No Discord account linked.',
              style: AppTextStyles.body()),
          const SizedBox(height: 10),
          if (linked)
            PkButton(
              label: 'Disconnect Discord',
              loading: _unlinkingDiscord,
              variant: PkButtonVariant.destructive,
              onPressed: _unlinkingDiscord ? null : _disconnectDiscord,
              expand: true,
            )
          else
            PkButton(
              label: 'Connect Discord',
              loading: _linkingDiscord,
              onPressed: _linkingDiscord
                  ? null
                  : () => _connectDiscord('/admin/settings'),
              expand: true,
            ),
          const SizedBox(height: 10),
          PkButton(
            label: 'Customer Profile Settings',
            icon: const Icon(Icons.manage_accounts_outlined),
            variant: PkButtonVariant.secondary,
            onPressed: () {
              ref.read(adminClientPreviewProvider.notifier).state = true;
              context.go('/settings');
            },
            expand: true,
          ),
        ],
      ),
    );
  }

  void _syncSettings(StoreSettings settings) {
    final key = Object.hashAll([
      settings.storeAnnouncement,
      settings.tradeCreditPercentage,
      settings.tradeCashPercentage,
      settings.maxTradeCardsPerOrder,
      settings.discordWebhookUrl,
      settings.ucscDiscordInvite,
      settings.publicDiscordInvite,
      settings.showFooterNewsletter,
      settings.isOoo,
      settings.oooUntil,
      settings.ordersDisabled,
      settings.payVenmo,
      settings.payZelle,
      settings.payPaypal,
      settings.payCash,
      settings.payTrade,
      settings.tradeInsEnabled,
    ]).toString();
    if (_syncedSettingsKey == key) return;
    _syncedSettingsKey = key;
    _announcementController.text = settings.storeAnnouncement;
    _tradeCreditController.text =
        settings.tradeCreditPercentage.toStringAsFixed(0);
    _tradeCashController.text = settings.tradeCashPercentage.toStringAsFixed(0);
    _maxTradeCardsController.text = '${settings.maxTradeCardsPerOrder}';
    _webhookController.text = settings.discordWebhookUrl;
    _ucscInviteController.text = settings.ucscDiscordInvite ?? '';
    _publicInviteController.text = settings.publicDiscordInvite ?? '';
    _oooUntilController.text = settings.oooUntil ?? '';
    _footerNewsletter = settings.showFooterNewsletter;
    _isOoo = settings.isOoo;
    _ordersDisabled = settings.ordersDisabled;
    _payVenmo = settings.payVenmo;
    _payZelle = settings.payZelle;
    _payPaypal = settings.payPaypal;
    _payCash = settings.payCash;
    _payTrade = settings.payTrade;
    _tradeInsEnabled = settings.tradeInsEnabled;
  }

  Future<void> _saveStoreConfig() async {
    setState(() => _savingStore = true);
    try {
      await ref.read(adminRepositoryProvider).updateStoreSettings({
        'store_announcement': _announcementController.text.trim(),
        'trade_credit_percentage':
            _doubleValue(_tradeCreditController.text, 85),
        'trade_cash_percentage': _doubleValue(_tradeCashController.text, 65),
        'max_trade_cards_per_order':
            _intValue(_maxTradeCardsController.text, 5),
        'discord_webhook_url': _webhookController.text.trim(),
        'ucsc_discord_invite': _emptyToNull(_ucscInviteController.text),
        'public_discord_invite': _emptyToNull(_publicInviteController.text),
        'show_footer_newsletter': _footerNewsletter,
      });
      ref.invalidate(storeSettingsProvider);
      _showSnack('Store config saved.');
    } catch (error) {
      _showSnack('Failed to save store config: $error');
    } finally {
      if (mounted) setState(() => _savingStore = false);
    }
  }

  Future<void> _saveControls() async {
    setState(() => _savingControls = true);
    try {
      await ref.read(adminRepositoryProvider).updateStoreSettings({
        'is_ooo': _isOoo,
        'ooo_until': _isOoo ? _emptyToNull(_oooUntilController.text) : null,
        'orders_disabled': _ordersDisabled,
        'trade_ins_enabled': _tradeInsEnabled,
        'pay_venmo_enabled': _payVenmo,
        'pay_zelle_enabled': _payZelle,
        'pay_paypal_enabled': _payPaypal,
        'pay_cash_enabled': _payCash,
        'pay_trade_enabled': _payTrade,
      });
      ref.invalidate(storeSettingsProvider);
      _showSnack('Controls saved.');
    } catch (error) {
      _showSnack('Failed to save controls: $error');
    } finally {
      if (mounted) setState(() => _savingControls = false);
    }
  }

  Future<void> _saveTimeslot() async {
    if (_startTimeController.text.trim().isEmpty ||
        _endTimeController.text.trim().isEmpty) {
      _showSnack('Start and end times are required.');
      return;
    }
    setState(() => _savingTimeslot = true);
    try {
      await ref.read(adminRepositoryProvider).saveRecurringTimeslot(
            id: _editingTimeslotId,
            payload: _timeslotPayload(),
          );
      ref.invalidate(adminRecurringTimeslotsProvider);
      _resetTimeslotForm();
      _showSnack('Timeslot saved.');
    } catch (error) {
      _showSnack('Failed to save timeslot: $error');
    } finally {
      if (mounted) setState(() => _savingTimeslot = false);
    }
  }

  Future<void> _toggleTimeslot(RecurringTimeslot slot) async {
    try {
      await ref.read(adminRepositoryProvider).saveRecurringTimeslot(
            id: slot.id,
            payload: _payloadFromSlot(slot, isActive: !slot.isActive),
          );
      ref.invalidate(adminRecurringTimeslotsProvider);
    } catch (error) {
      _showSnack('Failed to update timeslot: $error');
    }
  }

  Future<void> _deleteTimeslot(RecurringTimeslot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete timeslot?'),
        content: Text(
            '${_days[slot.dayOfWeek]} ${slot.startTime} - ${slot.endTime} will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteRecurringTimeslot(slot.id);
      ref.invalidate(adminRecurringTimeslotsProvider);
      _showSnack('Timeslot deleted.');
    } catch (error) {
      _showSnack('Failed to delete timeslot: $error');
    }
  }

  void _editTimeslot(RecurringTimeslot slot) {
    setState(() {
      _editingTimeslotId = slot.id;
      _dayOfWeek = slot.dayOfWeek.clamp(0, 6);
      _startTimeController.text = _shortTime(slot.startTime);
      _endTimeController.text = _shortTime(slot.endTime);
      _locationController.text = slot.location;
      _maxBookingsController.text =
          '${slot.maxBookings <= 0 ? 5 : slot.maxBookings}';
      _slotActive = slot.isActive;
    });
  }

  void _resetTimeslotForm() {
    setState(() {
      _editingTimeslotId = null;
      _dayOfWeek = 0;
      _startTimeController.clear();
      _endTimeController.clear();
      _locationController.clear();
      _maxBookingsController.text = '5';
      _slotActive = true;
    });
  }

  Future<void> _connectDiscord(String nextPath) async {
    setState(() => _linkingDiscord = true);
    try {
      final uri = await ref
          .read(authRepositoryProvider)
          .startDiscordLink(nextPath: nextPath);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _showSnack('Finish Discord linking in the browser, then return here.');
    } catch (error) {
      _showSnack('Failed to start Discord linking: $error');
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
      _showSnack('Discord disconnected.');
    } catch (error) {
      _showSnack('Failed to disconnect Discord: $error');
    } finally {
      if (mounted) setState(() => _unlinkingDiscord = false);
    }
  }

  Map<String, dynamic> _timeslotPayload() => {
        'day_of_week': _dayOfWeek,
        'start_time': _startTimeController.text.trim(),
        'end_time': _endTimeController.text.trim(),
        'location': _locationController.text.trim(),
        'max_bookings': _intValue(_maxBookingsController.text, 5),
        'is_active': _slotActive,
      };

  Map<String, dynamic> _payloadFromSlot(RecurringTimeslot slot,
          {required bool isActive}) =>
      {
        'day_of_week': slot.dayOfWeek,
        'start_time': _shortTime(slot.startTime),
        'end_time': _shortTime(slot.endTime),
        'location': slot.location,
        'max_bookings': slot.maxBookings <= 0 ? 5 : slot.maxBookings,
        'is_active': isActive,
      };

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  static String _shortTime(String value) =>
      value.length >= 5 ? value.substring(0, 5) : value;
  static String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();
  static int _intValue(String value, int fallback) =>
      int.tryParse(value.trim()) ?? fallback;
  static double _doubleValue(String value, double fallback) =>
      double.tryParse(value.trim()) ?? fallback;

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
}

class _SectionPicker extends StatelessWidget {
  const _SectionPicker({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(
            value: 0, label: Text('Store'), icon: Icon(Icons.tune_outlined)),
        ButtonSegment(
            value: 1,
            label: Text('Controls'),
            icon: Icon(Icons.toggle_on_outlined)),
        ButtonSegment(
            value: 2,
            label: Text('Slots'),
            icon: Icon(Icons.calendar_month_outlined)),
        ButtonSegment(
            value: 3, label: Text('Profile'), icon: Icon(Icons.person_outline)),
      ],
      selected: {selected},
      onSelectionChanged: (values) => onSelected(values.first),
      showSelectedIcon: false,
    );
  }
}

class _SwitchLine extends StatelessWidget {
  const _SwitchLine(
      {required this.title,
      required this.value,
      required this.onChanged,
      this.subtitle});

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
    );
  }
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(children: [first, const SizedBox(height: 10), second]);
        }
        return Row(children: [
          Expanded(child: first),
          const SizedBox(width: 10),
          Expanded(child: second)
        ]);
      },
    );
  }
}

class _TimeslotCard extends StatelessWidget {
  const _TimeslotCard(
      {required this.slot,
      required this.onEdit,
      required this.onToggle,
      required this.onDelete});

  final RecurringTimeslot slot;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final day = _AdminSettingsScreenState._days[slot.dayOfWeek.clamp(0, 6)];
    return PkCard(
      child: Row(
        children: [
          Icon(Icons.schedule,
              color:
                  slot.isActive ? AppColors.pkmnBlue : AppColors.pkmnGrayDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '$day ${_AdminSettingsScreenState._shortTime(slot.startTime)} - ${_AdminSettingsScreenState._shortTime(slot.endTime)}',
                    style: AppTextStyles.heading(size: 15)),
                const SizedBox(height: 3),
                Text(
                    '${slot.location.isEmpty ? 'No location' : slot.location} • ${slot.maxBookings} max • ${slot.bookingsThisWeek} booked',
                    style: AppTextStyles.body(size: 12)),
              ],
            ),
          ),
          IconButton(
              tooltip: slot.isActive ? 'Deactivate' : 'Activate',
              onPressed: onToggle,
              icon: Icon(
                  slot.isActive ? Icons.visibility : Icons.visibility_off)),
          IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined)),
          IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: AppColors.pkmnRed)),
        ],
      ),
    );
  }
}
