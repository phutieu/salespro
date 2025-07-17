import 'package:flutter/material.dart';
import 'package:salespro/admin/mock_data.dart';
import 'package:salespro/admin/models/user.dart';
import 'package:salespro/admin/widgets/user_form.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late List<User> _users;

  @override
  void initState() {
    super.initState();
    _users = List.from(mockUsers);
  }

  void _showUserForm(BuildContext context, {User? user}) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return UserForm(
            user: user,
            onSave: (savedUser) {
              setState(() {
                if (user == null) {
                  _users.add(savedUser);
                } else {
                  final index = _users.indexWhere((u) => u.id == savedUser.id);
                  if (index != -1) {
                    _users[index] = savedUser;
                  }
                }
              });
            },
          );
        });
  }

  void _toggleUserStatus(User user) {
    setState(() {
      user.isActive = !user.isActive;
    });
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
            'User Management',
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
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _users.map((user) {
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
                            _showUserForm(context, user: user);
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
                            _toggleUserStatus(user);
                          },
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
