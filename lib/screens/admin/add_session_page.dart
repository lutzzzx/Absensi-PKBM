import 'package:absensi_pkbm/screens/widgets/build_input_card.dart';
import 'package:absensi_pkbm/screens/widgets/build_switch_tile.dart';
import 'package:absensi_pkbm/screens/widgets/custom_button.dart';
import 'package:absensi_pkbm/screens/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddSessionPage extends StatefulWidget {
  @override
  _AddSessionPageState createState() => _AddSessionPageState();
}

class _AddSessionPageState extends State<AddSessionPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isTimeRestricted = false;
  bool _isActive = true;
  bool _isPasswordEnabled = false;

  // Variabel untuk menyimpan pilihan paket
  String? _selectedPackage;
  final List<String> _packages = ['Paket A', 'Paket B', 'Paket C', 'Tutor'];

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
      initialTime: TimeOfDay.now(),
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

  Future<void> _saveSession() async {
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

    await FirebaseFirestore.instance.collection('sessions').add({
      'title': _titleController.text,
      'date': _selectedDate!.toIso8601String(),
      'startTime': _isTimeRestricted ? _formatTime(_startTime!) : null,
      'endTime': _isTimeRestricted ? _formatTime(_endTime!) : null,
      'isTimeRestricted': _isTimeRestricted,
      'isActive': _isActive,
      'isPasswordEnabled': _isPasswordEnabled,
      'password': _isPasswordEnabled ? _passwordController.text : null,
      'attendees': [],
      'package': _selectedPackage, // Simpan pilihan paket
      'createdAt': FieldValue.serverTimestamp(), // Tambahkan waktu dibuatnya sesi
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Sesi Absensi'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card untuk Judul dan Tanggal
              BuildInputCard(
                child: Column(
                  children: [
                    CustomTextFormField (
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
              // Dropdown untuk memilih paket PKBM
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
                        obscureText: true,
                        keyboardType: TextInputType.text,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Tombol Simpan Sesi
              Center(
                child: CustomButton(
                  text: 'Simpan Sesi',
                  onPressed: _saveSession,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}