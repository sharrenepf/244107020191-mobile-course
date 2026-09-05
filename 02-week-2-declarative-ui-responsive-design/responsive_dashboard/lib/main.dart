import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
 
/// Breakpoint tunggal yang menentukan kapan layout berpindah
/// dari 1 kolom (layar sempit) menjadi 2 kolom (layar lebar).
/// Refactoring challenge poin 3: breakpoint hanya didefinisikan di sini.
const double kWideBreakpoint = 700;
 
void main() => runApp(const DashboardApp());
 
/// Root aplikasi. Dibuat StatefulWidget karena harus menyimpan
/// state `isDark` yang bisa berubah lewat toggle di AppBar.
class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});
 
  @override
  State<DashboardApp> createState() => _DashboardAppState();
}
 
class _DashboardAppState extends State<DashboardApp> {
  bool isDark = false;
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Academic Overview',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: DashboardPage(
        isDark: isDark,
        onDarkChanged: (value) => setState(() => isDark = value),
      ),
    );
  }
}
 
class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.isDark,
    required this.onDarkChanged,
    super.key,
  });
 
  final bool isDark;
  final ValueChanged<bool> onDarkChanged;
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Overview'),
        actions: [
          Semantics(
            label: isDark
                ? 'Mode gelap aktif. Ketuk untuk beralih ke mode terang.'
                : 'Mode terang aktif. Ketuk untuk beralih ke mode gelap.',
            child: Row(
              children: [
                Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                const SizedBox(width: 4),
                CupertinoSwitch(
                  value: isDark,
                  onChanged: onDarkChanged,
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= kWideBreakpoint;
            final columns = isWide ? 2 : 1;
 
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ProfileHeader(
                    nama: 'Sharren Elvaretta',
                    nim: '244107020191',
                    kelas: 'TI-3G',
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.6,
                    children: const [
                      InfoCard(
                        title: 'Assignments',
                        value: '8',
                        icon: Icons.assignment_outlined,
                      ),
                      InfoCard(
                        title: 'Attendance',
                        value: '92%',
                        icon: Icons.event_available_outlined,
                      ),
                      InfoCard(
                        title: 'Portfolio',
                        value: 'Ready',
                        icon: Icons.folder_special_outlined,
                      ),
                      InfoCard(
                        title: 'Current week',
                        value: '02',
                        icon: Icons.calendar_today_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
 
/// Header profil di bagian atas dashboard.
/// Memakai Row + Expanded + Container sesuai ketentuan tugas.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.nama,
    required this.nim,
    required this.kelas,
    super.key,
  });
 
  final String nama;
  final String nim;
  final String kelas;
 
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
 
    return Semantics(
      label: 'Kartu profil mahasiswa $nama, NIM $nim, kelas $kelas',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(Icons.person, color: theme.colorScheme.onPrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIM: $nim  |  Kelas: $kelas',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
/// Kartu informasi reusable (refactoring challenge poin 1).
/// Warna dan style diambil dari Theme.of(context), bukan hardcode
/// (refactoring challenge poin 2), sehingga otomatis mengikuti
/// light/dark theme.
class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.title,
    required this.value,
    this.icon,
    super.key,
  });
 
  final String title;
  final String value;
  final IconData? icon;
 
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
 
    return Semantics(
      label: '$title: $value',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 