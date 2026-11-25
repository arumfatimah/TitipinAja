
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'pilih_durasi_page.dart';

class TitipBarangPage extends StatefulWidget {
  const TitipBarangPage({super.key});

  @override
  State<TitipBarangPage> createState() => _TitipBarangPageState();
}

class _TitipBarangPageState extends State<TitipBarangPage> {
  final _formKey = GlobalKey<FormState>();

  final namaBarangController = TextEditingController();
  final jumlahController = TextEditingController(text: '1');
  final beratController = TextEditingController(text: '10');
  final catatanController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  final Color hijau = const Color(0xFF1F7A5A);
  final Color kuning = const Color(0xFFF5B700);

  String? kategoriBarang;
  String? ukuranBarang;

  Position? posisiPelanggan;
  bool sedangMencariLokasi = false;

  File? fotoBarang;

  final List<String> kategori = [
    'Buku & perlengkapan',
    'Pakaian',
    'Elektronik',
    'Perabot',
    'Lainnya',
  ];

  @override
  void dispose() {
    namaBarangController.dispose();
    jumlahController.dispose();
    beratController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  // GPS
  Future<void> ambilLokasi() async {
    setState(() {
      sedangMencariLokasi = true;
    });

    try {
      final layananAktif =
          await Geolocator.isLocationServiceEnabled();

      if (!layananAktif) {
        throw Exception('GPS belum aktif. Aktifkan lokasi HP kamu.');
      }

      LocationPermission izin =
          await Geolocator.checkPermission();

      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }

      if (izin == LocationPermission.denied) {
        throw Exception('Izin lokasi belum diberikan.');
      }

      if (izin == LocationPermission.deniedForever) {
        throw Exception(
          'Izin lokasi ditolak permanen. Aktifkan melalui pengaturan aplikasi.',
        );
      }

      final posisi = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );

      if (!mounted) return;

      setState(() {
        posisiPelanggan = posisi;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi berhasil ditemukan!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          sedangMencariLokasi = false;
        });
      }
    }
  }

  // FOTO BARANG
  Future<void> pilihFoto() async {
    try {
      final XFile? hasil = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (hasil != null && mounted) {
        setState(() {
          fotoBarang = File(hasil.path);
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memilih foto barang.'),
        ),
      );
    }
  }

  // LABEL FORM
  Widget labelForm(String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        teks,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  // INPUT
  InputDecoration dekorasiInput({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xFF9CA3AF),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hijau,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  // PILIH UKURAN
  Widget pilihanUkuran(String ukuran, String kapasitas) {
    final dipilih = ukuranBarang == ukuran;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () {
          setState(() {
            ukuranBarang = ukuran;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: 3,
          ),
          decoration: BoxDecoration(
            color: dipilih
                ? const Color(0xFFE6F4EE)
                : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: dipilih
                  ? hijau
                  : const Color(0xFFDDE1E5),
            ),
          ),
          child: Text(
            '$ukuran • $kapasitas UR',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: dipilih ? hijau : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  // STEPPER
  Widget stepper() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 13),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  '1 Barang',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1F7A5A),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '2 Durasi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '3 Konfirmasi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Container(height: 3, color: hijau)),
              Expanded(
                child: Container(
                  height: 3,
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              Expanded(
                child: Container(
                  height: 3,
                  color: const Color(0xFFE5E7EB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // KAPASITAS
  Widget kapasitasCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kapasitas tersedia',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Ketersediaan slot akan diperiksa berdasarkan ukuran barang.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF89919C),
            ),
          ),
        ],
      ),
    );
  }

  // FOTO CARD
  Widget fotoCard() {
    return InkWell(
      onTap: pilihFoto,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFB9DCCB),
          ),
        ),
        child: fotoBarang == null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      color: hijau, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tambahkan foto',
                    style: TextStyle(
                      color: hijau,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      fotoBarang!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ketuk untuk mengganti foto',
                    style: TextStyle(
                      color: hijau,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // LOKASI
  Widget lokasiCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lokasi penjemputan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF172033),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Tentukan lokasi barang yang akan dijemput.',
          style: TextStyle(
            color: Color(0xFF89919C),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: sedangMencariLokasi ? null : ambilLokasi,
            style: OutlinedButton.styleFrom(
              foregroundColor: hijau,
              side: const BorderSide(
                color: Color(0xFFB8C4BF),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            icon: sedangMencariLokasi
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.my_location, size: 18),
            label: Text(
              sedangMencariLokasi
                  ? 'Mencari lokasi...'
                  : 'Gunakan Lokasi Saya',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: posisiPelanggan == null
              ? const Text(
                  'Lokasi belum ditentukan.',
                  style: TextStyle(
                    color: Color(0xFF89919C),
                    fontSize: 12,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: hijau,
                          size: 19,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Lokasi berhasil ditemukan',
                          style: TextStyle(
                            color: hijau,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Latitude: ${posisiPelanggan!.latitude}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Longitude: ${posisiPelanggan!.longitude}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // VALIDASI
 
void lanjutkan() {
  if (!_formKey.currentState!.validate()) return;

  if (kategoriBarang == null || ukuranBarang == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Pilih kategori dan ukuran barang terlebih dahulu.',
        ),
      ),
    );
    return;
  }

  if (posisiPelanggan == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tentukan lokasi GPS terlebih dahulu.'),
      ),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PilihDurasiPage(
        namaBarang: namaBarangController.text,
        kategori: kategoriBarang!,
        jumlah: jumlahController.text,
        ukuran: ukuranBarang!,
        berat: beratController.text,
        catatan: catatanController.text,
        foto: fotoBarang,
        latitude: posisiPelanggan!.latitude,
        longitude: posisiPelanggan!.longitude,
      ),
    ),
  );
}


  // KONTEN KOLOM KIRI
  Widget kolomKiri() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        labelForm('Nama barang'),
        TextFormField(
          controller: namaBarangController,
          decoration: dekorasiInput(hint: 'Contoh: Kardus buku'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nama barang harus diisi';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),

        labelForm('Kategori barang'),
        DropdownButtonFormField<String>(
          value: kategoriBarang,
          isExpanded: true,
          decoration: dekorasiInput(),
          hint: const Text(
            'Pilih kategori barang',
            style: TextStyle(fontSize: 13),
          ),
          items: kategori.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              kategoriBarang = value;
            });
          },
        ),
        const SizedBox(height: 18),

        labelForm('Jumlah barang'),
        TextFormField(
          controller: jumlahController,
          keyboardType: TextInputType.number,
          decoration: dekorasiInput(hint: 'Masukkan jumlah'),
          validator: (value) {
            final jumlah = int.tryParse(value ?? '');
            if (jumlah == null || jumlah < 1) {
              return 'Jumlah minimal 1';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),

        labelForm('Paket ukuran'),
        Row(
          children: [
            pilihanUkuran('S', '1'),
            const SizedBox(width: 8),
            pilihanUkuran('M', '2'),
            const SizedBox(width: 8),
            pilihanUkuran('L', '4'),
            const SizedBox(width: 8),
            pilihanUkuran('XL', '8'),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'S: kecil • M: sedang • L: besar • XL: ekstra besar',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF89919C),
          ),
        ),
        const SizedBox(height: 16),
        kapasitasCard(),
      ],
    );
  }

  // KONTEN KOLOM KANAN
  Widget kolomKanan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        labelForm('Perkiraan berat (kg)'),
        TextFormField(
          controller: beratController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: dekorasiInput(hint: 'Contoh: 10'),
          validator: (value) {
            final berat = double.tryParse(value ?? '');
            if (berat == null || berat <= 0) {
              return 'Masukkan berat yang valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),

        labelForm('Foto barang'),
        fotoCard(),
        const SizedBox(height: 18),

        labelForm('Catatan khusus'),
        TextFormField(
          controller: catatanController,
          maxLines: 3,
          decoration: dekorasiInput(
            hint: 'Contoh: mudah pecah, elektronik...',
          ),
        ),
        const SizedBox(height: 24),

        lokasiCard(),
      ],
    );
  }

  // TAMPILAN UTAMA
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        title: const Text(
          'Titip Barang',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.notifications_none,
              color: kuning,
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 750;
          final contentWidth = constraints.maxWidth > 1100
              ? 1050.0
              : constraints.maxWidth;

         return Align(
  alignment: Alignment.topCenter,
  child: SizedBox(
    width: contentWidth,
    height: constraints.maxHeight,
    child: Column(
                children: [
                  stepper(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 28 : 18,
                        vertical: 22,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ceritakan barangmu',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Lengkapi informasi barang yang ingin kamu titipkan.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 25),

                            if (isDesktop)
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: kolomKiri()),
                                  const SizedBox(width: 28),
                                  Expanded(child: kolomKanan()),
                                ],
                              )
                            else
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  kolomKiri(),
                                  const SizedBox(height: 22),
                                  kolomKanan(),
                                ],
                              ),

                            const SizedBox(height: 25),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: lanjutkan,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hijau,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Lanjut pilih durasi →',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2,
        selectedItemColor: hijau,
        unselectedItemColor: const Color(0xFF89919C),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Titipan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
