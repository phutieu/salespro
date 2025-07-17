import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:salespro/admin/models/user.dart';

class CheckInRecord {
  final User user;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final LatLng location;
  final String address;

  CheckInRecord({
    required this.user,
    required this.checkInTime,
    this.checkOutTime,
    required this.location,
    required this.address,
  });
}
