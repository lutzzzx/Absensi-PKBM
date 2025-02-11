import 'package:absensi_pkbm/screens/admin/manual_attendance_page.dart';
import 'package:absensi_pkbm/screens/widgets/build_input_card.dart';
import 'package:absensi_pkbm/screens/widgets/build_switch_tile.dart';
import 'package:absensi_pkbm/screens/widgets/custom_button.dart';
import 'package:absensi_pkbm/screens/widgets/custom_fab.dart';
import 'package:absensi_pkbm/screens/widgets/custom_text_form_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SessionDetailPage extends StatefulWidget {
  final String sessionId;

  SessionDetailPage({required this.sessionId});

  @override
  _SessionDetailPageState createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(); // Controller untuk password
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isTimeRestricted = false;
  bool _isActive = true;
  bool _isPasswordEnabled = false; // Status apakah password diaktifkan
  String? _selectedPackage;
  final List<String> _packages = ['Paket A', 'Paket B', 'Paket C', 'Tutor'];

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    DocumentSnapshot sessionDoc = await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .get();
    if (sessionDoc.exists) {
      Map<String, dynamic> data = sessionDoc.data() as Map<String, dynamic>;
      setState(() {
        _titleController.text = data['title'] ?? '';
        _selectedDate = data['date'] != null ? DateTime.parse(data['date']) : null;
        _dateController.text = _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : '';
        _isTimeRestricted = data['isTimeRestricted'] ?? false;
        _isActive = data['isActive'] ?? true;
        _startTime = data['startTime'] != null ? _parseTimeOfDay(data['startTime']) : null;
        _startTimeController.text = _startTime != null ? _formatTime(_startTime!) : '';
        _endTime = data['endTime'] != null ? _parseTimeOfDay(data['endTime']) : null;
        _endTimeController.text = _endTime != null ? _formatTime(_endTime!) : '';
        _isPasswordEnabled = data['isPasswordEnabled'] ?? false;
        _passwordController.text = data['password'] ?? '';
        _selectedPackage = data['package'] ?? 'Paket A'; // Muat data paket
      });
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickTime(bool isStartTime) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          _startTimeController.text = _formatTime(picked);
        } else {
          _endTime = picked;
          _endTimeController.text = _formatTime(picked);
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return time.hour.toString().padLeft(2, '0') + ':' + time.minute.toString().padLeft(2, '0');
  }

  Future<void> _updateSession() async {
    if (_titleController.text.isEmpty || _selectedDate == null || _selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lengkapi semua isian')),
      );
      return;
    }

    if (_isTimeRestricted && (_startTime == null || _endTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih waktu mulai dan selesai jika waktu dibatasi')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId).update({
      'title': _titleController.text,
      'date': _selectedDate!.toIso8601String(),
      'startTime': _isTimeRestricted ? _formatTime(_startTime!) : null,
      'endTime': _isTimeRestricted ? _formatTime(_endTime!) : null,
      'isTimeRestricted': _isTimeRestricted,
      'isActive': _isActive,
      'isPasswordEnabled': _isPasswordEnabled,
      'password': _isPasswordEnabled ? _passwordController.text : null,
      'package': _selectedPackage, // Simpan pilihan paket
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sesi berhasil diperbarui')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail dan Edit Sesi'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionId)
            .snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return Center(child: Text('No data found'));
          }

          List attendees = data['attendees'] ?? [];
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card untuk Judul dan Tanggal
                BuildInputCard(
                  child: Column(
                    children: [
                      CustomTextFormField(
                        icon: Icon(Icons.title, color: Colors.blue),
                        controller: _titleController,
                        labelText: 'Judul Kegiatan',
                        keyboardType: TextInputType.text,
                      ),
                      CustomTextFormField(
                        icon: Icon(Icons.calendar_today, color: Colors.blue),
                        controller: _dateController,
                        labelText: 'Tanggal',
                        readOnly: true,
                        onTap: _pickDate,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                BuildInputCard(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Pilih Paket PKBM',
                          icon: Icon(Icons.list, color: Colors.blue),
                        ),
                        value: _selectedPackage,
                        items: _packages.map((String package) {
                          return DropdownMenuItem<String>(
                            value: package,
                            child: Text(package),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedPackage = newValue;
                          });
                        },
                        validator: (value) => value == null ? 'Pilih paket' : null,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // Card untuk Switch Fields
                BuildInputCard(
                  child: Column(
                    children: [
                      BuildSwitchTile(
                        title: 'Sesi Aktif',
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                BuildInputCard(
                  child: Column(
                    children: [
                      BuildSwitchTile(
                        title: 'Batasi Waktu Absensi',
                        value: _isTimeRestricted,
                        onChanged: (value) {
                          setState(() {
                            _isTimeRestricted = value;
                          });
                        },
                      ),
                      if (_isTimeRestricted) ...[
                        SizedBox(height: 16),
                        CustomTextFormField(
                          icon: Icon(Icons.access_time, color: Colors.blue),
                          controller: _startTimeController,
                          labelText: 'Waktu Mulai',
                          readOnly: true,
                          onTap: () => _pickTime(true),
                        ),
                        CustomTextFormField(
                          icon: Icon(Icons.access_time, color: Colors.blue),
                          controller: _endTimeController,
                          labelText: 'Waktu Selesai',
                          readOnly: true,
                          onTap: () => _pickTime(false),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 20),
                BuildInputCard(
                  child: Column(
                    children: [
                      BuildSwitchTile(
                        title: 'Aktifkan Password',
                        value: _isPasswordEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isPasswordEnabled = value;
                          });
                        },
                      ),
                      if (_isPasswordEnabled) ...[
                        SizedBox(height: 16),
                        CustomTextFormField(
                          icon: Icon(Icons.password, color: Colors.blue),
                          controller: _passwordController,
                          labelText: 'Password',
                          obscureText: false,
                          keyboardType: TextInputType.text,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Card untuk Daftar Peserta
                BuildInputCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daftar Siswa Hadir:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 20),
                      CustomButton(
                        text: 'Absensi Manual',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManualAttendancePage(sessionId: widget.sessionId),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      ListView(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        children: attendees.map((attendee) {
                          if (attendee is Map<String, dynamic>) {
                            String name = attendee['name'] ?? 'No Name';
                            String email = attendee['email'] ?? 'No Email';
                            return ListTile(
                              title: Text(name),
                              subtitle: Text(email),
                            );
                          } else {
                            return ListTile(
                              title: Text('Invalid attendee data'),
                            );
                          }
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: CustomFAB(
        onPressed: _updateSession,
        icon: Icons.save,
        text: 'Update Sesi',
      ),

    );
  }
}