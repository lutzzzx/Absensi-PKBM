import 'package:absensi_pkbm/screens/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:absensi_pkbm/screens/profile_screen.dart'; // Sesuaikan dengan path yang benar
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountSettingsScreen extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan Akun'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomButton(
              text: 'Ubah Email',
              onPressed: () => _updateEmail(context),
              isFullWidth: true,
            ),
            SizedBox(height: 16),
            CustomButton(
              text: 'Ubah Nama',
              onPressed: () => _updateFullName(context),
              isFullWidth: true,
            ),
            SizedBox(height: 16),
            CustomButton(
              text: 'Ubah Paket',
              onPressed: () => _updatePackage(context),
              isFullWidth: true,
            ),
            SizedBox(height: 16),
            CustomButton(
              text: 'Reset Kata Sandi',
              onPressed: () => _resetPassword(context),
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk reset password
  Future<void> _resetPassword(BuildContext context) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email reset kata sandi telah dikirim ke ${user!.email}')),
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
                  await user!.verifyBeforeUpdateEmail(newEmail);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Email verifikasi telah dikirim ke $newEmail. Silakan verifikasi email baru.')),
                  );
                  Navigator.pop(context);
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

  // Fungsi untuk mengubah nama (fullname)
  Future<void> _updateFullName(BuildContext context) async {
    final fullNameController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ubah Nama'),
          content: TextField(
            controller: fullNameController,
            decoration: InputDecoration(labelText: 'Nama Lengkap'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final newFullName = fullNameController.text.trim();
                if (newFullName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nama tidak boleh kosong')),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                    'fullName': newFullName,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nama berhasil diperbarui')),
                  );

                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal memperbarui nama: $e')),
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

  // Fungsi untuk mengubah package
  Future<void> _updatePackage(BuildContext context) async {
    String? selectedPackage;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ubah Paket'),
          content: DropdownButtonFormField<String>(
            value: selectedPackage,
            items: ['Paket A', 'Paket B', 'Paket C'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              selectedPackage = newValue;
            },
            decoration: InputDecoration(labelText: 'Pilih Paket'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                if (selectedPackage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Silakan pilih paket')),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                    'package': selectedPackage,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Paket berhasil diperbarui')),
                  );

                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal memperbarui paket: $e')),
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
}