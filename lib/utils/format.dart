String rupiah(int n) {
  final neg = n < 0;
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return neg ? '-Rp $buf' : 'Rp $buf';
}

String jam(String iso) {
  final d = DateTime.parse(iso);
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

const _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

String tanggal(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';