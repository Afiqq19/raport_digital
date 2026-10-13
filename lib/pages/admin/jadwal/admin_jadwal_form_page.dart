import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminJadwalFormPage extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? data;

  const AdminJadwalFormPage({super.key, this.docId, this.data});

  @override
  State<AdminJadwalFormPage> createState() => _AdminJadwalFormPageState();
}

class _AdminJadwalFormPageState extends State<AdminJadwalFormPage> {
  final _formKey = GlobalKey<FormState>();

  String? selectedGuruId;
  String? selectedGuruNama;
  String? selectedKelas;
  String? selectedMapel;

  List<String> listMapelGuru = [];
  final List<String> hariList = const [
    "Senin",
    "Selasa",
    "Rabu",
    "Kamis",
    "Jumat",
    "Sabtu"
  ];

  // List Hari yang dipilih
  List<String> selectedHariList = [];

  final Map<String, TextEditingController> _startControllers = {};
  final Map<String, TextEditingController> _endControllers = {};

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      selectedGuruId = widget.data!['guru_id'];
      selectedGuruNama = widget.data!['guru_nama'];
      selectedKelas = widget.data!['kelas'];
      selectedMapel = widget.data!['mapel'];

      // LOGIKA LOAD DATA HARI
      var hariData = widget.data!['hari'];
      if (hariData is List) {
        selectedHariList = List<String>.from(hariData);
      } else if (hariData is String) {
        selectedHariList = [hariData];
      }

      // Init Controller untuk hari yang sudah terpilih (Mode Edit)
      for (var hari in selectedHariList) {
        // Disini kita perlu logic tambahan kalau mau mode edit sempurna,
        // tapi untuk sekarang kita load mapel saja.
        _startControllers[hari] = TextEditingController();
        _endControllers[hari] = TextEditingController();
      }

