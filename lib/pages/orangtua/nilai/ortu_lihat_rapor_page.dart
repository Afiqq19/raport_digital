import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle; 

// IMPORT UNTUK PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class OrtuLihatRaporPage extends StatefulWidget {
  final String siswaId;
  final String namaSiswa;
  final String nisnSiswa;
  final String kelasSiswa;

  const OrtuLihatRaporPage({
    super.key,
    required this.siswaId,
    required this.namaSiswa,
    required this.nisnSiswa,
    required this.kelasSiswa,
  });

  @override
  State<OrtuLihatRaporPage> createState() => _OrtuLihatRaporPageState();
}

class _OrtuLihatRaporPageState extends State<OrtuLihatRaporPage> {
  List<String> listSemester = [];
  String? selectedSemester;
  String namaOrtu = "";
  String namaWaliKelas = "";
  
  // Variabel Gambar Logo
  pw.MemoryImage? _logoImage;

  @override
  void initState() {
    super.initState();
    _loadInfoTandaTangan();
    _loadAvailableSemesters();
    _loadLogo(); 
  }

  // --- 1. LOAD LOGO (Sesuaikan ekstensi .jpg) ---
  Future<void> _loadLogo() async {
    try {
      // Pastikan nama file di folder assets sama persis (logo_smk.jpg)
      final ByteData data = await rootBundle.load('assets/images/logo_smk.jpg');
      final Uint8List bytes = data.buffer.asUint8List();
      setState(() {
        _logoImage = pw.MemoryImage(bytes);
      });
    } catch (e) {
      debugPrint("Gagal load logo: $e");
    }
  }

