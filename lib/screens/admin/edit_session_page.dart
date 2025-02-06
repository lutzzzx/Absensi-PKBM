import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditSessionPage extends StatefulWidget {
  final String sessionId;

  EditSessionPage({required this.sessionId});

  @override
  _EditSessionPageState createState() => _EditSessionPageState();
}

class _EditSessionPageState extends State<EditSessionPage> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isTimeRestricted = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    DocumentSnapshot sessionDoc =
    await FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId).get();
    if (sessionDoc.exists) {
      Map<String, dynamic> data = sessionDoc.data() as Map<String, dynamic>;
      setState(() {
        _titleController.text = data['title'] ?? '';
        _selectedDate = data['date'] != null ? DateTime.parse(data['date']) : null;
        _isTimeRestricted = data['isTimeRestricted'] ?? false;
        _isActive = data['isActive'] ?? true;
        _startTime = data['startTime'] != null
            ? _parseTimeOfDay(data['startTime'])
            : null;
        _endTime = data['endTime'] != null
            ? _parseTimeOfDay(data['endTime'])
            : null;
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
      });
    }
  }

  Future<void> _pickTime(bool isStartTime) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return time.hour.toString().padLeft(2, '0') + ':' + time.minute.toString().padLeft(2, '0');
  }

  Future<void> _updateSession() async {
    if (_titleController.text.isEmpty || _selectedDate == null) {
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
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Sesi Absensi')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Judul Kegiatan'),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text(_selectedDate == null ? 'Pilih Tanggal' : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
                IconButton(icon: Icon(Icons.calendar_today), onPressed: _pickDate),
              ],
            ),
            SwitchListTile(
              title: Text('Batasi Waktu Absensi'),
              value: _isTimeRestricted,
              onChanged: (value) {
                setState(() {
                  _isTimeRestricted = value;
                });
              },
            ),
            if (_isTimeRestricted) ...[
              Row(
                children: [
                  Text(_startTime == null ? 'Pilih Waktu Mulai' : _formatTime(_startTime!)),
                  IconButton(icon: Icon(Icons.access_time), onPressed: () => _pickTime(true)),
                ],
              ),
              Row(
                children: [
                  Text(_endTime == null ? 'Pilih Waktu Selesai' : _formatTime(_endTime!)),
                  IconButton(icon: Icon(Icons.access_time), onPressed: () => _pickTime(false)),
                ],
              ),
            ],
            SwitchListTile(
              title: Text('Sesi Aktif'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _updateSession, child: Text('Update Sesi')),
          ],
        ),
      ),
    );
  }
}
