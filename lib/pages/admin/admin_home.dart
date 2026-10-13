import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  User? user = FirebaseAuth.instance.currentUser;
  String namaAdmin = "Admin Sistem";
  String emailAdmin = "admin@smk.com";

  // Variabel Statistik
  int totalSiswa = 0;
  int totalGuru = 0;
  int totalKelas = 0;

  @override
  void initState() {
    super.initState();
    _loadDataAdmin();
    _loadStatistik();
  }

  void _loadDataAdmin() async {
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        setState(() {
          namaAdmin = doc['nama'] ?? "Admin";
          emailAdmin = doc['email'] ?? user!.email;
        });
      }
    }
  }

  void _loadStatistik() async {
    var sSiswa = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'siswa').count().get();
    var sGuru = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'guru').count().get();
    var sKelas = await FirebaseFirestore.instance.collection('kelas').count().get();

    if (mounted) {
      setState(() {
        totalSiswa = sSiswa.count ?? 0;
        totalGuru = sGuru.count ?? 0;
        totalKelas = sKelas.count ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ================= HEADER ADMIN =================
            Stack(
              children: [
                Container(
                  height: 220,
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1565C0),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Selamat Datang,", style: TextStyle(color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 5),
                              Text(namaAdmin, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () {
                                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                              }, 
                              icon: const Icon(Icons.logout, color: Colors.white),
                              tooltip: "Keluar",
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                
                // ================= KARTU STATISTIK =================
                Padding(
                  padding: const EdgeInsets.only(top: 160, left: 20, right: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem("Siswa", totalSiswa.toString(), Colors.blue),
                        _divider(),
                        _statItem("Guru", totalGuru.toString(), Colors.orange),
                        _divider(),
                        _statItem("Kelas", totalKelas.toString(), Colors.purple),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ================= MENU GRID =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Menu Kelola", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 15),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    children: [
                      _menuItem(context, "Guru", Icons.person, Colors.blue, "/admin/guru"),
                      _menuItem(context, "Siswa", Icons.school, Colors.orange, "/admin/siswa"),
                      _menuItem(context, "Kelas", Icons.class_, Colors.purple, "/admin/kelas"),
                      _menuItem(context, "Orang Tua", Icons.family_restroom, Colors.green, "/admin/ortu"),
                      _menuItem(context, "Jadwal", Icons.schedule, Colors.redAccent, "/admin/jadwal"),
                      _menuItem(context, "Akademik", Icons.calendar_month, Colors.teal, "/admin/setting_akademik"),
                      _menuItem(context, "Kenaikan", Icons.move_up, Colors.indigo, "/admin/kenaikan_kelas"),
                      _menuItem(context, "Alumni", Icons.history_edu, Colors.brown, "/admin/alumni"),
                      _menuItem(context, "Pengumuman", Icons.campaign, Colors.pinkAccent, "/admin/pengumuman"),
                      _menuItem(context, "Keuangan", Icons.attach_money, Colors.green, "/admin/keuangan"),
                    ],
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

  // WIDGET STATISTIK KECIL
  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _divider() {
    return Container(height: 40, width: 1, color: Colors.grey.shade300);
  }

  // WIDGET MENU ITEM MODERN
  Widget _menuItem(BuildContext ctx, String title, IconData icon, Color color, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(ctx, route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
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
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 15),
            Text(
              title, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}