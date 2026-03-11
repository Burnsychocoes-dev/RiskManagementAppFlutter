import 'package:flutter/material.dart';

/// Dialog to reduce ALL subpositions of a position by the same percentage.
class ReducePositionDialog extends StatefulWidget {
  final VoidCallback onDismiss;
  final void Function(double percent) onReduce;

  const ReducePositionDialog({
    super.key,
    required this.onDismiss,
    required this.onReduce,
  });

  @override
  State<ReducePositionDialog> createState() => _ReducePositionDialogState();
}

class _ReducePositionDialogState extends State<ReducePositionDialog> {
  final _pctCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pctCtrl.dispose();
    super.dispose();
  }

  void _validate(String v) {
    final p = double.tryParse(v);
    setState(() {
      if (v.isEmpty) {
        _error = 'Required';
      } else if (p == null) {
        _error = 'Invalid number';
      } else if (p <= 0 || p > 100) {
        _error = 'Percent must be between 0 and 100';
      } else {
        _error = null;
      }
    });
  }

  bool get _canConfirm => _error == null && _pctCtrl.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reduce Position'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This percentage will be reduced equally across all subpositions.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pctCtrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Percent to remove (0–100)',
              suffixText: '%',
              errorText: _error,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _validate,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: widget.onDismiss, child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _canConfirm
              ? () => widget.onReduce(double.parse(_pctCtrl.text))
              : null,
          child: const Text('Reduce'),
        ),
      ],
    );
  }
}
