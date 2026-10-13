import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GuruJadwalPage extends StatefulWidget {
  const GuruJadwalPage({super.key});

  @override
  State<GuruJadwalPage> createState() => _GuruJadwalPageState();
}

class _GuruJadwalPageState extends State<GuruJadwalPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> hariList = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: hariList.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        title: const Text("Jadwal Mengajar"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.yellowAccent,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: hariList.map((hari) => Tab(text: hari)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: hariList.map((hari) {
          return _buildJadwalList(hari, myUid);
        }).toList(),
      ),
    );
  }

  Widget _buildJadwalList(String hari, String guruId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jadwal')
          .where('guru_id', isEqualTo: guruId)
          
          // PERBAIKAN DI SINI: Gunakan isEqualTo karena di DB datanya String
          .where('hari', isEqualTo: hari) 
          
          .orderBy('jam_mulai')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.teal));
        }
        
        if (snapshot.hasError) {
           return Center(child: Text("Error: ${snapshot.error}"));
        }

        var docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 50, color: Colors.grey.shade300),
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
            
            return _jadwalCard(
              mapel: data['mapel'] ?? "-",
              kelas: data['kelas'] ?? "-",
              jam: "${data['jam_mulai']} - ${data['jam_selesai']}",
            );
          },
        );
      },
    );
  }

  Widget _jadwalCard({required String mapel, required String kelas, required String jam}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border(left: BorderSide(color: Colors.teal.shade400, width: 5))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mapel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.class_, size: 16, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(kelas, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.teal),
                const SizedBox(width: 5),
                Text(jam, style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}