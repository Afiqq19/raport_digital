import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BobotNilaiPage extends StatefulWidget {
  const BobotNilaiPage({super.key});

  @override
  State<BobotNilaiPage> createState() => _BobotNilaiPageState();
}

class _BobotNilaiPageState extends State<BobotNilaiPage> {
  // Controller
  final TextEditingController _harianC = TextEditingController();
  final TextEditingController _utsC = TextEditingController();
  final TextEditingController _uasC = TextEditingController();
  final TextEditingController _skillC = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBobot();
  }

  // Ambil data bobot saat ini dari Firestore
  void _loadBobot() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('bobot_nilai')
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _harianC.text = (data['harian'] ?? 40).toString();
          _utsC.text = (data['uts'] ?? 20).toString();
          _uasC.text = (data['uas'] ?? 25).toString();
          _skillC.text = (data['keterampilan'] ?? 15).toString();
        });
      } else {
        // Default jika belum ada settingan
        _harianC.text = "40";
        _utsC.text = "20";
        _uasC.text = "25";
        _skillC.text = "15";
      }
    } catch (e) {
      debugPrint("Error load bobot: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        title: const Text("Pengaturan Bobot Nilai"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Total bobot harus berjumlah 100%. Nilai Akhir akan dihitung otomatis berdasarkan bobot ini.",
                            style: TextStyle(color: Colors.blue, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Input Fields dalam Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInputRow("Harian / Tugas", _harianC, Colors.orange),
                        const Divider(),
                        _buildInputRow("UTS (Tengah Semester)", _utsC, Colors.purple),
                        const Divider(),
                        _buildInputRow("UAS (Akhir Semester)", _uasC, Colors.red),
                        const Divider(),
                        _buildInputRow("Keterampilan / Praktik", _skillC, Colors.green),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Total Counter (Optional Logic Display)
                  // Anda bisa menambahkan Text Total % di sini secara real-time jika mau

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _simpanBobot,
                      child: const Text(
                        "SIMPAN PENGATURAN",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "%",
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          SizedBox(
            width: 70,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _simpanBobot() async {
    // 1. Validasi Total 100%
    double harian = double.tryParse(_harianC.text) ?? 0;
    double uts = double.tryParse(_utsC.text) ?? 0;
    double uas = double.tryParse(_uasC.text) ?? 0;
    double skill = double.tryParse(_skillC.text) ?? 0;

    double total = harian + uts + uas + skill;

    if (total != 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal! Total bobot saat ini: $total%. Harus pas 100%."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Simpan ke Firebase
    try {
      await FirebaseFirestore.instance.collection('settings').doc('bobot_nilai').set({
        "harian": harian,
        "uts": uts,
        "uas": uas,
        "keterampilan": skill,
        "updated_at": DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pengaturan Bobot Berhasil Disimpan!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}