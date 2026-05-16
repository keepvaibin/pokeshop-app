import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/json_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../data/admin_repository.dart';

class AdminStrikesScreen extends ConsumerStatefulWidget {
  const AdminStrikesScreen({super.key});

  @override
  ConsumerState<AdminStrikesScreen> createState() => _AdminStrikesScreenState();
}

class _AdminStrikesScreenState extends ConsumerState<AdminStrikesScreen> {
  final _searchController = TextEditingController();
  final _reasonController = TextEditingController();
  List<Map<String, dynamic>> _usersWithStrikes = const [];
  List<Map<String, dynamic>> _searchResults = const [];
  List<Map<String, dynamic>> _selectedStrikes = const [];
  Map<String, dynamic>? _targetUser;
  Map<String, dynamic>? _selectedUser;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strikes'),
        actions: [
          IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh')
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Strike management', style: AppTextStyles.heading(size: 24)),
            const SizedBox(height: 12),
            _IssueStrikePanel(
              searchController: _searchController,
              reasonController: _reasonController,
              targetUser: _targetUser,
              searchResults: _searchResults,
              submitting: _submitting,
              onSearch: _searchUsers,
              onSelect: (user) => setState(() {
                _targetUser = user;
                _searchResults = const [];
                _searchController.text = asString(user['email']);
              }),
              onClear: () => setState(() {
                _targetUser = null;
                _searchController.clear();
              }),
              onSubmit: _issueStrike,
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!,
                  style: AppTextStyles.body(color: AppColors.pkmnRed)),
            PkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Users with strikes',
                      style: AppTextStyles.heading(size: 18)),
                  const SizedBox(height: 8),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_usersWithStrikes.isEmpty)
                    const Text('No active strikes.')
                  else
                    ..._usersWithStrikes.map((user) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                              Icons.report_gmailerrorred_outlined,
                              color: AppColors.pkmnRed),
                          title: Text(asString(user['email'])),
                          subtitle:
                              Text('${asInt(user['strike_count'])} strike(s)'),
                          selected:
                              asInt(_selectedUser?['id']) == asInt(user['id']),
                          onTap: () => _selectUser(user),
                        )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedUser != null)
              PkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asString(_selectedUser!['email']),
                        style: AppTextStyles.heading(size: 18)),
                    const SizedBox(height: 8),
                    if (_selectedStrikes.isEmpty)
                      const Text('No strikes returned for this user.')
                    else
                      ..._selectedStrikes.map((strike) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(asString(strike['reason'])),
                            subtitle: Text(
                                'By ${asString(strike['given_by_email'], fallback: 'admin')} • ${asString(strike['created_at'])}'),
                            trailing: IconButton(
                              tooltip: 'Remove strike',
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.pkmnRed),
                              onPressed: () =>
                                  _deleteStrike(asInt(strike['id'])),
                            ),
                          )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await ref.read(adminRepositoryProvider).usersWithStrikes();
      if (!mounted) return;
      setState(() {
        _usersWithStrikes = users;
        _loading = false;
      });
      if (_selectedUser != null) {
        await _selectUser(_selectedUser!);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  Future<void> _searchUsers(String value) async {
    final query = value.trim();
    if (query.length < 2 || _targetUser != null) {
      setState(() => _searchResults = const []);
      return;
    }
    final results = await ref.read(adminRepositoryProvider).searchUsers(query);
    if (!mounted) return;
    setState(() => _searchResults = results);
  }

  Future<void> _selectUser(Map<String, dynamic> user) async {
    setState(() {
      _selectedUser = user;
      _selectedStrikes = const [];
    });
    try {
      final strikes = await ref
          .read(adminRepositoryProvider)
          .strikesForUser(asInt(user['id']));
      if (!mounted) return;
      setState(() => _selectedStrikes = strikes);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    }
  }

  Future<void> _issueStrike() async {
    final reason = _reasonController.text.trim();
    if (_targetUser == null || reason.isEmpty) {
      setState(() => _error = 'Select a user and enter a reason.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(adminRepositoryProvider)
          .issueStrike(userId: asInt(_targetUser!['id']), reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Strike issued.')));
      setState(() {
        _targetUser = null;
        _searchResults = const [];
        _searchController.clear();
        _reasonController.clear();
        _submitting = false;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _submitting = false;
      });
    }
  }

  Future<void> _deleteStrike(int id) async {
    await ref.read(adminRepositoryProvider).deleteStrike(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Strike removed.')));
    await _load();
  }
}

class _IssueStrikePanel extends StatelessWidget {
  const _IssueStrikePanel({
    required this.searchController,
    required this.reasonController,
    required this.targetUser,
    required this.searchResults,
    required this.submitting,
    required this.onSearch,
    required this.onSelect,
    required this.onClear,
    required this.onSubmit,
  });

  final TextEditingController searchController;
  final TextEditingController reasonController;
  final Map<String, dynamic>? targetUser;
  final List<Map<String, dynamic>> searchResults;
  final bool submitting;
  final ValueChanged<String> onSearch;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Issue new strike', style: AppTextStyles.heading(size: 18)),
          const SizedBox(height: 10),
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search), labelText: 'Search users'),
            onChanged: onSearch,
          ),
          if (targetUser != null) ...[
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(asString(targetUser!['email'])),
              trailing:
                  IconButton(onPressed: onClear, icon: const Icon(Icons.close)),
            ),
          ] else if (searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...searchResults.map((user) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(asString(user['email'])),
                  subtitle: Text(asString(user['display'])),
                  onTap: () => onSelect(user),
                )),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: reasonController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Reason'),
          ),
          const SizedBox(height: 12),
          PkButton(
            label: 'Issue Strike',
            icon: const Icon(Icons.report_gmailerrorred_outlined),
            variant: PkButtonVariant.destructive,
            loading: submitting,
            expand: true,
            onPressed: submitting ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}
