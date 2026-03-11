import 'package:flutter/material.dart';
import '../models/position.dart';

/// Dialog to estimate sub-position size based on entry, stop, and risk amount.
/// Mirrors the Kotlin EstimateSizeDialog.
class EstimateSizeDialog extends StatefulWidget {
  final String? defaultStop;
  final String? defaultTarget;
  final double? maxAllowedRisk;
  final String currency;
  final String direction;
  final VoidCallback onDismiss;
  final void Function(
    String entry,
    String stop,
    String riskFlat,
    String riskPct,
    String target,
  )
  onAdd;

  const EstimateSizeDialog({
    super.key,
    this.defaultStop,
    this.defaultTarget,
    this.maxAllowedRisk,
    this.currency = '\$',
    this.direction = 'LONG',
    required this.onDismiss,
    required this.onAdd,
  });

  @override
  State<EstimateSizeDialog> createState() => _EstimateSizeDialogState();
}

class _EstimateSizeDialogState extends State<EstimateSizeDialog> {
  final _entryCtrl = TextEditingController();
  late final TextEditingController _stopCtrl;
  final _riskFlatCtrl = TextEditingController();
  final _riskPctCtrl = TextEditingController();
  late final TextEditingController _targetCtrl;

  String? _entryError;
  String? _riskFlatError;
  String? _riskPctError;
  String? _targetError;
  String? _relationError;
  String? _relationTargetError;

