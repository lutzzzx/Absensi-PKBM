import 'package:absensi_pkbm/screens/widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FullSessionListPage extends StatefulWidget {
  @override
  _FullSessionListPageState createState() => _FullSessionListPageState();
}

class _FullSessionListPageState extends State<FullSessionListPage> {
  String _searchQuery = '';
  DateTime? _selectedDate;

  bool _isUserPresent(DocumentSnapshot session) {
    User? user = FirebaseAuth.instance.currentUser ;
    if (user == null) return false;

    List attendees = session['attendees'] ?? [];
    return attendees.any((attendee) => attendee['email'] == user.email);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Bar with Date Filter
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari sesi...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16),
                      SizedBox(width: 4),
                      Text(
                        _selectedDate == null
                            ? 'Tanggal'
                            : DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate!),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                if (_selectedDate != null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                      });
                    },
                    icon: Icon(Icons.clear, color: Colors.red),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('sessions').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var sessions = snapshot.data!.docs;

                // Filter sessions based on search query and selected date
                var filteredSessions = sessions.where((session) {
                  String title = session['title'].toString().toLowerCase();
                  DateTime sessionDate = DateTime.parse(session['date']);

                  bool matchesSearch = title.contains(_searchQuery);
                  bool matchesDate = _selectedDate == null ||
                      DateFormat('yyyy-MM-dd').format(sessionDate) ==
                          DateFormat('yyyy-MM-dd').format(_selectedDate!);

                  return matchesSearch && matchesDate;
                }).toList();

                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListView(
                    children: filteredSessions.map((session) {
                      bool hasTime = session['startTime'] != null && session['endTime'] != null;
                      bool isUserPresent = _isUserPresent(session);

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isUserPresent ? Colors.white : Colors.white,
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
                                      isUserPresent ? 'Hadir' : 'Tidak Hadir',
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
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}