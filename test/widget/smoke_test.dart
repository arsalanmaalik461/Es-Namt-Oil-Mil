import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:namt_oil_mil/app.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/navigation/app_shell.dart';
import 'package:namt_oil_mil/providers/settings_provider.dart';
import 'package:namt_oil_mil/screens/dashboard/dashboard_screen.dart';
import 'package:namt_oil_mil/screens/khata/party_form_sheet.dart';
import 'package:namt_oil_mil/widgets/app_text_field.dart';

// NOTE: these smoke tests intentionally do NOT open the database.
// sqflite_common_ffi's openDatabase never completes inside the widget-test
// FakeAsync zone, and these tests only need static UI: navigation, form
// validation, locale direction and theme. DB-backed providers stay in their
// loading/error states, which is fine — assertions below never depend on
// loaded data.

/// Pumps the full app with an isolated (mock) SharedPreferences, mirroring
/// main() but without platform channels or the database.
/// [initialPrefs] seeds mock preferences (the locale/theme notifiers read
/// their state from SharedPreferences).
Future<void> pumpApp(
  WidgetTester tester, {
  Map<String, Object> initialPrefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs);
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const NamtOilMilApp(),
    ),
  );
  await pumpFrames(tester);
}

/// Bounded pumping: lets the first frames (and provider-driven rebuilds)
/// run without pumpAndSettle, which can never settle while indeterminate
/// progress indicators are on screen.
Future<void> pumpFrames(WidgetTester tester, [int count = 20]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('app boots with all providers and the 5-tab shell',
      (tester) async {
    await pumpApp(tester);
    // The shell and its five destinations are up.
    expect(find.byType(AppShell), findsOneWidget);
    for (final label in [
      'Dashboard',
      'Khata',
      'Transactions',
      'Reports',
      'More'
    ]) {
      expect(find.text(label), findsWidgets);
    }
    // Dashboard is the landing tab.
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets('bottom navigation reaches all 5 tabs', (tester) async {
    await pumpApp(tester);
    final destinations = find.byType(NavigationDestination);
    expect(destinations, findsNWidgets(5));

    for (var i = 0; i < 5; i++) {
      await tester.tap(destinations.at(i));
      await pumpFrames(tester, 5);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        i,
        reason: 'tapping destination $i should select tab $i',
      );
    }
  });

  testWidgets('customer form rejects an empty name', (tester) async {
    // Open the real customer form from inside a localized app tree.
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider
              .overrideWithValue(await SharedPreferences.getInstance()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showPartyFormSheet(
                  context,
                  ref,
                  kind: PartyKind.customer,
                ),
                child: const Text('open form'),
              ),
            ),
          ),
        ),
      ),
    );
    await pumpFrames(tester);

    await tester.tap(find.text('open form'));
    await pumpFrames(tester);
    expect(find.text('Name'), findsOneWidget);

    // Save with the name left empty -> required-field error, no save.
    await tester.ensureVisible(find.text('Save'));
    await pumpFrames(tester, 3);
    await tester.tap(find.text('Save'), warnIfMissed: false);
    await pumpFrames(tester);
    expect(find.text('This field is required'), findsOneWidget);
    // The sheet stayed open (no success snackbar, no pop).
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('shared amount validator rejects zero and garbage',
      (tester) async {
    late BuildContext localizedContext;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            localizedContext = context;
            AppLocalizations.of(context); // ensure delegates loaded
            return const SizedBox();
          },
        ),
      ),
    );
    await pumpFrames(tester);

    final validate = AppValidators.amount(localizedContext);
    expect(validate(''), isNotNull); // empty -> required
    expect(validate('0'), isNotNull); // zero -> invalid amount
    expect(validate('-5'), isNotNull); // negative -> invalid amount
    expect(validate('abc'), isNotNull); // garbage -> invalid amount
    expect(validate('1500'), isNull); // positive -> OK
    expect(validate('1500.50'), isNull);
  });

  testWidgets('locale switch EN -> UR flips the app to RTL', (tester) async {
    // English first: LTR.
    await pumpApp(tester);
    Directionality dir() =>
        tester.widget<Directionality>(find.byType(Directionality).first);
    expect(dir().textDirection, TextDirection.ltr);

    // Urdu: the whole tree becomes RTL and Urdu labels render.
    await pumpApp(
      tester,
      initialPrefs: {'settings.locale': 'ur'},
    );
    expect(dir().textDirection, TextDirection.rtl);
    expect(find.text('کھاتہ'), findsWidgets); // nav label in Urdu
  });

  testWidgets('theme toggle applies dark mode', (tester) async {
    await pumpApp(
      tester,
      initialPrefs: {'settings.themeMode': 'dark'},
    );
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    final theme = Theme.of(tester.element(find.byType(Scaffold).first));
    expect(theme.brightness, Brightness.dark);
  });
}
