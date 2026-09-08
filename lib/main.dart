import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'widgets/clan_registry.dart';

import 'data/family_repository.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FamilyTreeApp());
}

/// Everything the app needs loaded once at startup: the main clan plus any
/// bundled side clans (خاندان‌های جانبی).
class _AppData {
  final FamilyRepository main;
  final List<FamilyRepository> sideClans;
  const _AppData({required this.main, required this.sideClans});
}

/// Shared one-shot loader: both the clan gate (for the registry) and the
/// home loader read the same future, so assets are parsed only once.
Future<_AppData>? _appDataFuture;

Future<_AppData> loadAppData() =>
    _appDataFuture ??= _loadAppData();

Future<_AppData> _loadAppData() async {
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
      // builder wraps the NAVIGATOR itself, so once the clan data is loaded
      // the [ClanRegistry] sits ABOVE every pushed route — any screen can
      // resolve cross-clan references. The navigator subtree itself is never
      // replaced (that would hang the splash); its `home` (_AppLoader) swaps
      // to HomeScreen in place when loading finishes.
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: _ClanGate(navigator: child),
        );
      },
      home: const _AppLoader(),
    );
  }
}

/// The navigator's initial route: shows a splash until the data is loaded,
/// then renders [HomeScreen] in place (no navigator surgery — this is why
/// previous versions worked reliably).
class _AppLoader extends StatelessWidget {
  const _AppLoader();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppData>(
      future: loadAppData(),
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
        return HomeScreen(repository: data.main, sideClans: data.sideClans);
      },
    );
  }
}

/// Sits ABOVE the navigator (via MaterialApp.builder). While loading it just
/// passes the navigator through; once loaded it wraps it in [ClanRegistry]
/// so every route — including pushed ones — can resolve cross-clan refs.
class _ClanGate extends StatelessWidget {
  final Widget? navigator;

  const _ClanGate({this.navigator});

  @override
  Widget build(BuildContext context) {
    final nav = navigator;
    if (nav == null) return const SizedBox.shrink();
    return FutureBuilder<_AppData>(
      future: loadAppData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData) {
          // Not ready yet: pass the navigator through unchanged (its home
          // shows the splash).
          return nav;
        }
        final data = snapshot.data!;
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
