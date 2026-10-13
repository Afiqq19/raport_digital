import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
// 1. IMPORT WAJIB UNTUK SPREADSHEET
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminSiswaAdd extends StatefulWidget {
  const AdminSiswaAdd({super.key});

  @override
  State<AdminSiswaAdd> createState() => _AdminSiswaAddState();
}

class _AdminSiswaAddState extends State<AdminSiswaAdd> {
  // 2. MASUKKAN URL APPS SCRIPT KAMU DI SINI
  final String scriptUrl = "https://script.google.com/macros/s/AKfycbx_L94_DqJ7yS8KOWbGIAN47YtgWUAgYeIJaUHzA4uckLXI0r8TVEQuaZMaGkvEXtJY/exec"; 

  final nisnC = TextEditingController();
  final namaC = TextEditingController();
  final kelasC = TextEditingController(); // Value dari dropdown
  final jurusanC = TextEditingController();
  final lahirC = TextEditingController();
  final alamatC = TextEditingController();
  final hpC = TextEditingController();

  String jk = "L";
  bool loading = false;
  String errorMsg = "";

  // List Jurusan
  final List<String> listJurusan = [
    "Teknik Komputer dan Informatika",
    "Teknik Kendaraan Ringan",
    "Teknik Pemesinan",
    "Teknik Elektronika Industri",
    "Teknik Instalasi Tenaga Listrik",
    "Desain Pemodelan dan Informasi Bangunan",
    "Teknik Body Otomotif",
  ];

  // Helper: Membersihkan nama untuk dijadikan email
  String sanitizeName(String name) {
    String cleaned = name.toLowerCase();
    cleaned = cleaned.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return cleaned;
  }

  Future<void> pilihTanggal() async {
    DateTime? pilih = await showDatePicker(
      context: context,
      initialDate: DateTime(2008, 1, 1),
      firstDate: DateTime(1995),
      lastDate: DateTime(2015),
    );

    if (pilih != null) {
      setState(() {
        lahirC.text = "${pilih.year}-${pilih.month}-${pilih.day}";
      });
    }
  }

  // 3. FUNGSI KIRIM DATA KE GOOGLE SPREADSHEET
  Future<void> kirimKeSpreadsheet(String nama, String nisn, String pass, String kelas, String email) async {
    try {
      var url = Uri.parse(scriptUrl);
      await http.post(url, body: jsonEncode({
        "nama": nama,
        "nisn": nisn,
        "password": pass,
        "kelas": kelas,
        "email": email, // Email ikut terkirim
      }));
    } catch (e) {
      debugPrint("Error Spreadsheet: $e");
    }
  }

  Future<void> saveData() async {
    String nisn = nisnC.text.trim();
    String nama = namaC.text.trim();
    String selectedKelas = kelasC.text.trim(); 
    String jurusan = jurusanC.text.trim();
    
    // Validasi Input Kosong
    if (nisn.isEmpty || nama.isEmpty || selectedKelas.isEmpty || jurusan.isEmpty) {
       setState(() {
         errorMsg = "Semua data wajib diisi!";
       });
       return;
    }

    // --- LOGIKA EMAIL BARU ---
    String emailUser = sanitizeName(nama);
    String email = "$emailUser@budhidarma.com";
    String password = nisn;

    setState(() {
      loading = true;
      errorMsg = "";
    });

    try {
      // 1. CEK KUOTA KELAS (MAX 30)
      var cekKelas = await FirebaseFirestore.instance
          .collection('users')
          .where('kelas', isEqualTo: selectedKelas)
          .where('role', isEqualTo: 'siswa')
          .get();

      if (cekKelas.docs.length >= 30) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text("GAGAL: Kelas $selectedKelas sudah penuh (Max 30)!"),
               backgroundColor: Colors.red,
             )
          );
        }
        setState(() => loading = false);
        return; 
      }

      // 2. BUAT AKUN DI AUTH (PAKAI SECONDARY APP)
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      UserCredential userCred = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCred.user!.uid;

      // 3. SIMPAN DATA KE FIRESTORE
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "uid": uid,
        "role": "siswa",
        "username": nisn,
        "nisn": nisn,
        "nama": nama,
        "kelas": selectedKelas,
        "jurusan": jurusan,
        "jenis_kelamin": jk,
        "tanggal_lahir": lahirC.text.trim(),
        "alamat": alamatC.text.trim(),
        "hp": hpC.text.trim(),
        "email": email,
        "created_at": DateTime.now().toIso8601String(),
      });

      // Hapus app sekunder
      await secondaryApp.delete();

      // 4. KIRIM JUGA KE GOOGLE SPREADSHEET
      await kirimKeSpreadsheet(nama, nisn, password, selectedKelas, email);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Berhasil! Login pakai NISN: $nisn")),
        );
      }

    } catch (e) {
      setState(() {
        errorMsg = "Gagal: $e";
      });
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Siswa")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          modernField(nisnC, "NISN (Akan jadi Password)"),
          const SizedBox(height: 12),

          modernField(namaC, "Nama Lengkap"),
          const SizedBox(height: 5),
          const Text(
            "*Email akan otomatis dibuat dari nama (contoh@budhidarma.com)",
            style: TextStyle(color: Colors.grey, fontSize: 12)
          ),
          const SizedBox(height: 12),

          // DROPDOWN KELAS
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('kelas').orderBy('namaKelas').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var listKelasDocs = snapshot.data!.docs;

              return DropdownButtonFormField<String>(
                decoration: inputStyle("Pilih Kelas"),
                value: kelasC.text.isEmpty ? null : kelasC.text,
                items: listKelasDocs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String namaKelas = data['namaKelas'] ?? "Tanpa Nama";
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
          
          const SizedBox(height: 12),

          DropdownButtonFormField(
            value: jurusanC.text.isEmpty ? null : jurusanC.text,
            items: listJurusan
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => jurusanC.text = v!),
            decoration: inputStyle("Jurusan"),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField(
            value: jk,
            items: const [
              DropdownMenuItem(value: "L", child: Text("Laki-laki")),
              DropdownMenuItem(value: "P", child: Text("Perempuan")),
            ],
            onChanged: (v) => setState(() => jk = v!),
            decoration: inputStyle("Jenis Kelamin"),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: lahirC,
            readOnly: true,
            onTap: pilihTanggal,
            decoration: inputStyle("Tanggal Lahir"),
          ),
          const SizedBox(height: 12),

          modernField(alamatC, "Alamat"),
          const SizedBox(height: 12),

          modernField(hpC, "No HP"),
          const SizedBox(height: 12),

          if (errorMsg.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(errorMsg, style: const TextStyle(color: Colors.red)),
            ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: loading ? null : saveData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("SIMPAN DATA SISWA", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget modernField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      decoration: inputStyle(label),
    );
  }

  InputDecoration inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}