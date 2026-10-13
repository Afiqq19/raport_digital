import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuruProfilPage extends StatefulWidget {
  const GuruProfilPage({super.key});

  @override
  State<GuruProfilPage> createState() => _GuruProfilPageState();
}

class _GuruProfilPageState extends State<GuruProfilPage> {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic> dataGuru = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  Future<void> _getData() async {
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        setState(() {
          dataGuru = doc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      }
    }
  }

  // --- FUNGSI LOGOUT ---
  void _logout() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  // --- FUNGSI EDIT DATA (HP & ALAMAT) ---
  void _editData() {
    final hpC = TextEditingController(text: dataGuru['hp'] ?? "");
    final alamatC = TextEditingController(text: dataGuru['alamat'] ?? "");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Kontak"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: hpC, decoration: const InputDecoration(labelText: "No HP", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: alamatC, decoration: const InputDecoration(labelText: "Alamat", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                'hp': hpC.text,
                'alamat': alamatC.text,
              });
              Navigator.pop(ctx);
              _getData(); // Refresh
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data berhasil diupdate!")));
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI GANTI PASSWORD ---
  void _gantiPassword() {
    final passC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ganti Password"),
        content: TextField(
          controller: passC,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Password Baru", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              if (passC.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password minimal 6 karakter")));
                return;
              }
              try {
                await user!.updatePassword(passC.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password berhasil diganti!")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e. Login ulang dulu.")));
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.teal)));
    }

    // Ambil Data
    String nama = dataGuru['nama'] ?? "-";
    String nip = dataGuru['nip'] ?? "-";
    String email = dataGuru['email'] ?? "-";
    String hp = dataGuru['hp'] ?? "-";
    String alamat = dataGuru['alamat'] ?? "-";
    String waliKelas = dataGuru['wali_kelas_nama'] ?? "-";
    
    List<dynamic> mapelList = dataGuru['mapel'] ?? [];
    String mapel = mapelList.isNotEmpty ? mapelList.join(", ") : "-";

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        title: const Text("Profil Saya"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _editData,
            icon: const Icon(Icons.edit),
            tooltip: "Edit Kontak",
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER BACKGROUND (Tanpa Tombol Kamera)
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Text(
                        nama.isNotEmpty ? nama[0].toUpperCase() : "G",
                        style: const TextStyle(fontSize: 40, color: Colors.teal, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            Text(nama, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("NIP: $nip", style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 20),

            // ITEM LIST DATA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _infoCard(Icons.email, "Email", email),
                  _infoCard(Icons.phone, "No HP", hp),
                  _infoCard(Icons.location_on, "Alamat", alamat),
                  const Divider(height: 30),
                  _infoCard(Icons.book, "Mata Pelajaran", mapel),
                  _infoCard(Icons.class_, "Wali Kelas", waliKelas),
                  
                  const SizedBox(height: 30),
                  
                  // TOMBOL AKSI
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _gantiPassword,
                      icon: const Icon(Icons.lock_reset, color: Colors.teal),
                      label: const Text("Ganti Password", style: TextStyle(color: Colors.teal)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.teal),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text("Logout", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Card(
      elevation: 0, 
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.teal),
        ),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      ),
    );
  }
}