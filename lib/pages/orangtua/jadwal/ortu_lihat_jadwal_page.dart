import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrtuLihatJadwalPage extends StatefulWidget {
  const OrtuLihatJadwalPage({super.key});

  @override
  State<OrtuLihatJadwalPage> createState() => _OrtuLihatJadwalPageState();
}

class _OrtuLihatJadwalPageState extends State<OrtuLihatJadwalPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> hariList = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"];
  
  String? kelasAnak;
  String? namaAnak;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: hariList.length, vsync: this);
    _getDataAnak();
  }

  // 1. Ambil Data Kelas Anak dari Akun Orang Tua
  void _getDataAnak() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            kelasAnak = data['siswa_kelas']; // Ambil kelas anak
            namaAnak = data['siswa_nama'];   // Ambil nama anak
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
      backgroundColor: const Color(0xffFFF3E0), // Background Orange Muda
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Jadwal Pelajaran Anak"),
            if (namaAnak != null)
              Text("Siswa: $namaAnak ($kelasAnak)", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
          ],
        ),
        backgroundColor: Colors.orange, // Tema Orang Tua
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: hariList.map((hari) => Tab(text: hari)).toList(),
        ),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : kelasAnak == null || kelasAnak == "-"
              ? const Center(child: Text("Data kelas anak belum terhubung."))
              : TabBarView(
                  controller: _tabController,
                  children: hariList.map((hari) {
                    return _buildJadwalList(hari);
                  }).toList(),
                ),
    );
  }

  // 2. Tampilkan Jadwal
  Widget _buildJadwalList(String hari) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jadwal')
          .where('kelas', isEqualTo: kelasAnak) // FILTER KELAS ANAK
          .where('hari', isEqualTo: hari)       // FILTER HARI
          .orderBy('jam_mulai')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }
        
        // Handle jika Index belum dibuat
        if (snapshot.hasError) {
           return Center(child: Text("Error Database: ${snapshot.error}"));
        }

        var docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text("Tidak ada jadwal hari $hari", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            
            return _cardJadwal(
              mapel: data['mapel'] ?? "-",
              guru: data['guru_nama'] ?? "Guru",
              jam: "${data['jam_mulai']} - ${data['jam_selesai']}",
            );
          },
        );
      },
    );
  }

  Widget _cardJadwal({required String mapel, required String guru, required String jam}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
        ],
        border: Border(left: BorderSide(color: Colors.orange.shade400, width: 5))
      ),
      child: Row(
        children: [
          // Kolom Jam
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.orange),
                const SizedBox(height: 4),
                Text(jam.split(' - ')[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const Text("-", style: TextStyle(fontSize: 10)),
                Text(jam.split(' - ')[1], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          
          const SizedBox(width: 15),

          // Kolom Info
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