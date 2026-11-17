import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/beer_type.dart';
import '../models/consumption.dart';
import '../theme/app_theme.dart';

enum EconomyPeriod { all, day, week, month, year, custom }

class EconomyScreen extends StatefulWidget {
  const EconomyScreen({super.key});

  @override
  State<EconomyScreen> createState() => _EconomyScreenState();
}

class _EconomyScreenState extends State<EconomyScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<BeerType> _beerTypes = [];
  List<Consumption> _consumptions = [];

  EconomyPeriod _period = EconomyPeriod.all;
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _customRange;

  bool _isLoading = true;
  bool _trackingEnabled = false;
  String? _errorMessage;

  static const List<Color> _chartColors = [
    Color(0xFFE9A83B),
    Color(0xFF56B88A),
    Color(0xFF5B9BD5),
    Color(0xFFE56868),
    Color(0xFF9B82CF),
    Color(0xFF55B9B2),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Carga los movimientos, los tipos de bebida y la configuración.
  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _databaseHelper.getBeerTypes(),
        _databaseHelper.getAllConsumptions(),
        _databaseHelper.getEconomicTrackingEnabled(),
      ]);

      if (!mounted) return;

      setState(() {
        _beerTypes = results[0] as List<BeerType>;
        _consumptions = results[1] as List<Consumption>;
        _trackingEnabled = results[2] as bool;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'No se han podido cargar las estadísticas.';
      });
    }
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  DateTime? get _rangeStart {
    switch (_period) {
      case EconomyPeriod.all:
        return null;
      case EconomyPeriod.day:
        return _startOfDay(_selectedDate);
      case EconomyPeriod.week:
        final date = _startOfDay(_selectedDate);
        return date.subtract(Duration(days: date.weekday - 1));
      case EconomyPeriod.month:
        return DateTime(_selectedDate.year, _selectedDate.month);
      case EconomyPeriod.year:
        return DateTime(_selectedDate.year);
      case EconomyPeriod.custom:
        return _customRange == null ? null : _startOfDay(_customRange!.start);
    }
  }

  DateTime? get _rangeEnd {
    switch (_period) {
      case EconomyPeriod.all:
        return null;
      case EconomyPeriod.day:
        return _endOfDay(_selectedDate);
      case EconomyPeriod.week:
        return _rangeStart!
            .add(const Duration(days: 7))
            .subtract(const Duration(milliseconds: 1));
      case EconomyPeriod.month:
        return DateTime(
          _selectedDate.year,
          _selectedDate.month + 1,
        ).subtract(const Duration(milliseconds: 1));
      case EconomyPeriod.year:
        return DateTime(_selectedDate.year + 1)
            .subtract(const Duration(milliseconds: 1));
      case EconomyPeriod.custom:
        return _customRange == null ? null : _endOfDay(_customRange!.end);
    }
  }

  /// Devuelve las consumiciones incluidas en el periodo.
  List<Consumption> get _filteredConsumptions {
    final start = _rangeStart;
    final end = _rangeEnd;

    return _consumptions.where((consumption) {
      if (start != null && consumption.dateTime.isBefore(start)) {
        return false;
      }

      if (end != null && consumption.dateTime.isAfter(end)) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Suma los precios registrados, ignorando los precios nulos.
  int get _totalSpentCents {
    return _filteredConsumptions.fold<int>(
      0,
      (total, consumption) => total + (consumption.priceCents ?? 0),
    );
  }

  /// Calcula el gasto de cada tipo de bebida.
  Map<int, int> get _spendingByType {
    final result = <int, int>{for (final type in _beerTypes) type.id: 0};

    for (final consumption in _filteredConsumptions) {
      result[consumption.beerTypeId] =
          (result[consumption.beerTypeId] ?? 0) + (consumption.priceCents ?? 0);
    }

    return result;
  }

  String _formatMoney(int cents) {
    return '${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  String _periodLabel() {
    switch (_period) {
      case EconomyPeriod.all:
        return 'Todo el historial';
      case EconomyPeriod.day:
        return '${_selectedDate.day.toString().padLeft(2, '0')}/'
            '${_selectedDate.month.toString().padLeft(2, '0')}/'
            '${_selectedDate.year}';
      case EconomyPeriod.week:
        final start = _rangeStart!;
        final end = _rangeEnd!;
        return '${start.day}/${start.month} - '
            '${end.day}/${end.month}/${end.year}';
      case EconomyPeriod.month:
        return '${_selectedDate.month.toString().padLeft(2, '0')}/'
            '${_selectedDate.year}';
      case EconomyPeriod.year:
        return '${_selectedDate.year}';
      case EconomyPeriod.custom:
        if (_customRange == null) return 'Selecciona fechas';

        return '${_customRange!.start.day}/'
            '${_customRange!.start.month}/'
            '${_customRange!.start.year} - '
            '${_customRange!.end.day}/'
            '${_customRange!.end.month}/'
            '${_customRange!.end.year}';
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _selectCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customRange,
    );

    if (range == null || !mounted) return;

    setState(() {
      _customRange = range;
      _period = EconomyPeriod.custom;
    });
  }

  Future<void> _changePeriod(EconomyPeriod? period) async {
    if (period == null) return;

    setState(() {
      _period = period;
    });

    if (period == EconomyPeriod.custom) {
      await _selectCustomRange();
    }
  }

  Future<void> _refreshData() async {
    try {
      final movements = await _databaseHelper.getAllConsumptions();
      final enabled = await _databaseHelper.getEconomicTrackingEnabled();

      if (!mounted) return;

      setState(() {
        _consumptions = movements;
        _trackingEnabled = enabled;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('No se han podido actualizar las estadísticas.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.danger),
    );
  }

  /// Genera los datos del gráfico circular.
  List<PieChartSectionData> _buildPieSections() {
    final spending = _spendingByType;

    final total = spending.values.fold<int>(0, (sum, value) => sum + value);

    if (total == 0) return [];

    final sections = <PieChartSectionData>[];

    for (var i = 0; i < _beerTypes.length; i++) {
      final type = _beerTypes[i];
      final amount = spending[type.id] ?? 0;

      if (amount == 0) continue;

      final percentage = amount / total * 100;

      sections.add(
        PieChartSectionData(
          value: amount.toDouble(),
          color: _chartColors[i % _chartColors.length],
          radius: 65,
          title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      );
    }

    return sections;
  }

  /// Agrupa el gasto por intervalos para el gráfico de líneas.
  Map<DateTime, int> get _timelineData {
    final result = <DateTime, int>{};

    for (final consumption in _filteredConsumptions) {
      if (consumption.priceCents == null) continue;

      final date = consumption.dateTime;
      late DateTime key;

      if (_period == EconomyPeriod.day) {
        key = DateTime(date.year, date.month, date.day, date.hour);
      } else if (_period == EconomyPeriod.year ||
          (_period == EconomyPeriod.all && _rangeStart == null)) {
        key = DateTime(date.year, date.month);
      } else {
        key = DateTime(date.year, date.month, date.day);
      }

      result[key] = (result[key] ?? 0) + consumption.priceCents!;
    }

    return result;
  }

  String _timelineLabel(DateTime date) {
    if (_period == EconomyPeriod.day) {
      return '${date.hour.toString().padLeft(2, '0')}:00';
    }

    if (_period == EconomyPeriod.year || _period == EconomyPeriod.all) {
      const months = [
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic',
      ];

      return '${months[date.month - 1]} ${date.year}';
    }

    return '${date.day}/${date.month}';
  }

  Widget _buildPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Periodo', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        DropdownButtonFormField<EconomyPeriod>(
          value: _period,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_month),
          ),
          items: const [
            DropdownMenuItem(
              value: EconomyPeriod.all,
              child: Text('Todo el historial'),
            ),
            DropdownMenuItem(value: EconomyPeriod.day, child: Text('Día')),
            DropdownMenuItem(value: EconomyPeriod.week, child: Text('Semana')),
            DropdownMenuItem(value: EconomyPeriod.month, child: Text('Mes')),
            DropdownMenuItem(value: EconomyPeriod.year, child: Text('Año')),
            DropdownMenuItem(
              value: EconomyPeriod.custom,
              child: Text('Periodo personalizado'),
            ),
          ],
          onChanged: _changePeriod,
        ),
        if (_period != EconomyPeriod.all) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _period == EconomyPeriod.custom
                ? _selectCustomRange
                : _selectDate,
            icon: const Icon(Icons.edit_calendar),
            label: Text(_periodLabel()),
          ),
        ],
      ],
    );
  }

  Widget _buildTotalCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet, color: AppTheme.primary),
                SizedBox(width: 10),
                Text(
                  'Gasto total',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _formatMoney(_totalSpentCents),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _periodLabel(),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingBreakdown() {
    final spending = _spendingByType;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gasto por tipo de bebida',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            ...List.generate(_beerTypes.length, (index) {
              final type = _beerTypes[index];
              final amount = spending[type.id] ?? 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _chartColors[index % _chartColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(type.name),
                          Text(
                            '${type.volumeMl} ml',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatMoney(amount),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final sections = _buildPieSections();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribución del gasto',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 18),
            if (sections.isEmpty)
              const SizedBox(
                height: 180,
                child: Center(
                  child: Text(
                    'No hay gastos registrados para este periodo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              SizedBox(
                height: 210,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 42,
                    sectionsSpace: 3,
                    startDegreeOffset: -90,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    final entries = _timelineData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolución del gasto',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _period == EconomyPeriod.day
                  ? 'Gasto agrupado por horas'
                  : (_period == EconomyPeriod.year ||
                        _period == EconomyPeriod.all)
                  ? 'Gasto agrupado por meses'
                  : 'Gasto agrupado por días',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            if (entries.isEmpty)
              const SizedBox(
                height: 180,
                child: Center(
                  child: Text(
                    'No hay datos suficientes para mostrar la evolución.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt() / 100}€',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 38,
                          interval: entries.length > 6
                              ? (entries.length / 5).ceilToDouble()
                              : 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();

                            if (index < 0 || index >= entries.length) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _timelineLabel(entries[index].key),
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 9,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < entries.length; i++)
                            FlSpot(i.toDouble(), entries[i].value.toDouble()),
                        ],
                        isCurved: true,
                        color: AppTheme.primary,
                        barWidth: 3,
                        dotData: FlDotData(show: entries.length <= 20),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppTheme.primary.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 60,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 18),
                Text(
                  'Seguimiento económico desactivado',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Para consultar tus estadísticas económicas, '
                  'activa el seguimiento económico desde Configuración.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadData();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (!_trackingEnabled) {
      return _buildDisabledMessage();
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Estadísticas económicas',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Analiza tus gastos en consumiciones.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),

            _buildPeriodSelector(),
            const SizedBox(height: 22),

            _buildTotalCard(),
            const SizedBox(height: 18),

            _buildSpendingBreakdown(),
            const SizedBox(height: 18),

            _buildPieChart(),
            const SizedBox(height: 18),

            _buildLineChart(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
