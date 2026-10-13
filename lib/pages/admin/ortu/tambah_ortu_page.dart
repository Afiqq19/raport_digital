import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class TambahOrtuPage extends StatefulWidget {
  const TambahOrtuPage({super.key});

  @override
  State<TambahOrtuPage> createState() => _TambahOrtuPageState();
}

class _TambahOrtuPageState extends State<TambahOrtuPage> {
  final TextEditingController _namaController = TextEditingController();
  
  // Variabel untuk menampung Siswa yang dipilih
  String? selectedSiswaId;
  String? selectedSiswaNama;
  String? selectedSiswaNisn;
  String? selectedSiswaKelas;

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Akun Orang Tua"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Nama Orang Tua
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: "Nama Orang Tua / Wali",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Dropdown Pilih Siswa
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Hubungkan dengan Siswa:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            
            StreamBuilder<QuerySnapshot>(
              // Ambil data user yang role-nya 'siswa'
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .where("role", isEqualTo: "siswa")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var siswaList = snapshot.data!.docs;

                // Urutkan siswa berdasarkan nama (opsional)
                siswaList.sort((a, b) => (a['nama'] as String).compareTo(b['nama'] as String));

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Pilih Siswa",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.child_care),
                  ),
                  value: selectedSiswaId,
                  isExpanded: true,
                  items: siswaList.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String nisn = data['nisn'] ?? "-";
                    String nama = data['nama'] ?? "Tanpa Nama";
                    String kelas = data['kelas'] ?? "-";

                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text("$nama ($kelas) - $nisn", overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    var doc = siswaList.firstWhere((d) => d.id == val);
                    var data = doc.data() as Map<String, dynamic>;
                    
                    setState(() {
                      selectedSiswaId = val;
                      selectedSiswaNama = data['nama'];
                      selectedSiswaNisn = data['nisn']; // Penting untuk login
                      selectedSiswaKelas = data['kelas'];
                    });
                  },
                );
              },
            ),

            if (selectedSiswaNisn != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Login Otomatis:\nEmail: $selectedSiswaNisn@ortu.com\nPass: 123456",
                          style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: isLoading ? null : _simpanOrtu,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SIMPAN DATA ORTU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simpanOrtu() async {
    if (_namaController.text.isEmpty || selectedSiswaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama dan Siswa wajib dipilih!")));
      return;
    }

    // Pastikan siswa punya NISN untuk jadi username
    if (selectedSiswaNisn == null || selectedSiswaNisn == "" || selectedSiswaNisn == "-") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Siswa yang dipilih tidak memiliki NISN valid.")));
      return;
    }

    setState(() => isLoading = true);

    FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'SecondaryAppOrtu',
      options: Firebase.app().options,
    );

    try {
      // Login menggunakan NISN Anak
      String email = "$selectedSiswaNisn@ortu.com";
      String password = "123456";

      // 1. Buat Akun Auth
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // 2. Simpan ke Firestore
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "nama": _namaController.text, // Nama Orang Tua
        "email": email,
        "role": "ortu", // Role Ortu
        "siswa_id": selectedSiswaId,       // Link ke ID Siswa
        "siswa_nama": selectedSiswaNama,   // Nama Siswa (untuk display cepat)
        "siswa_nisn": selectedSiswaNisn,
        "siswa_kelas": selectedSiswaKelas,
        "created_at": DateTime.now().toIso8601String(),
      });

      await secondaryApp.delete();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil membuat akun Orang Tua!")));
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}