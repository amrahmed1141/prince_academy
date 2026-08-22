import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

/// Screen-level background gradients only.
///
/// Gradients use **opaque** colors. Flutter ignores [BoxDecoration.color] when
/// a gradient is set, so translucent `withOpacity` stops would composite with
/// whatever sits behind the page (and can read as a dark wash).
class AppGradients {
  AppGradients._();

  static const Alignment _top = Alignment.topCenter;
  static const Alignment _bottom = Alignment.bottomCenter;

  /// Warm cream base shared with member home / booking history.
  static const Color _cream = Color(0xFFFFF9F5);
  static const Color _creamSoft = EColorConstants.authFieldBackground; // #F7F4EF

  /// Session-card progress bar fill — shared by member home day circles.
  static const LinearGradient sessionProgress = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFB7E27A),
      Color(0xFF8FD15B),
      Color(0xFF66BE47),
      Color(0xFF3E9F34),
    ],
    stops: [0.0, 0.35, 0.68, 1.0],
  );

  /// Standard screen background (booking, sessions, profile).
  static const LinearGradient screen = LinearGradient(
    begin: _top,
    end: _bottom,
    colors: [
      Color(0xFFF8F1E8), // ~primary @ 8% on cream
      Color(0xFFFBF7F2), // ~primary @ 3% on cream
      Colors.white,
    ],
    stops: [0.0, 0.3, 1.0],
  );

  /// Slightly stronger screen background for the home feed.
  static const LinearGradient screenHeavy = LinearGradient(
    begin: _top,
    end: _bottom,
    colors: [
      Color(0xFFF3E8DA), // ~primary @ 14% on cream
      Color(0xFFF9F0E6), // ~primary @ 6% on cream
      Colors.white,
    ],
    stops: [0.0, 0.35, 1.0],
  );

  /// Between [screen] and [screenHeavy] — home, coaches, booking history, sessions.
  static const LinearGradient screenSessions = LinearGradient(
    begin: _top,
    end: _bottom,
    colors: [
      _creamSoft, // #F7F4EF — same light level as home
      Color(0xFFFAF6F1),
      _cream,
    ],
    stops: [0.0, 0.35, 1.0],
  );

  static BoxDecoration screenDecoration({bool heavy = false}) => BoxDecoration(
        gradient: heavy ? screenHeavy : screen,
      );

  static BoxDecoration sessionsScreenDecoration() => const BoxDecoration(
        gradient: screenSessions,
      );

  /// Home feed + Coaches directory + Booking History — keep visually identical.
  static BoxDecoration homeScreenDecoration() => const BoxDecoration(
        gradient: screenSessions,
      );

  /// Same light cream gradient for **all admin screens** (and member home).
  /// Prefer this over flat `authFieldBackground` / dark auth gradients.
  static BoxDecoration lightScreenDecoration() => homeScreenDecoration();

  /// Full-bleed light gradient behind a transparent [Scaffold].
  static Widget lightBackground({required Widget child}) {
    return DecoratedBox(
      decoration: lightScreenDecoration(),
      child: SizedBox.expand(child: child),
    );
  }
}
