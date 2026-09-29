import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'pos_warung.db');
    _db = await openDatabase(
      path,
      version: 3,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  // Instalasi baru: langsung buat skema versi terbaru.
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE menu (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        harga INTEGER NOT NULL,
        aktif INTEGER NOT NULL DEFAULT 1,
        kategori TEXT NOT NULL DEFAULT 'makanan'
      )''');

    await db.execute('''
      CREATE TABLE transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        waktu TEXT NOT NULL,
        total INTEGER NOT NULL,
        uang_diterima INTEGER NOT NULL,
        kembalian INTEGER NOT NULL,
        catatan TEXT
      )''');

    await db.execute('''
      CREATE TABLE item_transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaksi_id INTEGER NOT NULL REFERENCES transaksi(id),
        nama TEXT NOT NULL,
        harga INTEGER NOT NULL,
        jumlah INTEGER NOT NULL,
        catatan TEXT,
        tipe TEXT NOT NULL DEFAULT 'makan_di_tempat'
      )''');

    await db.execute('''
      CREATE TABLE kategori_pengeluaran (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL
      )''');

    await db.execute('''
      CREATE TABLE pengeluaran (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        waktu TEXT NOT NULL,
        kategori_id INTEGER REFERENCES kategori_pengeluaran(id),
        jumlah INTEGER NOT NULL,
        catatan TEXT,
        sumber_uang TEXT NOT NULL DEFAULT 'laci'
      )''');

    for (final k in ['Bahan baku', 'Gas/Listrik', 'Gaji', 'Lainnya']) {
      await db.insert('kategori_pengeluaran', {'nama': k});
    }

    await db.execute('''
      CREATE TABLE pesanan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dibuat TEXT NOT NULL,
        jadwal TEXT NOT NULL,
        nama_pemesan TEXT,
        catatan TEXT,
        status TEXT NOT NULL DEFAULT 'menunggu',
        transaksi_id INTEGER REFERENCES transaksi(id)
      )''');

    await db.execute('''
      CREATE TABLE item_pesanan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pesanan_id INTEGER NOT NULL REFERENCES pesanan(id),
        nama TEXT NOT NULL,
        harga INTEGER NOT NULL,
        jumlah INTEGER NOT NULL,
        catatan TEXT,
        tipe TEXT NOT NULL DEFAULT 'bungkus'
      )''');

    await db.execute('''
      CREATE TABLE pembayaran_pesanan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pesanan_id INTEGER NOT NULL REFERENCES pesanan(id),
        waktu TEXT NOT NULL,
        jumlah INTEGER NOT NULL,
        jenis TEXT NOT NULL
      )''');
  }

  // HP yang sudah terpasang: pastikan skema lengkap ke versi terbaru,
  // apa pun kondisi sebelumnya. Aman dijalankan berkali-kali.
  static Future<void> _onUpgrade(
      Database db, int versiLama, int versiBaru) async {
    await _pastikanKolom(
        db, 'menu', 'kategori', "TEXT NOT NULL DEFAULT 'makanan'");
    await _pastikanKolom(db, 'transaksi', 'catatan', 'TEXT');
    await _pastikanKolom(db, 'item_transaksi', 'catatan', 'TEXT');
    await _pastikanKolom(db, 'item_transaksi', 'tipe',
        "TEXT NOT NULL DEFAULT 'makan_di_tempat'");

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pesanan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dibuat TEXT NOT NULL,
        jadwal TEXT NOT NULL,
        nama_pemesan TEXT,
        catatan TEXT,
        status TEXT NOT NULL DEFAULT 'menunggu',
        transaksi_id INTEGER REFERENCES transaksi(id)
      )''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS item_pesanan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pesanan_id INTEGER NOT NULL REFERENCES pesanan(id),
        nama TEXT NOT NULL,
        harga INTEGER NOT NULL,
        jumlah INTEGER NOT NULL,
        catatan TEXT,
        tipe TEXT NOT NULL DEFAULT 'bungkus'
      )''');
    await _pastikanKolom(db, 'item_pesanan', 'catatan', 'TEXT');
    await _pastikanKolom(
        db, 'item_pesanan', 'tipe', "TEXT NOT NULL DEFAULT 'bungkus'");

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pembayaran_pesanan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pesanan_id INTEGER NOT NULL REFERENCES pesanan(id),
        waktu TEXT NOT NULL,
        jumlah INTEGER NOT NULL,
        jenis TEXT NOT NULL
      )''');

    for (final k in ['Bahan baku', 'Gas/Listrik', 'Gaji', 'Lainnya']) {
      final ada = await db.query('kategori_pengeluaran',
          where: 'nama = ?', whereArgs: [k]);
      if (ada.isEmpty) {
        await db.insert('kategori_pengeluaran', {'nama': k});
      }
    }
  }

  static Future<void> _pastikanKolom(
      Database db, String tabel, String kolom, String definisi) async {
    final info = await db.rawQuery('PRAGMA table_info($tabel)');
    final ada = info.any((c) => c['name'] == kolom);
    if (!ada) {
      await db.execute('ALTER TABLE $tabel ADD COLUMN $kolom $definisi');
    }
  }
}