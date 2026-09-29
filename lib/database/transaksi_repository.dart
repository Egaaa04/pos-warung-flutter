import 'app_database.dart';

class ItemKeranjang {
  final int menuId;
  final String nama;
  final int harga;
  int jumlah;
  String? catatan;
  String tipe; // 'makan_di_tempat' atau 'bungkus'

  ItemKeranjang({
    required this.menuId,
    required this.nama,
    required this.harga,
    this.jumlah = 1,
    this.catatan,
    this.tipe = 'makan_di_tempat',
  });

  int get subtotal => harga * jumlah;

  // Baris digabung kalau menu, catatan, dan tipenya sama persis.
  String get kunci => '$menuId|${catatan ?? ''}|$tipe';
}

class TransaksiRepository {
  Future<int> simpan(
      List<ItemKeranjang> items, int uangDiterima, String? catatan) async {
    final db = await AppDatabase.instance;
    final total = items.fold<int>(0, (s, i) => s + i.subtotal);

    return db.transaction((txn) async {
      final id = await txn.insert('transaksi', {
        'waktu': DateTime.now().toIso8601String(),
        'total': total,
        'uang_diterima': uangDiterima,
        'kembalian': uangDiterima - total,
        'catatan': catatan,
      });
      for (final i in items) {
        await txn.insert('item_transaksi', {
          'transaksi_id': id,
          'nama': i.nama,
          'harga': i.harga,
          'jumlah': i.jumlah,
          'catatan': i.catatan,
          'tipe': i.tipe,
        });
      }
      return id;
    });
  }
}