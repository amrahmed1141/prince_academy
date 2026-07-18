import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/app_colors.dart';

/// Screen-level background gradients only.
class AppGradients {
  AppGradients._();

  static const Alignment _top = Alignment.topCenter;
  static const Alignment _bottom = Alignment.bottomCenter;

  /// Standard screen background (booking, sessions, profile).
  static LinearGradient get screen => LinearGradient(
        begin: _top,
        end: _bottom,
        colors: [
          AppColors.primary.withOpacity(0.08),
          AppColors.primary.withOpacity(0.03),
          Colors.white,
        ],
        stops: const [0.0, 0.3, 1.0],
      );

  /// Slightly stronger screen background for the home feed.
  static LinearGradient get screenHeavy => LinearGradient(
        begin: _top,
        end: _bottom,
        colors: [
          AppColors.primary.withOpacity(0.14),
          AppColors.primary.withOpacity(0.06),
          Colors.white,
        ],
        stops: const [0.0, 0.35, 1.0],
      );

  /// Between [screen] and [screenHeavy] — used on My Sessions.
  static LinearGradient get screenSessions => LinearGradient(
        begin: _top,
        end: _bottom,
        colors: [
          AppColors.primary.withOpacity(0.10),
          AppColors.primary.withOpacity(0.04),
          Colors.white,
        ],
        stops: const [0.0, 0.32, 1.0],
      );

  static BoxDecoration screenDecoration({bool heavy = false}) => BoxDecoration(
        gradient: heavy ? screenHeavy : screen,
      );

  static BoxDecoration sessionsScreenDecoration() => BoxDecoration(
        color: Colors.white,
        gradient: screenSessions,
      );

  /// Home feed + Coaches directory — keep these screens visually identical.
  static BoxDecoration homeScreenDecoration() => BoxDecoration(
        color: const Color(0xFFFFF9F5),
        gradient: screenSessions,
      );
}
