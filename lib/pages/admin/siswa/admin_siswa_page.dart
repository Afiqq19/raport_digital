import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSiswaPage extends StatefulWidget {
  const AdminSiswaPage({super.key});

  @override
  State<AdminSiswaPage> createState() => _AdminSiswaPageState();
}

class _AdminSiswaPageState extends State<AdminSiswaPage> {
  String searchText = "";
  String filterKelas = "Semua";
  String filterJurusan = "Semua";

  final List<String> listKelas = ["Semua", "X", "XI", "XII"];
  
  // Pastikan list ini sesuai dengan yang ada di database (tanpa singkatan kurung biar pencarian fleksibel)
  final List<String> listJurusan = [
    "Semua",
    "Teknik Komputer dan Informatika",
    "Teknik Kendaraan Ringan",
    "Teknik Pemesinan",
    "Teknik Elektronika Industri",
    "Teknik Instalasi Tenaga Listrik",
    "Desain Pemodelan dan Informasi Bangunan",
    "Teknik Body Otomotif",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9), // Background abu modern yang soft

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text(
          "Kelola Siswa",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28, color: Colors.white),
        onPressed: () => Navigator.pushNamed(context, '/admin/siswa/add'),
      ),

      body: Column(
        children: [
          const SizedBox(height: 15),

          // ================== SEARCH BAR MODERN ==================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  hintText: "Cari nama siswa...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: (v) => setState(() => searchText = v.toLowerCase()),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // ================== FILTER DROPDOWNS ==================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _modernDropdown(
                    label: "Kelas",
                    value: filterKelas,
                    items: listKelas,
                    onChanged: (v) => setState(() => filterKelas = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _modernDropdown(
                    label: "Jurusan",
                    value: filterJurusan,
                    items: listJurusan,
                    onChanged: (v) => setState(() => filterJurusan = v!),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // ================== LIST SISWA ==================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Kita ambil semua siswa dulu, baru filter di aplikasi (Client Side)
              // Ini mencegah error "Index Required" yang ribet di Firestore
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .where("role", isEqualTo: "siswa")
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text("Error: ${snap.error}"));
                }

                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  );
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text("Belum ada data siswa."));
                }

                final docs = snap.data!.docs;

                // --- LOGIKA FILTER (CLIENT SIDE) ---
                // Filter data berdasarkan Search, Kelas, dan Jurusan
                final filteredData = docs.where((d) {
                  final s = d.data() as Map<String, dynamic>;
                  final nama = (s["nama"] ?? s["name"] ?? "").toString().toLowerCase();
                  final kelas = (s["kelas"] ?? "").toString();
                  final jurusan = (s["jurusan"] ?? "").toString();

                  // Cek Search
                  final matchNama = nama.contains(searchText);
                  
                  // Cek Kelas (Pakai startsWith biar "X" ketemu "X TKJ 1")
                  final matchKelas = filterKelas == "Semua" || 
                                     kelas.startsWith("$filterKelas "); // X spasi
                  
                  // Cek Jurusan (Pakai contains biar "Teknik Komputer" ketemu "Teknik Komputer (TKJ)")
                  final matchJurusan = filterJurusan == "Semua" || 
                                       jurusan.contains(filterJurusan);

                  return matchNama && matchKelas && matchJurusan;
                }).toList();
                
                // Sortir manual berdasar nama
                filteredData.sort((a, b) {
                   var nA = (a.data() as Map)['nama'] ?? '';
                   var nB = (b.data() as Map)['nama'] ?? '';
                   return nA.compareTo(nB);
                });

                if (filteredData.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Tidak ada siswa yang cocok.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(15, 5, 15, 80), // Padding bawah lebih besar utk FAB
                  itemCount: filteredData.length,
                  itemBuilder: (context, i) {
                    final d = filteredData[i];
                    final s = d.data() as Map<String, dynamic>;

                    return _modernCard(
                      nama: s['nama'] ?? "Tanpa Nama",
                      nisn: s['nisn'] ?? "-",
                      kelas: s['kelas'] ?? "-",
                      jurusan: s['jurusan'] ?? "-",
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          "/admin/siswa/edit",
                          arguments: d.id,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================== WIDGET DROPDOWN MODERN ==================
  Widget _modernDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true, // Agar teks panjang tidak error
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
        ),
        items: items.map((e) {
          return DropdownMenuItem(
            value: e,
            child: Text(
              e,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // ================== WIDGET KARTU SISWA MODERN ==================
  Widget _modernCard({
    required String nama,
    required String nisn,
    required String kelas,
    required String jurusan,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // Avatar / Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person, color: Colors.blueAccent, size: 28),
            ),
            
            const SizedBox(width: 15),
            
            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Badge NISN
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(nisn, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                      const SizedBox(width: 8),
                      // Info Kelas
                      Expanded(
                        child: Text(
                          "$kelas • $jurusan",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Arrow Icon
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}