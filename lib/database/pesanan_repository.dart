import 'app_database.dart';
import 'transaksi_repository.dart';
import 'package:sqflite/sqflite.dart';

class ItemPesananRiwayat {
  final String nama;
  final int harga;
  final int jumlah;
  final String? catatan;
  final String tipe;

  ItemPesananRiwayat({
    required this.nama,
    required this.harga,
    required this.jumlah,
    this.catatan,
    required this.tipe,
  });

  int get subtotal => harga * jumlah;
}

class Pesanan {
  final int id;
  final String dibuat;
  final String jadwal;
  final String? namaPemesan;
  final String? catatan;
  final String status; // 'menunggu' atau 'selesai'
  final int total;
  final int sudahDibayar;
  final List<ItemPesananRiwayat> items;

  Pesanan({
    required this.id,
    required this.dibuat,
    required this.jadwal,
    this.namaPemesan,
    this.catatan,
    required this.status,
    required this.total,
    required this.sudahDibayar,
    required this.items,
  });

  int get sisa => total - sudahDibayar;
}

class PesananRepository {
  Future<int> buat({
    required DateTime jadwal,
    String? namaPemesan,
    String? catatan,
    required List<ItemKeranjang> items,
    required int dibayarSekarang,
  }) async {
    final db = await AppDatabase.instance;
    return db.transaction((txn) async {
      final id = await txn.insert('pesanan', {
        'dibuat': DateTime.now().toIso8601String(),
        'jadwal': jadwal.toIso8601String(),
        'nama_pemesan': namaPemesan,
        'catatan': catatan,
        'status': 'menunggu',
      });
      for (final i in items) {
        await txn.insert('item_pesanan', {
          'pesanan_id': id,
          'nama': i.nama,
          'harga': i.harga,
          'jumlah': i.jumlah,
          'catatan': i.catatan,
          'tipe': i.tipe,
        });
      }
      if (dibayarSekarang > 0) {
        final total = items.fold<int>(0, (s, i) => s + i.subtotal);
        await txn.insert('pembayaran_pesanan', {
          'pesanan_id': id,
          'waktu': DateTime.now().toIso8601String(),
          'jumlah': dibayarSekarang,
          'jenis': dibayarSekarang >= total ? 'lunas' : 'dp',
        });
      }
      return id;
    });
  }

  Future<List<Pesanan>> mendatang() async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'pesanan',
      where: "status = 'menunggu'",
      orderBy: 'jadwal ASC',
    );
    return _lengkapi(db, rows);
  }

  Future<List<Pesanan>> riwayatSelesai() async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'pesanan',
      where: "status = 'selesai'",
      orderBy: 'jadwal DESC',
      limit: 50,
    );
    return _lengkapi(db, rows);
  }

    Future<List<Pesanan>> _lengkapi(
      Database db, List<Map<String, Object?>> rows) async {
    final hasil = <Pesanan>[];
    for (final r in rows) {
      final id = r['id'] as int;
      final itemRows = await db.query(
        'item_pesanan',
        where: 'pesanan_id = ?',
        whereArgs: [id],
      );
      final items = itemRows
          .map(
            (m) => ItemPesananRiwayat(
              nama: m['nama'] as String,
              harga: m['harga'] as int,
              jumlah: m['jumlah'] as int,
              catatan: m['catatan'] as String?,
              tipe: m['tipe'] as String,
            ),
          )
          .toList();
      final total = items.fold<int>(0, (s, i) => s + i.subtotal);

      final bayarRows = await db.rawQuery(
        'SELECT COALESCE(SUM(jumlah), 0) AS total FROM pembayaran_pesanan WHERE pesanan_id = ?',
        [id],
      );
      final sudahDibayar = bayarRows.first['total'] as int;

      hasil.add(
        Pesanan(
          id: id,
          dibuat: r['dibuat'] as String,
          jadwal: r['jadwal'] as String,
          namaPemesan: r['nama_pemesan'] as String?,
          catatan: r['catatan'] as String?,
          status: r['status'] as String,
          total: total,
          sudahDibayar: sudahDibayar,
          items: items,
        ),
      );
    }
    return hasil;
  }

  // Lunasi sisa pembayaran, lalu selesaikan pesanan: buat baris transaksi
  // (masuk laporan penjualan hari ini) dan tandai pesanan selesai.
  Future<void> selesaikan(Pesanan p, int pelunasan) async {
    final db = await AppDatabase.instance;
    await db.transaction((txn) async {
      if (pelunasan > 0) {
        await txn.insert('pembayaran_pesanan', {
          'pesanan_id': p.id,
          'waktu': DateTime.now().toIso8601String(),
          'jumlah': pelunasan,
          'jenis': 'pelunasan',
        });
      }
      final totalDibayar = p.sudahDibayar + pelunasan;
      final trxId = await txn.insert('transaksi', {
        'waktu': DateTime.now().toIso8601String(),
        'total': p.total,
        'uang_diterima': totalDibayar,
        'kembalian': totalDibayar - p.total,
        'catatan': p.catatan,
      });
      for (final i in p.items) {
        await txn.insert('item_transaksi', {
          'transaksi_id': trxId,
          'nama': i.nama,
          'harga': i.harga,
          'jumlah': i.jumlah,
          'catatan': i.catatan,
          'tipe': i.tipe,
        });
      }
      await txn.update(
        'pesanan',
        {'status': 'selesai', 'transaksi_id': trxId},
        where: 'id = ?',
        whereArgs: [p.id],
      );
    });
  }

  Future<void> batalkan(int id) async {
    final db = await AppDatabase.instance;
    await db.transaction((txn) async {
      await txn.delete(
        'pembayaran_pesanan',
        where: 'pesanan_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'item_pesanan',
        where: 'pesanan_id = ?',
        whereArgs: [id],
      );
      await txn.delete('pesanan', where: 'id = ?', whereArgs: [id]);
    });
  }
}
