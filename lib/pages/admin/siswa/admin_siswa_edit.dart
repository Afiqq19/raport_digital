import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSiswaEdit extends StatefulWidget {
  final String sid; // ID dokumen siswa
  const AdminSiswaEdit({super.key, required this.sid});

  @override
  State<AdminSiswaEdit> createState() => _AdminSiswaEditState();
}

class _AdminSiswaEditState extends State<AdminSiswaEdit> {
  final namaC = TextEditingController();
  // kelasC digunakan untuk menampung value dropdown
  final kelasC = TextEditingController(); 
  // jurusanC digunakan untuk menampung value dropdown
  final jurusanC = TextEditingController(); 
  
  final lahirC = TextEditingController();
  final alamatC = TextEditingController();
  final hpC = TextEditingController();
  final emailC = TextEditingController(); // Email sebaiknya ReadOnly

  String jk = "L";
  bool loading = true;

  // List Jurusan (Sama seperti di halaman Tambah)
  final List<String> listJurusan = [
    "Teknik Komputer dan Informatika",
    "Teknik Kendaraan Ringan",
    "Teknik Pemesinan",
    "Teknik Elektronika Industri",
    "Teknik Instalasi Tenaga Listrik",
    "Desain Pemodelan dan Informasi Bangunan",
    "Teknik Body Otomotif",
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.sid)
          .get();

      if (snap.exists) {
        final d = snap.data()!;
        setState(() {
          namaC.text = d['nama'] ?? "";
          kelasC.text = d['kelas'] ?? ""; // Isi nilai awal kelas
          jurusanC.text = d['jurusan'] ?? ""; // Isi nilai awal jurusan
          lahirC.text = d['tanggal_lahir'] ?? "";
          alamatC.text = d['alamat'] ?? "";
          hpC.text = d['hp'] ?? "";
          emailC.text = d['email'] ?? "";
          jk = d['jenis_kelamin'] ?? "L";
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  // Fungsi Kalender
  Future<void> pilihTanggal() async {
    DateTime? pilih = await showDatePicker(
      context: context,
      initialDate: DateTime(2008, 1, 1),
      firstDate: DateTime(1995),
      lastDate: DateTime(2025),
    );

    if (pilih != null) {
      setState(() {
        lahirC.text = "${pilih.year}-${pilih.month}-${pilih.day}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      appBar: AppBar(
        title: const Text("Edit Data Siswa"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  buildCard(
                    Column(
                      children: [
                        // Nama
                        field(namaC, "Nama Lengkap"),
                        const SizedBox(height: 12),

                        // ================= DROPDOWN KELAS (STREAM ANTI DUPLIKAT) =================
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('kelas').snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox(
                                height: 50, 
                                child: Center(child: LinearProgressIndicator())
                              );
                            }

                            var listKelasDocs = snapshot.data!.docs;
                            
                            // --- PERBAIKAN DI SINI: FILTER DUPLIKAT ---
                            // Kita pakai Set<String> untuk menampung nama kelas yang unik
                            Set<String> uniqueClassNames = {};
                            
                            for (var doc in listKelasDocs) {
                              var data = doc.data() as Map<String, dynamic>;
                              String nama = data['namaKelas'] ?? "";
                              if (nama.isNotEmpty) {
                                uniqueClassNames.add(nama); // Set otomatis menolak duplikat
                              }
                            }
                            
                            // Ubah Set kembali jadi List
                            List<String> finalClassList = uniqueClassNames.toList();
                            // Urutkan abjad (opsional)
                            finalClassList.sort();

                            // Cek apakah value yang tersimpan di user (kelasC.text) ada di daftar?
                            // Jika tidak ada (misal kelas sudah dihapus), set jadi null agar tidak crash
                            var validValue = finalClassList.contains(kelasC.text) 
                                ? kelasC.text 
                                : null;

                            return DropdownButtonFormField<String>(
                              decoration: inputStyle("Kelas"),
                              value: validValue,
                              items: finalClassList.map((namaKelas) {
                                return DropdownMenuItem(
                                  value: namaKelas,
                                  child: Text(namaKelas),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  kelasC.text = val!;
                                });
                              },
                            );
                          },
                        ),
                        // ==========================================================
                        const SizedBox(height: 12),

                        // ================= DROPDOWN JURUSAN =================
                        DropdownButtonFormField<String>(
                          decoration: inputStyle("Jurusan"),
                          isExpanded: true, // Agar teks panjang muat
                          value: listJurusan.contains(jurusanC.text) ? jurusanC.text : null,
                          items: listJurusan.map((e) => DropdownMenuItem(
                            value: e, 
                            child: Text(e, overflow: TextOverflow.ellipsis)
                          )).toList(),
                          onChanged: (v) => setState(() => jurusanC.text = v!),
                        ),
                        // ====================================================
                        const SizedBox(height: 12),

                        // Jenis Kelamin
                        DropdownButtonFormField(
                          value: jk,
                          items: const [
                            DropdownMenuItem(value: "L", child: Text("Laki-laki")),
                            DropdownMenuItem(value: "P", child: Text("Perempuan")),
                          ],
                          onChanged: (v) => setState(() => jk = v.toString()),
                          decoration: inputStyle("Jenis Kelamin"),
                        ),
                        const SizedBox(height: 12),

                        // Tanggal Lahir (Dengan Picker)
                        TextField(
                          controller: lahirC,
                          readOnly: true,
                          onTap: pilihTanggal,
                          decoration: inputStyle("Tanggal Lahir"),
                        ),
                        const SizedBox(height: 12),

                        // Alamat & HP
                        field(alamatC, "Alamat"),
                        const SizedBox(height: 12),
                        field(hpC, "No HP"),
                        const SizedBox(height: 12),
                        
                        // Email (ReadOnly agar tidak merusak login)
                        TextField(
                          controller: emailC,
                          readOnly: true,
                          decoration: inputStyle("Email (Tidak dapat diubah)"),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Tombol Simpan
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: updateData,
                    child: const Text(
                      "Simpan Perubahan",
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildCard(Widget child) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Widget field(TextEditingController c, String label) {
    return TextField(
      controller: c,
      decoration: inputStyle(label),
    );
  }

  InputDecoration inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  updateData() async {
    // Validasi sederhana
    if (namaC.text.isEmpty || kelasC.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Nama dan Kelas tidak boleh kosong")),
       );
       return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.sid)
          .update({
        "nama": namaC.text,
        "kelas": kelasC.text, // Value dari dropdown
        "jurusan": jurusanC.text, // Value dari dropdown
        "jenis_kelamin": jk,
        "tanggal_lahir": lahirC.text,
        "alamat": alamatC.text,
        "hp": hpC.text,
        // Email tidak diupdate karena terkait Auth
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data berhasil diperbarui")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal update: $e")),
      );
    }
  }
}