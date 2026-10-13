import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'nilai/ortu_lihat_rapor_page.dart';
import 'jadwal/ortu_lihat_jadwal_page.dart';
import 'profil/ortu_profile_page.dart'; // Pastikan path ini benar sesuai file kamu
import 'pengumuman/ortu_pengumuman_page.dart';

//import 'keuangan/ortu_keuangan_page.dart';

class OrtuHome extends StatefulWidget {
  const OrtuHome({super.key});

  @override
  State<OrtuHome> createState() => _OrtuHomeState();
}

class _OrtuHomeState extends State<OrtuHome> {
  User? user = FirebaseAuth.instance.currentUser;

  String namaOrtu = "Memuat...";
  String namaSiswa = "-";
  String kelasSiswa = "-";
  String nisnSiswa = "-";
  String siswaId = "";

  String? namaWali;
  String? hpWali;

  @override
  void initState() {
    super.initState();
    _getDataOrtu();
  }

  void _getDataOrtu() async {
    if (user != null) {
      try {
        var doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;

          String kls = data['siswa_kelas'] ?? "-";

          if (mounted) {
            setState(() {
              namaOrtu = data['nama'] ?? "Orang Tua";
              namaSiswa = data['siswa_nama'] ?? "-";
              kelasSiswa = kls;
              nisnSiswa = data['siswa_nisn'] ?? "-";
              siswaId = data['siswa_id'] ?? "";
            });
          }

          if (kls != "-" && kls.isNotEmpty) {
            var guruSnap = await FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'guru')
                .where('wali_kelas_nama', isEqualTo: kls)
                .limit(1)
                .get();

            if (guruSnap.docs.isEmpty) {
              guruSnap = await FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'guru')
                  .where('wali_kelas', isEqualTo: kls)
                  .limit(1)
                  .get();
            }

            if (guruSnap.docs.isNotEmpty) {
              var dGuru = guruSnap.docs.first.data();
              if (mounted) {
                setState(() {
                  namaWali = dGuru['nama'];
                  hpWali = dGuru['hp'];
                });
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Error: $e");
      }
    }
  }

  Future<void> _hubungiWali() async {
    if (hpWali == null || hpWali!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nomor HP Wali Kelas belum terdaftar.")),
      );
      return;
    }

    String phone = hpWali!.trim();
    if (phone.startsWith('0')) {
      phone = "62${phone.substring(1)}";
    }

    final Uri url = Uri.parse(
      "https://wa.me/$phone?text=Halo%20Bapak/Ibu%20$namaWali,%20saya%20orang%20tua%20dari%20$namaSiswa%20($kelasSiswa).",
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        final Uri telUrl = Uri.parse("tel:$phone");
        await launchUrl(telUrl);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal membuka WA: $e")));
    }
  }

  void _logout() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text("Yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFF3E0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.only(
                top: 60,
                left: 20,
                right: 20,
                bottom: 30,
              ),
              decoration: const BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // --- BAGIAN INI DIEDIT AGAR BISA DIKLIK KE PROFIL ---
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            // Navigasi ke Halaman Profil
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OrtuProfilePage(),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Selamat Datang,",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                namaOrtu,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Indikator kecil agar user tau bisa diklik
                              Row(
                                children: const [
                                  Icon(
                                    Icons.person,
                                    color: Colors.white54,
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Lihat Profil >",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Tombol Logout
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, color: Colors.white),
                          tooltip: "Keluar",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // KARTU DATA SISWA
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.child_care,
                            size: 40,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Data Peserta Didik:",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                namaSiswa,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 5,
                                children: [
                                  _badge(
                                    kelasSiswa,
                                    Colors.blue.shade50,
                                    Colors.blue,
                                  ),
                                  _badge(
                                    nisnSiswa,
                                    Colors.grey.shade100,
                                    Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // MENU UTAMA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Menu Utama",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    children: [
                      _menuItem(
                        title: "Rapor & Nilai",
                        subtitle: "Lihat Hasil Belajar",
                        icon: Icons.analytics_outlined,
                        color: Colors.blue,
                        onTap: () {
                          if (siswaId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Data anak belum terhubung."),
                              ),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrtuLihatRaporPage(
                                siswaId: siswaId,
                                namaSiswa: namaSiswa,
                                nisnSiswa: nisnSiswa,
                                kelasSiswa: kelasSiswa,
                              ),
                            ),
                          );
                        },
                      ),

                      _menuItem(
                        title: "Jadwal Anak",
                        subtitle: "Pelajaran Sekolah",
                        icon: Icons.calendar_month,
                        color: Colors.green,
                        onTap: () {
                          if (kelasSiswa == "-" || kelasSiswa.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Data kelas anak belum terhubung.",
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OrtuLihatJadwalPage(),
                            ),
                          );
                        },
                      ),

                      // TOMBOL HUBUNGI WALI (DENGAN GAMBAR ASSET)
                      _menuItem(
                        title: "Hubungi Wali",
                        subtitle: namaWali != null
                            ? "Chat: $namaWali"
                            : "Kontak Guru",
                        isAssetImage: true,
                        imagePath: "assets/images/logo_wa.jpg",
                        color: Colors.orange,
                        onTap: _hubungiWali,
                      ),

                      _menuItem(
                        title: "Pengumuman",
                        subtitle: "Info Terbaru Sekolah",
                        icon: Icons.campaign,
                        color: Colors.pinkAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OrtuPengumumanPage(),
                            ),
                          );
                        },
                      ),

                      _menuItem(
                        title: "Keuangan",
                        subtitle: "Info SPP",
                        icon: Icons.account_balance_wallet,
                        color: Colors.purple,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Keuangan segera hadir")));
                          /*if (siswaId.isEmpty) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data anak belum terhubung.")));
                             return;
                           }
                           Navigator.push(
                             context, 
                             MaterialPageRoute(builder: (_) => OrtuKeuanganPage(siswaId: siswaId))
                           );*/
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  // WIDGET MENU ITEM (SUPPORT ASSET IMAGE)
  Widget _menuItem({
    required String title,
    required String subtitle,
    IconData? icon,
    String? imagePath,
    bool isAssetImage = false,
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
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: isAssetImage && imagePath != null
                    ? ClipOval(
                        child: Image.asset(
                          imagePath,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.broken_image, color: color, size: 32),
                        ),
                      )
                    : Icon(icon, size: 32, color: color),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
