/// Formats a [km] value as either meters (under 1 km) or kilometers
/// with one decimal place.
String formatRouteDistance(double km) =>
    km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

/// Formats a [minutes] value as a human-readable ETA.
String formatRouteEta(double minutes) {
  if (minutes < 1) return '< 1 min';
  if (minutes < 60) return '${minutes.round()} min';
  final h = minutes ~/ 60;
  final m = (minutes % 60).round();
  return '${h}h ${m}m';
}
