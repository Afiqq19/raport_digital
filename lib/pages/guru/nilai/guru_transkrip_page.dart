import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuruTranskripPage extends StatefulWidget {
  final String siswaId;
  final String namaSiswa;
  final String kelas;

  const GuruTranskripPage({
    super.key,
    required this.siswaId,
    required this.namaSiswa,
    required this.kelas,
  });

  @override
  State<GuruTranskripPage> createState() => _GuruTranskripPageState();
}

class _GuruTranskripPageState extends State<GuruTranskripPage> {
  // Bobot Nilai (Default)
  final double bobotHarian = 0.40;
  final double bobotUTS = 0.20;
  final double bobotUAS = 0.25;
  final double bobotSkill = 0.15;

  // Variabel Ranking
  int myRank = 0;
  int totalSiswa = 0;
  double myRataRata = 0.0;
  bool isLoadingRank = true;

  // Variabel Akademik (Filter Semester)
  String tahunAjaran = "2024/2025";
  String semester = "Ganjil";

  @override
  void initState() {
    super.initState();
    _loadAkademikAndCalculate();
  }

  // 1. Load Setting Akademik dulu, baru hitung ranking
  Future<void> _loadAkademikAndCalculate() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('settings').doc('akademik').get();
      if (doc.exists) {
        if (mounted) {
          setState(() {
            tahunAjaran = doc['tahun_ajaran'] ?? "2024/2025";
            semester = doc['semester'] ?? "Ganjil";
          });
        }
      }
      // Setelah dapat semester, baru hitung ranking
      _hitungRankingKelas();
    } catch (e) {
      debugPrint("Error load akademik: $e");
    }
  }

  // --- LOGIKA MENGHITUNG RANKING (Filter Semester) ---
  Future<void> _hitungRankingKelas() async {
    try {
      // Ambil nilai HANYA untuk semester & tahun ini
      var nilaiSnapshot = await FirebaseFirestore.instance
          .collection('nilai')
          .where('kelas', isEqualTo: widget.kelas)
          .where('tahun_ajaran', isEqualTo: tahunAjaran) // Filter Tahun
          .where('semester', isEqualTo: semester)       // Filter Semester
          .get();

      Map<String, List<Map<String, dynamic>>> studentGrades = {};
      Set<String> uniqueStudents = {};

      for (var doc in nilaiSnapshot.docs) {
        var data = doc.data();
        String sid = data['siswa_id'];
        uniqueStudents.add(sid);

        if (!studentGrades.containsKey(sid)) {
          studentGrades[sid] = [];
        }
        studentGrades[sid]!.add(data);
      }

      List<Map<String, dynamic>> leaderboard = [];

      studentGrades.forEach((sid, grades) {
        Map<String, List<Map<String, dynamic>>> mapelGrades = {};
        for (var g in grades) {
          String mapel = g['mapel'];
          if (!mapelGrades.containsKey(mapel)) mapelGrades[mapel] = [];
          mapelGrades[mapel]!.add(g);
        }

        double totalNilaiSemuaMapel = 0;
        int jumlahMapel = 0;

        mapelGrades.forEach((mapel, listNilai) {
          double nilaiAkhirMapel = _hitungNilaiAkhirPerMapel(listNilai);
          totalNilaiSemuaMapel += nilaiAkhirMapel;
          jumlahMapel++;
        });

        double rataRataAkhir = jumlahMapel > 0 ? totalNilaiSemuaMapel / jumlahMapel : 0;

        leaderboard.add({
          'id': sid,
          'score': rataRataAkhir,
        });
      });

      leaderboard.sort((a, b) => b['score'].compareTo(a['score']));

      int rank = leaderboard.indexWhere((e) => e['id'] == widget.siswaId) + 1;
      var myData = leaderboard.firstWhere((e) => e['id'] == widget.siswaId, orElse: () => {'score': 0.0});

      var userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'siswa')
          .where('kelas', isEqualTo: widget.kelas)
          .count()
          .get();

      if (mounted) {
        setState(() {
          myRank = rank > 0 ? rank : 0;
          myRataRata = myData['score'];
          totalSiswa = userSnapshot.count ?? uniqueStudents.length;
          isLoadingRank = false;
        });
      }

    } catch (e) {
      debugPrint("Error hitung ranking: $e");
      if (mounted) setState(() => isLoadingRank = false);
    }
  }

  double _hitungNilaiAkhirPerMapel(List<Map<String, dynamic>> nilaiList) {
    List<int> nHarian = [];
    int nUts = 0;
    int nUas = 0;
    List<int> nSkill = [];

    for (var data in nilaiList) {
      String kategori = data['kategori'];
      int nilai = data['nilai'];

      if (kategori.contains("Tugas") || kategori.contains("Harian")) {
        nHarian.add(nilai);
      } else if (kategori.contains("UTS")) {
        nUts = nilai;
      } else if (kategori.contains("UAS")) {
        nUas = nilai;
      } else if (kategori.contains("Keterampilan") || kategori.contains("Praktik")) {
        nSkill.add(nilai);
      }
    }

    double avgHarian = nHarian.isEmpty ? 0 : nHarian.reduce((a, b) => a + b) / nHarian.length;
    double avgSkill = nSkill.isEmpty ? 0 : nSkill.reduce((a, b) => a + b) / nSkill.length;

    return (avgHarian * bobotHarian) + (nUts * bobotUTS) + (nUas * bobotUAS) + (avgSkill * bobotSkill);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        title: const Text("Transkrip Nilai"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Info Semester di Pojok Kanan Atas
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Center(
              child: Text(
                "$semester $tahunAjaran", 
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // HEADER SISWA & RANKING
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            decoration: const BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Text(
                  widget.namaSiswa,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "Kelas: ${widget.kelas}",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: isLoadingRank 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem("Rata-Rata", myRataRata.toStringAsFixed(1)),
                          Container(height: 30, width: 1, color: Colors.white30),
                          _buildStatItem(
                            "Peringkat", 
                            myRank == 0 ? "-" : "$myRank / $totalSiswa",
                            isHighlight: true
                          ),
                        ],
                      ),
                ),
              ],
            ),
          ),

          // LIST NILAI PER MAPEL (FILTERED)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('nilai')
                  .where('siswa_id', isEqualTo: widget.siswaId)
                  .where('tahun_ajaran', isEqualTo: tahunAjaran) // FILTER TAHUN
                  .where('semester', isEqualTo: semester)       // FILTER SEMESTER
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_late, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Belum ada nilai semester ini."),
                      ],
                    ),
                  );
                }

                Map<String, List<Map<String, dynamic>>> groupedData = {};

                for (var doc in docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  String mapel = data['mapel'];
                  
                  if (!groupedData.containsKey(mapel)) {
                    groupedData[mapel] = [];
                  }
                  groupedData[mapel]!.add(data);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: groupedData.keys.length,
                  itemBuilder: (context, index) {
                    String mapel = groupedData.keys.elementAt(index);
                    List<Map<String, dynamic>> nilaiList = groupedData[mapel]!;

                    return _buildMapelCard(mapel, nilaiList);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(value, style: TextStyle(
          color: isHighlight ? Colors.yellowAccent : Colors.white, 
          fontSize: 20, 
          fontWeight: FontWeight.bold
        )),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildMapelCard(String mapel, List<Map<String, dynamic>> nilaiList) {
    double nilaiAkhir = _hitungNilaiAkhirPerMapel(nilaiList);

    String grade = "E";
    Color gradeColor = Colors.red;
    if (nilaiAkhir >= 90) { grade = "A"; gradeColor = Colors.green; }
    else if (nilaiAkhir >= 80) { grade = "B"; gradeColor = Colors.blue; }
    else if (nilaiAkhir >= 70) { grade = "C"; gradeColor = Colors.orange; }
    else if (nilaiAkhir >= 60) { grade = "D"; gradeColor = Colors.yellow.shade800; }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(mapel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text("Nilai Akhir: ${nilaiAkhir.toStringAsFixed(1)}"),
        leading: CircleAvatar(
          backgroundColor: gradeColor,
          child: Text(grade, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Rincian Komponen:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 5),
                ...nilaiList.map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("- ${n['kategori']}", style: const TextStyle(fontSize: 13)),
                      Text("${n['nilai']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Total: ${nilaiAkhir.toStringAsFixed(2)}", 
                    style: TextStyle(fontWeight: FontWeight.bold, color: gradeColor, fontSize: 16)
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}