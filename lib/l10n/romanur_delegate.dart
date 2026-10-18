import 'package:flutter/widgets.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations_romanur.dart';

/// Localizations delegate for Roman Urdu (`romanur`).
///
/// The generated [AppLocalizations.delegate] only knows en/sd/ur (Flutter's
/// gen-l10n validates language codes against the IANA registry, which has no
/// Roman-Urdu code), so Roman Urdu ships as a hand-rolled delegate that
/// serves [AppLocalizationsRomanur] — an English-backed table overridden by
/// lib/l10n/roman_ur.dart.
class RomanUrLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const RomanUrLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'romanur';

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizationsRomanur();

  @override
  bool shouldReload(RomanUrLocalizationsDelegate old) => false;
}

/// Extra locales beyond [AppLocalizations.supportedLocales].
const extraSupportedLocales = <Locale>[
  Locale('romanur'),
];
