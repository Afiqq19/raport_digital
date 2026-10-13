import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionTimeoutManager extends StatefulWidget {
  final Widget child;
  final Duration duration; // Durasi (misal: 5 Menit)

  const SessionTimeoutManager({
    super.key,
    required this.child,
    this.duration = const Duration(minutes: 5), 
  });

  @override
  State<SessionTimeoutManager> createState() => _SessionTimeoutManagerState();
}

class _SessionTimeoutManagerState extends State<SessionTimeoutManager> with WidgetsBindingObserver {
  Timer? _timer;
  
  // Variabel untuk mencatat waktu saat aplikasi di-minimize
  DateTime? _lastBackgroundTime;

  @override
  void initState() {
    super.initState();
    // 1. Daftarkan Observer untuk memantau status aplikasi (Background/Foreground)
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void dispose() {
    // 2. Hapus Observer saat widget dihancurkan
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  // ==================================================
  // LOGIKA 1: DETEKSI APLIKASI DI-MINIMIZE (BACKGROUND)
  // ==================================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // A. Saat aplikasi di-minimize (Background)
      // Catat jam berapa dia keluar
      _lastBackgroundTime = DateTime.now();
    } 
    else if (state == AppLifecycleState.resumed) {
      // B. Saat aplikasi dibuka kembali (Foreground)
      if (_lastBackgroundTime != null) {
        final timeDifference = DateTime.now().difference(_lastBackgroundTime!);
        
        // Cek apakah selisih waktu melebihi durasi (5 menit)
        if (timeDifference >= widget.duration) {
          // JIKA LEBIH DARI 5 MENIT -> LOGOUT
          _handleTimeout();
        } else {
          // JIKA KURANG DARI 5 MENIT -> RESET TIMER IDLE
          _startTimer(); 
        }
      }
    }
  }

  // ==================================================
  // LOGIKA 2: DETEKSI LAYAR TIDAK DISENTUH (IDLE)
  // ==================================================
  void _startTimer() {
    _timer?.cancel();
    
    // Cek user login
    if (FirebaseAuth.instance.currentUser == null) return;

    _timer = Timer(widget.duration, () {
      _handleTimeout();
    });
  }

  void _handleUserInteraction([_]) {
    // Reset timer setiap kali layar disentuh
    _startTimer();
  }

  // ==================================================
  // EKSEKUSI LOGOUT
  // ==================================================
  void _handleTimeout() async {
    User? user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        // Hapus semua rute dan kembali ke Login
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sesi habis (5 menit tidak aktif). Silakan login kembali."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listener untuk mendeteksi sentuhan jari
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleUserInteraction,
      onPointerMove: _handleUserInteraction,
      onPointerUp: _handleUserInteraction,
      child: widget.child,
    );
  }
}