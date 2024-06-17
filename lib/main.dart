import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:csv/csv.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<SalesData> _waterChartData = [];
  List<SalesData> _sanitizationChartData = [];
  List<String> _countries = [];
  String? _selectedCountry;
  String _selectedSanitizationType = 'Total';
  late TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    super.initState();
    _loadCountries();
    _tooltipBehavior = TooltipBehavior(enable: true);
  }

  Future<void> _loadCountries() async {
    final waterData = await rootBundle.loadString('assets/água.csv');
    final sanitizationData =
        await rootBundle.loadString('assets/sanitização.csv');

    List<List<dynamic>> waterCsvTable =
        const CsvToListConverter().convert(waterData);
    List<List<dynamic>> sanitizationCsvTable =
        const CsvToListConverter().convert(sanitizationData);

    Set<String> countriesSet = {};
    for (var row in waterCsvTable) {
      if (row[0] != 'Location') {
        countriesSet.add(row[0].toString());
      }
    }

    setState(() {
      _countries = countriesSet.toList();
      _selectedCountry = _countries.first;
    });

    _loadWaterData(_selectedCountry!);
    _loadSanitizationData(_selectedCountry!, _selectedSanitizationType);
  }

  Future<void> _loadWaterData(String country) async {
    final data = await rootBundle.loadString('assets/água.csv');
    List<List<dynamic>> csvTable = const CsvToListConverter().convert(data);

    List<SalesData> chartData = [];
    for (var row in csvTable) {
      if (row[0] == country) {
        final value = row[3].toString();
        if (double.tryParse(value) != null) {
          chartData.add(
            SalesData(
              row[1].toString(),
              double.parse(value),
            ),
          );
        }
      }
    }
    chartData.sort((a, b) => int.parse(a.year).compareTo(int.parse(b.year)));

    setState(() {
      _waterChartData = chartData;
    });
  }

  Future<void> _loadSanitizationData(String country, String type) async {
    final data = await rootBundle.loadString('assets/sanitização.csv');
    List<List<dynamic>> csvTable = const CsvToListConverter().convert(data);

    List<SalesData> chartData = [];
    for (var row in csvTable) {
      if (row[0] == country &&
          row[1] == 'Population using at least basic sanitation services (%)' &&
          row[3] == type) {
        final value = row[4].toString();
        if (double.tryParse(value) != null) {
          chartData.add(
            SalesData(
              row[2].toString(),
              double.parse(value),
            ),
          );
        }
      }
    }

    chartData.sort((a, b) => int.parse(a.year).compareTo(int.parse(b.year)));

    setState(() {
      _sanitizationChartData = chartData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AEP 2024'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Água Limpa e Saneamento',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 50, 0, 0),
                      child: SizedBox(
                        width: double.infinity,
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedCountry,
                          items: _countries
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCountry = newValue!;
                              _loadWaterData(_selectedCountry!);
                              _loadSanitizationData(
                                  _selectedCountry!, _selectedSanitizationType);
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Selecione o tipo de Sanitização:'),
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedSanitizationType,
                        items: ['Total', 'Urban', 'Rural']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedSanitizationType = newValue!;
                            _loadSanitizationData(
                                _selectedCountry!, _selectedSanitizationType);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Água (%)'),
              SfCartesianChart(
                tooltipBehavior: _tooltipBehavior,
                primaryXAxis: const CategoryAxis(),
                series: <LineSeries<SalesData, String>>[
                  LineSeries<SalesData, String>(
                    dataSource: _waterChartData,
                    xValueMapper: (SalesData sales, _) => sales.year,
                    yValueMapper: (SalesData sales, _) => sales.sales,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Sanitização em área $_selectedSanitizationType (%)'),
              SfCartesianChart(
                tooltipBehavior: _tooltipBehavior,
                primaryXAxis: const CategoryAxis(),
                series: <LineSeries<SalesData, String>>[
                  LineSeries<SalesData, String>(
                    dataSource: _sanitizationChartData,
                    xValueMapper: (SalesData sales, _) => sales.year,
                    yValueMapper: (SalesData sales, _) => sales.sales,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SalesData {
  SalesData(this.year, this.sales);
  final String year;
  final double sales;
}
