import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditOrtuPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditOrtuPage({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<EditOrtuPage> createState() => _EditOrtuPageState();
}

class _EditOrtuPageState extends State<EditOrtuPage> {
  late TextEditingController _namaController;

  // Variabel Siswa Terpilih
  String? selectedSiswaId;
  String? selectedSiswaNama;
  String? selectedSiswaNisn;
  String? selectedSiswaKelas;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Isi data awal dari database
    _namaController = TextEditingController(text: widget.data['nama'] ?? '');
    
    selectedSiswaId = widget.data['siswa_id'];
    selectedSiswaNama = widget.data['siswa_nama'];
    selectedSiswaNisn = widget.data['siswa_nisn'];
    selectedSiswaKelas = widget.data['siswa_kelas'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Edit Orang Tua"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // CARD INFO ORTU
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Informasi Orang Tua", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: _namaController,
                    decoration: _inputDecor("Nama Orang Tua", Icons.person_outline),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // CARD HUBUNGKAN SISWA
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Hubungkan dengan Siswa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text("Mengganti siswa akan mengubah data anak di dashboard orang tua.", 
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 15),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("users")
                        .where("role", isEqualTo: "siswa")
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const LinearProgressIndicator();

                      var siswaList = snapshot.data!.docs;
                      
                      // Urutkan abjad
                      siswaList.sort((a, b) => (a['nama'] as String).compareTo(b['nama'] as String));

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(border: InputBorder.none),
                          value: selectedSiswaId, // ID Siswa saat ini
                          isExpanded: true,
                          hint: const Text("Pilih Siswa"),
                          items: siswaList.map((doc) {
                            var data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(
                                "${data['nama']} (${data['kelas']})", 
                                overflow: TextOverflow.ellipsis
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            var doc = siswaList.firstWhere((d) => d.id == val);
                            var data = doc.data() as Map<String, dynamic>;
                            
                            setState(() {
                              selectedSiswaId = val;
                              selectedSiswaNama = data['nama'];
                              selectedSiswaNisn = data['nisn'];
                              selectedSiswaKelas = data['kelas'];
                            });
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // TOMBOL SIMPAN
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isLoading ? null : _updateOrtu,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SIMPAN PERUBAHAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Styles
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
      ],
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.orange),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }

  Future<void> _updateOrtu() async {
    setState(() => isLoading = true);

    try {
      // Update data di Firestore saja
      // Catatan: Ini tidak mengubah password/email login di Auth (tetap pakai NISN awal saat register)
      // Tapi akan mengubah data tampilan di dashboard.
      
      String emailBaru = "$selectedSiswaNisn@ortu.com";

      await FirebaseFirestore.instance.collection("users").doc(widget.docId).update({
        "nama": _namaController.text,
        "email": emailBaru, // Update email di display data
        "siswa_id": selectedSiswaId,
        "siswa_nama": selectedSiswaNama,
        "siswa_nisn": selectedSiswaNisn,
        "siswa_kelas": selectedSiswaKelas,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data Orang Tua Berhasil Diperbarui!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}