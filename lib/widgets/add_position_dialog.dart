import 'package:flutter/material.dart';

/// Dialog to add a new position.
class AddPositionDialog extends StatefulWidget {
  final double? remainingAllowed;
  final String currency;
  final void Function(
    String ticker,
    String stop,
    String maxRisk,
    String target,
    String direction,
    String timeframe,
  )
  onAdd;
  final VoidCallback onDismiss;

  const AddPositionDialog({
    super.key,
    this.remainingAllowed,
    this.currency = '\$',
    required this.onAdd,
    required this.onDismiss,
  });

  @override
  State<AddPositionDialog> createState() => _AddPositionDialogState();
}

class _AddPositionDialogState extends State<AddPositionDialog> {
  final _tickerCtrl = TextEditingController();
  final _stopCtrl = TextEditingController();
  final _maxRiskCtrl = TextEditingController(text: '0.00');
  final _targetCtrl = TextEditingController();
  final _timeframeCtrl = TextEditingController();
  String _direction = 'LONG';
  String? _stopError;
  String? _maxRiskError;
  String? _targetError;
  String? _timeframeError;

  @override
  void dispose() {
    _tickerCtrl.dispose();
    _stopCtrl.dispose();
    _maxRiskCtrl.dispose();
    _targetCtrl.dispose();
    _timeframeCtrl.dispose();
    super.dispose();
  }

  bool get _canAdd =>
      _tickerCtrl.text.isNotEmpty &&
      _stopError == null &&
      _stopCtrl.text.isNotEmpty &&
      _maxRiskError == null &&
      _maxRiskCtrl.text.isNotEmpty &&
      _targetError == null &&
      _targetCtrl.text.isNotEmpty &&
      _timeframeError == null &&
      _timeframeCtrl.text.isNotEmpty;

  void _validateStop(String v) {
    setState(() {
      _stopError = v.isEmpty
          ? 'Required'
          : double.tryParse(v) == null
          ? 'Invalid number'
          : null;
    });
  }

  void _validateMaxRisk(String v) {
    final parsed = double.tryParse(v);
    setState(() {
      if (parsed == null) {
        _maxRiskError = v.isEmpty ? 'Required' : 'Invalid number';
      } else if (widget.remainingAllowed != null &&
          parsed > widget.remainingAllowed!) {
        _maxRiskError =
            'Exceeds wallet remaining max: ${widget.currency}${widget.remainingAllowed}';
      } else {
        _maxRiskError = null;
      }
    });
  }

  void _validateTarget(String v) {
    setState(() {
      _targetError = v.isEmpty
          ? 'Required'
          : double.tryParse(v) == null
          ? 'Invalid number'
          : null;
    });
  }

  void _validateTimeframe(String v) {
    setState(() {
      _timeframeError = v.isEmpty ? 'Required' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Position'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _tickerCtrl,
              decoration: const InputDecoration(labelText: 'Ticker'),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _stopCtrl,
              decoration: InputDecoration(
                labelText: 'Stop-loss price',
                errorText: _stopError,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: _validateStop,
            ),
            const SizedBox(height: 8),
            Text(
              'Direction',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _direction = 'LONG'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _direction == 'LONG'
                          ? const Color(0xFF2E7D32)
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      foregroundColor: _direction == 'LONG'
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    child: const Text('▲ LONG'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _direction = 'SHORT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _direction == 'SHORT'
                          ? const Color(0xFFB71C1C)
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      foregroundColor: _direction == 'SHORT'
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    child: const Text('▼ SHORT'),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _maxRiskCtrl,
              decoration: InputDecoration(
                labelText: 'Max allowed risk (fiat)',
                errorText: _maxRiskError,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: _validateMaxRisk,
            ),
            TextField(
              controller: _targetCtrl,
              decoration: InputDecoration(
                labelText: 'Target price',
                errorText: _targetError,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: _validateTarget,
            ),
            TextField(
              controller: _timeframeCtrl,
              decoration: InputDecoration(
                labelText: 'Timeframe (e.g. 1h, 4h)',
                errorText: _timeframeError,
              ),
              onChanged: _validateTimeframe,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onDismiss, child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _canAdd
              ? () => widget.onAdd(
                  _tickerCtrl.text.trim(),
                  _stopCtrl.text.trim(),
                  _maxRiskCtrl.text.trim(),
                  _targetCtrl.text.trim(),
                  _direction,
                  _timeframeCtrl.text.trim(),
                )
              : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
