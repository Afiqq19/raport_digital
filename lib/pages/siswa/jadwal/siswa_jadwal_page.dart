import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SiswaJadwalPage extends StatefulWidget {
  const SiswaJadwalPage({super.key});

  @override
  State<SiswaJadwalPage> createState() => _SiswaJadwalPageState();
}

class _SiswaJadwalPageState extends State<SiswaJadwalPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> hariList = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"];
  
  String? userKelas;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: hariList.length, vsync: this);
    _getKelasSiswa();
  }

  // 1. Cari tahu siswa ini kelas apa
  void _getKelasSiswa() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        if (mounted) {
          setState(() {
            userKelas = doc['kelas']; // Misal: "XII TKJ 1"
            isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        title: const Text("Jadwal Pelajaran"),
        backgroundColor: Colors.indigo, // Tema Siswa
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.yellowAccent,
          
          // --- PERBAIKAN TAMPILAN TAB ---
          labelColor: Colors.white, // Teks aktif jadi Putih
          unselectedLabelColor: Colors.white60, // Teks tidak aktif agak transparan
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          // -----------------------------
          
          tabs: hariList.map((hari) => Tab(text: hari)).toList(),
        ),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : userKelas == null || userKelas == "-"
              ? const Center(child: Text("Anda belum masuk ke kelas manapun."))
              : TabBarView(
                  controller: _tabController,
                  children: hariList.map((hari) {
                    return _buildJadwalList(hari);
                  }).toList(),
                ),
    );
  }

  // 2. Tampilkan Jadwal berdasarkan Kelas & Hari
  Widget _buildJadwalList(String hari) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jadwal')
          .where('kelas', isEqualTo: userKelas) // FILTER KELAS SISWA
          .where('hari', isEqualTo: hari)       // FILTER HARI
          .orderBy('jam_mulai')                 // URUTKAN JAM
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.indigo));
        }
        
        // --- PERBAIKAN: DETEKSI ERROR INDEX ---
        if (snapshot.hasError) {
           return Center(
             child: Padding(
               padding: const EdgeInsets.all(20),
               child: SelectableText(
                 "Error Database: ${snapshot.error}\n\n(Silakan cek Debug Console laptop untuk klik link pembuatan Index)",
                 textAlign: TextAlign.center,
                 style: const TextStyle(color: Colors.red),
               ),
             ),
           );
        }
        // -------------------------------------

        var docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.free_breakfast_outlined, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text("Tidak ada pelajaran hari $hari", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            
            return _cardJadwalSiswa(
              mapel: data['mapel'] ?? "-",
              guru: data['guru_nama'] ?? "Guru",
              jam: "${data['jam_mulai']} - ${data['jam_selesai']}",
            );
          },
        );
      },
    );
  }

  Widget _cardJadwalSiswa({required String mapel, required String guru, required String jam}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.indigo.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
        ],
        border: Border(left: BorderSide(color: Colors.indigo.shade400, width: 5))
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Jam (Kolom Kiri)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.indigo),
                const SizedBox(height: 4),
                Text(jam.split(' - ')[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const Text("-", style: TextStyle(fontSize: 10)),
                Text(jam.split(' - ')[1], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          
          const SizedBox(width: 15),

          // Info Mapel (Kolom Kanan)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mapel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 5),
                    Expanded(child: Text(guru, style: const TextStyle(color: Colors.grey, fontSize: 13), overflow: TextOverflow.ellipsis)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}