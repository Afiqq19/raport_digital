import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminKenaikanKelasPage extends StatefulWidget {
  const AdminKenaikanKelasPage({super.key});

  @override
  State<AdminKenaikanKelasPage> createState() => _AdminKenaikanKelasPageState();
}

class _AdminKenaikanKelasPageState extends State<AdminKenaikanKelasPage> {
  // Variabel Pilihan
  String? selectedJurusan; // <--- FILTER BARU
  String? kelasAsal;
  String? kelasTujuanOtomatis;
  
  String tahunAjaranAktif = "Memuat..."; 
  bool isLoading = false;
  int jumlahSiswa = 0;

  // Daftar Jurusan (Sesuaikan dengan data sekolah)
  final List<String> listJurusan = [
    "Teknik Komputer dan Informatika (TKJ)",
    "Teknik Kendaraan Ringan (TKR)",
    "Teknik Pemesinan (TPM)",
    "Teknik Elektronika Industri (TEI)",
    "Teknik Instalasi Tenaga Listrik (TITL)",
    "Desain Pemodelan dan Informasi Bangunan (DPIB)",
    "Teknik Body Otomotif (TBO)"
  ];

  @override
  void initState() {
    super.initState();
    _loadTahunAjaran();
  }

  void _loadTahunAjaran() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('settings').doc('akademik').get();
      if (doc.exists) {
        setState(() {
          tahunAjaranAktif = doc['tahun_ajaran'] ?? "${DateTime.now().year}/${DateTime.now().year + 1}";
        });
      } else {
        setState(() => tahunAjaranAktif = "${DateTime.now().year}/${DateTime.now().year + 1}");
      }
    } catch (e) {
      debugPrint("Gagal load tahun ajaran: $e");
    }
  }

  // --- LOGIKA GENERATE KELAS ---
  String _generateKelasTujuan(String kelasLama) {
    String tahunLulus = tahunAjaranAktif.split('/')[1]; 

    if (kelasLama.startsWith("XII ")) {
      return "ALUMNI $tahunLulus"; 
    }
    if (kelasLama.startsWith("XI ")) {
      return kelasLama.replaceFirst("XI ", "XII ");
    }
    if (kelasLama.startsWith("X ")) {
      return kelasLama.replaceFirst("X ", "XI ");
    }
    return kelasLama; 
  }

  void _hitungSiswa(String namaKelas) async {
    var snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'siswa')
        .where('kelas', isEqualTo: namaKelas)
        .count()
        .get();
    
    setState(() {
      jumlahSiswa = snap.count ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        title: const Text("Proses Kenaikan Kelas"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // INFO TAHUN AJARAN
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  const Text("TAHUN AJARAN AKTIF", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(tahunAjaranAktif, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // ============================================================
            // 1. PILIH JURUSAN (FILTER)
            // ============================================================
            const Text("Langkah 1: Pilih Jurusan", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  prefixIcon: Icon(Icons.category, color: Colors.orange),
                ),
                value: selectedJurusan,
                hint: const Text("Pilih Jurusan Dulu"),
                items: listJurusan.map((j) => DropdownMenuItem(value: j, child: Text(j, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedJurusan = val;
                    // Reset kelas saat jurusan ganti
                    kelasAsal = null; 
                    kelasTujuanOtomatis = null;
                    jumlahSiswa = 0;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            // ============================================================
            // 2. PILIH KELAS ASAL (YANG SUDAH DI-FILTER)
            // ============================================================
            const Text("Langkah 2: Pilih Kelas Asal", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // Tampilkan Dropdown Kelas HANYA jika jurusan sudah dipilih
            if (selectedJurusan == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                child: const Text("Silakan pilih jurusan di atas terlebih dahulu.", style: TextStyle(color: Colors.grey)),
              )
            else
              StreamBuilder<QuerySnapshot>(
                // Ambil kelas yang jurusannya sesuai pilihan di atas
                stream: FirebaseFirestore.instance
                    .collection('kelas')
                    .where('jurusan', isEqualTo: selectedJurusan) // FILTER DISINI
                    .orderBy('namaKelas')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  var list = snapshot.data!.docs;
                  
                  if (list.isEmpty) {
                    return const Text("Tidak ada data kelas untuk jurusan ini.");
                  }

                  return Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        prefixIcon: Icon(Icons.meeting_room, color: Colors.orange),
                      ),
                      value: kelasAsal,
                      hint: const Text("Pilih Kelas (Misal: X TKJ 1)"),
                      items: list.map((doc) {
                        String namaK = doc['namaKelas'];
                        return DropdownMenuItem(value: namaK, child: Text(namaK));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          kelasAsal = val;
                          kelasTujuanOtomatis = _generateKelasTujuan(val!);
                          _hitungSiswa(val);
                        });
                      },
                    ),
                  );
                },
              ),
            
            const SizedBox(height: 20),
            const Center(child: Icon(Icons.arrow_circle_down, size: 40, color: Colors.grey)),
            const SizedBox(height: 20),

            // OUTPUT KELAS TUJUAN
            const Text("Akan Dipindahkan Ke:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kelasTujuanOtomatis != null && kelasTujuanOtomatis!.contains("ALUMNI") 
                    ? Colors.green.shade50 
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: kelasTujuanOtomatis != null && kelasTujuanOtomatis!.contains("ALUMNI") 
                      ? Colors.green 
                      : Colors.blue
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    kelasTujuanOtomatis ?? "-",
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: kelasTujuanOtomatis != null && kelasTujuanOtomatis!.contains("ALUMNI") ? Colors.green : Colors.blue
                    ),
                  ),
                  if (kelasTujuanOtomatis != null && kelasTujuanOtomatis!.contains("ALUMNI"))
                    const Chip(label: Text("LULUS"), backgroundColor: Colors.green, labelStyle: TextStyle(color: Colors.white))
                ],
              ),
            ),
            
            const SizedBox(height: 15),
            if (kelasAsal != null)
              Center(
                child: Text(
                  "Akan memproses $jumlahSiswa Siswa", 
                  style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)
                )
              ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5
                ),
                onPressed: (isLoading || kelasAsal == null || jumlahSiswa == 0) 
                    ? null 
                    : _prosesKenaikanOtomatis,
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("PROSES SEKARANG", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _prosesKenaikanOtomatis() async {
    if (kelasAsal == null || kelasTujuanOtomatis == null) return;

    setState(() => isLoading = true);

    try {
      // 1. CEK KELAS TUJUAN KOSONG?
      if (!kelasTujuanOtomatis!.contains("ALUMNI")) {
        var cekTarget = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'siswa')
            .where('kelas', isEqualTo: kelasTujuanOtomatis)
            .get();

        if (cekTarget.docs.isNotEmpty) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("⛔ GAGAL PROSES", style: TextStyle(color: Colors.red)),
                content: Text(
                  "Kelas Tujuan ($kelasTujuanOtomatis) BELUM KOSONG!\n\n"
                  "Masih ada ${cekTarget.docs.length} siswa di kelas tersebut.\n"
                  "Harap naikkan/luluskan dulu siswa di kelas $kelasTujuanOtomatis."
                ),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
              ),
            );
          }
          setState(() => isLoading = false);
          return;
        }
      }

      // 2. KONFIRMASI
      bool confirm = await showDialog(
        context: context, 
        builder: (ctx) => AlertDialog(
          title: const Text("Konfirmasi"),
          content: Text("Pindahkan $jumlahSiswa siswa dari $kelasAsal ke $kelasTujuanOtomatis?\n\nTahun Ajaran: $tahunAjaranAktif"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("YA, PROSES")),
          ],
        )
      ) ?? false;

      if (!confirm) {
        setState(() => isLoading = false);
        return;
      }

      // 3. EKSEKUSI
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'siswa')
          .where('kelas', isEqualTo: kelasAsal)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      bool isLulus = kelasTujuanOtomatis!.contains("ALUMNI");
      String roleBaru = isLulus ? "alumni" : "siswa"; 

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'kelas': kelasTujuanOtomatis, 
          'role': roleBaru, 
          'history_kelas': FieldValue.arrayUnion([
            "Naik ke $kelasTujuanOtomatis (TA $tahunAjaranAktif)"
          ])
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil memindahkan siswa!"), backgroundColor: Colors.green),
        );
        setState(() {
          kelasAsal = null;
          kelasTujuanOtomatis = null;
          jumlahSiswa = 0;
        });
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}