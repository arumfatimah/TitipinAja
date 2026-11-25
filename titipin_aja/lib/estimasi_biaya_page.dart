
import 'package:flutter/material.dart';

class EstimasiBiayaPage extends StatelessWidget {
  const EstimasiBiayaPage({
    super.key,
    required this.namaBarang,
    required this.namaTempat,
    required this.ukuranSlot,
    required this.hargaPerHari,
    required this.jumlah,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.metodeSerah,
    this.jarakKm,
    this.alamatTempat,
  });

  final String namaBarang;
  final String namaTempat;
  final String ukuranSlot;
  final int hargaPerHari;
  final int jumlah;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String metodeSerah;
  final double? jarakKm;
  final String? alamatTempat;

  int get jumlahHari {
    final mulai = DateTime(
      tanggalMulai.year,
      tanggalMulai.month,
      tanggalMulai.day,
    );

    final selesai = DateTime(
      tanggalSelesai.year,
      tanggalSelesai.month,
      tanggalSelesai.day,
    );

    return selesai.difference(mulai).inDays;
  }

  int get biayaPenyimpanan {
    var sisa = jumlahHari;

    if (sisa <= 0) return 0;

    final bulan = sisa ~/ 30;
    sisa %= 30;

    final minggu = sisa ~/ 7;
    sisa %= 7;

    final biayaBulan =
        bulan * 30 * hargaPerHari * 0.8;

    final biayaMinggu =
        minggu * 7 * hargaPerHari * 0.9;

    final biayaHarian = sisa * hargaPerHari;

    return ((biayaBulan + biayaMinggu + biayaHarian) *
            jumlah)
        .round();
  }

  int? get biayaKurir {
    if (metodeSerah != 'courier') return 0;

    if (jarakKm == null ||
        jarakKm!.isNaN ||
        jarakKm! < 0) {
      return null;
    }

    if (jarakKm! <= 5) return 0;

    final kmBerbayar = (jarakKm! - 5).ceil();

    return 13000 + ((kmBerbayar - 1) * 3000);
  }

  int get totalBiaya =>
      biayaPenyimpanan + (biayaKurir ?? 0);

  String rupiah(int angka) {
    final teks = angka.toString();
    final hasil = StringBuffer();

    for (var i = 0; i < teks.length; i++) {
      hasil.write(teks[i]);

      final sisa = teks.length - i - 1;

      if (sisa > 0 && sisa % 3 == 0) {
        hasil.write('.');
      }
    }

    return 'Rp$hasil';
  }

  String formatTanggal(DateTime tanggal) {
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    return '${tanggal.day} '
        '${bulan[tanggal.month - 1]} '
        '${tanggal.year}';
  }

  @override
  Widget build(BuildContext context) {
    final durasiValid = jumlahHari > 0;

    final jarakBelumAda =
        metodeSerah == 'courier' && biayaKurir == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Estimasi Biaya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
      ),
      body: SafeArea(
        child: !durasiValid
            ? const Center(
                child: Text(
                  'Tanggal selesai harus setelah tanggal mulai.',
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _panel(
                    'Ringkasan Penitipan',
                    [
                      _baris('Nama barang', namaBarang),
                      _baris('Tempat penyimpanan', namaTempat),

                      if (alamatTempat != null &&
                          alamatTempat!.isNotEmpty)
                        _baris('Alamat', alamatTempat!),

                      _baris('Ukuran slot', ukuranSlot),
                      _baris('Jumlah barang', '$jumlah'),
                      _baris(
                        'Tanggal mulai',
                        formatTanggal(tanggalMulai),
                      ),
                      _baris(
                        'Tanggal selesai',
                        formatTanggal(tanggalSelesai),
                      ),
                      _baris('Durasi', '$jumlahHari hari'),
                      _baris(
                        'Metode serah terima',
                        metodeSerah == 'courier'
                            ? 'Menggunakan kurir'
                            : 'Antar sendiri',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _panel(
                    'Rincian Biaya',
                    [
                      _baris(
                        'Tarif slot per hari',
                        '${rupiah(hargaPerHari)} × $jumlah',
                      ),
                      _baris(
                        'Biaya penyimpanan',
                        rupiah(biayaPenyimpanan),
                      ),

                      if (metodeSerah == 'courier') ...[
                        _baris(
                          'Jarak perkiraan',
                          jarakKm == null
                              ? 'Belum tersedia'
                              : '${jarakKm!.toStringAsFixed(1)} km',
                        ),
                        _baris(
                          'Biaya kurir',
                          biayaKurir == null
                              ? 'Belum dapat dihitung'
                              : rupiah(biayaKurir!),
                        ),
                      ] else
                        _baris(
                          'Biaya antar sendiri',
                          rupiah(0),
                        ),

                      const Divider(height: 28),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Estimasi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            jarakBelumAda
                                ? 'Menunggu jarak'
                                : rupiah(totalBiaya),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16865B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (jarakBelumAda) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Jarak ke tempat penyimpanan belum tersedia. '
                      'Biaya kurir belum bisa dihitung.',
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  const Text(
                    'Catatan: Diskon penyimpanan 20% berlaku '
                    'untuk setiap 30 hari penuh dan 10% untuk '
                    'setiap 7 hari penuh. Lima kilometer pertama '
                    'kurir gratis. Setelah itu, km berbayar '
                    'pertama Rp13.000 dan setiap km berikutnya '
                    'Rp3.000.',
                    style: TextStyle(
                      color: Color(0xFF70757A),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: jarakBelumAda
                          ? null
                          : () {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Tahap pembayaran akan '
                                    'dihubungkan setelah API siap.',
                                  ),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF16865B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Lanjutkan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _panel(String judul, List<Widget> isi) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...isi,
        ],
      ),
    );
  }

  Widget _baris(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF70757A),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              nilai,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF202124),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
