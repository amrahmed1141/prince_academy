// models/gym_location_model.dart
class GymLocation {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String description;

  GymLocation({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.description,
  });
}

// Sample gym locations
final List<GymLocation> gymLocations = [
  GymLocation(
    name: 'Prince Academy Main Gym',
    address: '123 Fitness Street, Sports City',
    latitude: 37.7749,
    longitude: -122.4194,
    description: 'Our flagship location with state-of-the-art facilities',
  ),
  GymLocation(
    name: 'Prince Academy Downtown',
    address: '456 Workout Avenue, Downtown',
    latitude: 37.7833,
    longitude: -122.4167,
    description: 'Convenient downtown location with extended hours',
  ),
  GymLocation(
    name: 'Prince Academy West',
    address: '789 Health Road, West District',
    latitude: 37.7699,
    longitude: -122.4334,
    description: 'Modern facility with specialized training areas',
  ),
];