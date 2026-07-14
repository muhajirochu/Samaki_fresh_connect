import 'package:geolocator/geolocator.dart';

void main() {
  const locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );
  
  Geolocator.getPositionStream(locationSettings: locationSettings);
  print('compiles!');
}
