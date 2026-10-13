import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // Pastikan sudah ada di pubspec.yaml

class OrtuPengumumanPage extends StatelessWidget {
  const OrtuPengumumanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Info & Pengumuman"),
        backgroundColor: Colors.green, // Warna tema Orang Tua
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pengumuman')
            .orderBy('created_at', descending: true) // Teratas yang paling baru
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          var docs = snapshot.data!.docs;

          // 2. Data Kosong
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mark_email_unread_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  const Text("Belum ada pengumuman dari sekolah.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 3. List Pengumuman
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              
              String tanggal = data['tanggal_event'] ?? "-";
              String judul = data['judul'] ?? "Tanpa Judul";
              String isi = data['isi'] ?? "";
              String linkFile = data['link_file'] ?? "";

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Tanggal
                      if (tanggal != "-")
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event_available, size: 14, color: Colors.green),
                              const SizedBox(width: 5),
                              Text(
                                "Pelaksanaan: $tanggal", 
                                style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                        ),

                      // Judul
                      Text(
                        judul,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),

                      // Isi Deskripsi
                      Text(
                        isi,
                        style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                        textAlign: TextAlign.justify,
                      ),

                      // Tombol Download / Lihat File
                      if (linkFile.isNotEmpty) ...[
                        const SizedBox(height: 15),
                        const Divider(),
                        TextButton.icon(
                          onPressed: () async {
                            final Uri url = Uri.parse(linkFile);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Gagal membuka dokumen")),
                              );
                            }
                          },
                          icon: const Icon(Icons.description, color: Colors.green),
                          label: const Text("Lihat Dokumen / Lampiran", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          ),
                        ),
                      ]
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