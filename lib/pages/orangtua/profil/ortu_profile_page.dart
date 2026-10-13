import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrtuProfilePage extends StatefulWidget {
  const OrtuProfilePage({super.key});

  @override
  State<OrtuProfilePage> createState() => _OrtuProfilePageState();
}

class _OrtuProfilePageState extends State<OrtuProfilePage> {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  Future<void> _getData() async {
    if (user != null) {
      try {
        var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
        if (doc.exists) {
          if (mounted) {
            setState(() {
              userData = doc.data();
              isLoading = false;
            });
          }
        }
      } catch (e) {
        debugPrint("Error: $e");
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  // --- 1. FUNGSI UPDATE NO HP ---
  void _showEditPhoneDialog() {
    final phoneController = TextEditingController(text: userData?['hp'] ?? "");
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ubah No Handphone"),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: "Nomor Baru", prefixIcon: Icon(Icons.phone)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (phoneController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                  'hp': phoneController.text.trim(),
                });
                _getData(); // Refresh data
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No HP berhasil diubah!")));
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  // --- 2. FUNGSI GANTI PASSWORD (VERIFIKASI PASSWORD LAMA) ---
  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ganti Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Demi keamanan, masukkan password lama Anda.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: oldPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password Lama", prefixIcon: Icon(Icons.lock_outline)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password Baru", prefixIcon: Icon(Icons.lock_reset)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              // Validasi
              if (oldPassController.text.isEmpty || newPassController.text.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi semua kolom!")));
                 return;
              }
              Navigator.pop(ctx);
              
              try {
                // 1. Re-Authenticate (Verifikasi Password Lama)
                String email = user!.email!;
                AuthCredential credential = EmailAuthProvider.credential(email: email, password: oldPassController.text);
                await user!.reauthenticateWithCredential(credential);

                // 2. Update Password
                await user!.updatePassword(newPassController.text);

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sukses! Password berhasil diganti.")));
              } on FirebaseAuthException catch (e) {
                String err = "Gagal mengganti password";
                if (e.code == 'wrong-password') err = "Password lama salah!";
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
              }
            },
            child: const Text("Ganti"),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text("Yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Profil Saya"),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.orange.shade100,
                    child: Text(
                      userData?['nama'] != null && userData!['nama'].toString().isNotEmpty
                          ? userData!['nama'][0].toString().toUpperCase()
                          : "U",
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    userData?['nama'] ?? "Nama Tidak Ada",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    userData?['email'] ?? "-",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  
                  const SizedBox(height: 30),

                  // --- KARTU DATA ORANG TUA (DENGAN TOMBOL EDIT) ---
                  _buildSectionTitle("Informasi Akun"),
                  _buildInfoCard([
                    _buildRowInfo("Nama Lengkap", userData?['nama'] ?? "-"),
                    
                    // Baris HP dengan Icon Edit
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const SizedBox(width: 120, child: Text("No Handphone", style: TextStyle(color: Colors.grey))),
                          Expanded(child: Text(userData?['hp'] ?? "-", style: const TextStyle(fontWeight: FontWeight.w600))),
                          InkWell(
                            onTap: _showEditPhoneDialog,
                            child: const Icon(Icons.edit, size: 18, color: Colors.orange),
                          )
                        ],
                      ),
                    ),

                    _buildRowInfo("Alamat", userData?['alamat'] ?? "-"),
                    
                    // Baris Ganti Password
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const SizedBox(width: 120, child: Text("Keamanan", style: TextStyle(color: Colors.grey))),
                          Expanded(
                            child: InkWell(
                              onTap: _showChangePasswordDialog,
                              child: const Text("Ganti Password", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // --- KARTU DATA SISWA ---
                  _buildSectionTitle("Data Anak (Siswa)"),
                  _buildInfoCard([
                    _buildRowInfo("Nama Siswa", userData?['siswa_nama'] ?? "-"),
                    _buildRowInfo("NISN", userData?['siswa_nisn'] ?? "-"),
                    _buildRowInfo("Kelas", userData?['siswa_kelas'] ?? "-"),
                  ]),

                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text("Keluar Aplikasi", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  const Text("Versi Aplikasi 1.0.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
        ],
      ),
    );
  }
}