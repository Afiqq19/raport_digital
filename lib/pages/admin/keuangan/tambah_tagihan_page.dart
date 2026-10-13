import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 

class TambahTagihanPage extends StatefulWidget {
  const TambahTagihanPage({super.key});

  @override
  State<TambahTagihanPage> createState() => _TambahTagihanPageState();
}

class _TambahTagihanPageState extends State<TambahTagihanPage> {
  // Controller
  final _judulC = TextEditingController();
  
  // 1. DEFAULT NOMINAL RP 250.000
  final _jumlahC = TextEditingController(text: "250000"); 
  final _jatuhTempoC = TextEditingController();

  // Variabel Data
  String? selectedKelas;
  List<Map<String, dynamic>> siswaList = []; 
  List<String> selectedSiswaIds = [];
  
  bool isLoading = false;
  bool isCheckAll = false;
  bool isFetchingSiswa = false; 

  @override
  void initState() {
    super.initState();
    _setDefaults();
  }

  // 2. DEFAULT TANGGAL 1 BULAN DEPAN
  void _setDefaults() {
    DateTime now = DateTime.now();
    
    // Logic: Jika sekarang Desember (12), bulan depan Januari (1) tahun depan
    // Jika tidak, bulan + 1, tanggal tetap 1
    DateTime nextMonth = (now.month == 12) 
        ? DateTime(now.year + 1, 1, 1) 
        : DateTime(now.year, now.month + 1, 1);
    
    // Format Judul Otomatis (Contoh: SPP Januari 2026)
    String namaBulan = DateFormat('MMMM yyyy', 'id_ID').format(nextMonth);
    _judulC.text = "SPP $namaBulan";
    
    // Format Tanggal Input (01-01-2026)
    _jatuhTempoC.text = "${nextMonth.day}-${nextMonth.month}-${nextMonth.year}";
  }

