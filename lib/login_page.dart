import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart'; // WAJIB ADA

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isObscure = true; 
  bool _isLoading = false;
  String _version = "Loading..."; // Variabel Versi

  @override
  void initState() {
    super.initState();
    _getVersion(); // Ambil versi saat halaman dibuka
  }

  // --- FUNGSI AMBIL VERSI APLIKASI ---
  Future<void> _getVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          // Format: v1.0.0 (1)
          _version = "v${packageInfo.version}"; 
        });
      }
    } catch (e) {
      if (mounted) setState(() => _version = "v1.0.0");
    }
  }

  // --- FUNGSI LOGIN ---
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String input = _emailController.text.trim();
      String emailFinal = input;
      
      // 1. CEK: Jika input bukan Email (Cuma Angka NIP/NISN)
      if (!input.contains('@')) {
        // Kita harus cari Email aslinya di Database berdasarkan NIP/NISN
        
        // Cek apakah dia Guru (berdasarkan NIP)?
        var query = await FirebaseFirestore.instance
            .collection('users')
            .where('nip', isEqualTo: input)
            .limit(1)
            .get();

        // Jika tidak ketemu, Cek apakah dia Siswa (berdasarkan NISN)?
        if (query.docs.isEmpty) {
           query = await FirebaseFirestore.instance
            .collection('users')
            .where('nisn', isEqualTo: input)
            .limit(1)
            .get();
        }

        if (query.docs.isNotEmpty) {
          // KETEMU! Ambil email asli dari database
          var userData = query.docs.first.data();
          emailFinal = userData['email']; 
        } else {
          // Jika tidak ada di DB, gunakan default (fallback)
          emailFinal = "$input@budhidarma.com";
        }
      }

      // 2. LOGIN KE FIREBASE AUTH (Pakai Email yang sudah ditemukan)
      UserCredential userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailFinal,
        password: _passwordController.text.trim(),
      );

      // 3. CEK ROLE & STATUS DI FIRESTORE
      String uid = userCred.user!.uid;
      DocumentSnapshot snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        
      if (snap.exists) {
        String role = snap['role'];
        
        if (mounted) {
          // Redirect sesuai Role
          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin');
          } else if (role == 'guru') {
            Navigator.pushReplacementNamed(context, '/guru');
          } else if (role == 'siswa') {
            Navigator.pushReplacementNamed(context, '/siswa');
          } else if (role == 'ortu') {
            Navigator.pushReplacementNamed(context, '/ortu');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Role tidak dikenali!")));
            await FirebaseAuth.instance.signOut();
          }
        }
      } else {
        // Jika Login Auth Sukses tapi Data di Firestore Gak Ada
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Akun tidak ditemukan (Mungkin telah dihapus Admin)."), backgroundColor: Colors.red)
          );
        }
      }

    } on FirebaseAuthException catch (e) {
      String message = "Login Gagal";
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        message = "User tidak ditemukan. Pastikan NIP/NISN benar.";
      } else if (e.code == 'wrong-password') {
        message = "Password salah.";
      } else if (e.code == 'too-many-requests') {
        message = "Terlalu banyak percobaan gagal. Coba lagi nanti.";
      }
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // Abu sangat muda
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height, 
          child: Column(
            children: [
              // ================= HEADER MELENGKUNG =================
              Stack(
                children: [
                  // Background Biru Lengkung
                  ClipPath(
                    clipper: HeaderClipper(),
                    child: Container(
                      height: 320, 
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color.fromARGB(255, 250, 255, 98), Color.fromARGB(255, 5, 12, 18)], // Biru Gradasi
                        ),
                      ),
                    ),
                  ),
                  // Logo & Teks
                  Positioned(
                    top: 90, 
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            // Pastikan aset logo sudah didaftarkan di pubspec.yaml
                            backgroundImage: AssetImage("assets/images/logo_smk.jpg"), 
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "SISTEM RAPORT DIGITAL\nDAN INFORMASI AKADEMIK",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ================= FORM LOGIN (CARD) =================
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Transform.translate(
                    offset: const Offset(0, -40), // Geser ke atas sedikit menimpa header
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // Agar tinggi menyesuaikan isi
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Silakan Login", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 5),
                            const Text("Masukkan NISN/NIP dan Password", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 30),

                            // Input Username
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: "Username / Email",
                                hintText: "NIP atau NISN",
                                prefixIcon: const Icon(Icons.person_outline, color: Colors.blue),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (v) => v!.isEmpty ? "Harap isi username" : null,
                            ),
                            const SizedBox(height: 20),

                            // Input Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _isObscure,
                              decoration: InputDecoration(
                                labelText: "Password",
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
                                suffixIcon: IconButton(
                                  icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                  onPressed: () => setState(() => _isObscure = !_isObscure),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (v) => v!.isEmpty ? "Harap isi password" : null,
                            ),
                            
                            const SizedBox(height: 30),

                            // Tombol Login
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1565C0), // Warna Biru Tua
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 5,
                                  shadowColor: Colors.blue.withOpacity(0.4),
                                ),
                                onPressed: _isLoading ? null : _login,
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                        "MASUK",
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Footer Text (OTOMATIS VERSI)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  "© 2025 MSS SMK Budhi Darma Indrapura\n$_version", // Menampilkan versi otomatis
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET CLIPPER UNTUK HEADER MELENGKUNG ---
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var controlPoint = Offset(size.width / 2, size.height);
    var endPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}