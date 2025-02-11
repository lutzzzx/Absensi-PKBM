import 'package:absensi_pkbm/screens/widgets/custom_fab.dart';
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
  String? sessionPackage;
  bool isLoading = true; // Tambahkan variabel untuk menandai status loading

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      // Ambil data sesi untuk mendapatkan package
      DocumentSnapshot sessionSnapshot = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .get();

      if (sessionSnapshot.exists) {
        setState(() {
          sessionPackage = sessionSnapshot['package']; // Simpan package dari sesi
        });
      }

      // Ambil data pengguna yang memiliki package yang sama dengan sesi
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('package', isEqualTo: sessionPackage) // Filter berdasarkan package
          .get();

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
        isLoading = false; // Set loading ke false setelah data dimuat
      });
    } catch (e) {
      setState(() {
        isLoading = false; // Set loading ke false jika terjadi error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    }
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

    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .update({
      'attendees': updatedAttendees,
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Absensi diperbarui')));

    // Kembali ke halaman sebelumnya setelah menyimpan
    Navigator.pop(context);
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
            child: isLoading
                ? Center(child: CircularProgressIndicator()) // Tampilkan loading jika masih memuat
                : _buildAttendanceList(),
          ),
        ],
      ),
      floatingActionButton: CustomFAB(
        onPressed: _updateAttendance,
        icon: Icons.save,
        text: 'Simpan Kehadiran',
      ),
    );
  }

  Widget _buildAttendanceList() {
    final filteredEntries = attendanceStatus.entries
        .where((entry) =>
    userNames[entry.key]?.toLowerCase().contains(searchQuery) ?? false)
        .toList();

    if (filteredEntries.isEmpty) {
      return Center(child: Text('Tidak ada data')); // Tampilkan pesan jika tidak ada data
    }

    return ListView(
      children: filteredEntries.map((entry) {
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
    );
  }
}