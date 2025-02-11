import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'waiting_screen.dart';
import 'login_screen.dart';
import 'package:absensi_pkbm/screens/widgets/custom_button.dart';
import 'package:absensi_pkbm/screens/widgets/custom_text_form_field.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _acceptTerms = false;
  String? _selectedPackage;
  final List<String> _packageOptions = ['Paket A', 'Paket B', 'Paket C', 'Tutor'];

  void _registerWithEmailPassword() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (_fullNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Full Name is required')),
      );
      return;
    }

    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silakan pilih paket PKBM')),
      );
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      await userCredential.user?.sendEmailVerification();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WaitingScreen()),
      );

      await _waitForEmailVerification(userCredential.user!);

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'fullName': _fullNameController.text,
        'email': _emailController.text,
        'role': 'user',
        'package': _selectedPackage,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _waitForEmailVerification(User user) async {
    while (!user.emailVerified) {
      await Future.delayed(Duration(seconds: 5));
      await user.reload();
      user = _auth.currentUser!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, size: 100, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    "Buat Akun Baru",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Pastikan email yang digunakan aktif untuk verifikasi",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 10,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          SizedBox(height: 10),
                          CustomTextFormField(
                            icon: Icon(Icons.person),
                            controller: _fullNameController,
                            labelText: 'Nama Lengkap',
                            keyboardType: TextInputType.text,
                          ),
                          CustomTextFormField(
                            icon: Icon(Icons.email),
                            controller: _emailController,
                            labelText: 'Email',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          CustomTextFormField(
                            icon: Icon(Icons.lock),
                            controller: _passwordController,
                            labelText: 'Kata Sandi',
                            obscureText: true,
                          ),
                          CustomTextFormField(
                            icon: Icon(Icons.lock),
                            controller: _confirmPasswordController,
                            labelText: 'Konfirmasi Kata Sandi',
                            obscureText: true,
                          ),
                          CustomTextFormField(
                            icon: Icon(Icons.school), // Icon untuk prefix
                            controller: TextEditingController(), // Controller untuk menyimpan nilai
                            labelText: 'Pilih Paket PKBM', // Label untuk form field
                            dropdownItems: _packageOptions, // Daftar item dropdown
                            initialDropdownValue: _selectedPackage, // Nilai awal dropdown
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedPackage = newValue; // Update nilai yang dipilih
                              });
                            },
                          ),
                          SizedBox(height: 10),
                          CustomButton(text: 'Daftar', onPressed: _registerWithEmailPassword),
                          SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => LoginScreen()),
                              );
                            },
                            child: Text(
                              "Sudah punya akun? Login di sini",
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}