# POS Warung — Aplikasi Kasir Offline untuk UMKM

Aplikasi Point of Sale (POS) berbasis Flutter yang dirancang khusus untuk warung dan restoran kecil (UMKM) di daerah dengan koneksi internet terbatas. Seluruh data tersimpan secara lokal di perangkat, sehingga aplikasi tetap berfungsi penuh tanpa internet.

## Latar Belakang

Kebanyakan aplikasi kasir mengharuskan koneksi internet aktif untuk mencatat transaksi. Ini menjadi kendala bagi warung di desa yang sinyalnya tidak stabil. Aplikasi ini dibangun dengan pendekatan **offline-first**: semua fitur inti (transaksi, laporan, pengeluaran, pesanan) berjalan sepenuhnya tanpa internet.

## Fitur

- **Kasir** — pilih menu dengan sekali ketuk, atur jumlah/catatan/tipe (bungkus atau makan di tempat) per item, hitung kembalian otomatis, cetak struk di layar.
- **Manajemen Menu** — kelola menu per kategori (Makanan, Minuman, Add-on).
- **Pengeluaran Harian** — catat belanja bahan baku dan pengeluaran lain, dengan sumber uang (laci kasir atau uang pribadi) agar laporan kas tetap akurat.
- **Pesanan Terjadwal (Pre-order)** — buat pesanan untuk tanggal/jam tertentu, dengan uang muka (DP) opsional. Sistem otomatis mengelola pengakuan pendapatan (di hari pesanan selesai) terpisah dari kas fisik (di hari uang diterima).
- **Laporan Harian** — ringkasan penjualan, pengeluaran, laba kasar, dan estimasi uang di laci, lengkap dengan riwayat transaksi per hari.
- **100% Offline** — seluruh data disimpan di database SQLite lokal di perangkat, tidak memerlukan koneksi internet maupun server.

## Tech Stack

- **Framework:** Flutter (Dart)
- **Database:** SQLite (`sqflite`), disimpan lokal di perangkat
- **UI:** Material 3, dengan tema kustom (Google Fonts — Plus Jakarta Sans)
- **Target Platform:** Android (utama), dengan dukungan web untuk keperluan dashboard di masa mendatang

## Arsitektur

Aplikasi menggunakan pendekatan **single-device, offline-first**:
- Satu instance aplikasi = satu database lokal, tanpa perlu sinkronisasi antar perangkat.
- Migrasi skema database ditulis idempotent (aman dijalankan berkali-kali), memakai pengecekan `PRAGMA table_info` sebelum menambah kolom baru, sehingga update aplikasi tidak berisiko merusak data yang sudah ada.
- Pemisahan antara **pengakuan pendapatan** (kapan transaksi dianggap selesai, untuk laporan laba) dan **kas fisik** (kapan uang benar-benar diterima, untuk saldo laci) — penting untuk kasus pesanan dengan uang muka.

## Struktur Folder
lib/
├── database/ # Repository & skema database (SQLite)
├── screens/ # Halaman UI (Kasir, Menu, Laporan, Pengeluaran, Pesanan)
├── theme/ # Tema visual terpusat
├── utils/ # Fungsi bantu (format rupiah, tanggal, dll)
└── main.dart # Entry point & navigasi


## Cara Menjalankan

1. Pastikan Flutter SDK sudah terpasang ([panduan resmi](https://docs.flutter.dev/get-started/install)).
2. Clone repository ini:
git clone https://github.com/Egaaa04/pos-warung-flutter.git
cd pos-warung-flutter

3. Pasang dependency:
flutter pub get

4. Jalankan di perangkat Android (sambungkan lewat USB, aktifkan USB debugging):

flutter run

## Status Pengembangan

Proyek ini masih dikembangkan sebagai portofolio pribadi. Rencana fitur berikutnya:
- [ ] Manajemen stok bahan baku
- [ ] Backup dan restore data (ekspor/impor)
- [ ] Dashboard web untuk pemilik (opsional, terhubung ke backend)

---

Dibangun dengan Flutter oleh Ega. pos-warung-flutter.