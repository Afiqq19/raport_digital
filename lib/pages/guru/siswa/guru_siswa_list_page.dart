import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// IMPORT PDF & PRINTING
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../nilai/guru_transkrip_page.dart';

class GuruSiswaListPage extends StatefulWidget {
  final String namaKelas;

  const GuruSiswaListPage({super.key, required this.namaKelas});

  @override
  State<GuruSiswaListPage> createState() => _GuruSiswaListPageState();
}

class _GuruSiswaListPageState extends State<GuruSiswaListPage> {
  String tahunAjaran = "";
  String semester = "";
  String namaGuru = "( ....................... )"; // Nama Wali Kelas

  pw.MemoryImage? _logoImage;

  @override
  void initState() {
    super.initState();
    _loadDataAwal();
    _loadLogo();
  }

  Future<void> _loadLogo() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/logo_smk.jpg');
      final Uint8List bytes = data.buffer.asUint8List();
      setState(() {
        _logoImage = pw.MemoryImage(bytes);
      });
    } catch (e) {
      debugPrint("Gagal load logo: $e");
    }
  }

  void _loadDataAwal() async {
    try {
      var docSettings = await FirebaseFirestore.instance.collection('settings').doc('akademik').get();
      
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var docUser = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (docUser.exists) {
           setState(() {
             namaGuru = docUser['nama'] ?? "( ....................... )";
           });
        }
      }

      if (docSettings.exists) {
        setState(() {
          tahunAjaran = docSettings['tahun_ajaran'] ?? "2025/2026";
          semester = docSettings['semester'] ?? "Ganjil";
        });
      } else {
        setState(() {
          tahunAjaran = "2025/2026";
          semester = "Ganjil";
        });
      }
    } catch (e) {
      debugPrint("Error load data: $e");
    }
  }

  // --- HELPER PREDIKAT (A, B, C, D) ---
  String _getPredikat(double nilai) {
    if (nilai >= 90) return "A";
    if (nilai >= 80) return "B";
    if (nilai >= 70) return "C";
    return "D";
  }

  // ============================================================
  // FUNGSI CETAK LEGER (LENGKAP: NISN, PREDIKAT, TTD)
  // ============================================================
  Future<void> _cetakLeger() async {
    if (tahunAjaran.isEmpty) return;

    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));

    try {
      // 1. AMBIL DATA SISWA
      var siswaSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'siswa')
          .where('kelas', isEqualTo: widget.namaKelas)
          .orderBy('nama')
          .get();

      if (siswaSnap.docs.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada siswa.")));
        return;
      }

      // 2. AMBIL DATA NILAI
      var nilaiSnap = await FirebaseFirestore.instance
          .collection('nilai')
          .where('kelas', isEqualTo: widget.namaKelas)
          .where('tahun_ajaran', isEqualTo: tahunAjaran)
          .where('semester', isEqualTo: semester)
          .get();

      // 3. OLAH DATA (PIVOT TABLE)
      Map<String, Map<String, double>> rekapNilai = {};
      Set<String> listMapelUnik = {}; 
      Map<String, Map<String, String>> infoSiswa = {}; 

      for (var doc in siswaSnap.docs) {
        rekapNilai[doc.id] = {};
        infoSiswa[doc.id] = {
          'nama': doc['nama'] ?? '-',
          'nisn': doc['nisn'] ?? '-',
        };
      }

      Map<String, Map<String, List<double>>> tempNilai = {}; 

      for (var doc in nilaiSnap.docs) {
        var data = doc.data();
        String uid = data['siswa_id'];
        String mapel = data['mapel'];
        double nilai = double.parse(data['nilai'].toString());

        listMapelUnik.add(mapel);

        if (!tempNilai.containsKey(uid)) tempNilai[uid] = {};
        if (!tempNilai[uid]!.containsKey(mapel)) tempNilai[uid]![mapel] = [];
        
        tempNilai[uid]![mapel]!.add(nilai);
      }

      tempNilai.forEach((uid, mapels) {
        mapels.forEach((mapel, scores) {
          double rata = scores.reduce((a, b) => a + b) / scores.length;
          if (rekapNilai.containsKey(uid)) {
            rekapNilai[uid]![mapel] = rata;
          }
        });
      });

      List<String> sortedMapel = listMapelUnik.toList()..sort();

      List<Map<String, dynamic>> leaderboard = [];
      rekapNilai.forEach((uid, mapelScores) {
        double total = 0;
        mapelScores.forEach((k, v) => total += v);
        double rataRataTotal = mapelScores.isNotEmpty ? total / mapelScores.length : 0;
        
        leaderboard.add({
          'id': uid,
          'nama': infoSiswa[uid]!['nama'],
          'nisn': infoSiswa[uid]!['nisn'],
          'total': total,
          'rata': rataRataTotal,
          'scores': mapelScores
        });
      });

      leaderboard.sort((a, b) => b['rata'].compareTo(a['rata']));

      // 4. BUAT PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          // --- SETTING LANDSCAPE (KERTAS MELEBAR) ---
          pageFormat: PdfPageFormat.a4.landscape, 
          margin: const pw.EdgeInsets.all(30), // Margin kertas
          
          // --- HEADER KOP SURAT YANG DIPERBAIKI ---
          header: (pw.Context context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Row(
                children: [
                  // 1. SPACER KIRI (Supaya logo agak ke tengah dikit)
                  pw.SizedBox(width: 40), 

                  // 2. LOGO
                  if (_logoImage != null)
                    pw.Container(
                      width: 70, height: 70,
                      margin: const pw.EdgeInsets.only(right: 15), 
                      child: pw.Image(_logoImage!),
                    ),
                  
                  // 3. JUDUL DI TENGAH
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text("SMK SWASTA BUDHI DARMA INDRAPURA", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Text("LEGER NILAI KELAS ${widget.namaKelas.toUpperCase()}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.Text("Tahun Ajaran: $tahunAjaran | Semester: $semester", style: const pw.TextStyle(fontSize: 12)),
                        pw.SizedBox(height: 8),
                        pw.Divider(thickness: 2),
                      ]
                    ),
                  ),
                  
                  // 4. PENYEIMBANG KANAN (Supaya Judul benar-benar di tengah)
                  // Lebar Spacer Kiri (40) + Lebar Logo (70) + Margin Logo (15) = 125
                  if (_logoImage != null) pw.SizedBox(width: 125),
                ]
              )
            );
          },

          build: (pw.Context context) {
            return [
              pw.Table(
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.black),
                children: [
                  // HEADER TABEL
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _cellHeader("No", width: 25),
                      _cellHeader("NISN", width: 55),
                      _cellHeader("Nama Siswa", width: 110),
                      ...sortedMapel.map((m) => _cellHeader(m)),
                      _cellHeader("JML", width: 35),
                      _cellHeader("Rata", width: 35),
                      _cellHeader("Rank", width: 30),
                    ]
                  ),

                  // ISI DATA
                  ...List.generate(leaderboard.length, (index) {
                    var s = leaderboard[index];
                    Map<String, double> scores = s['scores'];
                    
                    return pw.TableRow(
                      children: [
                        _cellBody((index + 1).toString(), align: pw.TextAlign.center),
                        _cellBody(s['nisn'], align: pw.TextAlign.center),
                        _cellBody(s['nama']),
                        
                        ...sortedMapel.map((m) {
                           double? val = scores[m];
                           String textVal = "-";
                           if (val != null) {
                             String pred = _getPredikat(val);
                             textVal = "${val.toStringAsFixed(0)} $pred";
                           }
                           return _cellBody(textVal, align: pw.TextAlign.center);
                        }),

                        _cellBody(s['total'].toStringAsFixed(0), align: pw.TextAlign.center, isBold: true),
                        _cellBody(s['rata'].toStringAsFixed(1), align: pw.TextAlign.center, isBold: true),
                        _cellBody((index + 1).toString(), align: pw.TextAlign.center, isBold: true),
                      ]
                    );
                  })
                ]
              ),

              pw.SizedBox(height: 30),

              // TANDA TANGAN
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text("Indrapura, ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text("Wali Kelas", style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 60),
                      pw.Text(namaGuru, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline, fontSize: 10)),
                      pw.Text("NIP. ........................", style: const pw.TextStyle(fontSize: 10)),
                    ]
                  )
                ]
              )
            ];
          },
        ),
      );

      Navigator.pop(context); // Tutup loading
      
      String tahunFile = tahunAjaran.replaceAll('/', '-');
      String namaFile = "LEGER_${widget.namaKelas}_${semester}_$tahunFile.pdf";

      await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: namaFile);

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal cetak: $e")));
    }
  }

  // Helper PDF Cell
  pw.Widget _cellHeader(String text, {double? width}) {
    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center),
    );
  }

  pw.Widget _cellBody(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, textAlign: align, style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        title: Text("Siswa ${widget.namaKelas}"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _cetakLeger, 
            icon: const Icon(Icons.print),
            tooltip: "Cetak Leger Nilai",
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'siswa')
            .where('kelas', isEqualTo: widget.namaKelas)
            .orderBy('nama')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.teal));

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Tidak ada siswa di kelas ini"));
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                color: Colors.teal.withOpacity(0.1),
                child: Text(
                  "Total Siswa: ${docs.length}",
                  style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: Text(data['nama'][0].toUpperCase(), style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(data['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("NISN: ${data['nisn']}"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GuruTranskripPage(
                                siswaId: docs[index].id,
                                namaSiswa: data['nama'],
                                kelas: widget.namaKelas,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}