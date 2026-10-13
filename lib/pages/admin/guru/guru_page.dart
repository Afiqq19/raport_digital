import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Pastikan path import ini sesuai dengan folder Anda
import 'tambah_guru_page.dart'; 
import 'edit_guru_page.dart'; // Nanti kita buat jika belum ada

class GuruPage extends StatelessWidget {
  const GuruPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        title: const Text("Kelola Guru"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
        onPressed: () {
          // Navigasi ke halaman tambah (Pastikan nama class sesuai file Anda)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TambahGuruPage()),
          );
        },
      ),

      // Mengambil data dari collection 'users' dimana role-nya 'guru'
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users") // <--- PERBAIKAN: Gunakan 'users', bukan 'guru'
            .where("role", isEqualTo: "guru") // <--- FILTER: Ambil yg guru saja
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error State
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}"));
          }

          // 3. Data Kosong
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada data guru."));
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var d = docs[index];
              // Ambil data sebagai Map agar aman
              var data = d.data() as Map<String, dynamic>;

              // Ambil data dengan nilai default ("-") jika kosong agar tidak error
              String nama = data["nama"] ?? "Tanpa Nama";
              String nip = data["nip"] ?? "-";
              String waliKelas = data["wali_kelas"] ?? "-";

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  
                  // Avatar inisial nama
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent.shade100,
                    child: Text(
                      nama.isNotEmpty ? nama[0].toUpperCase() : "?",
                      style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                    ),
                  ),

                  title: Text(
                    nama,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("NIP: $nip"),
                      Text("Wali Kelas: $waliKelas"), // Menampilkan data yang kita input kemarin
                    ],
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TOMBOL EDIT
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () {
                           // Navigasi ke Edit (Kirim ID document)
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              // Kirim ID dokumen agar bisa diedit
                              builder: (_) => EditGuruPage(docId: d.id, data: data)
                            ),
                          );
                        },
                      ),

                      // TOMBOL DELETE
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Konfirmasi Hapus
                          showDialog(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                title: const Text("Hapus Guru?"),
                                content: Text("Yakin ingin menghapus $nama?"),
                                actions: [
                                  TextButton(
                                    child: const Text("Batal"),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  TextButton(
                                    child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                                    onPressed: () async {
                                      // Hapus dari collection 'users'
                                      await FirebaseFirestore.instance
                                          .collection("users")
                                          .doc(d.id)
                                          .delete();
                                      
                                      if (context.mounted) Navigator.pop(context);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
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