import 'package:flutter/material.dart';

/// Dialog to reduce a specific sub-position by units or percentage.
/// Mirrors the Kotlin ReduceSubpositionDialog.
class ReduceSubpositionDialog extends StatefulWidget {
  final double currentSizeInAsset;
  final VoidCallback onDismiss;
  final void Function(String units, String percent) onReduce;

  const ReduceSubpositionDialog({
    super.key,
    required this.currentSizeInAsset,
    required this.onDismiss,
    required this.onReduce,
  });

  @override
  State<ReduceSubpositionDialog> createState() =>
      _ReduceSubpositionDialogState();
}

class _ReduceSubpositionDialogState extends State<ReduceSubpositionDialog> {
  final _unitsCtrl = TextEditingController();
  final _pctCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _unitsCtrl.dispose();
    _pctCtrl.dispose();
    super.dispose();
  }

  double? _parse(String s) => s.isEmpty ? null : double.tryParse(s);

  void _validate(String units, String pct) {
    final u = _parse(units);
    final p = _parse(pct);
    setState(() {
      if (units.isEmpty && pct.isEmpty) {
        _error = 'Enter units or percent';
      } else if (units.isNotEmpty && u == null) {
        _error = 'Invalid units';
      } else if (units.isNotEmpty && u != null && u <= 0) {
        _error = 'Units must be > 0';
      } else if (units.isNotEmpty &&
          u != null &&
          u > widget.currentSizeInAsset) {
        _error = 'Exceeds current size (${widget.currentSizeInAsset})';
      } else if (pct.isNotEmpty && p == null) {
        _error = 'Invalid percent';
      } else if (pct.isNotEmpty && p != null && (p <= 0 || p > 100)) {
        _error = 'Percent must be 0..100';
      } else {
        _error = null;
      }
    });
  }

  void _onUnitsChanged(String v) {
    final u = _parse(v);
    if (u != null && widget.currentSizeInAsset > 0) {
      final derived = (u / widget.currentSizeInAsset * 100);
      _pctCtrl.text = derived.toStringAsFixed(2);
    } else if (v.isEmpty) {
      _pctCtrl.text = '';
    }
    _validate(v, _pctCtrl.text);
  }

  void _onPctChanged(String v) {
    final p = _parse(v);
    if (p != null) {
      final derived = p / 100.0 * widget.currentSizeInAsset;
      _unitsCtrl.text = derived.toStringAsFixed(8);
    } else if (v.isEmpty) {
      _unitsCtrl.text = '';
    }
    _validate(_unitsCtrl.text, v);
  }

  bool get _canConfirm =>
      _error == null &&
      (_unitsCtrl.text.isNotEmpty || _pctCtrl.text.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reduce Subposition'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Current size: ${widget.currentSizeInAsset} units',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _unitsCtrl,
            decoration: const InputDecoration(
              labelText: 'Units to remove (asset)',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _onUnitsChanged,
          ),
          TextField(
            controller: _pctCtrl,
            decoration: const InputDecoration(
              labelText: 'Percent to remove (0-100)',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _onPctChanged,
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: widget.onDismiss, child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _canConfirm
              ? () => widget.onReduce(_unitsCtrl.text, _pctCtrl.text)
              : null,
          child: const Text('Reduce'),
        ),
      ],
    );
  }
}
