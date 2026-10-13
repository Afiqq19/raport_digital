import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TambahPengumumanPage extends StatefulWidget {
  const TambahPengumumanPage({super.key});

  @override
  State<TambahPengumumanPage> createState() => _TambahPengumumanPageState();
}

class _TambahPengumumanPageState extends State<TambahPengumumanPage> {
  final _judulC = TextEditingController();
  final _isiC = TextEditingController();
  final _linkC = TextEditingController(); // Untuk link PDF/Google Drive
  final _tanggalC = TextEditingController(); // Tanggal Event

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Pengumuman Baru"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul
            const Text("Judul Pengumuman", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _judulC,
              decoration: const InputDecoration(
                hintText: "Contoh: Jadwal UTS Semester Ganjil",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Tanggal Pelaksanaan
            const Text("Tanggal Pelaksanaan (Opsional)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _tanggalC,
              readOnly: true,
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() {
                    _tanggalC.text = "${picked.day}-${picked.month}-${picked.year}";
                  });
                }
              },
              decoration: const InputDecoration(
                hintText: "Pilih Tanggal",
                suffixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Isi / Deskripsi
            const Text("Isi Pengumuman", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _isiC,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Tulis detail pengumuman di sini...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Link File (PDF/Drive)
            const Text("Link File PDF / Dokumen (Opsional)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _linkC,
              decoration: const InputDecoration(
                hintText: "Tempel link Google Drive / Website di sini",
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                onPressed: isLoading ? null : _simpanPengumuman,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("PUBLIKASIKAN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simpanPengumuman() async {
    if (_judulC.text.isEmpty || _isiC.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Judul dan Isi wajib diisi!")));
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('pengumuman').add({
        'judul': _judulC.text,
        'isi': _isiC.text,
        'tanggal_event': _tanggalC.text, // Tanggal acara (bukan tanggal upload)
        'link_file': _linkC.text,
        'created_at': FieldValue.serverTimestamp(), // Tanggal posting (untuk urutan)
        'penulis': 'Admin Sekolah',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pengumuman berhasil diterbitkan!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}