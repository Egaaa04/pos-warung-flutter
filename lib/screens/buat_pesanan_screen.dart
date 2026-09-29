import 'package:flutter/material.dart';
import '../database/menu_repository.dart';
import '../database/pesanan_repository.dart';
import '../database/transaksi_repository.dart';
import '../utils/format.dart';

const _labelTipe = {
  'makan_di_tempat': 'Makan di tempat',
  'bungkus': 'Bungkus',
};

const _warnaKategori = {
  'makanan': Color(0xFFEA580C),
  'minuman': Color(0xFF0284C7),
  'addon': Color(0xFF7C3AED),
};

class BuatPesananScreen extends StatefulWidget {
  const BuatPesananScreen({super.key});

  @override
  State<BuatPesananScreen> createState() => _BuatPesananScreenState();
}

class _BuatPesananScreenState extends State<BuatPesananScreen> {
  final _menuRepo = MenuRepository();
  final _pesananRepo = PesananRepository();
  List<Menu> _menu = [];
  String _filter = 'semua';
  final Map<String, ItemKeranjang> _keranjang = {};

  DateTime _jadwal = DateTime.now().add(const Duration(hours: 1));
  final _namaCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  final _dpCtrl = TextEditingController();

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

  // Ketuk menu: tambah cepat 1 porsi, default Bungkus (paling umum untuk pesanan).
  void _tambahCepat(Menu m) {
    setState(() {
      final item = ItemKeranjang(
        menuId: m.id!,
        nama: m.nama,
        harga: m.harga,
        tipe: 'bungkus',
      );
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
    String tipe = 'bungkus';
    final catatanCtrl = TextEditingController();

    final tambah = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    ButtonSegment(value: 'bungkus', label: Text('Bungkus')),
                    ButtonSegment(
                        value: 'makan_di_tempat', label: Text('Makan sini')),
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
                    hintText: 'Contoh: tanpa sayur'),
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

  Future<void> _pilihJadwal() async {
    final tgl = await showDatePicker(
      context: context,
      initialDate: _jadwal,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (tgl == null) return;
    if (!mounted) return;
    final jamDipilih = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_jadwal),
    );
    if (jamDipilih == null) return;
    setState(() {
      _jadwal = DateTime(
          tgl.year, tgl.month, tgl.day, jamDipilih.hour, jamDipilih.minute);
    });
  }

  Future<void> _simpan() async {
    if (_keranjang.isEmpty) return;
    final total = _total;
    final dp = int.tryParse(_dpCtrl.text.trim()) ?? 0;

    if (dp > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uang muka tidak boleh lebih dari total')),
      );
      return;
    }

    try {
      await _pesananRepo.buat(
        jadwal: _jadwal,
        namaPemesan:
            _namaCtrl.text.trim().isEmpty ? null : _namaCtrl.text.trim(),
        catatan: _catatanCtrl.text.trim().isEmpty
            ? null
            : _catatanCtrl.text.trim(),
        items: _keranjang.values.toList(),
        dibayarSekarang: dp,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Pesanan')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(Icons.schedule,
                              size: 18, color: scheme.onPrimaryContainer),
                        ),
                        title: const Text('Jadwal diambil'),
                        subtitle: Text(
                          '${tanggal(_jadwal)}, ${jam(_jadwal.toIso8601String())}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: OutlinedButton(
                          onPressed: _pilihJadwal,
                          child: const Text('Ubah'),
                        ),
                      ),
                      const Divider(height: 20),
                      TextField(
                        controller: _namaCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Nama pemesan (opsional)'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _catatanCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Catatan pesanan (opsional)'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final e in {'semua': 'Semua', ...kategoriMenu}
                          .entries)
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
                            onSelected: (_) =>
                                setState(() => _filter = e.key),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (_tampil.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('Tidak ada menu di kategori ini.',
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    ),
                  )
                else
                  for (final m in _tampil)
                    Builder(builder: (context) {
                      final warna = _warnaKategori[m.kategori] ?? scheme.primary;
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
                                  backgroundColor:
                                      warna.withValues(alpha: 0.15),
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
                                      borderRadius:
                                          BorderRadius.circular(10),
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
                    }),
              ],
            ),
          ),
          if (_keranjang.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
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
                  TextField(
                    controller: _dpCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: scheme.onPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: scheme.onPrimary.withValues(alpha: 0.12),
                      labelText: 'Dibayar sekarang (Rp, boleh 0)',
                      labelStyle:
                          TextStyle(color: scheme.onPrimary.withValues(alpha: 0.85)),
                      hintText: 'DP atau lunas',
                      hintStyle:
                          TextStyle(color: scheme.onPrimary.withValues(alpha: 0.6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                              horizontal: 24, vertical: 16),
                        ),
                        onPressed: _keranjang.isEmpty ? null : _simpan,
                        child: const Text('Simpan Pesanan'),
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