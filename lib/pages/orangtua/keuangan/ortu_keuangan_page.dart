import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Add intl di pubspec.yaml untuk format Rupiah

class OrtuKeuanganPage extends StatelessWidget {
  final String siswaId; // Butuh ID Siswa

  const OrtuKeuanganPage({super.key, required this.siswaId});

  // Helper Format Rupiah
  String formatRupiah(int number) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return currencyFormatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Info Keuangan & SPP"),
        backgroundColor: Colors.purple, // Tema Keuangan
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tagihan')
            .where('siswa_id', isEqualTo: siswaId)
            .orderBy('jatuh_tempo', descending: true) // Tagihan terbaru di atas
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.purple));

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  const Text("Belum ada data tagihan.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              
              String judul = data['judul'] ?? "Tagihan";
              int jumlah = data['jumlah'] ?? 0;
              String status = data['status'] ?? "BELUM"; // LUNAS / BELUM
              String tempo = data['jatuh_tempo'] ?? "-";

              bool isLunas = status == "LUNAS";

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isLunas ? Colors.green.shade100 : Colors.red.shade100,
                    child: Icon(
                      isLunas ? Icons.check : Icons.priority_high,
                      color: isLunas ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(judul, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Jatuh Tempo: $tempo", style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        formatRupiah(jumlah), 
                        style: TextStyle(
                          color: isLunas ? Colors.black54 : Colors.red, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isLunas ? Colors.green : Colors.redAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isLunas ? "LUNAS" : "BELUM LUNAS",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
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