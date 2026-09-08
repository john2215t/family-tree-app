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
      // builder wraps the NAVIGATOR itself, so ClanRegistry (provided by
      // _ClanGate once data is loaded) sits ABOVE every pushed route —
      // pushed screens can always resolve cross-clan references.
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: _ClanGate(navigator: child),
        );
      },
      home: const _Splash(),
    );
  }
}

/// Splash shown as the initial route while clans load.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
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

/// Loads the main + side clans once, then provides them via [ClanRegistry]
/// ABOVE the navigator (so every pushed route can resolve cross-clan refs)
/// and swaps the splash for the real [HomeScreen].
class _ClanGate extends StatefulWidget {
  final Widget? navigator;

  const _ClanGate({this.navigator});

  @override
  State<_ClanGate> createState() => _ClanGateState();
}

class _ClanGateState extends State<_ClanGate> {
  late Future<_AppData> _future;
  bool _replaced = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

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
      future: _future,
      builder: (context, snapshot) {
        final nav = widget.navigator;
        if (snapshot.hasError) {
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
        if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData ||
            nav == null) {
          // Before data arrives there is no registry yet — the navigator
          // shows the splash route anyway.
          return nav ?? const _Splash();
        }
        final data = snapshot.data!;
        // Swap the splash for the real home exactly once.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_replaced && mounted) {
            _replaced = true;
            Navigator.of(context, rootNavigator: true).pushReplacement(
              MaterialPageRoute(
                builder: (_) => HomeScreen(
                  repository: data.main,
                  sideClans: data.sideClans,
                ),
              ),
            );
          }
        });
        return ClanRegistry(
          clans: {
            data.main.clanKey: data.main,
            for (final clan in data.sideClans) clan.clanKey: clan,
          },
          child: nav,
        );
      },
    );
  }
}
