import 'app_database.dart';

const kategoriMenu = {
  'makanan': 'Makanan',
  'minuman': 'Minuman',
  'addon': 'Add-on',
};

class Menu {
  final int? id;
  final String nama;
  final int harga;
  final String kategori;

  Menu({
    this.id,
    required this.nama,
    required this.harga,
    required this.kategori,
  });

  factory Menu.fromMap(Map<String, Object?> m) => Menu(
        id: m['id'] as int,
        nama: m['nama'] as String,
        harga: m['harga'] as int,
        kategori: m['kategori'] as String,
      );
}

class MenuRepository {
  Future<List<Menu>> semua() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('menu', orderBy: 'nama');
    return rows.map(Menu.fromMap).toList();
  }

  Future<void> tambah(String nama, int harga, String kategori) async {
    final db = await AppDatabase.instance;
    await db.insert(
        'menu', {'nama': nama, 'harga': harga, 'kategori': kategori});
  }

  Future<void> ubah(int id, String nama, int harga, String kategori) async {
    final db = await AppDatabase.instance;
    await db.update('menu', {'nama': nama, 'harga': harga, 'kategori': kategori},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> hapus(int id) async {
    final db = await AppDatabase.instance;
    await db.delete('menu', where: 'id = ?', whereArgs: [id]);
  }
}