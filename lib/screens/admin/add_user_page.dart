import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddUserPage extends StatefulWidget {
  @override
  _AddUserPageState createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  Future<void> _addUser() async {
    setState(() {
      _isLoading = true;
    });

    final currentUser = _auth.currentUser;
    final currentEmail = currentUser?.email;
    final currentPassword = 'halo@gmail.com'; // Ubah ini dengan cara yang aman

    try {
      // Re-authenticate current user
      final credential = EmailAuthProvider.credential(
        email: currentEmail ?? '',
        password: currentPassword,
      );
      await currentUser?.reauthenticateWithCredential(credential);

      // Create a new user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Add the user to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Log out from the newly created user
      await _auth.signOut();

      // Log back in as the original user
      await _auth.signInWithEmailAndPassword(
        email: currentEmail ?? '',
        password: currentPassword,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pengguna berhasil ditambahkan!')),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambah pengguna: ${e.message}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Pengguna'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(labelText: 'Nama Lengkap'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Kata Sandi'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _addUser,
              child: Text('Tambah Pengguna'),
            ),
          ],
        ),
      ),
    );
  }
}