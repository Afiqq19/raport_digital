import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 

import 'tambah_tagihan_page.dart';

class AdminTagihanPage extends StatefulWidget {
  const AdminTagihanPage({super.key});

  @override
  State<AdminTagihanPage> createState() => _AdminTagihanPageState();
}

class _AdminTagihanPageState extends State<AdminTagihanPage> {
  
  // Helper Rupiah
  String formatRupiah(int number) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return currencyFormatter.format(number);
  }

  // Helper Tanggal
  String formatTanggal(Timestamp? timestamp) {
    if (timestamp == null) return "-";
    DateTime date = timestamp.toDate();
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Kelola Tagihan SPP", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigoAccent,
        icon: const Icon(Icons.add_card, color: Colors.white),
        label: const Text("Buat Tagihan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TambahTagihanPage()),
          );
        },
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tagihan')
            .orderBy('created_at', descending: true) 
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded, size: 60, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 20),
                  const Text("Belum ada data tagihan.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // --- LOGIKA PENGELOMPOKAN DATA BERDASARKAN KELAS ---
          Map<String, List<DocumentSnapshot>> groupedData = {};
          
          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            String kelas = data['kelas'] ?? "Lainnya";
            
            if (!groupedData.containsKey(kelas)) {
              groupedData[kelas] = [];
            }
            groupedData[kelas]!.add(doc);
          }

          // Sortir Nama Kelas (A-Z)
          var sortedKeys = groupedData.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              String className = sortedKeys[index];
              List<DocumentSnapshot> classBills = groupedData[className]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER KELAS
                  _buildClassHeader(className, classBills.length),
                  
                  // LIST TAGIHAN DI KELAS TERSEBUT
                  ...classBills.map((doc) => _buildBillCard(doc)).toList(),
                  
                  const SizedBox(height: 10), // Spasi antar kelas
                ],
              );
            },
          );
        },
      ),
    );
  }

  // --- WIDGET HEADER KELAS ---
  Widget _buildClassHeader(String className, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: Row(
        children: [
          Container(
            width: 4, height: 18, 
            decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(
            className, 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(10)),
            child: Text("$count Tagihan", style: TextStyle(fontSize: 10, color: Colors.indigo.shade700, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // --- WIDGET KARTU TAGIHAN (Modern) ---
  Widget _buildBillCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    String docId = doc.id;
    
    String judul = data['judul'] ?? "-";
    String siswaNama = data['siswa_nama'] ?? "Siswa";
    // String kelas = data['kelas'] ?? "-"; // Tidak perlu ditampilkan lagi karena sudah di header
    int jumlah = data['jumlah'] ?? 0;
    String status = data['status'] ?? "BELUM LUNAS";
    String tipe = data['tipe'] ?? "SPP"; 
    Timestamp? createdAt = data['created_at'];

    bool isLunas = status == "LUNAS";
    bool isReminder = tipe == 'REMINDER';

    Color statusColor = isReminder ? Colors.redAccent : (isLunas ? Colors.teal : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Strip Warna Kiri
              Container(width: 5, color: statusColor),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul & Tanggal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          Text(formatTanggal(createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Info Siswa
                      Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text(siswaNama, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
                        ],
                      ),
                      
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 10),

                      // Bawah: Harga & Status & Menu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Harga / Pesan
                          Text(
                            isReminder ? "TUNGGAKAN" : formatRupiah(jumlah),
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 15,
                              color: isReminder ? Colors.red : Colors.indigo
                            ),
                          ),

                          Row(
                            children: [
                              // Badge Status
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  isReminder ? "PERINGATAN" : (isLunas ? "LUNAS" : "BELUM"),
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                              ),
                              
                              const SizedBox(width: 5),

                              // Menu Opsi
                              SizedBox(
                                width: 24, height: 24,
                                child: PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                                  onSelected: (value) {
                                    if (value == 'lunas') _updateStatus(docId, "LUNAS");
                                    if (value == 'belum') _updateStatus(docId, "BELUM LUNAS");
                                    if (value == 'hapus') _hapusTagihan(docId);
                                  },
                                  itemBuilder: (context) => isReminder ? [
                                     const PopupMenuItem(value: 'hapus', child: Text("Hapus Reminder", style: TextStyle(color: Colors.red))),
                                  ] : [
                                    const PopupMenuItem(value: 'lunas', child: Text("Set LUNAS")),
                                    const PopupMenuItem(value: 'belum', child: Text("Set BELUM")),
                                    const PopupMenuItem(value: 'hapus', child: Text("Hapus", style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              )
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _updateStatus(String docId, String statusBaru) {
    FirebaseFirestore.instance.collection('tagihan').doc(docId).update({
      'status': statusBaru,
      'tanggal_bayar': statusBaru == "LUNAS" ? DateTime.now().toString() : null, 
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Status diperbarui: $statusBaru")));
  }

  void _hapusTagihan(String docId) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Hapus Data"),
        content: const Text("Data ini akan hilang permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('tagihan').doc(docId).delete();
              Navigator.pop(c);
            }, 
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}