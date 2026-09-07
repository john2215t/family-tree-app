import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'widgets/clan_registry.dart';

import 'data/family_repository.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FamilyTreeApp());
}

class FamilyTreeApp extends StatelessWidget {
  const FamilyTreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'شجره‌نامه',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      // The whole app is Persian-first and right-to-left.
      locale: const Locale('fa', 'IR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fa', 'IR')],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const _AppLoader(),
    );
  }
}

/// Everything the app needs loaded once at startup: the main clan plus any
/// bundled side clans (خاندان‌های جانبی).
class _AppData {
  final FamilyRepository main;
  final List<FamilyRepository> sideClans;
  const _AppData({required this.main, required this.sideClans});
}

/// Loads the bundled family data once at startup and shows a small splash
/// while doing so, before handing off to [HomeScreen].
class _AppLoader extends StatelessWidget {
  const _AppLoader();

  Future<_AppData> _load() async {
    final main = await FamilyRepository.loadDefault();
    List<FamilyRepository> sideClans = const [];
    try {
      sideClans = await FamilyRepository.loadSideClans();
    } catch (_) {
      // Side clans are optional — never block startup on them.
      sideClans = const [];
    }
    return _AppData(main: main, sideClans: sideClans);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppData>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'خطا در بارگذاری اطلاعات خاندان:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        final data = snapshot.data!;
        return ClanRegistry(
          clans: {
            data.main.clanKey: data.main,
            for (final clan in data.sideClans) clan.clanKey: clan,
          },
          child: HomeScreen(repository: data.main, sideClans: data.sideClans),
        );
      },
    );
  }
}
