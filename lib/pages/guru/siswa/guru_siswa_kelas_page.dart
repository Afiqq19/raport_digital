import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'guru_siswa_list_page.dart'; // Kita buat file ini di langkah ke-2

class GuruSiswaKelasPage extends StatelessWidget {
  const GuruSiswaKelasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        title: const Text("Pilih Kelas (Data Siswa)"),
        backgroundColor: Colors.teal, // Tema Data Siswa
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('kelas').snapshots(),
        builder: (context, snapshot) {
          // Loading
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          var docs = snapshot.data!.docs;

          // Data Kosong
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.class_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Belum ada data kelas", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Grid View
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 Kolom
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.1, // Rasio tinggi kotak
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String namaKelas = data['namaKelas'] ?? "Tanpa Nama";
              String jurusan = data['jurusan'] ?? "-";

              return _buildCard(context, namaKelas, jurusan);
            },
          );
        },
      ),
    );
  }

  // Widget Kartu Kelas Modern
  Widget _buildCard(BuildContext context, String namaKelas, String jurusan) {
    return InkWell(
      onTap: () {
        // Navigasi ke Halaman List Siswa
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GuruSiswaListPage(namaKelas: namaKelas),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups, color: Colors.teal, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              namaKelas,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                jurusan,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}