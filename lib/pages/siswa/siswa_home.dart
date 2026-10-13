import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Pastikan intl ada di pubspec.yaml

// Import halaman fitur
import 'nilai/siswa_lihat_rapor_page.dart'; 
import 'jadwal/siswa_jadwal_page.dart';
import 'pengumuman/siswa_pengumuman_page.dart'; 
import 'profil/siswa_profile_page.dart';

class SiswaHome extends StatefulWidget {
  const SiswaHome({super.key});

  @override
  State<SiswaHome> createState() => _SiswaHomeState();
}

class _SiswaHomeState extends State<SiswaHome> {
  User? user = FirebaseAuth.instance.currentUser;
  
  // Variabel Data Siswa
  String nama = "Memuat...";
  String nisn = "-";
  String kelas = "-";
  String jurusan = "-";

  @override
  void initState() {
    super.initState();
    _getDataSiswa();
  }

  // --- 1. AMBIL DATA DARI FIREBASE ---
  Future<void> _getDataSiswa() async {
    if (user != null) {
      try {
        var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
        if (doc.exists) {
          var data = doc.data()!;
          if (mounted) {
            setState(() {
              nama = data['nama'] ?? "Siswa";
              nisn = data['nisn'] ?? "-";
              kelas = data['kelas'] ?? "-";
              jurusan = _singkatJurusan(data['jurusan'] ?? "-");
            });
          }
        }
      } catch (e) {
        debugPrint("Error: $e");
      }
    }
  }

  // Helper: Menyingkat Nama Jurusan
  String _singkatJurusan(String full) {
    if (full.contains("Komputer")) return "TKJ";
    if (full.contains("Kendaraan")) return "TKR";
    if (full.contains("Pemesinan")) return "TPM";
    if (full.contains("Elektronika")) return "TEI";
    if (full.contains("Listrik")) return "TITL";
    if (full.contains("Bangunan")) return "DPIB";
    if (full.contains("Otomotif")) return "TBO";
    return full; 
  }

  // Helper: Get Hari Ini (Senin, Selasa, dst)
  String _getHariIni() {
    String hariInggris = DateFormat('EEEE').format(DateTime.now());
    switch (hariInggris) {
      case 'Monday': return 'Senin';
      case 'Tuesday': return 'Selasa';
      case 'Wednesday': return 'Rabu';
      case 'Thursday': return 'Kamis';
      case 'Friday': return 'Jumat';
      case 'Saturday': return 'Sabtu';
      case 'Sunday': return 'Minggu';
      default: return 'Senin';
    }
  }

  @override
  Widget build(BuildContext context) {
    String hariIni = _getHariIni();

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA), // Background Abu Muda Bersih
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ================= HEADER MODERN =================
            Stack(
              clipBehavior: Clip.none, // Agar kartu bisa overlap
              children: [
                // 1. Background Gradient Biru
                Container(
                  height: 260,
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3949AB), Color(0xFF1A237E)], // Indigo Gradient
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Baris Atas: Profil (Tanpa Tombol Logout)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Avatar Inisial
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white,
                                child: Text(
                                  nama.isNotEmpty ? nama[0].toUpperCase() : "S",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF3949AB)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Selamat Datang,", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  SizedBox(
                                    width: 250, // Lebar diperbesar karena tombol logout hilang
                                    child: Text(
                                      nama, 
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Tombol Logout Dihapus dari Sini
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Kartu Info Akademik (Floating)
                Positioned(
                  top: 160,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _infoItem("NISN", nisn, Icons.badge),
                        _divider(),
                        _infoItem("Kelas", kelas, Icons.class_),
                        _divider(),
                        _infoItem("Jurusan", jurusan, Icons.engineering),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 80), // Spasi karena ada kartu floating

            // ================= MENU GRID =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Menu Akademik", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 15),
                  
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.1, 
                    children: [
                      // MENU 1: LIHAT NILAI
                      _menuItem(
                        title: "Hasil Belajar",
                        subtitle: "Lihat Rapor",
                        icon: Icons.bar_chart_rounded,
                        color: Colors.blueAccent,
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => const SiswaLihatRaporPage())
                          );
                        },
                      ),

                      // MENU 2: JADWAL
                      _menuItem(
                        title: "Jadwal",
                        subtitle: "Pelajaran",
                        icon: Icons.calendar_month_rounded,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => const SiswaJadwalPage())
                          );
                        },
                      ),

                      // MENU 3: PROFIL
                      _menuItem(
                        title: "Profil Saya",
                        subtitle: "Data Akun",
                        icon: Icons.person_rounded,
                        color: Colors.indigo,
                        onTap: () {
                           Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => const SiswaProfilePage())
                          );
                        },
                      ),

                      // MENU 4: PENGUMUMAN
                      _menuItem(
                        title: "Pengumuman",
                        subtitle: "Info Sekolah",
                        icon: Icons.notifications_active_rounded,
                        color: Colors.pinkAccent,
                        onTap: () { 
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => const SiswaPengumumanPage())
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // ================= JADWAL HARI INI (OTOMATIS DARI DB) =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Jadwal Hari Ini", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text("$hariIni, ${DateFormat('d MMM', 'id_ID').format(DateTime.now())}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  // STREAM BUILDER UNTUK JADWAL HARI INI
                  if (kelas == "-" || kelas.isEmpty)
                    const Center(child: Text("Data kelas belum tersedia."))
                  else
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('jadwal')
                          .where('kelas', isEqualTo: kelas)
                          .where('hari', isEqualTo: hariIni) // Filter Hari Ini
                          .orderBy('jam_mulai') // Urutkan jam
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        var docs = snapshot.data!.docs;

                        if (docs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                            child: const Center(child: Text("Tidak ada pelajaran hari ini 🏖️", style: TextStyle(color: Colors.grey))),
                          );
                        }

                        // Tampilkan hanya 3 pelajaran pertama agar tidak terlalu panjang
                        var limitedDocs = docs.take(3).toList();

                        return Column(
                          children: limitedDocs.map((doc) {
                            var data = doc.data() as Map<String, dynamic>;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border(left: BorderSide(color: Colors.orange, width: 5)),
                                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.access_time_filled, color: Colors.orange),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(data['mapel'] ?? "-", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text("${data['jam_mulai']} - ${data['jam_selesai']} WIB • Guru: ${data['guru_nama'] ?? '-'}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widget Info Header (NISN/Kelas)
  Widget _infoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.indigo.shade300),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _divider() {
    return Container(height: 30, width: 1, color: Colors.grey.shade300);
  }

  // Widget Kartu Menu Modern
  Widget _menuItem({
    required String title,
    required String subtitle,
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
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const Spacer(),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}