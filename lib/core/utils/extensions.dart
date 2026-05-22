import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

extension AppPaletteX on BuildContext {
  AppPalette get colors => Theme.of(this).brightness == Brightness.light
      ? AppPalette.light
      : AppPalette.light;
}

extension ThemeX on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
}
