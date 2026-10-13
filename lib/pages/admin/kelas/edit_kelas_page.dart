import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'jurusan_list.dart'; // Pastikan file ini ada

class EditKelasPage extends StatefulWidget {
  final String id;
  final DocumentSnapshot data;

  const EditKelasPage({super.key, required this.id, required this.data});

  @override
  State<EditKelasPage> createState() => _EditKelasPageState();
}

class _EditKelasPageState extends State<EditKelasPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _kelasController;
  String? selectedJurusan;
  bool isLoading = false;

  // Fallback jika file jurusan_list kosong/bermasalah
  final List<String> fallbackJurusan = [
    "Teknik Komputer dan Informatika",
    "Teknik Kendaraan Ringan",
    "Teknik Pemesinan",
    "Teknik Elektronika Industri",
    "Desain Pemodelan dan Informasi Bangunan",
  ];

  @override
  void initState() {
    super.initState();
    // Isi data awal dari database
    _kelasController = TextEditingController(text: widget.data['namaKelas']);
    selectedJurusan = widget.data['jurusan'];
  }

  @override
  Widget build(BuildContext context) {
    // Gabungkan list untuk memastikan jurusan yang tersimpan di DB tetap muncul
    // meskipun mungkin sudah dihapus dari daftar jurusanList master
    List<String> listPilihan = jurusanList.isNotEmpty ? jurusanList : fallbackJurusan;
    
    // SAFETY CHECK: Jika jurusan yang ada di DB tidak ada di list pilihan,
    // Kita tambahkan sementara agar Dropdown tidak error/crash.
    if (selectedJurusan != null && !listPilihan.contains(selectedJurusan)) {
      listPilihan.add(selectedJurusan!);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Edit Data Kelas"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Container Form
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Informasi Kelas", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    const SizedBox(height: 20),

                    // INPUT NAMA KELAS
                    TextFormField(
                      controller: _kelasController,
                      decoration: _inputDecor(
                        label: "Nama Kelas",
                        icon: Icons.meeting_room,
                      ),
                      validator: (val) => val!.isEmpty ? "Nama kelas wajib diisi" : null,
                    ),
                    const SizedBox(height: 20),

                    // DROPDOWN JURUSAN
                    DropdownButtonFormField<String>(
                      decoration: _inputDecor(
                        label: "Jurusan",
                        icon: Icons.school,
                      ),
                      value: selectedJurusan,
                      isExpanded: true,
                      items: listPilihan.map((j) {
                        return DropdownMenuItem(
                          value: j,
                          child: Text(
                            j,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => selectedJurusan = v),
                      validator: (val) => val == null ? "Jurusan wajib dipilih" : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // TOMBOL UPDATE
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    shadowColor: Colors.blueAccent.withOpacity(0.4),
                  ),
                  onPressed: isLoading ? null : _updateKelas,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "SIMPAN PERUBAHAN",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Styling Input Field Konsisten
  InputDecoration _inputDecor({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
    );
  }

  // Fungsi Update Data
  Future<void> _updateKelas() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection("kelas").doc(widget.id).update({
        "namaKelas": _kelasController.text.trim().toUpperCase(), // Paksa huruf besar biar rapi
        "jurusan": selectedJurusan,
        // Opsional: tambahkan updatedAt jika ingin tracking kapan diedit
        // "updatedAt": DateTime.now().toIso8601String(), 
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data Kelas Berhasil Diperbarui!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal update: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}