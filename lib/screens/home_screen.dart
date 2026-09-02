import 'package:flutter/material.dart';

import '../data/family_repository.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../widgets/person_card.dart';
import 'family_screen.dart';
import 'help_screen.dart';
import 'person_list_screen.dart';
import 'person_screen.dart';

/// The app's landing screen: the "شجره‌نامه" title, a search box for
/// finding a person, a single card for the default clan leading into its
/// family tree, an overview of clan-wide statistics (tappable — opens the
/// filtered member list), and a placeholder for future side clans.
class HomeScreen extends StatefulWidget {
  final FamilyRepository repository;

  const HomeScreen({super.key, required this.repository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  List<Person> _results = const [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _results = widget.repository.searchPeople(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = widget.repository;
    final rootCouple = repo.resolveCouple(repo.rootFamilyId);
    final query = _searchController.text.trim();
    final isSearching = query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('شجره‌نامه'),
        actions: [
          IconButton(
            tooltip: 'راهنما',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            const Center(
              child: Text('🌳', style: TextStyle(fontSize: 44)),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'شجره‌نامه',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'جستجوی فرد',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 20),
            if (isSearching) ...[
              Text(
                '${_results.length} نتیجه برای «$query» در کل خاندان یافت شد',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (_results.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'فردی با این مشخصات پیدا نشد',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    for (final person in _results) ...[
                      PersonCard(
                        person: person,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PersonScreen(
                                repository: repo,
                                personId: person.id,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
            ] else ...[
              Text(
                repo.title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (rootCouple != null)
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FamilyScreen(
                            repository: repo,
                            path: [repo.rootFamilyId],
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            rootCouple.displayName,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'مشاهده شجره‌نامه',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_left_rounded,
                                  color: AppTheme.primary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              _ClanStats(repository: repo),
              const SizedBox(height: 20),
              const _SideClansPlaceholder(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Clan-wide overview: total member count plus alive / deceased / martyr
/// breakdown. Every row is tappable and opens the filtered member list.
class _ClanStats extends StatelessWidget {
  final FamilyRepository repository;

  const _ClanStats({required this.repository});

  @override
  Widget build(BuildContext context) {
    final counts = repository.statusCounts;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'آمار خاندان',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'برای دیدن فهرست افراد، روی هر ردیف بزنید',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            _StatRow(
              label: 'تعداد کل اعضای خاندان',
              value: repository.totalPeopleCount,
              color: AppTheme.primary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PersonListScreen(
                      repository: repository,
                      title: 'همه اعضای خاندان',
                      people: repository.allPeople,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _StatRow(
              label: 'زنده',
              value: counts[PersonStatus.alive] ?? 0,
              dotColor: const Color(0xFF3FB562),
              onTap: () => openStatusList(
                  context, repository, PersonStatus.alive, 'اعضای زنده'),
            ),
            const SizedBox(height: 10),
            _StatRow(
              label: 'فوت کرده',
              value: counts[PersonStatus.deceased] ?? 0,
              dotColor: const Color(0xFF2A2A2A),
              onTap: () => openStatusList(context, repository,
                  PersonStatus.deceased, 'اعضای فوت‌کرده'),
            ),
            const SizedBox(height: 10),
            _StatRow(
              label: 'شهید',
              value: counts[PersonStatus.martyr] ?? 0,
              dotColor: const Color(0xFFD4AF37),
              onTap: () => openStatusList(
                  context, repository, PersonStatus.martyr, 'شهیدان'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;
  final Color? color;
  final Color? dotColor;
  final VoidCallback? onTap;

  const _StatRow({
    required this.label,
    required this.value,
    this.color,
    this.dotColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        if (dotColor != null) ...[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ),
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color ?? AppTheme.textPrimary,
              ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 6),
          Icon(Icons.chevron_left_rounded,
              size: 18, color: AppTheme.textSecondary),
        ],
      ],
    );

    if (onTap == null) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: row,
      ),
    );
  }
}

/// Placeholder for future side clans («خاندان‌های جانبی») that will be
/// added to the app later. Currently shows a disabled hint card.
class _SideClansPlaceholder extends StatelessWidget {
  const _SideClansPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_tree_rounded,
                    size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'خاندان‌های جانبی',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'به‌زودی: شجره‌نامه‌های خاندان‌های دیگر (خویشاوندان سببی) به این بخش اضافه می‌شود.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