  void _loadInfoTandaTangan() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          namaOrtu = doc['nama'] ?? "";
        });
      }
    }

    if (widget.kelasSiswa != "-" && widget.kelasSiswa.isNotEmpty) {
      try {
        var guruSnap = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'guru')
            .where('wali_kelas_nama', isEqualTo: widget.kelasSiswa)
            .limit(1)
            .get();

        if (guruSnap.docs.isNotEmpty) {
          setState(() {
            namaWaliKelas = guruSnap.docs.first.data()['nama'] ?? "";
          });
        }
      } catch (e) {
        debugPrint("Error cari wali kelas: $e");
      }
    }
  }

  void _loadAvailableSemesters() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('nilai')
        .where('siswa_id', isEqualTo: widget.siswaId)
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
  // FUNGSI PDF (HEADER LEBIH RAPI)
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

      // --- LOGIKA HITUNG NILAI ---
      var classSnapshot = await FirebaseFirestore.instance
          .collection('nilai')
          .where('kelas', isEqualTo: widget.kelasSiswa)
          .where('semester', isEqualTo: sem)
          .where('tahun_ajaran', isEqualTo: thn)
          .get();

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
        double totalSemua = 0;
        int count = 0;
        mapelGrades.forEach((_, listNilai) {
          var h = _hitungNilai(listNilai);
          totalSemua += h['raw_akhir'];
          count++;
        });
        double rata = count > 0 ? totalSemua / count : 0;
        leaderboard.add({'id': uid, 'score': rata});
      });

      leaderboard.sort((a, b) => b['score'].compareTo(a['score']));
      
      int myRank = leaderboard.indexWhere((e) => e['id'] == widget.siswaId) + 1;
      int totalSiswa = totalSiswaSet.length;

      var myDocs = classSnapshot.docs.where((d) => d['siswa_id'] == widget.siswaId).toList();

      if (myDocs.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data nilai belum lengkap.")));
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

      // --- TABEL DATA ---
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
        tableRows.add(pw.TableRow(children: [
          _cellPdf((no++).toString(), align: pw.TextAlign.center),
          _cellPdf(mapel),
          _cellPdf(h['peng'], align: pw.TextAlign.center),
          _cellPdf(h['ket'], align: pw.TextAlign.center),
          _cellPdf(h['akhir'], align: pw.TextAlign.center),
          _cellPdf(h['predikat'], align: pw.TextAlign.center),
        ]));
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
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("$myRank / $totalSiswa Siswa", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
        _cellPdf("-", align: pw.TextAlign.center, color: PdfColors.grey200),
      ]));

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ================= HEADER KOP SURAT RAPI =================
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center, // Vertikal tengah
                  children: [
                    // KIRI: Logo
                    pw.Container(
                      width: 60,
                      height: 60,
                      child: _logoImage != null ? pw.Image(_logoImage!) : pw.Container(),
                    ),
                    pw.SizedBox(width: 20), // Spasi antara Logo dan Teks

                    // TENGAH: Teks Header (Expanded agar mengambil sisa ruang tengah)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text("LAPORAN HASIL BELAJAR PESERTA DIDIK", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text("SMK SWASTA BUDHI DARMA INDRAPURA", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                          pw.SizedBox(height: 4),
                          pw.Text("Jalan Lintas Sumatera No. 123, Indrapura", style: const pw.TextStyle(fontSize: 10)),
                          pw.Text("Semester: $semesterNama | Tahun: $tahunAjar", style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),

                    // KANAN: Penyeimbang (Lebar Logo 60 + Spasi 20 = 80)
                    // Ini trik agar teks di tengah benar-benar center secara visual
                    pw.SizedBox(width: 80), 
                  ],
                ),
                
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 2), // Garis Tebal
                pw.Divider(thickness: 1, height: 2), // Garis Tipis (Efek Kop Surat)
                pw.SizedBox(height: 20),
                // ========================================================

                // INFO SISWA
                pw.Table(columnWidths: {0: const pw.FixedColumnWidth(130), 1: const pw.FixedColumnWidth(10), 2: const pw.FlexColumnWidth()}, children: [
                  _buildHeaderRow("Nama Peserta Didik", widget.namaSiswa.toUpperCase()),
                  _buildHeaderRow("NISN", widget.nisnSiswa),
                  _buildHeaderRow("Kelas / Jurusan", widget.kelasSiswa), 
                ]),
                
                pw.SizedBox(height: 15),
                pw.Text("A. Nilai Akademik", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.SizedBox(height: 5),
                
                // TABEL NILAI
                pw.Table(border: pw.TableBorder.all(width: 0.5, color: PdfColors.black), columnWidths: {0: const pw.FlexColumnWidth(0.5), 1: const pw.FlexColumnWidth(3.5), 2: const pw.FlexColumnWidth(0.8), 3: const pw.FlexColumnWidth(0.8), 4: const pw.FlexColumnWidth(0.8), 5: const pw.FlexColumnWidth(0.8)}, children: tableRows),
                
                pw.Spacer(),
                
                // TTD
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(children: [
                      pw.Text("Mengetahui,"),
                      pw.Text("Orang Tua / Wali"),
                      pw.SizedBox(height: 50),
                      pw.Text(namaOrtu.isNotEmpty ? "($namaOrtu)" : "( ....................... )", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ]),
                    pw.Column(children: [
                      pw.Text("Indrapura, ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}"),
                      pw.Text("Wali Kelas"),
                      pw.SizedBox(height: 50),
                      pw.Text(namaWaliKelas.isNotEmpty ? "($namaWaliKelas)" : "( ....................... )", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ])
                  ]
                )
              ],
            );
          },
        ),
      );

      Navigator.pop(context);
      await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: "Rapor_${widget.namaSiswa}.pdf");

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal cetak: $e")));
    }
  }

  pw.TableRow _buildHeaderRow(String label, String value) {
    return pw.TableRow(children: [
      pw.Padding(padding: const pw.EdgeInsets.only(bottom: 2), child: pw.Text(label, style: const pw.TextStyle(fontSize: 10))),
      pw.Text(":", style: const pw.TextStyle(fontSize: 10)),
      pw.Padding(padding: const pw.EdgeInsets.only(left: 5, bottom: 2), child: pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
    ]);
  }

  pw.Widget _cellPdf(String text, {bool isBold = false, pw.TextAlign align = pw.TextAlign.left, PdfColor? color}) {
    return pw.Container(color: color, padding: const pw.EdgeInsets.all(5), child: pw.Text(text, textAlign: align, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: 9)));
  }

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
    if (akhir >= 90) predikat = "A"; else if (akhir >= 80) predikat = "B"; else if (akhir >= 70) predikat = "C";
    return {"peng": avgPeng.toStringAsFixed(0), "ket": avgKet.toStringAsFixed(0), "akhir": akhir.toStringAsFixed(0), "predikat": predikat, "raw_akhir": akhir};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFF3E0),
      appBar: AppBar(
        title: const Text("Rapor Anak"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(onPressed: _cetakPdf, icon: const Icon(Icons.print), tooltip: "Cetak PDF")],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.orange,
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                   Text(widget.namaSiswa, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                   Text(widget.kelasSiswa, style: const TextStyle(color: Colors.white70)),
                ]),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
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
                ? const Center(child: Text("Pilih semester untuk melihat nilai."))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('nilai')
                        .where('siswa_id', isEqualTo: widget.siswaId) 
                        .where('semester', isEqualTo: selectedSemester!.split(' ')[0]) 
                        .where('tahun_ajaran', isEqualTo: selectedSemester!.split(' ')[1])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      
                      var docs = snapshot.data!.docs;
                      if (docs.isEmpty) return const Center(child: Text("Nilai belum tersedia."));

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
                              subtitle: Text("Peng: ${hasil['peng']} | Ket: ${hasil['ket']} | Akhir: ${hasil['akhir']}"),
                              trailing: CircleAvatar(
                                backgroundColor: Colors.orange.shade100,
                                child: Text(hasil['predikat'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
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