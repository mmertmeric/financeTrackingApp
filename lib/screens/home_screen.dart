import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../database/database_helper.dart';
import 'dart:math'; // Rastgele renk için

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedType = 'income';
  List<Map<String, dynamic>> _transactions = [];
  Map<String, Color> _titleColors = {}; // Her başlık için renkler

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final data = await _dbHelper.getTransactions();
    setState(() {
      _transactions = data;

      // Her başlığa farklı bir renk atıyoruz
      for (var transaction in _transactions) {
        final title = transaction['title']?.toString() ?? 'Bilinmeyen Başlık';
        if (!_titleColors.containsKey(title)) {
          _titleColors[title] = _generateRandomColor(); // Rastgele renk
        }
      }
    });
  }

  Future<void> _addTransaction() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) return;

    final transaction = {
      'title': _titleController.text,
      'amount': double.tryParse(_amountController.text) ?? 0.0,
      'type': _selectedType,
      'date': DateTime.now().toIso8601String(),
    };

    await _dbHelper.insertTransaction(transaction);
    _titleController.clear();
    _amountController.clear();

    setState(() {
      final title = transaction['title']?.toString() ?? 'Bilinmeyen Başlık';
      if (!_titleColors.containsKey(title)) {
        _titleColors[title] = _generateRandomColor(); // Yeni başlığa renk ata
      }
      _selectedType = 'income';
    });

    _fetchTransactions();
  }

  Color _generateRandomColor() {
    // Daha çeşitli renkler üretmek için rastgele renk oluşturuyoruz
    final random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  List<Map<String, dynamic>> _generateChartData() {
    Map<String, double> groupedData = {};
    double totalAmount = 0.0;

    for (var transaction in _transactions) {
      final title = transaction['title']?.toString() ?? 'Bilinmeyen Başlık';
      final amount = transaction['amount'];
      groupedData[title] = (groupedData[title] ?? 0.0) + amount;
      totalAmount += amount;
    }

    return groupedData.entries
        .map((entry) => {
              'title': entry.key,
              'value': entry.value,
              'percentage': totalAmount > 0
                  ? ((entry.value / totalAmount) * 100).toStringAsFixed(1) + '%'
                  : '0%',
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _generateChartData();

    return Scaffold(
      appBar: AppBar(
        title: Text('Finans Takip'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 200,
            child: SfCircularChart(
              series: <CircularSeries>[
                PieSeries<Map<String, dynamic>, String>(
                  dataSource: chartData,
                  xValueMapper: (data, _) => data['title'], // Başlık
                  yValueMapper: (data, _) => data['value'], // Değer
                  pointColorMapper: (data, _) => _titleColors[data['title']], // Başlığa özel renk
                  dataLabelMapper: (data, _) =>
                      '${data['title']}: ${data['percentage']}', // Yüzdelik gösterim
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                return ListTile(
                  title: Text(transaction['title']),
                  subtitle: Text(transaction['date']),
                  trailing: Text(
                    '${transaction['type'] == 'income' ? '+' : '-'} ${transaction['amount'].toStringAsFixed(2)}',
                    style: TextStyle(
                      color: transaction['type'] == 'income'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Başlık'),
                ),
                TextField(
                  controller: _amountController,
                  decoration: InputDecoration(labelText: 'Miktar'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButton<String>(
                  value: _selectedType,
                  items: [
                    DropdownMenuItem(value: 'income', child: Text('Gelir')),
                    DropdownMenuItem(value: 'expense', child: Text('Gider')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                ),
                ElevatedButton(
                  onPressed: _addTransaction,
                  child: Text('Ekle'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
