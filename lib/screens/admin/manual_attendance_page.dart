import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManualAttendancePage extends StatefulWidget {
  final String sessionId;

  ManualAttendancePage({required this.sessionId});

  @override
  _ManualAttendancePageState createState() => _ManualAttendancePageState();
}

class _ManualAttendancePageState extends State<ManualAttendancePage> {
  Map<String, bool> attendanceStatus = {};
  Map<String, String> userNames = {};
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    DocumentSnapshot sessionSnapshot = await FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId).get();

    List attendees = sessionSnapshot.exists ? (sessionSnapshot['attendees'] ?? []) : [];
    Map<String, bool> initialStatus = {};
    Map<String, String> names = {};

    for (var user in usersSnapshot.docs) {
      String email = user['email'] ?? '';
      String fullName = user['fullName'] ?? 'Nama tidak tersedia';
      names[email] = fullName;
      initialStatus[email] = attendees.any((attendee) => attendee['email'] == email);
    }

    setState(() {
      attendanceStatus = initialStatus;
      userNames = names;
    });
  }

  Future<void> _updateAttendance() async {
    List<Map<String, String>> updatedAttendees = attendanceStatus.entries
        .where((entry) => entry.value)
        .map((entry) => {
      'name': userNames[entry.key] ?? 'Nama tidak tersedia',
      'email': entry.key,
      'timestamp': DateTime.now().toIso8601String()
    })
        .toList();

    await FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId).update({
      'attendees': updatedAttendees,
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Absensi diperbarui')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Absensi Manual')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Cari pengguna',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: attendanceStatus.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView(
              children: attendanceStatus.entries
                  .where((entry) => userNames[entry.key]?.toLowerCase().contains(searchQuery) ?? false)
                  .map((entry) {
                return CheckboxListTile(
                  title: Text(userNames[entry.key] ?? entry.key),
                  subtitle: Text(entry.key),
                  value: entry.value,
                  onChanged: (bool? value) {
                    setState(() {
                      attendanceStatus[entry.key] = value ?? false;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateAttendance,
        child: Icon(Icons.save),
      ),
    );
  }
}