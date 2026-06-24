import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const FinTrackApp());
}

class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Map<String, dynamic>> _transactions = [];

  double get totalPemasukan {
    return _transactions
        .where((t) => t['tipe'] == 'pemasukan')
        .fold(0, (sum, t) => sum + (t['jumlah'] as double));
  }

  double get totalPengeluaran {
    return _transactions
        .where((t) => t['tipe'] == 'pengeluaran')
        .fold(0, (sum, t) => sum + (t['jumlah'] as double));
  }

  double get saldo => totalPemasukan - totalPengeluaran;

  String formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  void _tambahTransaksi(String tipe, String judul, double jumlah, String kategori, DateTime tanggal) {
    setState(() {
      _transactions.add({
        'tipe': tipe,
        'judul': judul,
        'jumlah': jumlah,
        'kategori': kategori,
        'tanggal': tanggal,
      });
    });
  }

  void _hapusTransaksi(int index) {
    setState(() {
      _transactions.removeAt(index);
    });
  }

  List<BarChartGroupData> _getBarChartData() {
    final now = DateTime.now();
    final Map<String, Map<String, double>> weeklyData = {};
    final List<String> days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    
    for (String day in days) {
      weeklyData[day] = {'pemasukan': 0.0, 'pengeluaran': 0.0};
    }
    
    for (var t in _transactions) {
      final daysDiff = now.difference(t['tanggal'] as DateTime).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        String dayName = DateFormat('EEE', 'id').format(t['tanggal']);
        if (dayName == 'Mon') dayName = 'Sen';
        if (dayName == 'Tue') dayName = 'Sel';
        if (dayName == 'Wed') dayName = 'Rab';
        if (dayName == 'Thu') dayName = 'Kam';
        if (dayName == 'Fri') dayName = 'Jum';
        if (dayName == 'Sat') dayName = 'Sab';
        if (dayName == 'Sun') dayName = 'Min';
        
        if (weeklyData.containsKey(dayName)) {
          if (t['tipe'] == 'pemasukan') {
            weeklyData[dayName]!['pemasukan'] = (weeklyData[dayName]!['pemasukan'] ?? 0) + (t['jumlah'] as double);
          } else {
            weeklyData[dayName]!['pengeluaran'] = (weeklyData[dayName]!['pengeluaran'] ?? 0) + (t['jumlah'] as double);
          }
        }
      }
    }
    
    double maxY = 0;
    for (var entry in weeklyData.values) {
      maxY = (entry['pemasukan'] ?? 0) > maxY ? (entry['pemasukan'] ?? 0) : maxY;
      maxY = (entry['pengeluaran'] ?? 0) > maxY ? (entry['pengeluaran'] ?? 0) : maxY;
    }
    maxY = maxY == 0 ? 100000 : maxY * 1.1;
    
    return List.generate(days.length, (index) {
      final day = days[index];
      final pemasukan = weeklyData[day]?['pemasukan'] ?? 0;
      final pengeluaran = weeklyData[day]?['pengeluaran'] ?? 0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(toY: pemasukan, color: Colors.green, width: 12, borderRadius: BorderRadius.circular(4)),
          BarChartRodData(toY: pengeluaran, color: Colors.red, width: 12, borderRadius: BorderRadius.circular(4)),
        ],
        groupingSpace: 4,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final barGroups = _getBarChartData();
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHome(barGroups),
          _buildHistory(),
          _buildAnalytics(),
          _buildBudget(),
          _buildProfile(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6366F1),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analisis'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Budget'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHome(List<BarChartGroupData> barGroups) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FinTrack', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('Total Saldo', style: TextStyle(color: Colors.white70)),
                  Text(formatRupiah(saldo), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Text('Pemasukan: ${formatRupiah(totalPemasukan)}', style: const TextStyle(color: Colors.white))),
                      Expanded(child: Text('Pengeluaran: ${formatRupiah(totalPengeluaran)}', style: const TextStyle(color: Colors.white), textAlign: TextAlign.end)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📊 Grafik 7 Hari Terakhir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: barGroups,
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                                final index = value.toInt();
                                if (index >= 0 && index < days.length) {
                                  return Text(days[index], style: const TextStyle(fontSize: 10));
                                }
                                return const Text('');
                              },
                              reservedSize: 22,
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend('Pemasukan', Colors.green),
                      const SizedBox(width: 24),
                      _buildLegend('Pengeluaran', Colors.red),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            const Text('Transaksi Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (_transactions.isEmpty)
              const Center(child: Text('Belum ada transaksi'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length > 5 ? 5 : _transactions.length,
                itemBuilder: (context, index) {
                  final t = _transactions[index];
                  final isPemasukan = t['tipe'] == 'pemasukan';
                  return Card(
                    child: ListTile(
                      leading: Icon(isPemasukan ? Icons.arrow_upward : Icons.arrow_downward, color: isPemasukan ? Colors.green : Colors.red),
                      title: Text(t['judul']),
                      subtitle: Text('${t['kategori']} • ${DateFormat('dd MMM yyyy').format(t['tanggal'])}'),
                      trailing: Text(formatRupiah(t['jumlah']), style: TextStyle(color: isPemasukan ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                      onLongPress: () => _hapusTransaksi(index),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildHistory() {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat'), backgroundColor: Colors.transparent, elevation: 0),
      body: _transactions.isEmpty
          ? const Center(child: Text('Belum ada transaksi'))
          : ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final t = _transactions[index];
                final isPemasukan = t['tipe'] == 'pemasukan';
                return Card(
                  child: ListTile(
                    leading: Icon(isPemasukan ? Icons.arrow_upward : Icons.arrow_downward, color: isPemasukan ? Colors.green : Colors.red),
                    title: Text(t['judul']),
                    subtitle: Text('${t['kategori']} • ${DateFormat('dd MMM yyyy').format(t['tanggal'])}'),
                    trailing: Text(formatRupiah(t['jumlah']), style: TextStyle(color: isPemasukan ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                    onLongPress: () => _hapusTransaksi(index),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAnalytics() {
    return Scaffold(
      appBar: AppBar(title: const Text('Analisis'), backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoCard('Total Pemasukan', formatRupiah(totalPemasukan), Colors.green),
            const SizedBox(height: 12),
            _infoCard('Total Pengeluaran', formatRupiah(totalPengeluaran), Colors.red),
            const SizedBox(height: 12),
            _infoCard('Saldo', formatRupiah(saldo), Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildBudget() {
    final target = totalPemasukan * 0.5;
    final persen = target > 0 ? (totalPengeluaran / target).clamp(0.0, 1.0) : 0.0;
    return Scaffold(
      appBar: AppBar(title: const Text('Budget'), backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet, size: 80, color: Colors.grey),
              const SizedBox(height: 10),
              const Text('Budget Bulanan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('Target: ${formatRupiah(target)}'),
                      const SizedBox(height: 8),
                      Text('Terpakai: ${formatRupiah(totalPengeluaran)}'),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: persen),
                      const SizedBox(height: 8),
                      Text('${(persen * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfile() {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil'), backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 10),
            const Text('Pengguna FinTrack', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('user@fintrack.com'),
            const SizedBox(height: 20),
            _infoRow('Total Transaksi', '${_transactions.length}'),
            _infoRow('Total Pemasukan', formatRupiah(totalPemasukan)),
            _infoRow('Total Pengeluaran', formatRupiah(totalPengeluaran)),
            _infoRow('Saldo', formatRupiah(saldo)),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title), Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color))]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]),
    );
  }

  void _showAddDialog() {
    const List<String> pemasukan = ['Gaji', 'Bisnis', 'Investasi', 'Hadiah', 'Lainnya'];
    const List<String> pengeluaran = ['Makanan', 'Transportasi', 'Hiburan', 'Pendidikan', 'Kesehatan', 'Belanja', 'Tagihan', 'Lainnya'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tambah Transaksi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: ElevatedButton(onPressed: () => _showForm('pemasukan', pemasukan), child: const Text('Pemasukan'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: () => _showForm('pengeluaran', pengeluaran), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Pengeluaran'))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showForm(String tipe, List<String> kategoriList) {
    final judulCtrl = TextEditingController();
    final jumlahCtrl = TextEditingController();
    String selectedKategori = kategoriList[0];
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottom) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Tambah $tipe', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(controller: judulCtrl, decoration: const InputDecoration(labelText: 'Judul', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(controller: jumlahCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedKategori,
                    decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                    items: kategoriList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setStateBottom(() => selectedKategori = v!),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setStateBottom(() => selectedDate = date);
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (judulCtrl.text.isNotEmpty && jumlahCtrl.text.isNotEmpty) {
                        _tambahTransaksi(tipe, judulCtrl.text, double.parse(jumlahCtrl.text), selectedKategori, selectedDate);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$tipe berhasil ditambahkan'), backgroundColor: tipe == 'pemasukan' ? Colors.green : Colors.red),
                        );
                      }
                    },
                    child: const Text('Simpan'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }
}