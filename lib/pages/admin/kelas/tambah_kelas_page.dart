import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'jurusan_list.dart'; // Pastikan file ini ada

class TambahKelasPage extends StatefulWidget {
  const TambahKelasPage({super.key});

  @override
  State<TambahKelasPage> createState() => _TambahKelasPageState();
}

class _TambahKelasPageState extends State<TambahKelasPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController kelasController = TextEditingController();
  
  String? selectedJurusan;
  bool isLoading = false;

  final List<String> fallbackJurusan = [
    "Teknik Komputer dan Informatika",
    "Teknik Kendaraan Ringan",
    "Teknik Pemesinan",
    "Teknik Elektronika Industri",
    "Desain Pemodelan dan Informasi Bangunan",
  ];

  @override
  Widget build(BuildContext context) {
    List<String> listPilihan = jurusanList.isNotEmpty ? jurusanList : fallbackJurusan;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Tambah Kelas Baru"),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Detail Kelas",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: kelasController,
                      decoration: _inputDecor(
                        label: "Nama Kelas",
                        hint: "Contoh: X TKJ 1",
                        icon: Icons.meeting_room,
                      ),
                      validator: (value) => value!.isEmpty ? "Nama kelas tidak boleh kosong" : null,
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      decoration: _inputDecor(
                        label: "Jurusan",
                        hint: "Pilih Jurusan",
                        icon: Icons.school,
                      ),
                      isExpanded: true,
                      value: selectedJurusan,
                      items: listPilihan.map((j) {
                        return DropdownMenuItem(
                          value: j,
                          child: Text(j, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedJurusan = val),
                      validator: (value) => value == null ? "Harap pilih jurusan" : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                  onPressed: isLoading ? null : _simpanKelas,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "SIMPAN KELAS",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor({required String label, required String hint, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Future<void> _simpanKelas() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Ubah jadi Huruf Besar semua (X TKJ 1) dan hapus spasi berlebih
      String namaKelasFinal = kelasController.text.trim().toUpperCase();

      // ============================================================
      // 1. CEK DUPLIKAT DI DATABASE
      // ============================================================
      var cekDuplikat = await FirebaseFirestore.instance
          .collection("kelas")
          .where("namaKelas", isEqualTo: namaKelasFinal)
          .get();

      if (cekDuplikat.docs.isNotEmpty) {
        // Jika ketemu data yang sama, TAMPILKAN ERROR
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal! Kelas '$namaKelasFinal' sudah ada."),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => isLoading = false);
        return; // BERHENTI DI SINI (JANGAN SIMPAN)
      }
      // ============================================================

      // 2. Simpan jika aman (tidak ada duplikat)
      await FirebaseFirestore.instance.collection("kelas").add({
        "namaKelas": namaKelasFinal,
        "jurusan": selectedJurusan,
        "createdAt": DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Berhasil menambahkan kelas baru"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}