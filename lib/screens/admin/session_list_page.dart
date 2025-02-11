import 'package:absensi_pkbm/screens/admin/edit_session_page.dart';
import 'package:absensi_pkbm/screens/admin/add_session_page.dart';
import 'package:absensi_pkbm/screens/admin/session_detail_page.dart';
import 'package:absensi_pkbm/screens/widgets/confirmation_dialog.dart';
import 'package:absensi_pkbm/screens/widgets/custom_fab.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SessionListPage extends StatefulWidget {
  @override
  _SessionListPageState createState() => _SessionListPageState();
}

class _SessionListPageState extends State<SessionListPage> {
  String _searchQuery = '';
  DateTime? _selectedDate;
  String _selectedPackage = 'All'; // Default to show all sessions

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

  void _deleteSession(BuildContext context, String sessionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          title: 'Konfirmasi Hapus',
          message: 'Apakah Anda yakin ingin menghapus sesi ini?',
          confirmButtonText: 'Hapus',
          confirmButtonColor: Colors.red,
          onConfirm: () async {
            await FirebaseFirestore.instance.collection('sessions').doc(sessionId).delete();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sesi berhasil dihapus'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }

  bool _isSessionActive(DocumentSnapshot session) {
    bool isActive = session['isActive'] ?? false;
    bool isTimeRestricted = session['isTimeRestricted'] ?? false;

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
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
          // Package Filter Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedPackage = 'All';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(50, 36), // Ukuran lebih kecil
                    backgroundColor: _selectedPackage == 'All' ? Colors.blue : Colors.grey[300],
                    elevation: 0, // Menghapus shadow
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Membuat rounded lebih besar
                    ),
                  ),
                  child: Text('Semua', style: TextStyle(color: _selectedPackage == 'All' ? Colors.white : Colors.black)),
                ),
                SizedBox(width: 5),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedPackage = 'Paket A';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(30, 36),
                    backgroundColor: _selectedPackage == 'Paket A' ? Colors.blue : Colors.grey[300],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('A', style: TextStyle(color: _selectedPackage == 'Paket A' ? Colors.white : Colors.black)),
                ),
                SizedBox(width: 5),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedPackage = 'Paket B';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(30, 36),
                    backgroundColor: _selectedPackage == 'Paket B' ? Colors.blue : Colors.grey[300],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('B', style: TextStyle(color: _selectedPackage == 'Paket B' ? Colors.white : Colors.black)),
                ),
                SizedBox(width: 5),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedPackage = 'Paket C';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(30, 36),
                    backgroundColor: _selectedPackage == 'Paket C' ? Colors.blue : Colors.grey[300],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('C', style: TextStyle(color: _selectedPackage == 'Paket C' ? Colors.white : Colors.black)),
                ),
                SizedBox(width: 5),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedPackage = 'Tutor';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(30, 36),
                    backgroundColor: _selectedPackage == 'Tutor' ? Colors.blue : Colors.grey[300],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Tutor', style: TextStyle(color: _selectedPackage == 'Tutor' ? Colors.white : Colors.black)),
                ),
              ],

            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('sessions')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var sessions = snapshot.data!.docs;

                // Filter sessions based on search query, selected date, and selected package
                var filteredSessions = sessions.where((session) {
                  String title = session['title'].toString().toLowerCase();
                  DateTime sessionDate = DateTime.parse(session['date']);
                  String package = session['package'] ?? '';

                  bool matchesSearch = title.contains(_searchQuery);
                  bool matchesDate = _selectedDate == null ||
                      DateFormat('yyyy-MM-dd').format(sessionDate) ==
                          DateFormat('yyyy-MM-dd').format(_selectedDate!);
                  bool matchesPackage = _selectedPackage == 'All' || package == _selectedPackage;

                  return matchesSearch && matchesDate && matchesPackage;
                }).toList();

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 12.0),
                  child: ListView(
                    children: filteredSessions.map((doc) {
                      bool isActive = _isSessionActive(doc);
                      bool isTimeRestricted = doc['isTimeRestricted'] ?? false;
                      bool hasTime = doc['startTime'] != null && doc['endTime'] != null;

                      // Count the number of attendees
                      int attendeeCount = (doc['attendees'] as List).length;

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 3,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SessionDetailPage(sessionId: doc.id),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      doc['title'],
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert, color: Colors.grey),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SessionDetailPage(sessionId: doc.id),
                                            ),
                                          );
                                        } else if (value == 'delete') {
                                          _deleteSession(context, doc.id);
                                        }
                                      },
                                      itemBuilder: (BuildContext context) {
                                        return [
                                          PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Text('Hapus', style: TextStyle(color: Colors.red)),
                                          ),
                                        ];
                                      },
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                    SizedBox(width: 8),
                                    Text(
                                      DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.parse(doc['date'])),
                                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                if (isTimeRestricted && hasTime)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Row(
                                      children: [
                                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                        SizedBox(width: 8),
                                        Text(
                                          '${doc['startTime']} - ${doc['endTime']}',
                                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isActive ? Colors.green[50] : Colors.red[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isActive ? Icons.check_circle : Icons.cancel,
                                            color: isActive ? Colors.green : Colors.red,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            isActive ? 'Aktif' : 'Tidak Aktif',
                                            style: TextStyle(
                                              color: isActive ? Colors.green : Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.people, color: Colors.blue, size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            '$attendeeCount Siswa Hadir',
                                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.purple[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.class_, color: Colors.purple, size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            '${doc['package']}',
                                            style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
      floatingActionButton: CustomFAB(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddSessionPage()),
          );
        },
        icon: Icons.add,
        text: 'Tambah Sesi',
      ),
    );
  }
}