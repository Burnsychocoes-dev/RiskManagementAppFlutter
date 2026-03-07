import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog to add a new wallet. Collects name, max risk, and currency symbol.
class AddWalletDialog extends StatefulWidget {
  final void Function(String name, String maxRisk, String currency) onAdd;
  final VoidCallback onDismiss;

  const AddWalletDialog({
    super.key,
    required this.onAdd,
    required this.onDismiss,
  });

  @override
  State<AddWalletDialog> createState() => _AddWalletDialogState();
}

class _AddWalletDialogState extends State<AddWalletDialog> {
  final _nameCtrl = TextEditingController();
  final _maxRiskCtrl = TextEditingController(text: '0.00');
  final _currencyCtrl = TextEditingController(text: '\$');
  String? _maxRiskError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _maxRiskCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  void _validate(String v) {
    setState(() {
      _maxRiskError = double.tryParse(v) == null ? 'Invalid number' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Wallet'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Wallet name'),
          ),
          TextField(
            controller: _maxRiskCtrl,
            decoration: InputDecoration(
              labelText: 'Max allowed risk (fiat)',
              errorText: _maxRiskError,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _validate,
          ),
          TextField(
            controller: _currencyCtrl,
            decoration: const InputDecoration(labelText: 'Currency symbol'),
            inputFormatters: [LengthLimitingTextInputFormatter(3)],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: widget.onDismiss, child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _maxRiskError == null && _nameCtrl.text.isNotEmpty
              ? () => widget.onAdd(
                  _nameCtrl.text.trim(),
                  _maxRiskCtrl.text.trim(),
                  _currencyCtrl.text.trim().isEmpty
                      ? '\$'
                      : _currencyCtrl.text.trim(),
                )
              : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
