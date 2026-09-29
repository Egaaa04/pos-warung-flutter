import 'package:flutter/material.dart';
import 'screens/kasir_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/laporan_screen.dart';
import 'screens/daftar_pesanan_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PosApp());
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Warung',
            theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final Widget halaman = switch (_tab) {
      0 => const KasirScreen(),
      1 => const DaftarPesananScreen(),
      2 => const LaporanScreen(),
      _ => const MenuScreen(),
    };
    return Scaffold(
      body: halaman,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Kasir'),
          NavigationDestination(icon: Icon(Icons.event_note), label: 'Pesanan'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Laporan'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
        ],
      ),
    );
  }
}