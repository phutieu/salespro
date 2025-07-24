import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:salespro/admin/models/user.dart';
import 'package:salespro/admin/widgets/user_form.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  void _showUserForm(BuildContext context, {DocumentSnapshot? doc}) {
    User? user;
    if (doc != null) {
      final data = doc.data() as Map<String, dynamic>;
      user = User.fromMap(data..['id'] = doc.id);
    }
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return UserForm(
            user: user,
            onSave: (savedUser) async {
              if (doc == null) {
                // Tạo user trên Firebase Auth với password mặc định
                try {
                  final userCredential = await auth.FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                    email: savedUser.email,
                    password: '123456',
                  );
                  final authUser = userCredential.user;
                  if (authUser != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(authUser.uid)
                        .set(savedUser.toMap()..['id'] = authUser.uid);
                  }
                } on auth.FirebaseAuthException catch (e) {
                  String message = 'Lỗi tạo tài khoản';
                  if (e.code == 'email-already-in-use') {
                    message = 'Email đã tồn tại trên hệ thống!';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                  return;
                }
              } else {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(doc.id)
                    .update(savedUser.toMap());
              }
              setState(() {});
            },
          );
        });
  }

  void _toggleUserStatus(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final user = User.fromMap(data..['id'] = doc.id);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(doc.id)
        .update({'isActive': !user.isActive});
    setState(() {});
  }

  String _getRoleText(UserRole role) {
    return role.toString().split('.').last;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Users',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              _showUserForm(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add User'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final user = User.fromMap(data..['id'] = doc.id);
                    return DataRow(cells: [
                      DataCell(Text(user.name)),
                      DataCell(Text(user.email)),
                      DataCell(Text(_getRoleText(user.role))),
                      DataCell(
                        Text(
                          user.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: user.isActive ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              _showUserForm(context, doc: doc);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              user.isActive
                                  ? Icons.lock_outline
                                  : Icons.lock_open,
                              color: user.isActive ? Colors.red : Colors.green,
                            ),
                            onPressed: () {
                              _toggleUserStatus(doc);
                            },
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
