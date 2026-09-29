import 'package:flutter/material.dart';
import '../database/menu_repository.dart';
import '../database/transaksi_repository.dart';
import '../utils/format.dart';
import 'pengeluaran_screen.dart';

const _labelTipe = {
  'makan_di_tempat': 'Makan di tempat',
  'bungkus': 'Bungkus',
};

const _warnaKategori = {
  'makanan': Color(0xFFEA580C),
  'minuman': Color(0xFF0284C7),
  'addon': Color(0xFF7C3AED),
};

class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key});

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  final _menuRepo = MenuRepository();
  final _trxRepo = TransaksiRepository();
  List<Menu> _menu = [];
  String _filter = 'semua';

  final Map<String, ItemKeranjang> _keranjang = {};
  String? _catatanUmum;

  List<Menu> get _tampil => _filter == 'semua'
      ? _menu
      : _menu.where((m) => m.kategori == _filter).toList();

  int get _total =>
      _keranjang.values.fold<int>(0, (s, i) => s + i.subtotal);

  int get _jumlahPorsi =>
      _keranjang.values.fold<int>(0, (s, i) => s + i.jumlah);

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final data = await _menuRepo.semua();
    if (!mounted) return;
    setState(() => _menu = data);
  }

  void _tambahCepat(Menu m) {
    setState(() {
      final item = ItemKeranjang(menuId: m.id!, nama: m.nama, harga: m.harga);
      final ada = _keranjang[item.kunci];
      if (ada != null) {
        ada.jumlah++;
      } else {
        _keranjang[item.kunci] = item;
      }
    });
  }

  Future<void> _tambahDenganDetail(Menu m) async {
    int jumlah = 1;
    String tipe = 'makan_di_tempat';
    final catatanCtrl = TextEditingController();

    final tambah = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(m.nama),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Jumlah'),
                  const Spacer(),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.remove),
                    onPressed: jumlah > 1 ? () => setD(() => jumlah--) : null,
                  ),
                  SizedBox(
                    width: 36,
                    child: Text('$jumlah',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    onPressed: () => setD(() => jumlah++),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'makan_di_tempat', label: Text('Makan sini')),
                    ButtonSegment(value: 'bungkus', label: Text('Bungkus')),
                  ],
                  selected: {tipe},
                  onSelectionChanged: (s) => setD(() => tipe = s.first),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: catatanCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Contoh: tanpa sayur',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Tambah')),
          ],
        ),
      ),
    );

    if (tambah != true) return;
    final catatan = catatanCtrl.text.trim();
    setState(() {
      final item = ItemKeranjang(
        menuId: m.id!,
        nama: m.nama,
        harga: m.harga,
        jumlah: jumlah,
        tipe: tipe,
        catatan: catatan.isEmpty ? null : catatan,
      );
      final ada = _keranjang[item.kunci];
      if (ada != null) {
        ada.jumlah += jumlah;
      } else {
        _keranjang[item.kunci] = item;
      }
    });
  }

  void _kurang(ItemKeranjang item) {
    setState(() {
      item.jumlah--;
      if (item.jumlah <= 0) _keranjang.remove(item.kunci);
    });
  }

  void _hapusBaris(ItemKeranjang item) {
    setState(() => _keranjang.remove(item.kunci));
  }

  Future<void> _ubahCatatanUmum() async {
    final ctrl = TextEditingController(text: _catatanUmum ?? '');
    final simpan = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Catatan untuk pesanan ini'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Contoh: pedas dipisah'),
          autofocus: true,
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
    );
    if (simpan != true) return;
    final teks = ctrl.text.trim();
    setState(() => _catatanUmum = teks.isEmpty ? null : teks);
  }

  Future<void> _bayar() async {
    final total = _total;
    final ctrl = TextEditingController();

    final uang = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) {
        final diterima = int.tryParse(ctrl.text) ?? 0;
        final kurang = diterima < total;
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total: ${rupiah(total)}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Uang diterima (Rp)'),
                onChanged: (_) => setD(() {}),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Uang pas'),
                    onPressed: () {
                      ctrl.text = total.toString();
                      setD(() {});
                    },
                  ),
                  for (final n in [10000, 20000, 50000, 100000])
                    if (n >= total)
                      ActionChip(
                        label: Text(rupiah(n)),
                        onPressed: () {
                          ctrl.text = n.toString();
                          setD(() {});
                        },
                      ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                diterima == 0
                    ? ''
                    : kurang
                        ? 'Kurang ${rupiah(total - diterima)}'
                        : 'Kembalian: ${rupiah(diterima - total)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kurang
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            FilledButton(
              onPressed: kurang ? null : () => Navigator.pop(ctx, diterima),
              child: const Text('Selesai'),
            ),
          ],
        );
      }),
    );

    if (uang == null) return;
    final items = _keranjang.values.toList();
    try {
      await _trxRepo.simpan(items, uang, _catatanUmum);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      return;
    }
    if (!mounted) return;
    await _tampilStruk(items, total, uang, _catatanUmum);
    setState(() {
      _keranjang.clear();
      _catatanUmum = null;
    });
  }

  Widget _baris(String kiri, String kanan, {bool tebal = false}) {
    final gaya = TextStyle(fontWeight: tebal ? FontWeight.bold : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(kiri, style: gaya)),
          Text(kanan, style: gaya),
        ],
      ),
    );
  }

  Future<void> _tampilStruk(
      List<ItemKeranjang> items, int total, int uang, String? catatan) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Transaksi Berhasil'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final i in items) ...[
                _baris(
                  '${i.nama} x${i.jumlah} (${_labelTipe[i.tipe]})',
                  rupiah(i.subtotal),
                ),
                if (i.catatan != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Text('- ${i.catatan}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
              ],
              const Divider(height: 20),
              _baris('Total', rupiah(total), tebal: true),
              _baris('Tunai', rupiah(uang)),
              _baris('Kembalian', rupiah(uang - total), tebal: true),
              if (catatan != null) ...[
                const SizedBox(height: 8),
                Text('Catatan: $catatan'),
              ],
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        actions: [
          if (_keranjang.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() {
                _keranjang.clear();
                _catatanUmum = null;
              }),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Kosongkan'),
            ),
          IconButton(
            icon: const Icon(Icons.payments_outlined),
            tooltip: 'Catat pengeluaran',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PengeluaranScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                for (final e in {'semua': 'Semua', ...kategoriMenu}.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: _filter == e.key,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _filter == e.key
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                      onSelected: (_) => setState(() => _filter = e.key),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _tampil.isEmpty
                ? Center(
                    child: Text('Tidak ada menu di kategori ini.',
                        style: Theme.of(context).textTheme.bodyMedium))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                    itemCount: _tampil.length,
                    itemBuilder: (context, i) {
                      final m = _tampil[i];
                      final warna =
                          _warnaKategori[m.kategori] ?? scheme.primary;
                      final jumlahDiKeranjang = _keranjang.values
                          .where((it) => it.menuId == m.id)
                          .fold<int>(0, (s, it) => s + it.jumlah);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _tambahCepat(m),
                          onLongPress: () => _tambahDenganDetail(m),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: warna.withValues(alpha: 0.15),
                                  child: Text(
                                    m.nama.isNotEmpty
                                        ? m.nama[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: warna,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(m.nama,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15)),
                                      const SizedBox(height: 2),
                                      Text(rupiah(m.harga),
                                          style: TextStyle(
                                            color: scheme.primary,
                                            fontWeight: FontWeight.w700,
                                          )),
                                    ],
                                  ),
                                ),
                                IconButton.outlined(
                                  icon: const Icon(Icons.edit_note),
                                  tooltip: 'Tambah dengan catatan/tipe',
                                  onPressed: () => _tambahDenganDetail(m),
                                ),
                                const SizedBox(width: 6),
                                if (jumlahDiKeranjang > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: scheme.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text('$jumlahDiKeranjang',
                                        style: TextStyle(
                                          color: scheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        )),
                                  )
                                else
                                  IconButton.filled(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => _tambahCepat(m),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_keranjang.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 210),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  for (final item in _keranjang.values)
                    ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: scheme.primaryContainer,
                        child: Text('${item.jumlah}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: scheme.onPrimaryContainer)),
                      ),
                      title: Text('${item.nama} • ${_labelTipe[item.tipe]}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: item.catatan == null
                          ? Text(rupiah(item.subtotal))
                          : Text('${item.catatan} • ${rupiah(item.subtotal)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _kurang(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => _hapusBaris(item),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _ubahCatatanUmum,
                    child: Row(
                      children: [
                        Icon(Icons.note_add_outlined,
                            size: 16, color: scheme.onPrimary.withValues(alpha: 0.85)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _catatanUmum ?? 'Tambah catatan pesanan',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onPrimary.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_jumlahPorsi porsi',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onPrimary.withValues(alpha: 0.85),
                              ),
                            ),
                            Text(
                              rupiah(_total),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: scheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.onPrimary,
                          foregroundColor: scheme.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 16),
                        ),
                        onPressed: _keranjang.isEmpty ? null : _bayar,
                        child: const Text('Bayar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}