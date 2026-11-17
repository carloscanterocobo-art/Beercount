import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/beer_type.dart';

class PriceDialog extends StatefulWidget {
  final BeerType beerType;

  const PriceDialog({super.key, required this.beerType});

  @override
  State<PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<PriceDialog> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _getPriceCents() {
    final text = _controller.text.trim();

    if (text.isEmpty) return null;

    final normalized = text.replaceAll(',', '.');
    final price = double.parse(normalized);

    return (price * 100).round();
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
      return 'Utiliza como máximo dos decimales.';
    }

    return null;
  }

  void _confirm({required bool withoutPrice}) {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop<Map<String, dynamic>>({
      'confirmed': true,
      'priceCents': withoutPrice ? null : _getPriceCents(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar consumición'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.beerType.name} · ${widget.beerType.volumeMl} ml'),
            const SizedBox(height: 20),
            const Text('Precio de la consumición (€)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              decoration: const InputDecoration(
                hintText: 'Ej. 2,30',
                prefixIcon: Icon(Icons.euro),
                border: OutlineInputBorder(),
              ),
              validator: _validatePrice,
            ),
            const SizedBox(height: 8),
            const Text(
              'Puedes dejar el precio vacío si no lo conoces.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => _confirm(withoutPrice: true),
          child: const Text('Sin precio'),
        ),
        ElevatedButton(
          onPressed: () => _confirm(withoutPrice: false),
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}
