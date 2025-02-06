import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSessionListPage extends StatelessWidget {
  Future<void> _checkIn(BuildContext context, String sessionId, bool isPresent) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Ambil data pengguna dari Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    String fullName = userDoc['fullName'] ?? 'Unknown';

    DocumentSnapshot session = await FirebaseFirestore.instance.collection('sessions').doc(sessionId).get();
    if (!session.exists) return;

    List attendees = List.from(session['attendees'] ?? []);
    bool isActive = session['isActive'] ?? false;
    bool isTimeRestricted = session['isTimeRestricted'] ?? false;

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

    if (isPresent) {
      // Batalkan kehadiran dengan menghapus entri berdasarkan email
      attendees.removeWhere((attendee) => attendee['email'] == user.email);

      await FirebaseFirestore.instance.collection('sessions').doc(sessionId).update({
        'attendees': attendees,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kehadiran dibatalkan')),
      );
    } else {
      // Tambahkan pengguna ke daftar attendees
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('List Sesi Absensi')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('sessions').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var sessions = snapshot.data!.docs;
          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              var session = sessions[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  title: Text(session['title']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(session['date']))),
                      SizedBox(height: 4.0),
                      Row(
                        children: [
                          _buildAttendanceStatus(session),
                          SizedBox(width: 8.0),
                          ElevatedButton(
                            onPressed: () {
                              User? user = FirebaseAuth.instance.currentUser;
                              if (user == null) return;

                              List attendees = session['attendees'] ?? [];
                              bool isPresent = attendees.any((attendee) => attendee['email'] == user.email);
                              _checkIn(context, session.id, isPresent);
                            },
                            child: Text(
                              _isUserPresent(session) ? 'Batalkan Hadir' : 'Hadir',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool _isUserPresent(DocumentSnapshot session) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    List attendees = session['attendees'] ?? [];
    return attendees.any((attendee) => attendee['email'] == user.email);
  }

  Widget _buildAttendanceStatus(DocumentSnapshot session) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return Icon(Icons.help_outline);

    List attendees = session['attendees'] ?? [];
    bool isPresent = attendees.any((attendee) => attendee['email'] == user.email);
    return Icon(isPresent ? Icons.check_circle : Icons.cancel, color: isPresent ? Colors.green : Colors.red);
  }
}