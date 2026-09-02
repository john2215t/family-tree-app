import 'package:flutter/material.dart';

import '../data/family_repository.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../widgets/person_card.dart';
import '../widgets/status_dot.dart';
import 'person_screen.dart';

/// A simple scrollable list of people — opened from the home-screen clan
/// stats (زنده / فوت کرده / شهید) and from generation-count chips
/// (نوه / نتیجه / نبیره / ندیده) on family and person screens.
///
/// [title] describes what the list shows, e.g. «افراد فوت‌کرده» or
/// «نوه‌های این خانواده». Tapping a person opens their profile.
class PersonListScreen extends StatelessWidget {
  final FamilyRepository repository;
  final String title;
  final List<Person> people;

  const PersonListScreen({
    super.key,
    required this.repository,
    required this.title,
    required this.people,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...people]..sort((a, b) => a.fullName.compareTo(b.fullName));

    return Scaffold(
      appBar: AppBar(title: Text('$title (${people.length})')),
      body: SafeArea(
        child: people.isEmpty
            ? Center(
                child: Text(
                  'فردی در این دسته ثبت نشده است',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  for (final person in sorted) ...[
                    PersonCard(
                      person: person,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PersonScreen(
                              repository: repository,
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
      ),
    );
  }
}

/// Opens a [PersonListScreen] pre-filtered by life status. Shared by the
/// home-screen stat rows.
void openStatusList(BuildContext context, FamilyRepository repository,
    PersonStatus status, String title) {
  final people =
      repository.allPeople.where((p) => p.status == status).toList();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PersonListScreen(
        repository: repository,
        title: title,
        people: people,
      ),
    ),
  );
}
