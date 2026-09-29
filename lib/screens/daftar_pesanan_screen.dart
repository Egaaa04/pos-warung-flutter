import 'package:flutter/material.dart';
import '../database/pesanan_repository.dart';
import '../utils/format.dart';
import 'buat_pesanan_screen.dart';

const _labelTipe = {
  'makan_di_tempat': 'Makan di tempat',
  'bungkus': 'Bungkus',
};

class DaftarPesananScreen extends StatefulWidget {
  const DaftarPesananScreen({super.key});

  @override
  State<DaftarPesananScreen> createState() => _DaftarPesananScreenState();
}

class _DaftarPesananScreenState extends State<DaftarPesananScreen> {
  final _repo = PesananRepository();
  List<Pesanan> _daftar = [];

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final d = await _repo.mendatang();
    if (!mounted) return;
    setState(() => _daftar = d);
  }

  Future<void> _buatBaru() async {
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const BuatPesananScreen()),
    );
    if (berhasil == true) _muat();
  }

  Future<void> _selesaikan(Pesanan p) async {
    final ctrl =
        TextEditingController(text: p.sisa > 0 ? p.sisa.toString() : '0');

    final konfirmasi = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Selesaikan pesanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ${rupiah(p.total)}'),
            Text('Sudah dibayar: ${rupiah(p.sudahDibayar)}'),
            Text('Sisa: ${rupiah(p.sisa)}'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Pelunasan diterima (Rp)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(ctrl.text.trim()) ?? 0),
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );

    if (konfirmasi == null) return;
    try {
      await _repo.selesaikan(p, konfirmasi);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      return;
    }
    _muat();
  }

  Future<void> _batalkan(Pesanan p) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Batalkan pesanan?'),
        content: Text(p.sudahDibayar > 0
            ? 'Pesanan ini sudah menerima pembayaran ${rupiah(p.sudahDibayar)}. Pastikan sudah diselesaikan dengan pelanggan.'
            : 'Pesanan belum ada pembayaran.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, batalkan')),
        ],
      ),
    );
    if (yakin != true) return;
    await _repo.batalkan(p.id);
    _muat();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const ungu = Color(0xFF7C3AED);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Mendatang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Pesanan Baru',
            onPressed: _buatBaru,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _daftar.isEmpty
          ? Center(
              child: Text('Belum ada pesanan terjadwal.',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _daftar.length,
              itemBuilder: (context, i) {
                final p = _daftar[i];
                final lunas = p.sisa <= 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: ungu.withValues(alpha: 0.15),
                        child: const Icon(Icons.event_note,
                            color: ungu, size: 20),
                      ),
                      title: Text(
                        '${tanggal(DateTime.parse(p.jadwal))}, ${jam(p.jadwal)}'
                        '${p.namaPemesan != null ? ' • ${p.namaPemesan}' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (lunas
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          lunas ? 'Lunas' : 'Sisa bayar: ${rupiah(p.sisa)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: lunas
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      children: [
                        const Divider(),
                        for (final it in p.items)
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
                                          '${it.nama} x${it.jumlah} (${_labelTipe[it.tipe]})'),
                                      if (it.catatan != null)
                                        Text(it.catatan!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                    color: scheme
                                                        .onSurfaceVariant)),
                                    ],
                                  ),
                                ),
                                Text(rupiah(it.subtotal)),
                              ],
                            ),
                          ),
                        if (p.catatan != null) ...[
                          const SizedBox(height: 4),
                          Text('Catatan: ${p.catatan}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: scheme.onSurfaceVariant)),
                        ],
                        const Divider(),
                        Text(
                            'Total ${rupiah(p.total)} • Dibayar ${rupiah(p.sudahDibayar)}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        OverflowBar(
                          alignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _batalkan(p),
                              child: const Text('Batalkan'),
                            ),
                            FilledButton(
                              onPressed: () => _selesaikan(p),
                              child: const Text('Selesaikan'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}