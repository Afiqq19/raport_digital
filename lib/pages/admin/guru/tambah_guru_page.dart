import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart'; 

// IMPORT DATA MAPEL
import '../../../data/mapel_list.dart'; 

class TambahGuruPage extends StatefulWidget {
  const TambahGuruPage({super.key});

  @override
  State<TambahGuruPage> createState() => _TambahGuruPageState();
}

class _TambahGuruPageState extends State<TambahGuruPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nipController = TextEditingController();
  final TextEditingController _hpController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  List<String> selectedMapel = [];
  String? selectedWaliKelasId;
  String? selectedWaliKelasNama;
  List<String> kelasSudahAdaWali = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _cekKelasYangSudahDiambil();
  }

  void _cekKelasYangSudahDiambil() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'guru')
        .get();

    List<String> takenIds = [];
    for (var doc in snapshot.docs) {
      var data = doc.data();
      if (data['wali_kelas_id'] != null && data['wali_kelas_id'] != "") {
        takenIds.add(data['wali_kelas_id']);
      }
    }
    if (mounted) {
      setState(() {
        kelasSudahAdaWali = takenIds;
      });
    }
  }

  // --- 1. HELPER: BERSIHKAN NAMA UNTUK EMAIL ---
  String _sanitizeName(String name) {
    // Kecilkan huruf, hapus spasi dan simbol, ambil huruf/angka saja
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  // --- 2. LOGIKA WHATSAPP ---
  String _formatNoHp(String nomor) {
    String bersih = nomor.replaceAll(RegExp(r'\D'), ''); 
    if (bersih.startsWith('0')) {
      return "62${bersih.substring(1)}";
    } else if (bersih.startsWith('8')) {
      return "62$bersih";
    }
    return bersih;
  }

  Future<void> _kirimWhatsApp(String nama, String noHp, String nip, String password, String email) async {
    String formattedHp = _formatNoHp(noHp);
    String linkDownload = "https://www.mediafire.com/folder/gpmj2h309itns/SIAKAD+SMK";
    
    // Isi Pesan (Menampilkan Email & NIP)
    String pesan = "*Info Akun Raport Digital SMK Budhi Darma*\n\n"
        "Yth. Bapak/Ibu *$nama*,\n"
        "Berikut akun Login Anda:\n\n"
        "👤 Username (NIP): *$nip*\n"
        "📧 Email Sistem: *$email*\n"
        "🔑 Password: *$password*\n\n"
        "Silakan login menggunakan NIP Anda.\n\n"
        "⬇️ *Download Aplikasi Disini:*\n"
        "$linkDownload";

    String url = "https://wa.me/$formattedHp?text=${Uri.encodeComponent(pesan)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
       debugPrint("Gagal membuka WhatsApp");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Guru"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FORM INPUT
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(labelText: "Nama Lengkap", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _nipController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "NIP", helperText: "NIP akan jadi Username Login", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _hpController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "No Handphone / WA", hintText: "08123456789", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _alamatController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Alamat Lengkap", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            // DROPDOWN WALI KELAS
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("kelas").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                var allKelas = snapshot.data!.docs;
                var availableKelas = allKelas.where((doc) => !kelasSudahAdaWali.contains(doc.id)).toList();

                List<DropdownMenuItem<String?>> menuItems = [];
                menuItems.add(const DropdownMenuItem(value: null, child: Text("Bukan Wali Kelas", style: TextStyle(color: Colors.grey))));
                for (var e in availableKelas) {
                   var data = e.data() as Map<String, dynamic>;
                   menuItems.add(DropdownMenuItem(value: e.id, child: Text(data['namaKelas'] ?? "-")));
                }

                return DropdownButtonFormField<String?>(
                  decoration: const InputDecoration(labelText: "Wali Kelas (Opsional)", border: OutlineInputBorder()),
                  value: selectedWaliKelasId,
                  items: menuItems,
                  onChanged: (val) {
                    setState(() {
                      if (val == null) {
                        selectedWaliKelasId = null;
                        selectedWaliKelasNama = "-";
                      } else {
                        var doc = availableKelas.firstWhere((e) => e.id == val);
                        var data = doc.data() as Map<String, dynamic>;
                        selectedWaliKelasId = val;
                        selectedWaliKelasNama = data['namaKelas']; 
                      }
                    });
                  },
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // MAPEL
            const Text("Mata Pelajaran (Max 2):", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              height: 200, 
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: semuaMapel.map((mapel) {
                    var isSelected = selectedMapel.contains(mapel);
                    return FilterChip(
                      label: Text(mapel, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
                      selected: isSelected,
                      selectedColor: Colors.blueAccent,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.grey.shade100,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            if (selectedMapel.length < 2) selectedMapel.add(mapel);
                            else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Maksimal 2 Mapel!")));
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

            const SizedBox(height: 30),

            // --- 3. DUA TOMBOL PILIHAN ---
            Row(
              children: [
                // TOMBOL 1: SIMPAN SAJA
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700], // Warna beda
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isLoading ? null : () => _simpanGuru(kirimWA: false),
                      child: const Text("SIMPAN SAJA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // TOMBOL 2: SIMPAN & KIRIM WA
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // Warna WA
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isLoading ? null : () => _simpanGuru(kirimWA: true),
                      child: isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text("SIMPAN & WA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- FUNGSI SIMPAN (TERIMA PARAMETER KIRIM WA) ---
  Future<void> _simpanGuru({required bool kirimWA}) async {
    if (_namaController.text.isEmpty || _nipController.text.isEmpty || _hpController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama, NIP dan No HP Wajib Diisi")));
       return;
    }

    setState(() => isLoading = true);

    try {
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      String nama = _namaController.text.trim();
      String nip = _nipController.text.trim();
      
      // LOGIKA EMAIL BARU: Pake Nama Bersih + Domain Kampus
      String cleanName = _sanitizeName(nama); 
      String email = "$cleanName@budhidarma.ac.id"; 
      
      String password = "123456"; 

      // Create User di Auth
      UserCredential cred = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = cred.user!.uid;

      // Simpan ke Firestore
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "uid": uid, // Tambahan UID di dokumen
        "nama": nama,
        "nip": nip,             
        "email": email,         // Email format nama disimpan
        "role": "guru",         
        
        "hp": _hpController.text.trim(),     
        "alamat": _alamatController.text.trim(), 
        
        "wali_kelas_id": selectedWaliKelasId ?? "",
        "wali_kelas_nama": selectedWaliKelasNama ?? "-",
        "wali_kelas": selectedWaliKelasNama ?? "-",
        
        "mapel": selectedMapel,
        "created_at": DateTime.now().toIso8601String(),
        "password_default": true, // Penanda akun baru
      });

      await secondaryApp.delete(); 

      if (mounted) {
        // JIKA TOMBOL WA DITEKAN
        if (kirimWA) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Membuka WhatsApp...")));
           await _kirimWhatsApp(nama, _hpController.text, nip, password, email);
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data Guru Berhasil Disimpan!")));
        }

        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}