import 'package:absensi_pkbm/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_screen.dart'; // Import halaman utama

class WaitingScreen extends StatefulWidget {
  @override
  _WaitingScreenState createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  final _auth = FirebaseAuth.instance;
  bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  void _checkEmailVerification() async {
    // Muat ulang status pengguna
    await _auth.currentUser?.reload();

    // Periksa apakah email sudah diverifikasi
    if (mounted) {
      setState(() {
        _isEmailVerified = _auth.currentUser?.emailVerified ?? false;
      });
    }

    if (_isEmailVerified) {
      // Jika email sudah diverifikasi, arahkan ke MainScreen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      }
    } else {
      // Jika belum, periksa lagi setelah 5 detik
      Future.delayed(Duration(seconds: 5), _checkEmailVerification);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animasi ikon email
              AnimatedSwitcher(
                duration: Duration(seconds: 2),
                child: _isEmailVerified
                    ? Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 100,
                )
                    : Icon(
                  Icons.email,
                  color: Colors.blue,
                  size: 100,
                ),
              ),
              SizedBox(height: 30),
              // Teks dengan animasi fade
              AnimatedOpacity(
                opacity: 1.0,
                duration: Duration(seconds: 1),
                child: Text(
                  _isEmailVerified
                      ? 'Email Anda telah diverifikasi!'
                      : 'Silakan verifikasi email Anda.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20),
              // Indikator loading dengan animasi
              if (!_isEmailVerified)
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              SizedBox(height: 30),
              // Tombol kembali dengan desain modern
              OutlinedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text(
                  'Kembali',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}