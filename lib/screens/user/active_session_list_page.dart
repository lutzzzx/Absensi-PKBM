import 'package:absensi_pkbm/screens/admin/session_detail_page.dart';
import 'package:absensi_pkbm/screens/widgets/confirmation_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActiveSessionListPage extends StatelessWidget {
  Future<void> _checkIn(BuildContext context, String sessionId, bool isPresent, {String? password}) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    String fullName = userDoc['fullName'] ?? 'Unknown';

    DocumentSnapshot session = await FirebaseFirestore.instance.collection('sessions').doc(sessionId).get();
    if (!session.exists) return;

    List attendees = List.from(session['attendees'] ?? []);
    bool isActive = session['isActive'] ?? false;
    bool isTimeRestricted = session['isTimeRestricted'] ?? false;
    bool isPasswordEnabled = session['isPasswordEnabled'] ?? false;

    if (!isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sesi ini tidak aktif')),
      );
      return;
    }

    if (isTimeRestricted) {
      DateTime now = DateTime.now();
      DateTime sessionDate = DateTime.parse(session['date']);

      TimeOfDay startTime = TimeOfDay(
        hour: int.parse(session['startTime'].split(':')[0]),
        minute: int.parse(session['startTime'].split(':')[1]),
      );
      TimeOfDay endTime = TimeOfDay(
        hour: int.parse(session['endTime'].split(':')[0]),
        minute: int.parse(session['endTime'].split(':')[1]),
      );

      DateTime startDateTime = DateTime(
          sessionDate.year, sessionDate.month, sessionDate.day, startTime.hour, startTime.minute);
      DateTime endDateTime = DateTime(
          sessionDate.year, sessionDate.month, sessionDate.day, endTime.hour, endTime.minute);

      if (now.isBefore(startDateTime) || now.isAfter(endDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Absensi hanya dapat dilakukan dalam rentang waktu yang ditentukan')),
        );
        return;
      }
    }

    if (isPasswordEnabled && !isPresent && password == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password diperlukan untuk absensi')),
      );
      return;
    }

    if (isPasswordEnabled && !isPresent && password != session['password']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password salah')),
      );
      return;
    }

    if (isPresent) {
      attendees.removeWhere((attendee) => attendee['email'] == user.email);
      await FirebaseFirestore.instance.collection('sessions').doc(sessionId).update({
        'attendees': attendees,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kehadiran dibatalkan')),
      );
    } else {
      attendees.add({
        'name': fullName,
        'email': user.email,
        'timestamp': DateTime.now().toIso8601String(),
      });
      await FirebaseFirestore.instance.collection('sessions').doc(sessionId).update({
        'attendees': attendees,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Absensi berhasil')),
      );
    }
  }

  Future<void> _showPasswordDialog(BuildContext context, String sessionId, bool isPresent) async {
    TextEditingController passwordController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Masukkan Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(hintText: 'Password'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _checkIn(context, sessionId, isPresent, password: passwordController.text);
              },
              child: Text('Konfirmasi'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCancelConfirmationDialog(BuildContext context, String sessionId) async {
    return showDialog(
      context: context,
      builder: (context) {
        return ConfirmationDialog(
          title: 'Konfirmasi Pembatalan',
          message: 'Apakah Anda yakin ingin membatalkan kehadiran?',
          cancelButtonText: 'Batal',
          confirmButtonText: 'Ya',
          confirmButtonColor: Colors.red,
          onConfirm: () async {
            // Panggil fungsi _checkIn dengan isPresent = true
            await _checkIn(context, sessionId, true);
            // Tutup dialog setelah fungsi selesai
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  bool _isUserPresent(DocumentSnapshot session) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    List attendees = session['attendees'] ?? [];
    return attendees.any((attendee) => attendee['email'] == user.email);
  }

  Future<void> _refreshData(BuildContext context) async {
    // Fungsi untuk refresh data
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data sedang diperbarui...')),
    );
  }

  Future<String?> _getUserPackage() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return userDoc['package'] ?? 'Paket A'; // Default ke Paket A jika tidak ada data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<String?>(
        future: _getUserPackage(),
        builder: (context, packageSnapshot) {
          if (!packageSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          String? userPackage = packageSnapshot.data;

          return StreamBuilder(
            stream: FirebaseFirestore.instance.collection('sessions').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              var sessions = snapshot.data!.docs.where((session) {
                bool isActive = session['isActive'] ?? false;
                bool isTimeRestricted = session['isTimeRestricted'] ?? false;
                String sessionPackage = session['package'] ?? 'Paket A';

                // Filter berdasarkan paket pengguna
                if (sessionPackage != userPackage) return false;

                if (!isActive) return false;

                if (isTimeRestricted) {
                  DateTime now = DateTime.now();
                  DateTime sessionDate = DateTime.parse(session['date']);

                  TimeOfDay startTime = TimeOfDay(
                    hour: int.parse(session['startTime'].split(':')[0]),
                    minute: int.parse(session['startTime'].split(':')[1]),
                  );
                  TimeOfDay endTime = TimeOfDay(
                    hour: int.parse(session['endTime'].split(':')[0]),
                    minute: int.parse(session['endTime'].split(':')[1]),
                  );

                  DateTime startDateTime = DateTime(
                      sessionDate.year, sessionDate.month, sessionDate.day, startTime.hour, startTime.minute);
                  DateTime endDateTime = DateTime(
                      sessionDate.year, sessionDate.month, sessionDate.day, endTime.hour, endTime.minute);

                  return now.isAfter(startDateTime) && now.isBefore(endDateTime);
                }

                return true;
              }).toList();

              return Column(
                children: [
                  // Tombol Refresh
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ElevatedButton.icon(
                      onPressed: () => _refreshData(context),
                      icon: Icon(Icons.refresh),
                      label: Text('Refresh Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        minimumSize: Size(double.infinity, 48), // Full width
                      ),
                    ),
                  ),
                  // Keterangan jika tidak ada data
                  if (sessions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                        child: Text(
                          'Tidak ada sesi aktif untuk paket Anda saat ini.',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  // ListView untuk menampilkan sesi
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: ListView(
                        children: sessions.map((session) {
                          bool hasTime = session['startTime'] != null && session['endTime'] != null;
                          bool isUserPresent = _isUserPresent(session);

                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isUserPresent ? Colors.white : Colors.white, // Warna border sesuai status kehadiran
                                width: 0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 3,
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Status Hadir atau Belum Hadir di atas judul
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isUserPresent ? Colors.green[50] : Colors.red[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isUserPresent ? Icons.check_circle : Icons.cancel,
                                          color: isUserPresent ? Colors.green : Colors.red,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          isUserPresent ? 'Sudah Hadir' : 'Belum Hadir',
                                          style: TextStyle(
                                            color: isUserPresent ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  // Judul sesi
                                  Text(
                                    session['title'],
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),
                                  // Tanggal sesi
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                      SizedBox(width: 8),
                                      Text(
                                        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.parse(session['date'])),
                                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  // Waktu sesi (jika ada)
                                  if (hasTime)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                          SizedBox(width: 8),
                                          Text(
                                            '${session['startTime']} - ${session['endTime']}',
                                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  SizedBox(height: 12),
                                  // Tombol Konfirmasi Kehadiran atau Batalkan Kehadiran
                                  ElevatedButton(
                                    onPressed: () {
                                      User? user = FirebaseAuth.instance.currentUser;
                                      if (user == null) return;

                                      List attendees = session['attendees'] ?? [];
                                      bool isPresent = attendees.any((attendee) => attendee['email'] == user.email);

                                      if (isPresent) {
                                        _showCancelConfirmationDialog(context, session.id); // Tampilkan dialog konfirmasi
                                      } else if (session['isPasswordEnabled'] ?? false) {
                                        _showPasswordDialog(context, session.id, isPresent);
                                      } else {
                                        _checkIn(context, session.id, isPresent);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isUserPresent ? Colors.red[50] : Colors.green[50],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                      minimumSize: Size(double.infinity, 48), // Full width
                                    ),
                                    child: Text(
                                      isUserPresent ? 'Batalkan Kehadiran' : 'Konfirmasi Kehadiran',
                                      style: TextStyle(
                                        color: isUserPresent ? Colors.red : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}