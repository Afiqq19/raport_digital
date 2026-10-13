import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'guru_input_nilai_page.dart'; // Import halaman input nilai yang baru dibuat

class GuruPilihKelasNilaiPage extends StatelessWidget {
  const GuruPilihKelasNilaiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        title: const Text("Pilih Kelas untuk Input Nilai"),
        backgroundColor: Colors.blue, // Pembeda warna (Biru = Input)
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('kelas').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.3,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String namaKelas = data['namaKelas'] ?? "-";

              return InkWell(
                onTap: () {
                  // NAVIGASI KE HALAMAN INPUT NILAI
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GuruInputNilaiPage(namaKelas: namaKelas),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit_note, color: Colors.blue, size: 35),
                      const SizedBox(height: 10),
                      Text(namaKelas, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text("Klik untuk input nilai", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}