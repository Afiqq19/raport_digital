import 'dart:typed_data'; // WAJIB: Untuk gambar
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle; // WAJIB: Untuk load aset

// IMPORT UNTUK PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SiswaLihatRaporPage extends StatefulWidget {
  const SiswaLihatRaporPage({super.key});

  @override
  State<SiswaLihatRaporPage> createState() => _SiswaLihatRaporPageState();
}

class _SiswaLihatRaporPageState extends State<SiswaLihatRaporPage> {
  User? user = FirebaseAuth.instance.currentUser;
  
  List<String> listSemester = [];
  String? selectedSemester;
  
  // Data Siswa
  String nama = "";
  String nisn = "";
  String kelas = "";

  // Data Tanda Tangan
  String namaOrtu = "";
  String namaWaliKelas = "";
  
  // Variabel Logo
  pw.MemoryImage? _logoImage;

  @override
  void initState() {
    super.initState();
    _loadDataLengkap();
    _loadAvailableSemesters();
    _loadLogo(); // Load Logo saat init
  }

  // --- LOAD LOGO ---
  Future<void> _loadLogo() async {
    try {
      // Pastikan path aset benar (logo_smk.jpg atau .png)
      final ByteData data = await rootBundle.load('assets/images/logo_smk.jpg');
      final Uint8List bytes = data.buffer.asUint8List();
      setState(() {
        _logoImage = pw.MemoryImage(bytes);
      });
    } catch (e) {
      debugPrint("Gagal load logo: $e");
    }
  }

