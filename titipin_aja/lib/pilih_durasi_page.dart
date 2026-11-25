
import 'dart:io';

import 'package:flutter/material.dart';
import 'estimasi_biaya_page.dart';

class PilihDurasiPage extends StatefulWidget {
  final String namaBarang;
  final String kategori;
  final String jumlah;
  final String ukuran;
  final String berat;
  final String catatan;
  final File? foto;
  final double? latitude;
  final double? longitude;

  // Data tempat dan tarif dari Laravel
  final String namaTempat;
  final String alamatTempat;
  final int hargaPerHari;

  const PilihDurasiPage({
    super.key,
    required this.namaBarang,
    required this.kategori,
    required this.jumlah,
    required this.ukuran,
    required this.berat,
    required this.catatan,
    this.foto,
    this.latitude,
    this.longitude,
    this.namaTempat = '',
    this.alamatTempat = '',
    this.hargaPerHari = 0,
  });

  @override
  State<PilihDurasiPage> createState() => _PilihDurasiPageState();
}

class _PilihDurasiPageState extends State<PilihDurasiPage> {
  final Color hijau = const Color(0xFF1F7A5A);

  DateTime tanggalMulai = DateUtils.dateOnly(DateTime.now());
  late DateTime tanggalSelesai;

  String metodeSerah = 'self';

  int get jumlahHari =>
      tanggalSelesai.difference(tanggalMulai).inDays;

  @override
  void initState() {
    super.initState();
    tanggalSelesai = tanggalMulai.add(
      const Duration(days: 7),
    );
  }

  String formatTanggal(DateTime tanggal) {
    return '${tanggal.month.toString().padLeft(2, '0')}/'
        '${tanggal.day.toString().padLeft(2, '0')}/'
        '${tanggal.year}';
  }

  Future<void> pilihTanggal(bool pilihMulai) async {
    final hasil = await showDatePicker(
      context: context,
      initialDate: pilihMulai ? tanggalMulai : tanggalSelesai,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
    );

    if (hasil == null || !mounted) return;

    setState(() {
      final tanggal = DateUtils.dateOnly(hasil);

      if (pilihMulai) {
        tanggalMulai = tanggal;

        if (!tanggalSelesai.isAfter(tanggalMulai)) {
          tanggalSelesai =
              tanggalMulai.add(const Duration(days: 7));
        }
      } else if (tanggal.isAfter(tanggalMulai)) {
        tanggalSelesai = tanggal;
      }
    });
  }

  Widget labelForm(String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        teks,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget tanggalCard({
    required String label,
    required DateTime tanggal,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        labelForm(label),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFFD1D5DB),
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatTanggal(tanggal),
                  style: const TextStyle(fontSize: 13),
                ),
                const Icon(
                  Icons.calendar_month,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget ringkasanDurasi() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Durasi dihitung otomatis',
                style: TextStyle(fontSize: 12),
              ),
              Text(
                '$jumlahHari hari',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Text(
            'Durasi berasal dari selisih tanggal mulai dan tanggal selesai. Tidak perlu memilih durasi manual.',
            style: TextStyle(
              fontSize: 10,
              height: 1.5,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ketersediaan',
                style: TextStyle(fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Perlu cek kapasitas',
                  style: TextStyle(
                    color: Color(0xFF166534),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget metodeSerahCard(String value, String teks) {
    final dipilih = metodeSerah == value;

    return ChoiceChip(
      label: Text(
        teks,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: dipilih ? hijau : Colors.black,
        ),
      ),
      selected: dipilih,
      selectedColor: const Color(0xFFE6F4EE),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: dipilih ? hijau : const Color(0xFFD1D5DB),
      ),
      onSelected: (_) {
        setState(() {
          metodeSerah = value;
        });
      },
    );
  }

  // Membuka halaman estimasi biaya
  void lihatEstimasi() {
    if (jumlahHari < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tanggal selesai harus setelah tanggal mulai.',
          ),
        ),
      );
      return;
    }

    if (widget.hargaPerHari <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tarif slot belum tersedia. Periksa data tempat penyimpanan.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EstimasiBiayaPage(
          namaBarang: widget.namaBarang,
          namaTempat: widget.namaTempat,
          alamatTempat: widget.alamatTempat,
          ukuranSlot: widget.ukuran,
          hargaPerHari: widget.hargaPerHari,
          jumlah: int.tryParse(widget.jumlah) ?? 1,
          tanggalMulai: tanggalMulai,
          tanggalSelesai: tanggalSelesai,
          metodeSerah: metodeSerah,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PELANGGAN',
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Pilih Durasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: const [
          Icon(
            Icons.notifications,
            color: Color(0xFFF5B700),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final lebar = constraints.maxWidth > 900
              ? 850.0
              : constraints.maxWidth;

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: lebar,
              height: constraints.maxHeight,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      13,
                      16,
                      12,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '1 Barang',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: hijau,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '2 Durasi',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: hijau,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                '3 Konfirmasi',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 3,
                                color: hijau,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 3,
                                color: hijau,
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
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pilih tanggal penitipan',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 20),

                          tanggalCard(
                            label: 'Tanggal mulai',
                            tanggal: tanggalMulai,
                            onTap: () => pilihTanggal(true),
                          ),

                          const SizedBox(height: 15),

                          tanggalCard(
                            label: 'Tanggal selesai',
                            tanggal: tanggalSelesai,
                            onTap: () => pilihTanggal(false),
                          ),

                          const SizedBox(height: 15),

                          ringkasanDurasi(),

                          const SizedBox(height: 22),

                          const Text(
                            'Metode serah barang',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 7,
                            children: [
                              metodeSerahCard(
                                'self',
                                'Antar sendiri (Rp0)',
                              ),
                              metodeSerahCard(
                                'courier',
                                'Pakai kurir',
                              ),
                            ],
                          ),

                          if (metodeSerah == 'courier') ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Text(
                                widget.latitude != null &&
                                        widget.longitude != null
                                    ? 'Lokasi penjemputan sudah tersedia.'
                                    : 'Lokasi GPS belum tersedia. Kembali ke halaman barang untuk menentukan lokasi.',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],

                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: lihatEstimasi,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hijau,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                              child: const Text(
                                'Lihat estimasi biaya',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
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
