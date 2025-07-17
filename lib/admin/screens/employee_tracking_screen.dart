import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:salespro/admin/mock_data.dart';
import 'package:salespro/admin/models/check_in_record.dart';

class EmployeeTrackingScreen extends StatefulWidget {
  const EmployeeTrackingScreen({super.key});

  @override
  _EmployeeTrackingScreenState createState() => _EmployeeTrackingScreenState();
}

class _EmployeeTrackingScreenState extends State<EmployeeTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<Marker> _markers = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(16.0544, 108.2022), // Da Nang, center of Vietnam
    zoom: 5.5,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _createMarkers();
  }

  void _createMarkers() {
    for (var record in mockCheckIns) {
      if (record.checkOutTime == null) {
        // Only show current location (not checked out)
        _markers.add(
          Marker(
            markerId: MarkerId(record.user.id),
            position: record.location,
            infoWindow: InfoWindow(
              title: record.user.name,
              snippet:
                  'Checked in at: ${DateFormat('HH:mm').format(record.checkInTime)}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Employee Tracking',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Live Map', icon: Icon(Icons.map)),
              Tab(text: 'Attendance Log', icon: Icon(Icons.timer)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMapView(),
                _buildAttendanceLog(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    // A placeholder if the API key is not set.
    return GoogleMap(
      initialCameraPosition: _initialPosition,
      markers: _markers,
    );
  }

  Widget _buildAttendanceLog() {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Employee')),
        DataColumn(label: Text('Check-in')),
        DataColumn(label: Text('Check-out')),
        DataColumn(label: Text('Address')),
      ],
      rows: mockCheckIns.map((record) {
        return DataRow(cells: [
          DataCell(Text(record.user.name)),
          DataCell(Text(DateFormat('dd/MM HH:mm').format(record.checkInTime))),
          DataCell(Text(record.checkOutTime != null
              ? DateFormat('dd/MM HH:mm').format(record.checkOutTime!)
              : 'N/A')),
          DataCell(Text(record.address, overflow: TextOverflow.ellipsis)),
        ]);
      }).toList(),
    );
  }
}