      if (selectedGuruId != null) {
        _loadMapelGuru(selectedGuruId!);
      }
    }
  }

  @override
  void dispose() {
    for (var c in _startControllers.values) {
      c.dispose();
    }
    for (var c in _endControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // --- BAGIAN INI YANG DIPERBAIKI ---
  void _loadMapelGuru(String guruId) async {
    var doc = await FirebaseFirestore.instance.collection('users').doc(guruId).get();

    if (doc.exists && mounted) {
      var data = doc.data();
      setState(() {
        // Menggunakan ? dan ?? [] agar aman dan bersih
        listMapelGuru = List<String>.from(data?['mapel'] ?? []);
      });
    }
  }

  Future<void> _pickTime(String hari, bool isStart) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
    );
    if (picked != null) {
      String hour = picked.hour.toString().padLeft(2, '0');
      String minute = picked.minute.toString().padLeft(2, '0');

      setState(() {
        if (isStart) {
          _startControllers[hari]?.text = "$hour:$minute";
        } else {
          _endControllers[hari]?.text = "$hour:$minute";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      appBar: AppBar(
        title: Text(widget.docId == null ? "Tambah Jadwal" : "Edit Jadwal"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PILIH GURU
              _label("Pilih Guru Pengajar:"),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'guru')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  return DropdownButtonFormField<String>(
                    value: selectedGuruId,
                    decoration: _inputDecor(Icons.person),
                    hint: const Text("Pilih Guru"),
                    items: snapshot.data!.docs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                          value: doc.id, child: Text(data['nama'] ?? "-"));
                    }).toList(),
                    onChanged: (val) {
                      var doc =
                          snapshot.data!.docs.firstWhere((d) => d.id == val);
                      var data = doc.data() as Map<String, dynamic>;
                      setState(() {
                        selectedGuruId = val;
                        selectedGuruNama = data['nama'];
                        selectedMapel = null;
                        listMapelGuru = List<String>.from(data['mapel'] ?? []);
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 15),

              // 2. PILIH MATA PELAJARAN
              _label("Mata Pelajaran:"),
              DropdownButtonFormField<String>(
                value: selectedMapel,
                decoration: _inputDecor(Icons.book),
                hint: const Text("Pilih Mapel"),
                items: listMapelGuru
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) => setState(() => selectedMapel = val),
              ),
              const SizedBox(height: 15),

              // 3. PILIH KELAS
              _label("Kelas:"),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('kelas')
                    .orderBy('namaKelas')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  return DropdownButtonFormField<String>(
                    value: selectedKelas,
                    decoration: _inputDecor(Icons.class_),
                    hint: const Text("Pilih Kelas"),
                    items: snapshot.data!.docs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                          value: data['namaKelas'] as String,
                          child: Text(data['namaKelas']));
                    }).toList(),
                    onChanged: (val) => setState(() => selectedKelas = val),
                  );
                },
              ),
              const SizedBox(height: 15),

              // 4. PILIH HARI (CHIPS)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _label("Pilih Hari (Klik untuk memilih):"),
                  Text("${selectedHariList.length} Hari dipilih",
                      style: const TextStyle(color: Colors.blue)),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                child: Wrap(
                  spacing: 8,
                  children: hariList.map((hari) {
                    bool isSelected = selectedHariList.contains(hari);
                    return FilterChip(
                      label: Text(hari),
                      selected: isSelected,
                      selectedColor: Colors.blue.shade100,
                      checkmarkColor: Colors.blue,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            selectedHariList.add(hari);
                            // Init Controller untuk hari ini
                            _startControllers[hari] = TextEditingController();
                            _endControllers[hari] = TextEditingController();
                          } else {
                            selectedHariList.remove(hari);
                            // Hapus Controller agar hemat memori
                            _startControllers.remove(hari);
                            _endControllers.remove(hari);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // 5. INPUT JAM DINAMIS
              if (selectedHariList.isNotEmpty) ...[
                _label("Atur Jam Per Hari:"),
                const SizedBox(height: 5),
                Column(
                  children: selectedHariList.map((hari) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(hari,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _startControllers[hari],
                                  readOnly: true,
                                  onTap: () => _pickTime(hari, true),
                                  decoration: _inputDecor(Icons.access_time)
                                      .copyWith(
                                          labelText: "Mulai",
                                          fillColor: Colors.grey.shade50),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text("-",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _endControllers[hari],
                                  readOnly: true,
                                  onTap: () => _pickTime(hari, false),
                                  decoration: _inputDecor(
                                          Icons.access_time_filled)
                                      .copyWith(
                                          labelText: "Selesai",
                                          fillColor: Colors.grey.shade50),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 30),

              // TOMBOL SIMPAN
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isLoading ? null : _simpanJadwal,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SIMPAN JADWAL",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  InputDecoration _inputDecor(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    );
  }

  Future<void> _simpanJadwal() async {
    if (selectedGuruId == null ||
        selectedKelas == null ||
        selectedMapel == null ||
        selectedHariList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Mohon lengkapi semua data!"),
          backgroundColor: Colors.red));
      return;
    }

    bool jamLengkap = true;
    for (String hari in selectedHariList) {
      if (_startControllers[hari]?.text.isEmpty ?? true) {
        jamLengkap = false;
        break;
      }
      if (_endControllers[hari]?.text.isEmpty ?? true) {
        jamLengkap = false;
        break;
      }
    }

    if (!jamLengkap) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Jam mulai dan selesai harus diisi untuk setiap hari!"),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => isLoading = true);

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (String hari in selectedHariList) {
        DocumentReference docRef =
            FirebaseFirestore.instance.collection('jadwal').doc();

        batch.set(docRef, {
          "guru_id": selectedGuruId,
          "guru_nama": selectedGuruNama,
          "kelas": selectedKelas,
          "mapel": selectedMapel,
          "hari": hari,
          "jam_mulai": _startControllers[hari]!.text,
          "jam_selesai": _endControllers[hari]!.text,
          "created_at": DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Jadwal Berhasil Disimpan"),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}