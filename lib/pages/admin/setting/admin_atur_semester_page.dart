import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAturSemesterPage extends StatefulWidget {
  const AdminAturSemesterPage({super.key});

  @override
  State<AdminAturSemesterPage> createState() => _AdminAturSemesterPageState();
}

class _AdminAturSemesterPageState extends State<AdminAturSemesterPage> {
  final TextEditingController _tahunC = TextEditingController();
  String _semester = "Ganjil";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() async {
    var doc = await FirebaseFirestore.instance.collection('settings').doc('akademik').get();
    if (doc.exists) {
      setState(() {
        _tahunC.text = doc['tahun_ajaran'];
        _semester = doc['semester'];
      });
    } else {
      _tahunC.text = "2024/2025"; // Default
    }
  }

  Future<void> _simpanPengaturan() async {
    setState(() => isLoading = true);
    await FirebaseFirestore.instance.collection('settings').doc('akademik').set({
      'tahun_ajaran': _tahunC.text,
      'semester': _semester,
    });
    setState(() => isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pengaturan Akademik Disimpan!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Atur Tahun Ajaran")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _tahunC,
              decoration: const InputDecoration(
                labelText: "Tahun Ajaran (Contoh: 2024/2025)",
                border: OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField(
              value: _semester,
              items: ["Ganjil", "Genap"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _semester = v!),
              decoration: const InputDecoration(labelText: "Semester Aktif", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _simpanPengaturan,
              child: const Text("Simpan Perubahan"),
            )
          ],
        ),
      ),
    );
  }
}