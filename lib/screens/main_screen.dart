import 'package:absensi_pkbm/screens/admin/session_list_page.dart';
import 'package:absensi_pkbm/screens/admin/user_management_page.dart';
import 'package:absensi_pkbm/screens/profile_screen.dart';
import 'package:absensi_pkbm/screens/user/active_session_list_page.dart';
import 'package:absensi_pkbm/screens/user/full_session_list_page.dart';
import 'package:absensi_pkbm/screens/user/user_session_list_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'waiting_screen.dart'; // Import WaitingScreen

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String _role = ''; // Menyimpan peran pengguna
  bool _isLoading = true; // Menandakan apakah sedang memeriksa data pengguna
  String _userName = ''; // Menyimpan nama pengguna

  // Halaman untuk "user"
  static List<Widget> _userPages = <Widget>[
    ActiveSessionListPage(),
    FullSessionListPage(),
    ProfileScreen(),
  ];

  // Halaman untuk "admin"
  static List<Widget> _adminPages = <Widget>[
    SessionListPage(),
    UserManagementPage(),
    const Text('Laporan'),
    ProfileScreen(),
  ];

  static const List<String> _userPageTitles = [
    'Absensi PKBM',
    'Daftar Sesi',
    'Profil Saya',
    'Daftar Kunjungan',
    'Kalkulator Tubuh',
  ];

  static const List<String> _adminPageTitles = [
    'Dashboard Admin',
    'Manajemen Pengguna',
    'Manajemen Obat',
    'Laporan Kunjungan',
    'Pengaturan Admin',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkUserData();
  }

  Future<void> _checkUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Jika tidak ada pengguna yang login, arahkan ke LoginScreen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
      return;
    }

    try {
      // Ambil data pengguna dari Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // Jika data pengguna tidak ada, arahkan ke WaitingScreen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => WaitingScreen()),
          );
        });
        return;
      }

      // Jika data pengguna ada, set peran pengguna dan nama
      setState(() {
        _role = userDoc.data()!['role'] ?? 'user'; // Default ke "user"
        _userName = userDoc.data()!['fullName'] ?? 'Pengguna'; // Default ke "Pengguna"
        _isLoading = false; // Selesai memuat
      });
    } catch (e) {
      print('Gagal memeriksa data pengguna: $e');
      setState(() {
        _isLoading = false; // Selesai memuat meskipun ada error
      });
    }
  }

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

    // Jika masih memuat, tampilkan indikator loading
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isUser = _role == 'user';
    final pages = isUser ? _userPages : _adminPages;
    final titles = isUser ? _userPageTitles : _adminPageTitles;

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0, // Menghilangkan bayangan AppBar
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                'Hai, $_userName',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: isUser
            ? <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_fill), // Ikon untuk sesi aktif
            label: 'Sesi Aktif',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list), // Ikon untuk daftar sesi
            label: 'Daftar Sesi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), // Ikon untuk profil
            label: 'Profil',
          ),
        ]
            : <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Pengguna',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}