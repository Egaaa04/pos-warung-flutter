import 'app_database.dart';

class ItemRiwayat {
  final String nama;
  final int harga;
  final int jumlah;
  final String? catatan;
  final String tipe;

  ItemRiwayat({
    required this.nama,
    required this.harga,
    required this.jumlah,
    this.catatan,
    required this.tipe,
  });

  int get subtotal => harga * jumlah;
}

class TransaksiRiwayat {
  final int id;
  final String waktu;
  final int total;
  final int uangDiterima;
  final int kembalian;
  final String? catatan;
  final List<ItemRiwayat> items;

  TransaksiRiwayat({
    required this.id,
    required this.waktu,
    required this.total,
    required this.uangDiterima,
    required this.kembalian,
    this.catatan,
    required this.items,
  });
}

class RingkasanHarian {
  final List<TransaksiRiwayat> transaksi;
  final int totalPenjualan;
  final int totalPengeluaran;
  final int pengeluaranLaci;
  final int kasDariKasir; // penjualan tunai langsung (bukan dari pesanan)
  final int kasDariPesanan; // DP + pelunasan pesanan yang diterima hari ini

  RingkasanHarian({
    required this.transaksi,
    required this.totalPenjualan,
    required this.totalPengeluaran,
    required this.pengeluaranLaci,
    required this.kasDariKasir,
    required this.kasDariPesanan,
  });

  int get laba => totalPenjualan - totalPengeluaran;
  int get totalKasMasuk => kasDariKasir + kasDariPesanan;
  int get tambahanLaci => totalKasMasuk - pengeluaranLaci;
}

class LaporanRepository {
  Future<RingkasanHarian> ringkasan(DateTime tgl) async {
    final db = await AppDatabase.instance;
    final awal = DateTime(tgl.year, tgl.month, tgl.day).toIso8601String();
    final akhir = DateTime(tgl.year, tgl.month, tgl.day + 1).toIso8601String();

    final rows = await db.rawQuery('''
      SELECT t.id, t.waktu, t.total, t.uang_diterima, t.kembalian, t.catatan AS catatan_transaksi,
             i.nama, i.harga, i.jumlah, i.catatan AS catatan_item, i.tipe
      FROM transaksi t
      JOIN item_transaksi i ON i.transaksi_id = t.id
      WHERE t.waktu >= ? AND t.waktu < ?
      ORDER BY t.waktu DESC, i.id
    ''', [awal, akhir]);

    final map = <int, TransaksiRiwayat>{};
    for (final r in rows) {
      final id = r['id'] as int;
      final t = map.putIfAbsent(
        id,
        () => TransaksiRiwayat(
          id: id,
          waktu: r['waktu'] as String,
          total: r['total'] as int,
          uangDiterima: r['uang_diterima'] as int,
          kembalian: r['kembalian'] as int,
          catatan: r['catatan_transaksi'] as String?,
          items: [],
        ),
      );
      t.items.add(ItemRiwayat(
        nama: r['nama'] as String,
        harga: r['harga'] as int,
        jumlah: r['jumlah'] as int,
        catatan: r['catatan_item'] as String?,
        tipe: r['tipe'] as String,
      ));
    }
    final transaksi = map.values.toList();
    final totalPenjualan = transaksi.fold<int>(0, (s, t) => s + t.total);

    // Kas dari transaksi kasir LANGSUNG hari ini (bukan hasil pesanan
    // terjadwal), supaya tidak dobel hitung dengan pembayaran_pesanan.
    final kasKasirRows = await db.rawQuery('''
      SELECT COALESCE(SUM(t.total), 0) AS total
      FROM transaksi t
      WHERE t.waktu >= ? AND t.waktu < ?
        AND t.id NOT IN (
          SELECT transaksi_id FROM pesanan WHERE transaksi_id IS NOT NULL
        )
    ''', [awal, akhir]);
    final kasDariKasir = kasKasirRows.first['total'] as int;

    // Kas dari pesanan (DP/lunas/pelunasan) yang DITERIMA hari ini,
    // apa pun tanggal pesanannya dibuat atau diselesaikan.
    final kasPesananRows = await db.rawQuery('''
      SELECT COALESCE(SUM(jumlah), 0) AS total
      FROM pembayaran_pesanan
      WHERE waktu >= ? AND waktu < ?
    ''', [awal, akhir]);
    final kasDariPesanan = kasPesananRows.first['total'] as int;

    final p = await db.rawQuery('''
      SELECT COALESCE(SUM(jumlah), 0) AS total,
             COALESCE(SUM(CASE WHEN sumber_uang = 'laci' THEN jumlah ELSE 0 END), 0) AS laci
      FROM pengeluaran
      WHERE waktu >= ? AND waktu < ?
    ''', [awal, akhir]);

    return RingkasanHarian(
      transaksi: transaksi,
      totalPenjualan: totalPenjualan,
      totalPengeluaran: p.first['total'] as int,
      pengeluaranLaci: p.first['laci'] as int,
      kasDariKasir: kasDariKasir,
      kasDariPesanan: kasDariPesanan,
    );
  }
}