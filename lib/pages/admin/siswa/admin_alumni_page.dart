import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAlumniPage extends StatelessWidget {
  const AdminAlumniPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        title: const Text("Data Alumni"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // QUERY KHUSUS ALUMNI
        stream: FirebaseFirestore.instance
            .collection("users")
            .where("role", isEqualTo: "alumni") // Filter Role Alumni
            .orderBy("nama")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_edu, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text("Belum ada data alumni.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String nama = data['nama'] ?? "Tanpa Nama";
              String kelasLulus = data['kelas'] ?? "Alumni"; // Contoh: ALUMNI 2025
              String nisn = data['nisn'] ?? "-";

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(Icons.school, color: Colors.grey), // Ikon Topi Wisuda
                  ),
                  title: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kelasLulus, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      Text("NISN: $nisn"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: "Hapus Arsip",
                    onPressed: () {
                      _confirmDelete(context, docs[index].id, nama);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId, String nama) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Arsip?"),
        content: Text("Yakin ingin menghapus data alumni $nama secara permanen?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
            onPressed: () {
              FirebaseFirestore.instance.collection("users").doc(docId).delete();
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}