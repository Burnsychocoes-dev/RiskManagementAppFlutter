import 'package:flutter/material.dart';

/// Dialog to edit the stop-loss of a position.
///
/// Rules:
///   LONG  – stop must be <= avgEntry (can't move above avg entry)
///           stop must be >= minStop  (can't exceed maxRisk)
///   SHORT – stop must be >= avgEntry (can't move below avg entry)
///           stop must be <= maxStop  (can't exceed maxRisk)
///
/// If stop == avgEntry the position is set to break-even (risk → 0).
class EditPositionStopDialog extends StatefulWidget {
  final bool isLong;
  final double currentStop;
  final double avgEntry;

  /// Lower bound for LONG (stop that would make currentRisk == maxRisk).
  /// Upper bound for SHORT (stop that would make currentRisk == maxRisk).
  final double? boundStop;
  final String currency;
  final VoidCallback onDismiss;
  final void Function(double newStop) onSave;

  const EditPositionStopDialog({
    super.key,
    required this.isLong,
    required this.currentStop,
    required this.avgEntry,
    required this.boundStop,
    required this.currency,
    required this.onDismiss,
    required this.onSave,
  });

  @override
  State<EditPositionStopDialog> createState() => _EditPositionStopDialogState();
}

class _EditPositionStopDialogState extends State<EditPositionStopDialog> {
  late final TextEditingController _ctrl;
  String? _error;
  String? _hint;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentStop.toStringAsFixed(2));
    _validate(_ctrl.text);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _validate(String v) {
    final val = double.tryParse(v);
    setState(() {
      _hint = null;
      if (v.isEmpty) {
        _error = 'Required';
        return;
      }
      if (val == null) {
        _error = 'Invalid number';
        return;
      }

      if (widget.isLong) {
        // Upper bound: can't go above avg entry
        if (val > widget.avgEntry) {
          _error =
              'For LONG, stop cannot be above avg entry (${widget.avgEntry.toStringAsFixed(2)})';
          return;
        }
        // Lower bound: can't go below the stop that would hit maxRisk
        if (widget.boundStop != null && val < widget.boundStop!) {
          _error =
              'Stop too low — would exceed max risk (min: ${widget.boundStop!.toStringAsFixed(2)})';
          return;
        }
        // Break-even hint
        if ((val - widget.avgEntry).abs() < 0.000001) {
          _hint = 'Break-even: max risk & current risk will be set to 0';
        }
      } else {
        // SHORT: upper bound is the stop that would hit maxRisk
        if (widget.boundStop != null && val > widget.boundStop!) {
          _error =
              'Stop too high — would exceed max risk (max: ${widget.boundStop!.toStringAsFixed(2)})';
          return;
        }
        // Lower bound: can't go below avg entry
        if (val < widget.avgEntry) {
          _error =
              'For SHORT, stop cannot be below avg entry (${widget.avgEntry.toStringAsFixed(2)})';
          return;
        }
        // Break-even hint
        if ((val - widget.avgEntry).abs() < 0.000001) {
          _hint = 'Break-even: max risk & current risk will be set to 0';
        }
      }

      _error = null;
    });
  }

  bool get _canSave => _error == null && _ctrl.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final direction = widget.isLong ? 'LONG' : 'SHORT';
    final boundsText = widget.boundStop != null
        ? widget.isLong
              ? 'Min: ${widget.boundStop!.toStringAsFixed(2)}  •  Max: ${widget.avgEntry.toStringAsFixed(2)} (avg entry)'
              : 'Min: ${widget.avgEntry.toStringAsFixed(2)} (avg entry)  •  Max: ${widget.boundStop!.toStringAsFixed(2)}'
        : null;

    return AlertDialog(
      title: Text('Edit Stop-Loss ($direction)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (boundsText != null) ...[
            Text(
              boundsText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'New stop-loss price',
              errorText: _error,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _validate,
          ),
          if (_hint != null) ...[
            const SizedBox(height: 6),
            Text(
              _hint!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.orange[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: widget.onDismiss, child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _canSave
              ? () => widget.onSave(double.parse(_ctrl.text))
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
