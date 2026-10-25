import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/navigation/routes.dart';
import 'package:namt_oil_mil/providers/settings_provider.dart';
import 'package:namt_oil_mil/screens/security/app_lock_screen.dart';
import 'package:namt_oil_mil/services/app_lock_service.dart';
import 'package:namt_oil_mil/theme/app_theme.dart';

/// Root widget of the Namt Oil Mil app.
///
/// Wraps [MaterialApp] with the app-lock gate: when PIN/biometric lock is
/// enabled, [AppLockScreen] covers the app on launch and on resume from
/// background (after the configured auto-lock timeout).
class NamtOilMilApp extends ConsumerStatefulWidget {
  const NamtOilMilApp({super.key});

  @override
  ConsumerState<NamtOilMilApp> createState() => _NamtOilMilAppState();
}

class _NamtOilMilAppState extends ConsumerState<NamtOilMilApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockOnLaunch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkLockOnLaunch() async {
    final active = await ref.read(appLockServiceProvider).isLockActive;
    if (active && mounted) {
      ref.read(appLockedProvider.notifier).state = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final svc = ref.read(appLockServiceProvider);
    if (state == AppLifecycleState.paused) {
      svc.markPaused();
    } else if (state == AppLifecycleState.resumed) {
      svc.shouldLockOnResume().then((shouldLock) {
        if (shouldLock && mounted) {
          ref.read(appLockedProvider.notifier).state = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final locked = ref.watch(appLockedProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: RouteRegistry.onGenerateRoute,
      initialRoute: Routes.home,
      builder: (context, child) {
        if (locked) return const AppLockScreen();
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
