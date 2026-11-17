import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/beer_type.dart';
import '../models/consumption.dart';
import '../theme/app_theme.dart';

enum HistoryPeriod { all, day, week, month, year, custom }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<BeerType> _beerTypes = [];
  List<Consumption> _consumptions = [];

  final Set<int> _selectedBeerTypes = {};

  HistoryPeriod _period = HistoryPeriod.all;

  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _customRange;

  bool _isLoading = true;
  String? _errorMessage;

  static const Map<int, String> _beerEmojis = {
    1: '🍺',
    2: '🍾',
    3: '🍻',
    4: '🍺',
    5: '🍺',
    6: '🍹',
  };

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// Carga las categorías y los movimientos de SQLite.
  Future<void> _loadHistory() async {
    try {
      final types = await _databaseHelper.getBeerTypes();
      final movements = await _databaseHelper.getAllConsumptions();

      if (!mounted) return;

      setState(() {
        _beerTypes = types;
        _consumptions = movements;
        _selectedBeerTypes
          ..clear()
          ..addAll(types.map((type) => type.id));
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'No se ha podido cargar el historial.';
      });
    }
  }

  /// Actualiza el historial después de una modificación.
  Future<void> _refreshHistory() async {
    final movements = await _databaseHelper.getAllConsumptions();

    if (!mounted) return;

    setState(() {
      _consumptions = movements;
    });
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Calcula los límites del periodo seleccionado.
  DateTime? get _rangeStart {
    switch (_period) {
      case HistoryPeriod.all:
        return null;
      case HistoryPeriod.day:
        return _startOfDay(_selectedDate);
      case HistoryPeriod.week:
        final date = _startOfDay(_selectedDate);
        return date.subtract(Duration(days: date.weekday - 1));
      case HistoryPeriod.month:
        return DateTime(_selectedDate.year, _selectedDate.month);
      case HistoryPeriod.year:
        return DateTime(_selectedDate.year);
      case HistoryPeriod.custom:
        return _customRange == null ? null : _startOfDay(_customRange!.start);
    }
  }

  DateTime? get _rangeEnd {
    switch (_period) {
      case HistoryPeriod.all:
        return null;
      case HistoryPeriod.day:
        return _endOfDay(_selectedDate);
      case HistoryPeriod.week:
        final start = _rangeStart!;
        return start
            .add(const Duration(days: 7))
            .subtract(const Duration(milliseconds: 1));
      case HistoryPeriod.month:
        return DateTime(
          _selectedDate.year,
          _selectedDate.month + 1,
        ).subtract(const Duration(milliseconds: 1));
      case HistoryPeriod.year:
        return DateTime(_selectedDate.year + 1)
            .subtract(const Duration(milliseconds: 1));
      case HistoryPeriod.custom:
        return _customRange == null ? null : _endOfDay(_customRange!.end);
    }
  }

  /// Aplica los filtros de fecha y tipo de bebida.
  List<Consumption> get _filteredConsumptions {
    final start = _rangeStart;
    final end = _rangeEnd;

    return _consumptions.where((consumption) {
      if (!_selectedBeerTypes.contains(consumption.beerTypeId)) {
        return false;
      }

      if (start != null && consumption.dateTime.isBefore(start)) {
        return false;
      }

      if (end != null && consumption.dateTime.isAfter(end)) {
        return false;
      }

      return true;
    }).toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  /// Calcula el volumen total de las consumiciones filtradas, en ml.
  int get _totalVolumeMl {
    final volumesByType = {
      for (final type in _beerTypes) type.id: type.volumeMl,
    };

    return _filteredConsumptions.fold<int>(0, (total, consumption) {
      return total + (volumesByType[consumption.beerTypeId] ?? 0);
    });
  }

  /// Convierte el volumen total a litros.
  double get _totalVolumeLiters {
    return _totalVolumeMl / 1000;
  }

  /// Agrupa los movimientos por día.
  Map<DateTime, List<Consumption>> get _groupedConsumptions {
    final groups = <DateTime, List<Consumption>>{};

    for (final consumption in _filteredConsumptions) {
      final day = _startOfDay(consumption.dateTime);
      groups.putIfAbsent(day, () => []).add(consumption);
    }

    return groups;
  }

  String _formatDate(DateTime date) {
    const weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${weekdays[date.weekday - 1]}, '
        '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatPrice(int? priceCents) {
    if (priceCents == null) return 'Sin precio';

    return '${(priceCents / 100).toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  String _periodLabel() {
    switch (_period) {
      case HistoryPeriod.all:
        return 'Todos los movimientos';
      case HistoryPeriod.day:
        return _formatDate(_selectedDate);
      case HistoryPeriod.week:
        final start = _rangeStart!;
        final end = _rangeEnd!;
        return '${start.day}/${start.month}/${start.year} - '
            '${end.day}/${end.month}/${end.year}';
      case HistoryPeriod.month:
        return '${_selectedDate.month.toString().padLeft(2, '0')}/'
            '${_selectedDate.year}';
      case HistoryPeriod.year:
        return '${_selectedDate.year}';
      case HistoryPeriod.custom:
        if (_customRange == null) return 'Selecciona fechas';
        return '${_customRange!.start.day}/${_customRange!.start.month}/${_customRange!.start.year}'
            ' - ${_customRange!.end.day}/${_customRange!.end.month}/${_customRange!.end.year}';
    }
  }

  Future<void> _selectReferenceDate() async {
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
      _period = HistoryPeriod.custom;
    });
  }

  /// Abre el diálogo de edición de un movimiento.
  Future<void> _editConsumption(Consumption consumption) async {
    final beerType = _beerTypes.firstWhere(
      (type) => type.id == consumption.beerTypeId,
    );

    final result = await showDialog<Consumption>(
      context: context,
      builder: (context) => _EditConsumptionDialog(
        consumption: consumption,
        beerTypes: _beerTypes,
      ),
    );

    if (result == null) return;

    try {
      await _databaseHelper.updateConsumption(result);
      await _refreshHistory();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${beerType.name}: movimiento actualizado.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('No se ha podido actualizar el movimiento.');
    }
  }

  /// Elimina un movimiento después de confirmar.
  Future<void> _deleteConsumption(Consumption consumption) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar consumición'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este movimiento? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _databaseHelper.deleteConsumption(consumption.id!);
      await _refreshHistory();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consumición eliminada correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('No se ha podido eliminar el movimiento.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.danger),
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
                _loadHistory();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final groups = _groupedConsumptions;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Historial',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Consulta y administra tus consumiciones.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 22),

                // Selector de periodo.
                Text('Periodo', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                DropdownButtonFormField<HistoryPeriod>(
                  value: _period,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_month),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: HistoryPeriod.all,
                      child: Text('Todos'),
                    ),
                    DropdownMenuItem(
                      value: HistoryPeriod.day,
                      child: Text('Día'),
                    ),
                    DropdownMenuItem(
                      value: HistoryPeriod.week,
                      child: Text('Semana'),
                    ),
                    DropdownMenuItem(
                      value: HistoryPeriod.month,
                      child: Text('Mes'),
                    ),
                    DropdownMenuItem(
                      value: HistoryPeriod.year,
                      child: Text('Año'),
                    ),
                    DropdownMenuItem(
                      value: HistoryPeriod.custom,
                      child: Text('Periodo personalizado'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _period = value;
                    });

                    if (value == HistoryPeriod.custom) {
                      _selectCustomRange();
                    }
                  },
                ),

                if (_period != HistoryPeriod.all) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _period == HistoryPeriod.custom
                        ? _selectCustomRange
                        : _selectReferenceDate,
                    icon: const Icon(Icons.edit_calendar),
                    label: Text(_periodLabel()),
                  ),
                ],

                const SizedBox(height: 24),

                // Filtro por tipos.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tipos de bebida',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedBeerTypes.length == _beerTypes.length) {
                            _selectedBeerTypes.clear();
                          } else {
                            _selectedBeerTypes
                              ..clear()
                              ..addAll(_beerTypes.map((type) => type.id));
                          }
                        });
                      },
                      child: Text(
                        _selectedBeerTypes.length == _beerTypes.length
                            ? 'Ninguno'
                            : 'Todos',
                      ),
                    ),
                  ],
                ),

                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _beerTypes.map((type) {
                    final selected = _selectedBeerTypes.contains(type.id);

                    return FilterChip(
                      label: Text(type.name),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _selectedBeerTypes.add(type.id);
                          } else {
                            _selectedBeerTypes.remove(type.id);
                          }
                        });
                      },
                      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.primary,
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.water_drop,
                            color: AppTheme.primary,
                            size: 30,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Volumen total consumido',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                '${_totalVolumeLiters.toStringAsFixed(2).replaceAll('.', ',')} L',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),

                              const SizedBox(height: 3),

                              Text(
                                '$_totalVolumeMl ml en total',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Resumen de resultados.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Movimientos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${_filteredConsumptions.length} registros',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (groups.isEmpty)
                  _buildEmptyState()
                else
                  ...groups.entries.map((entry) {
                    return _buildDayGroup(entry.key, entry.value);
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.history, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 14),
            Text(
              'No hay consumiciones',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Prueba a modificar los filtros o registra una nueva bebida.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayGroup(DateTime day, List<Consumption> movements) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 8),
          child: Text(
            _formatDate(day),
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: AppTheme.primary),
          ),
        ),
        ...movements.map(_buildMovementCard),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildMovementCard(Consumption consumption) {
    final beerType = _beerTypes.firstWhere(
      (type) => type.id == consumption.beerTypeId,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: AppTheme.surfaceHighlight,
          child: Text(
            _beerEmojis[beerType.id] ?? '🍺',
            style: const TextStyle(fontSize: 21),
          ),
        ),
        title: Text(beerType.name),
        subtitle: Text(
          '${beerType.volumeMl} ml · ${_formatTime(consumption.dateTime)}',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatPrice(consumption.priceCents),
              style: TextStyle(
                color: consumption.priceCents == null
                    ? AppTheme.textSecondary
                    : AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editConsumption(consumption);
                } else if (value == 'delete') {
                  _deleteConsumption(consumption);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 10),
                      Text('Editar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline),
                      SizedBox(width: 10),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para modificar una consumición existente.
class _EditConsumptionDialog extends StatefulWidget {
  final Consumption consumption;
  final List<BeerType> beerTypes;

  const _EditConsumptionDialog({
    required this.consumption,
    required this.beerTypes,
  });

  @override
  State<_EditConsumptionDialog> createState() => _EditConsumptionDialogState();
}

class _EditConsumptionDialogState extends State<_EditConsumptionDialog> {
  late int _beerTypeId;
  late DateTime _dateTime;

  late final TextEditingController _priceController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _beerTypeId = widget.consumption.beerTypeId;
    _dateTime = widget.consumption.dateTime;

    _priceController = TextEditingController(
      text: widget.consumption.priceCents == null
          ? ''
          : (widget.consumption.priceCents! / 100)
                .toStringAsFixed(2)
                .replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  String? _validatePrice(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    final normalized = text.replaceAll(',', '.');
    final price = double.tryParse(normalized);

    if (price == null || !price.isFinite || price < 0) {
      return 'Introduce un precio válido.';
    }

    if (normalized.split('.').length > 2 ||
        (normalized.contains('.') && normalized.split('.').last.length > 2)) {
      return 'Máximo dos decimales.';
    }

    return null;
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    setState(() {
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        _dateTime.hour,
        _dateTime.minute,
      );
    });
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );

    if (time == null || !mounted) return;

    setState(() {
      _dateTime = DateTime(
        _dateTime.year,
        _dateTime.month,
        _dateTime.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final text = _priceController.text.trim();
    final normalized = text.replaceAll(',', '.');

    final priceCents = text.isEmpty
        ? null
        : (double.parse(normalized) * 100).round();

    Navigator.of(context).pop(
      Consumption(
        id: widget.consumption.id,
        beerTypeId: _beerTypeId,
        dateTime: _dateTime,
        priceCents: priceCents,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar consumición'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                value: _beerTypeId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Tipo de bebida'),
                items: widget.beerTypes.map((type) {
                  return DropdownMenuItem(
                    value: type.id,
                    child: Text('${type.name} (${type.volumeMl} ml)'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _beerTypeId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  '${_dateTime.day.toString().padLeft(2, '0')}/'
                  '${_dateTime.month.toString().padLeft(2, '0')}/'
                  '${_dateTime.year}',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _selectTime,
                icon: const Icon(Icons.access_time),
                label: Text(
                  '${_dateTime.hour.toString().padLeft(2, '0')}:'
                  '${_dateTime.minute.toString().padLeft(2, '0')}',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Precio (€)',
                  hintText: 'Ej. 2,30',
                  prefixIcon: Icon(Icons.euro),
                ),
                validator: _validatePrice,
              ),
              const SizedBox(height: 6),
              const Text(
                'Deja el precio vacío si no deseas registrar un importe.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Guardar cambios')),
      ],
    );
  }
}
