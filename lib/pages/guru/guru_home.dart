import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// PENTING: Import halaman tujuan
import 'siswa/guru_siswa_kelas_page.dart';
import 'nilai/guru_pilih_kelas_nilai_page.dart';// Import halaman pilih kelas untuk input nilai
import 'jadwal/guru_jadwal_page.dart';
import 'profil/guru_profil_page.dart';

class GuruHome extends StatefulWidget {
  const GuruHome({super.key});

  @override
  State<GuruHome> createState() => _GuruHomeState();
}

class _GuruHomeState extends State<GuruHome> {
  User? user = FirebaseAuth.instance.currentUser;
  
  // Variabel untuk menampung data guru
  String nama = "Memuat...";
  String nip = "-";
  String mapelString = "-";
  String waliKelas = "-";

  @override
  void initState() {
    super.initState();
    _getDataGuru();
  }

  // Fungsi mengambil data dari Firestore berdasarkan UID Login
  Future<void> _getDataGuru() async {
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          if (mounted) {
            setState(() {
              nama = data['nama'] ?? "Guru";
              nip = data['nip'] ?? "-";
              waliKelas = data['wali_kelas_nama'] ?? "-";
              
              // Mengambil list mapel dan mengubahnya jadi string koma
              List<dynamic> mapelList = data['mapel'] ?? [];
              if (mapelList.isNotEmpty) {
                mapelString = mapelList.join(", ");
              } else {
                mapelString = "Belum ada mapel";
              }
            });
          }
        }
      } catch (e) {
        debugPrint("Error mengambil data guru: $e");
      }
    }
  }

  // Fungsi Logout
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA), // Background abu sangat muda
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ================= HEADER PROFIL =================
            Container(
              padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
              decoration: const BoxDecoration(
                color: Colors.teal, // Warna Tema Guru
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris Judul & Logout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Dashboard Guru",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.white),
                        tooltip: "Keluar",
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Kartu Profil Mini (Foto & Nama)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: Text(
                          nama.isNotEmpty ? nama[0].toUpperCase() : "G",
                          style: const TextStyle(fontSize: 28, color: Colors.teal, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nama,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "NIP: $nip",
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            // Badge Mapel
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Mapel: $mapelString",
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= INFO WALI KELAS =================
            if (waliKelas != "-" && waliKelas != "")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade200),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
                        child: const Icon(Icons.class_, color: Colors.orange, size: 20),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Anda adalah Wali Kelas:", style: TextStyle(color: Colors.black54, fontSize: 12)),
                          Text(waliKelas, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 25),

            // ================= MENU GRID =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  
                  // --- MENU 1: INPUT NILAI (Sudah Diupdate) ---
                  _menuItem(
                    title: "Input Nilai",
                    icon: Icons.edit_document,
                    color: Colors.blue,
                    onTap: () {
                      // Mengarahkan ke halaman pilih kelas untuk Input Nilai
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const GuruPilihKelasNilaiPage())
                      );
                    },
                  ),
                  
                  // --- MENU 2: DATA SISWA ---
                  _menuItem(
                    title: "Data Siswa",
                    icon: Icons.groups,
                    color: Colors.teal,
                    onTap: () {
                      // Mengarahkan ke halaman pilih kelas untuk Data Siswa
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const GuruSiswaKelasPage())
                      );
                    },
                  ),

                  _menuItem(
                    title: "Jadwal Mengajar",
                    icon: Icons.calendar_month,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const GuruJadwalPage())
                      );
                    },
                  ),
                  _menuItem(
                    title: "Profil Saya",
                    icon: Icons.person_pin,
                    color: Colors.orange,
                    onTap: () { 
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const GuruProfilPage())
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // WIDGET TOMBOL MENU MODERN
  Widget _menuItem({
    required String title, 
    required IconData icon, 
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 35, color: color),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}