  // --- FUNGSI AMBIL SISWA BERDASARKAN KELAS ---
  void _getSiswaByKelas(String kelas) async {
    setState(() {
      isFetchingSiswa = true;
      siswaList.clear();       
      selectedSiswaIds.clear(); 
      isCheckAll = false;
    });

    try {
      var snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'siswa')
          .where('kelas', isEqualTo: kelas)
          .orderBy('nama')
          .get();

      List<Map<String, dynamic>> tempData = [];
      for (var doc in snap.docs) {
        tempData.add({
          "id": doc.id,
          "nama": doc['nama'],
          "nisn": doc['nisn']
        });
      }

      if (mounted) {
        setState(() {
          siswaList = tempData;
          isFetchingSiswa = false;
        });
      }
    } catch (e) {
      debugPrint("Error ambil siswa: $e");
      if (mounted) setState(() => isFetchingSiswa = false);
    }
  }

  void _toggleSelectAll(bool? val) {
    setState(() {
      isCheckAll = val ?? false;
      if (isCheckAll) {
        selectedSiswaIds = siswaList.map((e) => e['id'] as String).toList();
      } else {
        selectedSiswaIds.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Tagihan Massal"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // INFO TAGIHAN
            const Text("Info Tagihan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            
            TextField(
              controller: _judulC,
              decoration: const InputDecoration(labelText: "Judul Tagihan", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _jumlahC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Nominal (Rp)", border: OutlineInputBorder(), prefixText: "Rp "),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _jatuhTempoC,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: "Jatuh Tempo", suffixIcon: Icon(Icons.calendar_month), border: OutlineInputBorder()),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _jatuhTempoC.text = "${picked.day}-${picked.month}-${picked.year}";
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),
            const Divider(thickness: 2),
            const SizedBox(height: 15),

            // PILIH KELAS
            const Text("Target Siswa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('kelas').orderBy('namaKelas').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                var docs = snapshot.data!.docs;
                
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 15)),
                  hint: const Text("Pilih Kelas"),
                  value: selectedKelas,
                  items: docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: data['namaKelas'] as String,
                      child: Text(data['namaKelas']),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedKelas = val;
                    });
                    if (val != null) _getSiswaByKelas(val);
                  },
                );
              },
            ),

            const SizedBox(height: 10),

            // LIST SISWA
            if (isFetchingSiswa) ...[
               const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
            ]
            else if (siswaList.isNotEmpty) ...[
              CheckboxListTile(
                title: const Text("Pilih Semua Siswa"),
                value: isCheckAll,
                onChanged: _toggleSelectAll,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              
              Container(
                height: 300, 
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                child: ListView.builder(
                  itemCount: siswaList.length,
                  itemBuilder: (context, index) {
                    var s = siswaList[index];
                    bool isSelected = selectedSiswaIds.contains(s['id']);
                    
                    return CheckboxListTile(
                      title: Text(s['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(s['nisn']),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedSiswaIds.add(s['id']);
                          } else {
                            selectedSiswaIds.remove(s['id']);
                          }
                          isCheckAll = selectedSiswaIds.length == siswaList.length;
                        });
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 10),
              Text("Total Siswa Dipilih: ${selectedSiswaIds.length}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ] else if (selectedKelas != null) ...[
              const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("Kelas ini kosong / Belum ada siswa.")))
            ],

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: isLoading || selectedSiswaIds.isEmpty ? null : _prosesTagihanMassal,
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("PROSES TAGIHAN & REMINDER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- LOGIKA UTAMA (TAGIHAN + REMINDER) ---
  Future<void> _prosesTagihanMassal() async {
    if (_judulC.text.isEmpty || _jumlahC.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lengkapi data tagihan!")));
      return;
    }

    setState(() => isLoading = true);

    WriteBatch batch = FirebaseFirestore.instance.batch();
    
    try {
      int jumlahTagihan = 0;
      int jumlahReminder = 0;

      for (String uid in selectedSiswaIds) {
        var siswaData = siswaList.firstWhere((e) => e['id'] == uid);
        String namaSiswa = siswaData['nama'];

        // 1. BUAT TAGIHAN BULAN INI (Desember)
        DocumentReference refBaru = FirebaseFirestore.instance.collection('tagihan').doc();
        batch.set(refBaru, {
          'siswa_id': uid,
          'siswa_nama': namaSiswa,
          'kelas': selectedKelas,
          'judul': _judulC.text,
          'jumlah': int.parse(_jumlahC.text),
          'jatuh_tempo': _jatuhTempoC.text,
          'status': 'BELUM LUNAS',
          'created_at': FieldValue.serverTimestamp(),
          'tipe': 'SPP', 
        });
        jumlahTagihan++;

        // 2. CEK TUNGGAKAN BULAN LALU (REMINDER OTOMATIS)
        // Kita cek apakah ada tagihan tipe SPP yang statusnya BELUM LUNAS di database
        var queryTunggakan = await FirebaseFirestore.instance
            .collection('tagihan')
            .where('siswa_id', isEqualTo: uid)
            .where('status', isEqualTo: 'BELUM LUNAS')
            .where('tipe', isEqualTo: 'SPP') 
            .get();

        // Jika ditemukan tunggakan, buat 1 Surat Peringatan
        if (queryTunggakan.docs.isNotEmpty) {
          DocumentReference refReminder = FirebaseFirestore.instance.collection('tagihan').doc();
          batch.set(refReminder, {
            'siswa_id': uid,
            'siswa_nama': namaSiswa,
            'kelas': selectedKelas,
            'judul': "⚠️ PERINGATAN: TUNGGAKAN SPP", 
            'jumlah': 0, // Nominal 0 karena hanya surat peringatan
            'jatuh_tempo': "SEGERA",
            'status': 'BELUM LUNAS',
            'created_at': FieldValue.serverTimestamp(),
            'tipe': 'REMINDER', // Tipe khusus agar warnanya Merah di Admin Page
            'pesan': "Siswa memiliki ${queryTunggakan.docs.length} bulan tagihan belum lunas."
          });
          jumlahReminder++;
        }
      }

      await batch.commit();

      if (mounted) {
        showDialog(
          context: context, 
          builder: (c) => AlertDialog(
            title: const Text("Berhasil!"),
            content: Text("Dibuat:\n- $jumlahTagihan Tagihan Baru\n- $jumlahReminder Peringatan Tunggakan"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(c);
                  Navigator.pop(context); 
                }, 
                child: const Text("OK")
              )
            ],
          )
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}