import 'package:flutter/material.dart';
import '../database/pengeluaran_repository.dart';
import '../utils/format.dart';

const _ikonKategori = {
  'Bahan baku': Icons.shopping_basket_outlined,
  'Gas/Listrik': Icons.bolt_outlined,
  'Gaji': Icons.people_outline,
  'Lainnya': Icons.more_horiz,
};

class PengeluaranScreen extends StatefulWidget {
  const PengeluaranScreen({super.key});

  @override
  State<PengeluaranScreen> createState() => _PengeluaranScreenState();
}

class _PengeluaranScreenState extends State<PengeluaranScreen> {
  final _repo = PengeluaranRepository();
  List<Pengeluaran> _daftar = [];
  List<Kategori> _kategori = [];

  int get _total => _daftar.fold<int>(0, (s, p) => s + p.jumlah);
  int get _totalLaci => _daftar
      .where((p) => p.sumberUang == 'laci')
      .fold<int>(0, (s, p) => s + p.jumlah);

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final k = await _repo.kategori();
    final d = await _repo.hariIni();
    if (!mounted) return;
    setState(() {
      _kategori = k;
      _daftar = d;
    });
  }

  Future<void> _form() async {
    if (_kategori.isEmpty) return;
    int kategoriId = _kategori.first.id;
    String sumber = 'laci';
    final jumlahCtrl = TextEditingController();
    final catatanCtrl = TextEditingController();

    final simpan = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Catat pengeluaran'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final k in _kategori)
                      ChoiceChip(
                        label: Text(k.nama),
                        avatar: Icon(
                            _ikonKategori[k.nama] ?? Icons.category_outlined,
                            size: 16),
                        showCheckmark: false,
                        selected: kategoriId == k.id,
                        onSelected: (_) => setD(() => kategoriId = k.id),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: jumlahCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: catatanCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)'),
                ),
                const SizedBox(height: 16),
                const Text('Uang diambil dari',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'laci', label: Text('Laci')),
                      ButtonSegment(value: 'pribadi', label: Text('Pribadi')),
                    ],
                    selected: {sumber},
                    onSelectionChanged: (s) => setD(() => sumber = s.first),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Simpan')),
          ],
        ),
      ),
    );

    if (simpan != true) return;
    final jumlah = int.tryParse(jumlahCtrl.text.trim());
    if (jumlah == null || jumlah <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus diisi dengan benar')),
      );
      return;
    }

    final catatan = catatanCtrl.text.trim();
    await _repo.tambah(
      kategoriId: kategoriId,
      jumlah: jumlah,
      catatan: catatan.isEmpty ? null : catatan,
      sumberUang: sumber,
    );
    _muat();
  }

  Future<void> _hapus(Pengeluaran p) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus pengeluaran?'),
        content: Text('${p.kategori} - ${rupiah(p.jumlah)}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (yakin != true) return;
    await _repo.hapus(p.id);
    _muat();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const merah = Color(0xFFDC2626);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengeluaran Hari Ini'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Catat pengeluaran',
            onPressed: _form,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: merah.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: merah.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.trending_down, color: merah),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total hari ini',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: merah)),
                    Text(rupiah(_total),
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: merah)),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Dari laci',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant)),
                    Text(rupiah(_totalLaci),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _daftar.isEmpty
                ? Center(
                    child: Text('Belum ada pengeluaran hari ini.',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: _daftar.length,
                    itemBuilder: (context, i) {
                      final p = _daftar[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: merah.withValues(alpha: 0.12),
                            child: Icon(
                                _ikonKategori[p.kategori] ??
                                    Icons.category_outlined,
                                color: merah,
                                size: 20),
                          ),
                          title: Text(p.kategori,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text([
                            jam(p.waktu),
                            p.sumberUang == 'laci' ? 'Laci kasir' : 'Uang pribadi',
                            if (p.catatan != null && p.catatan!.isNotEmpty)
                              p.catatan!,
                          ].join(' • ')),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(rupiah(p.jumlah),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: merah)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _hapus(p),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}