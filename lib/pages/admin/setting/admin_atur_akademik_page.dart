import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAturAkademikPage extends StatefulWidget {
  const AdminAturAkademikPage({super.key});

  @override
  State<AdminAturAkademikPage> createState() => _AdminAturAkademikPageState();
}

class _AdminAturAkademikPageState extends State<AdminAturAkademikPage> {
  String? _selectedTahun;
  String? _selectedSemester;
  bool isLoading = false;

  // List Tahun Ajaran (Dibuat otomatis 5 tahun ke depan & belakang)
  List<String> _listTahun = [];

  @override
  void initState() {
    super.initState();
    _generateListTahun();
    _loadCurrentSettings();
  }

  // 1. Generate Tahun Otomatis (biar gak capek ngetik)
  void _generateListTahun() {
    int currentYear = DateTime.now().year;
    // Buat list dari 2 tahun lalu sampai 5 tahun ke depan
    for (int i = -2; i < 5; i++) {
      int start = currentYear + i;
      int end = start + 1;
      _listTahun.add("$start/$end");
    }
  }

  // 2. Load Data Sekarang dari Firebase
  void _loadCurrentSettings() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('settings').doc('akademik').get();
      if (doc.exists) {
        setState(() {
          _selectedTahun = doc['tahun_ajaran'];
          _selectedSemester = doc['semester'];
        });
      } else {
        // Default jika belum ada
        setState(() {
          _selectedTahun = _listTahun[2]; // Tahun sekarang
          _selectedSemester = "Ganjil";
        });
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    }
  }

  // 3. Simpan ke Firebase
  Future<void> _simpanPengaturan() async {
    if (_selectedTahun == null || _selectedSemester == null) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('settings').doc('akademik').set({
        'tahun_ajaran': _selectedTahun,
        'semester': _selectedSemester,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Berhasil! Tahun Ajaran Aktif telah diubah."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        title: const Text("Atur Tahun Ajaran"),
        backgroundColor: Colors.blueAccent, // Warna Admin
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // INFO CARD
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "Perhatian: Mengubah pengaturan ini akan mempengaruhi input nilai Guru. Pastikan semester lama sudah selesai.",
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // INPUT FORM
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Tahun Ajaran", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: _inputDecor(Icons.calendar_today),
                    value: _listTahun.contains(_selectedTahun) ? _selectedTahun : null,
                    hint: const Text("Pilih Tahun"),
                    items: _listTahun.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _selectedTahun = v),
                  ),

                  const SizedBox(height: 20),

                  const Text("Semester Aktif", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: _inputDecor(Icons.timeline),
                    value: _selectedSemester,
                    hint: const Text("Pilih Semester"),
                    items: const [
                      DropdownMenuItem(value: "Ganjil", child: Text("Ganjil (Semester 1)")),
                      DropdownMenuItem(value: "Genap", child: Text("Genap (Semester 2)")),
                    ],
                    onChanged: (v) => setState(() => _selectedSemester = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // TOMBOL SIMPAN
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isLoading ? null : _simpanPengaturan,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SIMPAN PENGATURAN",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecor(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}