  // --- 1. LOAD DATA SISWA, ORTU, DAN WALI KELAS ---
  void _loadDataLengkap() async {
    if (user != null) {
      try {
        var docSiswa = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
        if (docSiswa.exists) {
          setState(() {
            nama = docSiswa['nama'] ?? "-";
            nisn = docSiswa['nisn'] ?? "-";
            kelas = docSiswa['kelas'] ?? "-";
          });

          // Cari Data Orang Tua
          var ortuSnap = await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'ortu')
              .where('siswa_id', isEqualTo: user!.uid)
              .limit(1)
              .get();

          if (ortuSnap.docs.isNotEmpty) {
            setState(() {
              namaOrtu = ortuSnap.docs.first.data()['nama'] ?? "";
            });
          }

          // Cari Data Wali Kelas
          if (kelas != "-" && kelas.isNotEmpty) {
            var guruSnap = await FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'guru')
                .where('wali_kelas_nama', isEqualTo: kelas)
                .limit(1)
                .get();

            if (guruSnap.docs.isNotEmpty) {
              setState(() {
                namaWaliKelas = guruSnap.docs.first.data()['nama'] ?? "";
              });
            }
          }
        }
      } catch (e) {
        debugPrint("Error load data: $e");
      }
    }
  }

  void _loadAvailableSemesters() async {
    if (user == null) return;
    
    var snapshot = await FirebaseFirestore.instance
        .collection('nilai')
        .where('siswa_id', isEqualTo: user!.uid)
        .get();

    Set<String> semesters = {};
    for (var doc in snapshot.docs) {
      String smt = doc.data()['semester'] ?? "";
      String thn = doc.data()['tahun_ajaran'] ?? "";
      if (smt.isNotEmpty && thn.isNotEmpty) {
        semesters.add("$smt $thn");
      }
    }

    if (mounted) {
      setState(() {
        listSemester = semesters.toList();
        listSemester.sort(); 
        if (listSemester.isNotEmpty) {
          selectedSemester = listSemester.last;
        }
      });
    }
  }

  // ============================================================
  // FUNGSI GENERATE PDF (HEADER DENGAN LOGO)
  // ============================================================
  Future<void> _cetakPdf() async {
    if (selectedSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih semester dulu!")));
      return;
    }

    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));

    try {
      List<String> parts = selectedSemester!.split(' ');
      String semesterNama = parts[0]; 
      String tahunAjar = parts.length > 1 ? parts[1] : "-"; 
      String sem = parts[0];
      String thn = parts[1];

      // 1. Query Data Nilai (Satu Kelas untuk Ranking)
      var classSnapshot = await FirebaseFirestore.instance
          .collection('nilai')
          .where('kelas', isEqualTo: kelas)
          .where('semester', isEqualTo: sem)
          .where('tahun_ajaran', isEqualTo: thn)
          .get();

      // 2. Logika Ranking
      Map<String, List<Map<String, dynamic>>> classGrades = {};
      Set<String> totalSiswaSet = {};

      for (var doc in classSnapshot.docs) {
        var d = doc.data();
        String uid = d['siswa_id'];
        totalSiswaSet.add(uid);
        if (!classGrades.containsKey(uid)) classGrades[uid] = [];
        classGrades[uid]!.add(d);
      }

      List<Map<String, dynamic>> leaderboard = [];
      classGrades.forEach((uid, grades) {
        Map<String, List<Map<String, dynamic>>> mapelGrades = {};
        for (var g in grades) {
          String m = g['mapel'];
          if (!mapelGrades.containsKey(m)) mapelGrades[m] = [];
          mapelGrades[m]!.add(g);
        }
        double totalSemuaMapel = 0;
        int countMapel = 0;
        mapelGrades.forEach((_, listNilai) {
          var h = _hitungNilai(listNilai); 
          totalSemuaMapel += h['raw_akhir']; 
          countMapel++;
        });
        double rataRataSiswa = countMapel > 0 ? totalSemuaMapel / countMapel : 0;
        leaderboard.add({'id': uid, 'score': rataRataSiswa});
      });

      leaderboard.sort((a, b) => b['score'].compareTo(a['score']));
      
      int myRank = leaderboard.indexWhere((e) => e['id'] == user!.uid) + 1;
      int totalSiswa = totalSiswaSet.length;

      // 3. Filter Data Saya
      var myDocs = classSnapshot.docs.where((d) => d['siswa_id'] == user!.uid).toList();
      
      if (myDocs.isEmpty) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data nilai Anda belum lengkap.")));
        return;
      }

      Map<String, List<Map<String, dynamic>>> myGrouped = {};
      for (var doc in myDocs) {
        var d = doc.data();
        String mapel = d['mapel'];
        if (!myGrouped.containsKey(mapel)) myGrouped[mapel] = [];
        myGrouped[mapel]!.add(d);
      }

      double grandTotal = 0;
      int totalMapel = 0;
      
      List<pw.TableRow> tableRows = [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _cellPdf("No", isBold: true, align: pw.TextAlign.center),
            _cellPdf("Mata Pelajaran", isBold: true),
            _cellPdf("Peng", isBold: true, align: pw.TextAlign.center),
            _cellPdf("Ket", isBold: true, align: pw.TextAlign.center),
            _cellPdf("Akhir", isBold: true, align: pw.TextAlign.center),
            _cellPdf("Pred", isBold: true, align: pw.TextAlign.center),
          ]
        )
      ];

      int no = 1;
      for (var mapel in myGrouped.keys) {
        var list = myGrouped[mapel]!;
        var h = _hitungNilai(list);
        
        grandTotal += h['raw_akhir'];
        totalMapel++;

        tableRows.add(pw.TableRow(
          children: [
            _cellPdf((no++).toString(), align: pw.TextAlign.center),
            _cellPdf(mapel),
            _cellPdf(h['peng'], align: pw.TextAlign.center),
            _cellPdf(h['ket'], align: pw.TextAlign.center),
            _cellPdf(h['akhir'], align: pw.TextAlign.center),
            _cellPdf(h['predikat'], align: pw.TextAlign.center),
          ]
        ));
      }

      double rataRataSaya = totalMapel > 0 ? grandTotal / totalMapel : 0;

      tableRows.add(pw.TableRow(children: [
        _cellPdf("", color: PdfColors.grey200),
        _cellPdf("Jumlah Nilai", isBold: true),
        _cellPdf("-", align: pw.TextAlign.center, color: PdfColors.grey200),
        _cellPdf("-", align: pw.TextAlign.center, color: PdfColors.grey200),
        _cellPdf(grandTotal.toStringAsFixed(0), isBold: true, align: pw.TextAlign.center),
        _cellPdf("-", align: pw.TextAlign.center, color: PdfColors.grey200),
      ]));
      
      tableRows.add(pw.TableRow(children: [
        _cellPdf("", color: PdfColors.grey200),
        _cellPdf("Rata-rata", isBold: true),
        _cellPdf("-", align: pw.TextAlign.center, color: PdfColors.grey200),
        _cellPdf("-", align: pw.TextAlign.center, color: PdfColors.grey200),
        _cellPdf(rataRataSaya.toStringAsFixed(2), isBold: true, align: pw.TextAlign.center),
        _cellPdf("-", align: pw.TextAlign.center, color: PdfColors.grey200),
      ]));

      tableRows.add(pw.TableRow(children: [
        _cellPdf("", color: PdfColors.grey200),
        _cellPdf("Ranking Kelas", isBold: true),
        _cellPdf("-", align: pw.TextAlign.center, color: PdfColors.grey200),
        _cellPdf("-", align: pw.TextAlign.center, color: PdfColors.grey200),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
             "$myRank / $totalSiswa Siswa",
             textAlign: pw.TextAlign.center,
             style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)
          )
        ),
        _cellPdf("-", align: pw.TextAlign.center, color: PdfColors.grey200),
      ]));

      // 4. BUILD PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ================= HEADER KOP SURAT (DENGAN LOGO) =================
                pw.Row(
                  children: [
                    // KIRI: Logo
                    if (_logoImage != null)
                      pw.Container(
                        width: 60, height: 60,
                        margin: const pw.EdgeInsets.only(right: 15),
                        child: pw.Image(_logoImage!),
                      ),
                    
                    // TENGAH: Teks Kop Surat
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text("LAPORAN HASIL BELAJAR PESERTA DIDIK", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text("SMK SWASTA BUDHI DARMA INDRAPURA", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                          pw.SizedBox(height: 5),
                          pw.Text("Jalan Lintas Sumatera No. 123, Indrapura", style: const pw.TextStyle(fontSize: 10)),
                        ]
                      )
                    ),

                    // KANAN: Penyeimbang (Kosong agar teks tengah benar-benar center)
                    if (_logoImage != null) pw.SizedBox(width: 75), 
                  ]
                ),
                
                pw.SizedBox(height: 5),
                pw.Divider(thickness: 2),
                pw.Divider(thickness: 0.5, height: 2),
                pw.SizedBox(height: 20),
                // ==============================================================

                // Header Identitas
                pw.Table(
                  columnWidths: {
                    0: const pw.FixedColumnWidth(130),
                    1: const pw.FixedColumnWidth(10),
                    2: const pw.FlexColumnWidth(),
                  },
                  children: [
                    _buildHeaderRow("Nama Peserta Didik", nama.toUpperCase()),
                    _buildHeaderRow("NISN", nisn),
                    _buildHeaderRow("Kelas / Semester", "$kelas / $semesterNama"),
                    _buildHeaderRow("Tahun Pelajaran", tahunAjar),
                  ]
                ),
                
                pw.SizedBox(height: 15),
                pw.Text("A. Nilai Akademik", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.SizedBox(height: 5),

                // Tabel Nilai
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5, color: PdfColors.black),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(0.5), 
                    1: const pw.FlexColumnWidth(3),   
                    2: const pw.FlexColumnWidth(1),   
                    3: const pw.FlexColumnWidth(1),   
                    4: const pw.FlexColumnWidth(1),   
                    5: const pw.FlexColumnWidth(1),   
                  },
                  children: tableRows,
                ),

                pw.Spacer(),
                
                // TTD
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text("Mengetahui,"),
                        pw.Text("Orang Tua / Wali"),
                        pw.SizedBox(height: 50),
                        pw.Text(
                          namaOrtu.isNotEmpty ? "($namaOrtu)" : "( ....................... )",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)
                        ),
                      ]
                    ),
                    pw.Column(
                      children: [
                        pw.Text("Indrapura, ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}"),
                        pw.Text("Wali Kelas"),
                        pw.SizedBox(height: 50),
                        pw.Text(
                          namaWaliKelas.isNotEmpty ? "($namaWaliKelas)" : "( ....................... )",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)
                        ), 
                      ]
                    )
                  ]
                )
              ],
            );
          },
        ),
      );

      Navigator.pop(context);
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: "Rapor_${nama}_$kelas.pdf", 
      );

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal cetak: $e")));
    }
  }

  // Helper Header Row
  pw.TableRow _buildHeaderRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        ),
        pw.Text(":", style: const pw.TextStyle(fontSize: 10)),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 5, bottom: 2),
          child: pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ),
      ]
    );
  }

  // Helper Cell
  pw.Widget _cellPdf(String text, {bool isBold = false, pw.TextAlign align = pw.TextAlign.left, PdfColor? color}) {
    return pw.Container(
      color: color,
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 9,
        ),
      ),
    );
  }

  // Helper Hitung
  Map<String, dynamic> _hitungNilai(List<Map<String, dynamic>> nilaiList) {
    List<int> nPeng = [];
    List<int> nKet = [];

    for (var d in nilaiList) {
      String kat = d['kategori'];
      int val = d['nilai'];
      if (kat.contains("Keterampilan") || kat.contains("Praktik")) {
        nKet.add(val);
      } else {
        nPeng.add(val);
      }
    }

    double avgPeng = nPeng.isEmpty ? 0 : nPeng.reduce((a, b) => a + b) / nPeng.length;
    double avgKet = nKet.isEmpty ? 0 : nKet.reduce((a, b) => a + b) / nKet.length;
    double akhir = (avgKet > 0) ? (avgPeng + avgKet) / 2 : avgPeng;

    String predikat = "D";
    if (akhir >= 90) predikat = "A";
    else if (akhir >= 80) predikat = "B";
    else if (akhir >= 70) predikat = "C";

    return {
      "peng": avgPeng.toStringAsFixed(0),
      "ket": avgKet.toStringAsFixed(0),
      "akhir": akhir.toStringAsFixed(0),
      "predikat": predikat,
      "raw_akhir": akhir,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        title: const Text("Laporan Hasil Belajar"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _cetakPdf, 
            icon: const Icon(Icons.print),
            tooltip: "Cetak / Simpan PDF",
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.indigo,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(nama, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(kelas, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedSemester,
                      hint: const Text("Pilih Semester"),
                      items: listSemester.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => selectedSemester = val),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: selectedSemester == null
                ? const Center(child: Text("Belum ada data nilai."))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('nilai')
                        .where('siswa_id', isEqualTo: user!.uid)
                        .where('semester', isEqualTo: selectedSemester!.split(' ')[0]) 
                        .where('tahun_ajaran', isEqualTo: selectedSemester!.split(' ')[1])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      
                      var docs = snapshot.data!.docs;
                      if (docs.isEmpty) return const Center(child: Text("Data tidak ditemukan."));

                      Map<String, List<Map<String, dynamic>>> grouped = {};
                      for (var doc in docs) {
                        var d = doc.data() as Map<String, dynamic>;
                        String mapel = d['mapel'];
                        if (!grouped.containsKey(mapel)) grouped[mapel] = [];
                        grouped[mapel]!.add(d);
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: grouped.keys.length,
                        itemBuilder: (context, index) {
                          String mapel = grouped.keys.elementAt(index);
                          List<Map<String, dynamic>> nilaiList = grouped[mapel]!;
                          
                          var hasil = _hitungNilai(nilaiList);
                          return Card(
                            child: ListTile(
                              title: Text(mapel, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Pengetahuan: ${hasil['peng']} | Keterampilan: ${hasil['ket']}"),
                              trailing: CircleAvatar(
                                backgroundColor: Colors.indigo.shade50,
                                child: Text(hasil['predikat'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
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
    );
  }
}