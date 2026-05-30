import 'package:zedu/core/core.dart';

extension MediaQueryValues on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  SizedBox screenHeightSpace(double percent) =>
      SizedBox(height: percent * screenHeight);

  SizedBox screenWidthSpace(double percent) =>
      SizedBox(width: percent * screenWidth);

  double get _scale {
    final w = screenWidth;
    return w >= SizeConfig.baseWidth ? 1.0 : w / SizeConfig.baseWidth;
  }

  double s(double value) => value * _scale;

  SizedBox gapV(double value) => SizedBox(height: s(value));

  SizedBox gapH(double value) => SizedBox(width: s(value));

  EdgeInsets all(double value) => EdgeInsets.all(s(value));

  EdgeInsets symmetric({double vertical = 0, double horizontal = 0}) =>
      EdgeInsets.symmetric(vertical: s(vertical), horizontal: s(horizontal));

  EdgeInsets only({
    double top = 0,
    double left = 0,
    double bottom = 0,
    double right = 0,
  }) => EdgeInsets.only(
    top: s(top),
    left: s(left),
    right: s(right),
    bottom: s(bottom),
  );
}

class SizeConfig {
  static double baseWidth = 1440;
}
