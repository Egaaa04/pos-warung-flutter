import 'app_database.dart';

class Kategori {
  final int id;
  final String nama;
  Kategori({required this.id, required this.nama});
}

class Pengeluaran {
  final int id;
  final String waktu;
  final String kategori;
  final int jumlah;
  final String? catatan;
  final String sumberUang;

  Pengeluaran({
    required this.id,
    required this.waktu,
    required this.kategori,
    required this.jumlah,
    this.catatan,
    required this.sumberUang,
  });
}

class PengeluaranRepository {
  Future<List<Kategori>> kategori() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('kategori_pengeluaran', orderBy: 'id');
    return rows
        .map((r) => Kategori(id: r['id'] as int, nama: r['nama'] as String))
        .toList();
  }

  Future<void> tambah({
    required int kategoriId,
    required int jumlah,
    String? catatan,
    required String sumberUang,
  }) async {
    final db = await AppDatabase.instance;
    await db.insert('pengeluaran', {
      'waktu': DateTime.now().toIso8601String(),
      'kategori_id': kategoriId,
      'jumlah': jumlah,
      'catatan': catatan,
      'sumber_uang': sumberUang,
    });
  }

  Future<List<Pengeluaran>> hariIni() async {
    final db = await AppDatabase.instance;
    final now = DateTime.now();
    final awal = DateTime(now.year, now.month, now.day).toIso8601String();
    final akhir = DateTime(now.year, now.month, now.day + 1).toIso8601String();

    final rows = await db.rawQuery('''
      SELECT p.id, p.waktu, p.jumlah, p.catatan, p.sumber_uang,
             k.nama AS kategori
      FROM pengeluaran p
      LEFT JOIN kategori_pengeluaran k ON k.id = p.kategori_id
      WHERE p.waktu >= ? AND p.waktu < ?
      ORDER BY p.waktu DESC
    ''', [awal, akhir]);

    return rows
        .map((r) => Pengeluaran(
              id: r['id'] as int,
              waktu: r['waktu'] as String,
              kategori: (r['kategori'] as String?) ?? 'Lainnya',
              jumlah: r['jumlah'] as int,
              catatan: r['catatan'] as String?,
              sumberUang: r['sumber_uang'] as String,
            ))
        .toList();
  }

  Future<void> hapus(int id) async {
    final db = await AppDatabase.instance;
    await db.delete('pengeluaran', where: 'id = ?', whereArgs: [id]);
  }
}