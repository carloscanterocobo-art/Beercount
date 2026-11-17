import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  bool _economicTrackingEnabled = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Recupera las preferencias guardadas en SQLite.
  Future<void> _loadSettings() async {
    try {
      final enabled = await _databaseHelper.getEconomicTrackingEnabled();

      if (!mounted) return;

      setState(() {
        _economicTrackingEnabled = enabled;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('No se ha podido cargar la configuración.', isError: true);
    }
  }

  /// Actualiza y guarda el seguimiento económico.
  Future<void> _updateEconomicTracking(bool enabled) async {
    if (_isSaving) return;

    final previousValue = _economicTrackingEnabled;

    setState(() {
      _economicTrackingEnabled = enabled;
      _isSaving = true;
    });

    try {
      await _databaseHelper.setEconomicTrackingEnabled(enabled);

      if (!mounted) return;

      _showMessage(
        enabled
            ? 'Seguimiento económico activado.'
            : 'Seguimiento económico desactivado.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _economicTrackingEnabled = previousValue;
      });

      _showMessage('No se ha podido guardar la configuración.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Muestra un mensaje informativo.
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Encabezado.
          Text(
            'Configuración',
            style: Theme.of(context).textTheme.headlineMedium,
          ),

          const SizedBox(height: 8),

          const Text(
            'Personaliza el funcionamiento de Beercount.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),

          const SizedBox(height: 28),

          // Apartado económico.
          Text(
            'Seguimiento económico',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 14),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.euro,
                          color: AppTheme.primary,
                          size: 26,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Control de gastos',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),

                            const SizedBox(height: 4),

                            const Text(
                              'Registra el precio de cada consumición.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 28),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Activar seguimiento económico'),
                    subtitle: Text(
                      _economicTrackingEnabled
                          ? 'Se solicitará el precio al añadir una bebida.'
                          : 'Las consumiciones se registrarán sin precio.',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    value: _economicTrackingEnabled,
                    activeThumbColor: AppTheme.primary,
                    onChanged: _isSaving ? null : _updateEconomicTracking,
                  ),

                  if (_isSaving) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Información de la aplicación.
          Text('Aplicación', style: Theme.of(context).textTheme.titleLarge),

          const SizedBox(height: 14),

          Card(
            child: ListTile(
              leading: const Icon(Icons.local_bar, color: AppTheme.primary),
              title: const Text('Beercount'),
              subtitle: const Text(
                'COUNT YOUR BEERS.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              trailing: const Text(
                'v1.0.0',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
