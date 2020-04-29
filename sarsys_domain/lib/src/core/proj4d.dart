import 'dart:math';

class ProjMath {
  static double eucledianDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final degLen = 110250;
    final x = lat1 - lat2;
    final y = (lon1 - lon2) * cos(lat2 * pi / 180.0);
    return degLen * sqrt(x * x + y * y);
  }
}
