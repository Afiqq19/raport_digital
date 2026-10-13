import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// WAJIB: UNTUK FORMAT TANGGAL & RUPIAH (Solusi Layar Merah)
import 'package:intl/date_symbol_data_local.dart'; 

// IMPORT SESSION MANAGER 
import 'services/session_manager.dart';

// --- TAMBAHAN PENTING AGAR WEB BISA JALAN ---
import 'firebase_options.dart'; 
// ---------------------------------------------

// Halaman Login
import 'login_page.dart';

// Halaman Admin
import 'pages/admin/admin_home.dart';
import 'pages/admin/guru/guru_page.dart';
import 'pages/admin/siswa/admin_siswa_page.dart';
import 'pages/admin/siswa/admin_siswa_add.dart';
import 'pages/admin/siswa/admin_siswa_edit.dart';
import 'pages/admin/siswa/admin_alumni_page.dart';         
import 'pages/admin/siswa/admin_kenaikan_kelas_page.dart'; 
import 'pages/admin/ortu/ortu_page.dart';                  
import 'pages/admin/kelas/kelas_page.dart';                
import 'pages/admin/jadwal/admin_jadwal_page.dart';        
import 'pages/admin/setting/admin_atur_akademik_page.dart';
import 'pages/admin/pengumuman/admin_pengumuman_page.dart'; 
import 'pages/admin/keuangan/admin_tagihan_page.dart';      

// Halaman Dashboard User
import 'pages/guru/guru_home.dart';
import 'pages/siswa/siswa_home.dart';
import 'pages/orangtua/ortu_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- BAGIAN INI YANG DIUBAH AGAR SUPPORT WEB ---
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // -----------------------------------------------
  
  // --- INISIALISASI FORMAT TANGGAL INDONESIA ---
  await initializeDateFormatting('id_ID', null); 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _checkUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginPage();
    }

    try {
      DocumentSnapshot snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!snap.exists) return const LoginPage();

      String role = snap['role'];

      switch (role) {
        case "admin":
          return const AdminHome();
        case "guru":
          return const GuruHome();
        case "siswa":
          return const SiswaHome();
        case "ortu":
          return const OrtuHome();
        default:
          return const LoginPage();
      }
    } catch (e) {
      return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SessionTimeoutManager(
      duration: const Duration(minutes: 5), 
      child: MaterialApp(
        title: 'SIAKAD RAPORT DIGITAL',
        debugShowCheckedModeBanner: false,

        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xffF5F7FA),
        ),

        home: FutureBuilder(
          future: _checkUserRole(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return snapshot.data ?? const LoginPage();
          },
        ),

        routes: {
          '/login': (context) => const LoginPage(),

          // ADMIN
          '/admin': (context) => const AdminHome(),
          '/admin/guru': (context) => const GuruPage(),
          '/admin/siswa': (context) => const AdminSiswaPage(),
          '/admin/siswa/add': (context) => const AdminSiswaAdd(),
          '/admin/siswa/edit': (context) {
            final sid = ModalRoute.of(context)!.settings.arguments as String;
            return AdminSiswaEdit(sid: sid);
          },
          '/admin/ortu': (context) => const OrtuPage(),
          '/admin/kelas': (context) => const KelasPage(),
          '/admin/jadwal': (context) => const AdminJadwalPage(),
          '/admin/setting_akademik': (context) => const AdminAturAkademikPage(),
          '/admin/kenaikan_kelas': (context) => const AdminKenaikanKelasPage(),
          '/admin/alumni': (context) => const AdminAlumniPage(),
          '/admin/pengumuman': (context) => const AdminPengumumanPage(),
          '/admin/keuangan': (context) => const AdminTagihanPage(),

          // USER LAIN
          '/guru': (context) => const GuruHome(),
          '/siswa': (context) => const SiswaHome(),
          '/orangtua': (context) => const OrtuHome(),
          '/ortu': (context) => const OrtuHome(), 
        },
      ),
    );
  }
}