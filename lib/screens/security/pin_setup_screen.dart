import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namt_oil_mil/l10n/gen/app_localizations.dart';
import 'package:namt_oil_mil/services/app_lock_service.dart';

/// Set up (or change) the 4-digit app PIN: enter once, confirm once.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _first = '';
  String _second = '';
  bool get _confirming => _first.length == 4;

  void _onDigit(String d) {
    setState(() {
      if (!_confirming) {
        if (_first.length < 4) _first += d;
      } else {
        if (_second.length < 4) _second += d;
      }
    });
    if (_second.length == 4) _finish();
  }

  void _onBackspace() {
    setState(() {
      if (_second.isNotEmpty) {
        _second = _second.substring(0, _second.length - 1);
      } else if (_first.isNotEmpty && !_confirming) {
        _first = _first.substring(0, _first.length - 1);
      } else if (_confirming && _second.isEmpty) {
        // back out of confirm step
        _first = '';
      }
    });
  }

  Future<void> _finish() async {
    final l10n = AppLocalizations.of(context);
    if (_first != _second) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.security_pinMismatch)),
      );
      setState(() => _second = '');
      return;
    }
    await ref.read(appLockServiceProvider).setPin(_first);
    ref.read(appLockedProvider.notifier).state = false;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.security_pinSet)),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shown = _confirming ? _second : _first;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.security_setupPin)),
      body: Column(
        children: [
          const SizedBox(height: 32),
          Text(
            _confirming ? l10n.security_confirmPin : l10n.security_enterPin,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < shown.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                ),
              );
            }),
          ),
          const Spacer(),
          _PinPad(onDigit: _onDigit, onBackspace: _onBackspace),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Shared 4-digit PIN pad widget (also used by the lock screen).
class _PinPad extends StatelessWidget {
  const _PinPad({required this.onDigit, required this.onBackspace});

  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onTap, bool dim = false}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap ?? () => onDigit(label),
            child: Container(
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dim
                    ? Colors.transparent
                    : Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: label.isEmpty
                  ? const SizedBox.shrink()
                  : label == 'back'
                      ? const Icon(Icons.backspace_outlined)
                      : Text(
                          label,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(children: [key('1'), key('2'), key('3')]),
          Row(children: [key('4'), key('5'), key('6')]),
          Row(children: [key('7'), key('8'), key('9')]),
          Row(children: [
            key('', dim: true),
            key('0'),
            key('back', onTap: onBackspace),
          ]),
        ],
      ),
    );
  }
}

/// Public PIN pad for reuse by the lock screen.
class PinPad extends StatelessWidget {
  const PinPad(
      {super.key, required this.onDigit, required this.onBackspace});

  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) =>
      _PinPad(onDigit: onDigit, onBackspace: onBackspace);
}
