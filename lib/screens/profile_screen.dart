import 'package:absensi_pkbm/screens/login_screen.dart';
import 'package:absensi_pkbm/screens/waiting_screen2.dart';
import 'package:absensi_pkbm/screens/widgets/confirmation_dialog.dart';
import 'package:absensi_pkbm/screens/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
      return Scaffold();
    }

    // Fungsi untuk reset password
    Future<void> _resetPassword(BuildContext context) async {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email reset kata sandi telah dikirim ke ${user.email}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim email reset: $e')),
        );
      }
    }

    // Fungsi untuk mengubah email
    Future<void> _updateEmail(BuildContext context) async {
      final newEmailController = TextEditingController();

      return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Ubah Email'),
            content: TextField(
              controller: newEmailController,
              decoration: InputDecoration(labelText: 'Email Baru'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  final newEmail = newEmailController.text.trim();
                  if (newEmail.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Email tidak boleh kosong')),
                    );
                    return;
                  }

                  try {
                    final user = FirebaseAuth.instance.currentUser ;

                    // Send verification email to the new address
                    await user!.verifyBeforeUpdateEmail(newEmail);

                    // Notify user that verification email has been sent
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Email verifikasi telah dikirim ke $newEmail. Silakan verifikasi email baru.')),
                    );

                    // Navigate to WaitingScreen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WaitingScreen2(
                          newEmail: newEmail,
                          oldEmail: user.email!,
                        ),
                      ),
                    );

                  } on FirebaseAuthException catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal memperbarui email: ${e.message}')),
                    );
                  }
                },
                child: Text('Simpan'),
              ),
            ],
          );
        },
      );
    }

    // Fungsi untuk logout dengan konfirmasi
    Future<void> _logout(BuildContext context) async {
      return showDialog(
        context: context,
        builder: (context) {
          return ConfirmationDialog(
            title: 'Konfirmasi Logout',
            message: 'Apakah Anda yakin ingin logout?',
            cancelButtonText: 'Batal',
            confirmButtonText: 'Logout',
            onConfirm: () async {
              try {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal logout: $e')),
                );
              }
            },
          );
        },
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Center(child: Text('Error loading profile information')),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final fullName = userData['fullName'] ?? '-';

        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.transparent],
                // colors: [Colors.blue.shade800, Colors.blue.shade400],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Card(
                      margin: EdgeInsets.all(20),
                      elevation: 10,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Menampilkan foto profil jika tersedia
                            if (user.photoURL != null)
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: NetworkImage(user.photoURL!),
                              )
                            else
                              Icon(
                                Icons.account_circle,
                                size: 100,
                                color: Colors.blue.shade800,
                              ),
                            SizedBox(height: 20),
                            // Menampilkan nama lengkap dan email pengguna
                            Text('Nama: $fullName', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            SizedBox(height: 10),
                            Text('Email: ${user.email}', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                            SizedBox(height: 20),
                            CustomButton(
                              text: 'Reset Kata Sandi',
                              onPressed: () => _resetPassword(context),
                              isFullWidth: true,
                            ),
                            SizedBox(height: 16),
                            CustomButton(
                              text: 'Ubah Email',
                              onPressed: () => _updateEmail(context),
                              isFullWidth: true,
                            ),
                            SizedBox(height: 16),
                            CustomButton(
                              text: 'Logout',
                              onPressed: () => _logout(context),
                              isFullWidth: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Kredit dan informasi kontak bantuan
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Text(
                            'Made with ❤️ by',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                          Text(
                            'KKN UNSOED Desa Gumiwang 2025',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Jika butuh bantuan, silakan hubungi:',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                          Text(
                            'luthfiaz49@gmail.com',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}