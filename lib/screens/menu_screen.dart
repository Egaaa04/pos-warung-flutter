import 'package:flutter/material.dart';
import '../database/menu_repository.dart';
import '../utils/format.dart';

const _warnaKategori = {
  'makanan': Color(0xFFEA580C),
  'minuman': Color(0xFF0284C7),
  'addon': Color(0xFF7C3AED),
};

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _repo = MenuRepository();
  List<Menu> _daftar = [];

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final data = await _repo.semua();
    if (!mounted) return;
    setState(() => _daftar = data);
  }

  Future<void> _form([Menu? menu]) async {
    final namaCtrl = TextEditingController(text: menu?.nama ?? '');
    final hargaCtrl =
        TextEditingController(text: menu?.harga.toString() ?? '');
    String kategori = menu?.kategori ?? 'makanan';

    final simpan = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(menu == null ? 'Tambah menu' : 'Ubah menu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaCtrl,
                decoration: const InputDecoration(labelText: 'Nama menu'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hargaCtrl,
                decoration: const InputDecoration(labelText: 'Harga (Rp)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: [
                    for (final e in kategoriMenu.entries)
                      ButtonSegment(value: e.key, label: Text(e.value)),
                  ],
                  selected: {kategori},
                  onSelectionChanged: (s) => setD(() => kategori = s.first),
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
                child: const Text('Simpan')),
          ],
        ),
      ),
    );

    if (simpan != true) return;
    final nama = namaCtrl.text.trim();
    final harga = int.tryParse(hargaCtrl.text.trim());

    if (nama.isEmpty || harga == null || harga <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan harga harus diisi dengan benar')),
      );
      return;
    }

    if (menu == null) {
      await _repo.tambah(nama, harga, kategori);
    } else {
      await _repo.ubah(menu.id!, nama, harga, kategori);
    }
    _muat();
  }

  Future<void> _hapus(Menu menu) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus menu?'),
        content: Text(menu.nama),
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
    await _repo.hapus(menu.id!);
    _muat();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Menu')),
      body: _daftar.isEmpty
          ? Center(
              child: Text('Belum ada menu. Tekan + untuk menambah.',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
              itemCount: _daftar.length,
              itemBuilder: (context, i) {
                final m = _daftar[i];
                final warna = _warnaKategori[m.kategori] ?? scheme.primary;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _form(m),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: warna.withValues(alpha: 0.15),
                            child: Text(
                              m.nama.isNotEmpty ? m.nama[0].toUpperCase() : '?',
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.nama,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: warna.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        kategoriMenu[m.kategori] ?? '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: warna,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(rupiah(m.harga),
                                        style: TextStyle(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: scheme.error,
                            onPressed: () => _hapus(m),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Menu'),
      ),
    );
  }
}