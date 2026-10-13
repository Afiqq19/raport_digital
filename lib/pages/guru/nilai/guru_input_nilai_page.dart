import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GuruInputNilaiPage extends StatefulWidget {
  final String namaKelas;

  const GuruInputNilaiPage({super.key, required this.namaKelas});

  @override
  State<GuruInputNilaiPage> createState() => _GuruInputNilaiPageState();
}

class _GuruInputNilaiPageState extends State<GuruInputNilaiPage> {
  String? selectedMapel;
  String? selectedKategori;
  
  List<String> listKategori = [
    "Tugas 1", "Tugas 2", "Tugas 3",
    "Ulangan Harian 1", "Ulangan Harian 2",
    "UTS", "UAS",
    "Keterampilan / Praktik"
  ];

  List<String> teacherMapels = [];
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _existingDocIds = {};

  bool isLoading = false;
  bool isFetchingData = false;

  // Variabel Global Akademik
  String tahunAjaranAktif = "Memuat..."; // Default text loading
  String semesterAktif = "";

  @override
  void initState() {
    super.initState();
    _loadTeacherMapels();
    _loadAkademikSettings(); // Panggil fungsi cek tahun ajaran
  }

  // --- AMBIL SETTING DARI DATABASE ---
  void _loadAkademikSettings() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('settings').doc('akademik').get();
      if (doc.exists) {
        if (mounted) {
          setState(() {
            tahunAjaranAktif = doc['tahun_ajaran'] ?? "2024/2025";
            semesterAktif = doc['semester'] ?? "Ganjil";
          });
        }
      } else {
        if (mounted) {
          setState(() {
            tahunAjaranAktif = "2024/2025";
            semesterAktif = "Ganjil";
          });
        }
      }
    } catch (e) {
      debugPrint("Error load akademik: $e");
    }
  }

  void _loadTeacherMapels() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        var data = doc.data()!;
        if (mounted) {
          setState(() {
            teacherMapels = List<String>.from(data['mapel'] ?? []);
            if (teacherMapels.isNotEmpty) {
              selectedMapel = teacherMapels[0];
              _fetchExistingGrades(); 
            }
          });
        }
      }
    }
  }

  void _fetchExistingGrades() async {
    // Pastikan setting akademik sudah terload sebelum fetch nilai
    if (tahunAjaranAktif == "Memuat..." || selectedMapel == null || selectedKategori == null) return;

    setState(() => isFetchingData = true);

    try {
      _controllers.forEach((key, ctrl) => ctrl.clear());
      _existingDocIds.clear();

      var snapshot = await FirebaseFirestore.instance
          .collection('nilai')
          .where('kelas', isEqualTo: widget.namaKelas)
          .where('mapel', isEqualTo: selectedMapel)
          .where('kategori', isEqualTo: selectedKategori)
          // Filter Nilai berdasarkan Tahun Ajaran Aktif
          .where('tahun_ajaran', isEqualTo: tahunAjaranAktif) 
          .where('semester', isEqualTo: semesterAktif)       
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data();
        String siswaId = data['siswa_id'];
        String nilai = data['nilai'].toString();

        _existingDocIds[siswaId] = doc.id;

        if (_controllers.containsKey(siswaId)) {
          _controllers[siswaId]!.text = nilai;
        }
      }
    } catch (e) {
      debugPrint("Error fetching grades: $e");
    } finally {
      if (mounted) setState(() => isFetchingData = false);
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      
      // ================= APP BAR YANG DIPERBARUI =================
      appBar: AppBar(
        // Menggunakan Column agar ada Judul Besar dan Info Kecil di bawahnya
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Input Nilai ${widget.namaKelas}", 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            // Tampilkan Tahun Ajaran Disini
            Text(
              "Semester $semesterAktif $tahunAjaranAktif", 
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300)
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isLoading ? null : _simpanNilaiBatch,
            icon: const Icon(Icons.save),
            tooltip: "Simpan Semua",
          )
        ],
      ),
      // ===========================================================

      body: Column(
        children: [
          // FILTER SECTION
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))
              ],
            ),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: _inputDecor("Mata Pelajaran", Icons.book),
                  value: selectedMapel,
                  hint: const Text("Pilih Mapel"),
                  items: teacherMapels.isEmpty 
                      ? [] 
                      : teacherMapels.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) {
                    setState(() => selectedMapel = val);
                    _fetchExistingGrades(); 
                  },
                ),
                const SizedBox(height: 12),
                
                DropdownButtonFormField<String>(
                  decoration: _inputDecor("Kategori Nilai", Icons.category),
                  value: selectedKategori,
                  hint: const Text("Pilih Kategori"),
                  items: listKategori.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                  onChanged: (val) {
                    setState(() => selectedKategori = val);
                    _fetchExistingGrades(); 
                  },
                ),
              ],
            ),
          ),

          // LIST SISWA
          Expanded(
            child: isFetchingData 
              ? const Center(child: CircularProgressIndicator()) 
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'siswa')
                      .where('kelas', isEqualTo: widget.namaKelas)
                      .orderBy('nama')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    var docs = snapshot.data!.docs;
                    if (docs.isEmpty) return const Center(child: Text("Tidak ada siswa."));

                    return ListView.builder(
                      padding: const EdgeInsets.all(15),
                      itemCount: docs.length + 1,
                      itemBuilder: (context, index) {
                        if (index == docs.length) return const SizedBox(height: 80);

                        var data = docs[index].data() as Map<String, dynamic>;
                        String uid = docs[index].id;
                        String nama = data['nama'] ?? "-";
                        String nisn = data['nisn'] ?? "-";

                        if (!_controllers.containsKey(uid)) {
                          _controllers[uid] = TextEditingController();
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.teal.shade50,
                                  child: Text(
                                    nama.isNotEmpty ? nama[0].toUpperCase() : "?",
                                    style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text(nisn, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: _controllers[uid],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    maxLength: 3,
                                    decoration: InputDecoration(
                                      counterText: "",
                                      hintText: "0",
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Colors.teal, width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        onPressed: isLoading ? null : _simpanNilaiBatch,
        icon: isLoading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
          : const Icon(Icons.save),
        label: Text(isLoading ? "Menyimpan..." : "Simpan Nilai"),
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.teal),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    );
  }

  Future<void> _simpanNilaiBatch() async {
    if (selectedMapel == null || selectedKategori == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih Mapel & Kategori dulu!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      int count = 0;
      String guruId = FirebaseAuth.instance.currentUser!.uid;
      
      // Ambil variabel global yang sudah diload
      String thn = tahunAjaranAktif; 
      String smt = semesterAktif;

      _controllers.forEach((siswaId, controller) {
        String nilaiStr = controller.text.trim();
        
        if (nilaiStr.isNotEmpty) {
          int nilaiAngka = int.tryParse(nilaiStr) ?? 0;
          if (nilaiAngka < 0) nilaiAngka = 0;
          if (nilaiAngka > 100) nilaiAngka = 100;

          if (_existingDocIds.containsKey(siswaId)) {
            // UPDATE DATA LAMA
            String docId = _existingDocIds[siswaId]!;
            DocumentReference docRef = FirebaseFirestore.instance.collection('nilai').doc(docId);
            
            batch.update(docRef, {
              "nilai": nilaiAngka,
              "updated_at": DateTime.now().toIso8601String(),
            });
          } else {
            // BUAT DATA BARU
            DocumentReference docRef = FirebaseFirestore.instance.collection('nilai').doc();
            batch.set(docRef, {
              "siswa_id": siswaId,
              "guru_id": guruId,
              "kelas": widget.namaKelas,
              "mapel": selectedMapel,
              "kategori": selectedKategori,
              "semester": smt,       
              "tahun_ajaran": thn,   
              "nilai": nilaiAngka,
              "created_at": DateTime.now().toIso8601String(),
            });
          }
          count++;
        }
      });

      if (count > 0) {
        await batch.commit();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Berhasil menyimpan $count nilai!"), 
              backgroundColor: Colors.teal,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // --- PERBAIKAN DI SINI ---
          // 1. HAPUS Navigator.pop(context); agar tidak keluar halaman
          
          // 2. Refresh data agar ID dokumen baru terdeteksi
          _fetchExistingGrades(); 
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tidak ada nilai yang diisi."), backgroundColor: Colors.orange),
          );
        }
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}