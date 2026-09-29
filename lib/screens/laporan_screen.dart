import 'package:flutter/material.dart';
import '../database/laporan_repository.dart';
import '../utils/format.dart';

const _labelTipe = {
  'makan_di_tempat': 'Makan di tempat',
  'bungkus': 'Bungkus',
};

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  final _repo = LaporanRepository();
  DateTime _tanggal = DateTime.now();
  RingkasanHarian? _data;
  String? _error;

  bool get _hariIni {
    final n = DateTime.now();
    return _tanggal.year == n.year &&
        _tanggal.month == n.month &&
        _tanggal.day == n.day;
  }

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    try {
      final d = await _repo.ringkasan(_tanggal);
      if (!mounted) return;
      setState(() {
        _data = d;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  void _geser(int hari) {
    setState(() => _tanggal =
        DateTime(_tanggal.year, _tanggal.month, _tanggal.day + hari));
    _muat();
  }

  Future<void> _pilihTanggal() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (p == null) return;
    setState(() => _tanggal = p);
    _muat();
  }

  Widget _kartuRingkasan(
    BuildContext context, {
    required String label,
    required String nilai,
    required IconData ikon,
    required Color warna,
    String? catatan,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warna.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(ikon, size: 18, color: warna),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: warna, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(nilai,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: warna)),
          if (catatan != null) ...[
            const SizedBox(height: 2),
            Text(catatan,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = _data;

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: _error != null
          ? Center(child: Text('Gagal memuat: $_error'))
          : d == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => _geser(-1),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: _pilihTanggal,
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Column(
                                  children: [
                                    if (_hariIni)
                                      Text('HARI INI',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                              color: scheme.primary)),
                                    Text(
                                      tanggal(_tanggal),
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _hariIni ? null : () => _geser(1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      children: [
                        _kartuRingkasan(
                          context,
                          label: 'Penjualan',
                          nilai: rupiah(d.totalPenjualan),
                          ikon: Icons.trending_up,
                          warna: const Color(0xFF16A34A),
                          catatan: '${d.transaksi.length} transaksi',
                        ),
                        _kartuRingkasan(
                          context,
                          label: 'Pengeluaran',
                          nilai: rupiah(d.totalPengeluaran),
                          ikon: Icons.trending_down,
                          warna: const Color(0xFFDC2626),
                        ),
                        _kartuRingkasan(
                          context,
                          label: 'Laba Kasar',
                          nilai: rupiah(d.laba),
                          ikon: Icons.savings_outlined,
                          warna: d.laba < 0
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF2563EB),
                          catatan: 'Penjualan − pengeluaran',
                        ),
                        _kartuRingkasan(
                          context,
                          label: 'Uang di Laci',
                          nilai: rupiah(d.tambahanLaci),
                          ikon: Icons.point_of_sale,
                          warna: const Color(0xFF7C3AED),
                          catatan: 'Belum termasuk modal awal',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Riwayat Transaksi',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (d.transaksi.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('Belum ada transaksi pada hari ini.',
                              style: TextStyle(color: scheme.onSurfaceVariant)),
                        ),
                      ),
                    for (final t in d.transaksi)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ExpansionTile(
                          shape: const RoundedRectangleBorder(
                              side: BorderSide.none),
                          leading: CircleAvatar(
                            backgroundColor: scheme.primaryContainer,
                            child: Icon(Icons.receipt_long,
                                size: 18, color: scheme.onPrimaryContainer),
                          ),
                          title: Text(rupiah(t.total),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(t.catatan == null
                              ? '${jam(t.waktu)} • ${t.items.length} jenis item'
                              : '${jam(t.waktu)} • ${t.catatan}'),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          children: [
                            const Divider(),
                            for (final i in t.items)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              '${i.nama} x${i.jumlah} (${_labelTipe[i.tipe]})'),
                                          if (i.catatan != null)
                                            Text(i.catatan!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                        color: scheme
                                                            .onSurfaceVariant)),
                                        ],
                                      ),
                                    ),
                                    Text(rupiah(i.subtotal)),
                                  ],
                                ),
                              ),
                            const Divider(),
                            Text(
                                'Tunai ${rupiah(t.uangDiterima)} • Kembalian ${rupiah(t.kembalian)}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}