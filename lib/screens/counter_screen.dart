import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database_helper.dart';
import '../models/beer_type.dart';
import '../models/consumption.dart';
import '../theme/app_theme.dart';
import '../widgets/beer_counter_card.dart';
import '../widgets/total_consumptions_card.dart';
import '../widgets/price_dialog.dart';

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<BeerType> _beerTypes = [];
  Map<int, int> _consumptionCounts = {};

  bool _isLoading = true;
  String? _errorMessage;

  // Emojis asociados a los identificadores de las bebidas.
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
    _loadData();
  }

  /// Carga los tipos de bebida y las cantidades desde SQLite.
  Future<void> _loadData() async {
    try {
      final beerTypes = await _databaseHelper.getBeerTypes();
      final counts = await _databaseHelper.getConsumptionCounts();

      if (!mounted) return;

      setState(() {
        _beerTypes = beerTypes;
        _consumptionCounts = counts;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'No se han podido cargar los datos: $e';
      });
    }
  }

  /// Calcula el total de consumiciones.
  int get _totalConsumptions {
    return _consumptionCounts.values.fold<int>(
      0,
      (total, count) => total + count,
    );
  }

  Future<Map<String, dynamic>?> _showPriceDialog(BeerType beerType) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => PriceDialog(beerType: beerType),
    );
  }

  /// Registra una nueva consumición en SQLite.
  Future<void> _incrementBeer(BeerType beerType) async {
    try {
      final trackingEnabled = await _databaseHelper
          .getEconomicTrackingEnabled();

      if (!mounted) return;

      int? priceCents;

      if (trackingEnabled) {
        final result = await _showPriceDialog(beerType);

        if (!mounted || result == null) return;
        if (result['confirmed'] != true) return;

        priceCents = result['priceCents'] as int?;
      }

      final consumption = Consumption(
        beerTypeId: beerType.id,
        dateTime: DateTime.now(),
        priceCents: priceCents,
      );

      await _databaseHelper.insertConsumption(consumption);

      if (!mounted) return;

      setState(() {
        _consumptionCounts[beerType.id] =
            (_consumptionCounts[beerType.id] ?? 0) + 1;
      });
    } catch (e) {
      if (!mounted) return;

      _showError('No se ha podido registrar la consumición: $e');
    }
  }

  /// Elimina la última consumición de una categoría.
  Future<void> _decrementBeer(BeerType beerType) async {
    final currentCount = _consumptionCounts[beerType.id] ?? 0;

    if (currentCount <= 0) return;

    try {
      final deleted = await _databaseHelper.deleteLatestConsumption(
        beerType.id,
      );

      if (!mounted) return;

      if (deleted) {
        setState(() {
          _consumptionCounts[beerType.id] = currentCount - 1;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showError('No se ha podido eliminar la consumición.');
    }
  }

  /// Muestra un mensaje de error.
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadData();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Presentación.
            Text(
              '¡A contar consumiciones! 🍻',
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 8),

            const Text(
              'Tu recuento de bebidas',
              style: TextStyle(color: AppTheme.textSecondary),
            ),

            const SizedBox(height: 24),

            // Total de consumiciones.
            TotalConsumptionsCard(total: _totalConsumptions),

            const SizedBox(height: 30),

            // Categorías.
            Text(
              'Mis consumiciones',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 14),

            // Tarjetas de bebidas cargadas desde SQLite.
            ..._beerTypes.map((beerType) {
              final count = _consumptionCounts[beerType.id] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: BeerCounterCard(
                  name: beerType.name,
                  description: '${beerType.volumeMl} ml',
                  emoji: _beerEmojis[beerType.id] ?? '🍺',
                  count: count,
                  onIncrement: () => _incrementBeer(beerType),
                  onDecrement: () => _decrementBeer(beerType),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
