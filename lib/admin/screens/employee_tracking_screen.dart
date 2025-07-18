import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salespro/admin/models/check_in_record.dart';

class EmployeeTrackingScreen extends StatefulWidget {
  const EmployeeTrackingScreen({super.key});

  @override
  _EmployeeTrackingScreenState createState() => _EmployeeTrackingScreenState();
}

class _EmployeeTrackingScreenState extends State<EmployeeTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(16.0544, 108.2022), // Da Nang, center of Vietnam
    zoom: 5.5,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('check_ins').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        final markers = <Marker>{};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final record = CheckInRecord.fromMap(data);
          if (record.checkOutTime == null) {
            markers.add(
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
        return GoogleMap(
          initialCameraPosition: _initialPosition,
          markers: markers,
        );
      },
    );
  }

  Widget _buildAttendanceLog() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('check_ins').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        final records = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return CheckInRecord.fromMap(data);
        }).toList();
        return DataTable(
          columns: const [
            DataColumn(label: Text('Employee')),
            DataColumn(label: Text('Check-in')),
            DataColumn(label: Text('Check-out')),
            DataColumn(label: Text('Address')),
          ],
          rows: records.map((record) {
            return DataRow(cells: [
              DataCell(Text(record.user.name)),
              DataCell(
                  Text(DateFormat('dd/MM HH:mm').format(record.checkInTime))),
              DataCell(Text(record.checkOutTime != null
                  ? DateFormat('dd/MM HH:mm').format(record.checkOutTime!)
                  : 'N/A')),
              DataCell(Text(record.address, overflow: TextOverflow.ellipsis)),
            ]);
          }).toList(),
        );
      },
    );
  }
}
