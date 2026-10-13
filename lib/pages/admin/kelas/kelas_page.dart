import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tambah_kelas_page.dart';
import 'edit_kelas_page.dart';

class KelasPage extends StatelessWidget {
  const KelasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // Background Abu Modern
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Kelola Data Kelas",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah Kelas", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TambahKelasPage()),
          );
        },
      ),

      body: StreamBuilder<QuerySnapshot>(
        // Urutkan berdasarkan namaKelas agar rapi
        stream: FirebaseFirestore.instance.collection('kelas').orderBy('namaKelas').snapshots(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
          }

          var docs = snapshot.data!.docs;

          // 2. Empty State (Data Kosong)
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.meeting_room_outlined, size: 60, color: Colors.blue.shade300),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Belum ada data kelas",
                    style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          // 3. List Data Modern
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var d = docs[index];
              var data = d.data() as Map<String, dynamic>;
              
              String namaKelas = data['namaKelas'] ?? "Tanpa Nama";
              String jurusan = data['jurusan'] ?? "-";

              return _buildClassCard(context, d.id, namaKelas, jurusan, data);
            },
          );
        },
      ),
    );
  }

  // WIDGET KARTU KELAS MODERN
  Widget _buildClassCard(BuildContext context, String docId, String namaKelas, String jurusan, Map<String, dynamic> fullData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // ICON KELAS (KIRI)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.class_, color: Colors.blueAccent, size: 28),
            ),
            
            const SizedBox(width: 16),

            // TEXT INFO (TENGAH)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaKelas,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    jurusan,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // TOMBOL AKSI (KANAN)
            Row(
              children: [
                // Tombol Edit
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditKelasPage(id: docId, data: fullData as DocumentSnapshot), 
                        // Catatan: Sesuaikan parameter EditKelasPage Anda. 
                        // Jika parameter minta DocumentSnapshot, kirim 'd'. 
                        // Jika minta Map, kirim 'data'.
                        // Kode di atas asumsi EditKelasPage Anda minta DocumentSnapshot atau ID.
                        // Cek EditKelasPage Anda. Jika error type, sesuaikan.
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.edit, color: Colors.orange, size: 22),
                  ),
                ),
                
                // Tombol Hapus
                InkWell(
                  onTap: () {
                    _showDeleteConfirm(context, docId, namaKelas);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.delete, color: Colors.redAccent, size: 22),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // DIALOG KONFIRMASI HAPUS YANG CANTIK
  void _showDeleteConfirm(BuildContext context, String docId, String namaKelas) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Hapus Kelas?"),
          ],
        ),
        content: Text.rich(
          TextSpan(
            text: "Anda yakin ingin menghapus kelas ",
            style: const TextStyle(color: Colors.black87),
            children: [
              TextSpan(text: namaKelas, style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: "?\n\nData siswa di kelas ini mungkin akan kehilangan referensi."),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              FirebaseFirestore.instance.collection("kelas").doc(docId).delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Kelas berhasil dihapus"), backgroundColor: Colors.red),
              );
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}