import 'package:flutter/material.dart';

/// App-wide page transition: quick fade + subtle slide (250ms).
///
/// Applied through [PageTransitionsTheme] in [AppTheme] so every
/// [MaterialPageRoute] (and the [SaleFormScreen] push in the sales list)
/// animates consistently on all platforms, in light and dark mode.
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = CurvedAnimation(parent: animation, curve: _curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// Shared [PageTransitionsTheme] installed on both app themes.
///
/// The fade/slide runs inside [MaterialPageRoute]'s own ~300ms transition
/// window (within the 200-300ms spec).
PageTransitionsTheme buildAppPageTransitionsTheme() {
  const builder = FadeSlidePageTransitionsBuilder();
  return const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: builder,
      TargetPlatform.iOS: builder,
      TargetPlatform.macOS: builder,
      TargetPlatform.windows: builder,
      TargetPlatform.linux: builder,
      TargetPlatform.fuchsia: builder,
    },
  );
}
