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

  factory CheckInRecord.fromMap(Map<String, dynamic> map) {
    return CheckInRecord(
      user: map['user'] is Map<String, dynamic>
          ? User.fromMap(map['user'])
          : User.fromMap({}),
      checkInTime: map['checkInTime'] != null
          ? DateTime.tryParse(map['checkInTime']) ?? DateTime.now()
          : DateTime.now(),
      checkOutTime: map['checkOutTime'] != null && map['checkOutTime'] != ''
          ? DateTime.tryParse(map['checkOutTime'])
          : null,
      location: map['location'] is Map<String, dynamic>
          ? LatLng(
              (map['location']['latitude'] as num).toDouble(),
              (map['location']['longitude'] as num).toDouble(),
            )
          : const LatLng(0, 0),
      address: map['address'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user': user.toMap(),
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String() ?? '',
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'address': address,
    };
  }
}
