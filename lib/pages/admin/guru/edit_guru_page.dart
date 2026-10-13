import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // WAJIB: Import ini untuk fitur WA

// IMPORT DATA MAPEL
import '../../../data/mapel_list.dart'; 

class EditGuruPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditGuruPage({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<EditGuruPage> createState() => _EditGuruPageState();
}

class _EditGuruPageState extends State<EditGuruPage> {
  late TextEditingController _namaController;
  late TextEditingController _nipController;
  late TextEditingController _hpController;
  late TextEditingController _alamatController;

  List<String> selectedMapel = [];
  String? selectedWaliKelasId; 
  String? selectedWaliKelasNama;

  List<String> takenClassIds = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // 1. Load Data Awal
    _namaController = TextEditingController(text: widget.data['nama'] ?? '');
    _nipController = TextEditingController(text: widget.data['nip'] ?? '');
    _hpController = TextEditingController(text: widget.data['hp'] ?? '');
    _alamatController = TextEditingController(text: widget.data['alamat'] ?? ''); 
    
    if (widget.data['mapel'] != null) {
      selectedMapel = List<String>.from(widget.data['mapel']);
    }

    String? idDariDb = widget.data['wali_kelas_id'];
    if (idDariDb == "" || idDariDb == null) {
      selectedWaliKelasId = null;
    } else {
      selectedWaliKelasId = idDariDb;
    }
    
    selectedWaliKelasNama = widget.data['wali_kelas_nama'] ?? widget.data['wali_kelas'];

    _cekKelasTerpakai();
  }

  void _cekKelasTerpakai() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'guru')
        .get();

    List<String> ids = [];
    for (var doc in snapshot.docs) {
      if (doc.id == widget.docId) continue; 

      var d = doc.data();
      if (d['wali_kelas_id'] != null && d['wali_kelas_id'] != "") {
        ids.add(d['wali_kelas_id']);
      }
    }

    if (mounted) {
      setState(() {
        takenClassIds = ids;
      });
    }
  }

  // --- LOGIKA WHATSAPP (Baru) ---
  String _formatNoHp(String nomor) {
    String bersih = nomor.replaceAll(RegExp(r'\D'), ''); 
    if (bersih.startsWith('0')) {
      return "62${bersih.substring(1)}";
    } else if (bersih.startsWith('8')) {
      return "62$bersih";
    }
    return bersih;
  }

  Future<void> _kirimInfoViaWA() async {
    String nama = _namaController.text;
    String nip = _nipController.text;
    String hp = _hpController.text;
    String formattedHp = _formatNoHp(hp);
    
    // Link Download Aplikasi
    String linkDownload = "https://www.mediafire.com/folder/gpmj2h309itns/SIAKAD+SMK";
    
    // Pesan
    String pesan = "*Info Akun Guru SMK Budhi Darma (Update)*\n\n"
        "Halo Bapak/Ibu *$nama*,\n"
        "Berikut detail akun Anda:\n\n"
        "👤 Username (NIP): *$nip*\n"
        "🔑 Password Default: *123456*\n"
        "(Segera ganti password jika belum)\n\n"
        "⬇️ *Download Aplikasi:*\n"
        "$linkDownload";

    String url = "https://wa.me/$formattedHp?text=${Uri.encodeComponent(pesan)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membuka WhatsApp")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Edit Data Guru"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // CARD INFORMASI
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Informasi Dasar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 20),
                  
                  _buildModernInput(controller: _namaController, label: "Nama Lengkap", icon: Icons.person_outline),
                  const SizedBox(height: 15),
                  
                  _buildModernInput(controller: _nipController, label: "NIP", icon: Icons.badge_outlined, isNumber: true),
                  const SizedBox(height: 15),
                  
                  // INPUT NO HP
                  _buildModernInput(controller: _hpController, label: "No Handphone", icon: Icons.phone, isNumber: true),
                  const SizedBox(height: 15),
                  
                  // INPUT ALAMAT
                  TextFormField(
                    controller: _alamatController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "Alamat Lengkap",
                      prefixIcon: const Icon(Icons.location_on, color: Colors.blueAccent),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // CARD TUGAS
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Tugas & Tanggung Jawab", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 20),

                  // DROPDOWN WALI KELAS
                  const Text("Wali Kelas", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection("kelas").snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const LinearProgressIndicator();

                      var allKelas = snapshot.data!.docs;
                      
                      var availableKelas = allKelas.where((doc) {
                        return !takenClassIds.contains(doc.id);
                      }).toList();

                      List<DropdownMenuItem<String?>> menuItems = [];

                      menuItems.add(
                        const DropdownMenuItem(
                          value: null, 
                          child: Row(
                            children: [
                              Icon(Icons.not_interested, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text("Bukan Wali Kelas", style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      );

                      for (var e in availableKelas) {
                        var d = e.data() as Map<String, dynamic>;
                        menuItems.add(
                          DropdownMenuItem(value: e.id, child: Text(d['namaKelas'] ?? "-")),
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonFormField<String?>(
                          decoration: const InputDecoration(border: InputBorder.none),
                          value: selectedWaliKelasId, 
                          isExpanded: true,
                          items: menuItems,
                          onChanged: (val) {
                            setState(() {
                              if (val == null) {
                                selectedWaliKelasId = null;
                                selectedWaliKelasNama = "-";
                              } else {
                                var doc = availableKelas.firstWhere((e) => e.id == val);
                                var d = doc.data() as Map<String, dynamic>;
                                selectedWaliKelasId = val;
                                selectedWaliKelasNama = d['namaKelas'];
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // PILIHAN MAPEL
                  const Text("Mata Pelajaran (Max 2)", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 10),
                  
                  Container(
                    width: double.infinity,
                    height: 250,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: semuaMapel.map((mapel) {
                          bool isSelected = selectedMapel.contains(mapel);
                          return FilterChip(
                            label: Text(mapel),
                            selected: isSelected,
                            selectedColor: Colors.blueAccent.withOpacity(0.2),
                            checkmarkColor: Colors.blue[800],
                            labelStyle: TextStyle(fontSize: 12, color: isSelected ? Colors.blue[800] : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                            backgroundColor: Colors.grey[100],
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  if (selectedMapel.length < 2) {
                                    selectedMapel.add(mapel);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Maksimal 2 Mapel")));
                                  }
                                } else {
                                  selectedMapel.remove(mapel);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
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
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isLoading ? null : _updateGuru,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SIMPAN PERUBAHAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),

            const SizedBox(height: 15),

            // TOMBOL KIRIM WA (FITUR BARU)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.send, color: Colors.green),
                label: const Text("Kirim Ulang Info Akun ke WA", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.green, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _kirimInfoViaWA,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInput({required TextEditingController controller, required String label, required IconData icon, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _updateGuru() async {
    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection("users").doc(widget.docId).update({
        "nama": _namaController.text,
        "nip": _nipController.text,
        "hp": _hpController.text,           // Update HP
        "alamat": _alamatController.text,   // Update Alamat
        
        "wali_kelas_id": selectedWaliKelasId ?? "", 
        "wali_kelas_nama": selectedWaliKelasNama ?? "-",
        "wali_kelas": selectedWaliKelasNama ?? "-", 
        "mapel": selectedMapel,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data Guru Berhasil Diperbarui!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}