  @override
  void initState() {
    super.initState();
    _stopCtrl = TextEditingController(text: widget.defaultStop ?? '');
    _targetCtrl = TextEditingController(text: widget.defaultTarget ?? '');
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _stopCtrl.dispose();
    _riskFlatCtrl.dispose();
    _riskPctCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  double? _parse(String s) => s.isEmpty ? null : double.tryParse(s);

  void _validateRelations() {
    final e = _parse(_entryCtrl.text);
    final s = _parse(_stopCtrl.text);
    final t = _parse(_targetCtrl.text);
    setState(() {
      _relationError = null;
      _relationTargetError = null;
      if (e != null && s != null) {
        if (widget.direction == 'LONG' && e <= s) {
          _relationError = 'For LONG, entry must be greater than stop';
        } else if (widget.direction == 'SHORT' && e >= s) {
          _relationError = 'For SHORT, entry must be lower than stop';
        }
      }
      if (e != null && t != null) {
        if (widget.direction == 'LONG' && e >= t) {
          _relationTargetError = 'For LONG, entry must be lower than target';
        } else if (widget.direction == 'SHORT' && e <= t) {
          _relationTargetError = 'For SHORT, entry must be higher than target';
        }
      }
    });
  }

  void _onRiskFlatChanged(String v) {
    final flat = _parse(v);
    setState(() {
      if (flat == null) {
        _riskFlatError = v.isEmpty ? 'Required' : 'Invalid number';
      } else if (widget.maxAllowedRisk != null &&
          flat > widget.maxAllowedRisk!) {
        _riskFlatError =
            'Exceeds max risk (${widget.currency}${widget.maxAllowedRisk!.toStringAsFixed(2)})';
      } else {
        _riskFlatError = null;
      }

      if (flat != null &&
          widget.maxAllowedRisk != null &&
          widget.maxAllowedRisk! > 0) {
        final pct = flat / widget.maxAllowedRisk! * 100;
        _riskPctCtrl.text = pct.toStringAsFixed(2);
        _riskPctError = pct > 100
            ? 'Cannot exceed 100% of position max risk'
            : null;
      }
    });
  }

  void _onRiskPctChanged(String v) {
    final pct = _parse(v);
    setState(() {
      if (pct == null) {
        _riskPctError = v.isEmpty ? 'Required' : 'Invalid number';
      } else if (pct > 100) {
        _riskPctError = 'Cannot exceed 100% of position max risk';
      } else {
        _riskPctError = null;
      }

      if (pct != null && widget.maxAllowedRisk != null) {
        final flat = pct / 100.0 * widget.maxAllowedRisk!;
        _riskFlatCtrl.text = flat.toStringAsFixed(2);
        _riskFlatError = flat > widget.maxAllowedRisk!
            ? 'Exceeds max risk (${widget.currency}${widget.maxAllowedRisk!.toStringAsFixed(2)})'
            : null;
      }
    });
  }

  // ── preview ──

  (double, double)? get _preview {
    final e = _parse(_entryCtrl.text);
    final s = _parse(_stopCtrl.text);
    final r = _parse(_riskFlatCtrl.text);
    if (e == null || s == null || r == null) return null;
    return Position.estimateSizeForRisk(e, s, r);
  }

  String? get _previewPct {
    final e = _parse(_entryCtrl.text);
    final s = _parse(_stopCtrl.text);
    if (e == null || s == null || e == 0) return null;
    return ((e - s).abs() / e * 100).toStringAsFixed(2);
  }

  String? get _previewLeverage {
    final e = _parse(_entryCtrl.text);
    final s = _parse(_stopCtrl.text);
    if (e == null || s == null || e == 0) return null;
    final frac = (e - s).abs() / e;
    if (frac == 0) return null;
    return (1 / frac).toStringAsFixed(2);
  }

  String? get _previewRR {
    final e = _parse(_entryCtrl.text);
    final s = _parse(_stopCtrl.text);
    final t = _parse(_targetCtrl.text);
    if (e == null || s == null || t == null) return null;
    final reward = (t - e).abs();
    final risk = (e - s).abs();
    if (risk == 0) return null;
    return (reward / risk).toStringAsFixed(2);
  }

  bool get _canAdd =>
      _parse(_entryCtrl.text) != null &&
      _parse(_stopCtrl.text) != null &&
      _parse(_riskFlatCtrl.text) != null &&
      _riskFlatError == null &&
      _riskPctError == null &&
      _entryError == null &&
      _relationError == null &&
      _relationTargetError == null &&
      _targetError == null;

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return AlertDialog(
      title: const Text('Estimate Size'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _entryCtrl,
              decoration: InputDecoration(
                labelText: 'Entry price',
                errorText: _entryError,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (v) {
                setState(() {
                  _entryError = _parse(v) == null
                      ? (v.isEmpty ? 'Required' : 'Must be a number')
                      : null;
                });
                _validateRelations();
              },
            ),
            TextField(
              controller: _stopCtrl,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Stop-loss price'),
            ),
            if (_relationError != null)
              Text(
                _relationError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            if (_relationTargetError != null)
              Text(
                _relationTargetError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            TextField(
              controller: _riskFlatCtrl,
              decoration: InputDecoration(
                labelText: 'Risk amount (fiat)',
                errorText: _riskFlatError,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: _onRiskFlatChanged,
            ),
            TextField(
              controller: _riskPctCtrl,
              decoration: InputDecoration(
                labelText: 'Risk (%)',
                errorText: _riskPctError,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: _onRiskPctChanged,
            ),
            Text(
              'Direction: ${widget.direction}',
              style: Theme.of(context).textTheme.bodyMedium,
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
              onChanged: (v) {
                setState(() {
                  _targetError = _parse(v) == null
                      ? (v.isEmpty ? 'Required' : 'Invalid number')
                      : null;
                });
                _validateRelations();
              },
            ),
            const SizedBox(height: 10),
            if (preview != null) ...[
              Text(() {
                final rrPart = _previewRR != null
                    ? ' — R:R: ${_previewRR}'
                    : '';
                final lvgPart = _previewLeverage != null
                    ? ' — Max lev: ${_previewLeverage}x'
                    : '';
                final pctPart = _previewPct != null
                    ? ' — Risk: ${_previewPct}%'
                    : '';
                return 'Estimated size: ${preview.$1} units (~${widget.currency}${preview.$2})$pctPart$lvgPart$rrPart';
              }(), style: Theme.of(context).textTheme.bodySmall),
            ] else
              Text(
                'Enter valid Entry/Stop/Risk to see preview',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onDismiss, child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _canAdd
              ? () => widget.onAdd(
                  _entryCtrl.text.trim(),
                  _stopCtrl.text.trim(),
                  _riskFlatCtrl.text.trim(),
                  _riskPctCtrl.text.trim(),
                  _targetCtrl.text.trim(),
                )
              : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
