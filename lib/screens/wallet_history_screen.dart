import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../models/wallet_action.dart';

final _dtFmtHistory = DateFormat('yyyy-MM-dd HH:mm');
final _dateFmt = DateFormat('yyyy-MM-dd');

/// Equivalent to WalletHistoryScreen in Kotlin.
class WalletHistoryScreen extends StatefulWidget {
  final String walletId;
  final VoidCallback onBack;

  const WalletHistoryScreen({
    super.key,
    required this.walletId,
    required this.onBack,
  });

  @override
  State<WalletHistoryScreen> createState() => _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends State<WalletHistoryScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _showFilter = false;

  List<WalletAction> _filtered(List<WalletAction> actions) {
    return actions.where((a) {
      final t = DateTime.fromMillisecondsSinceEpoch(a.timestampMillis);
      if (_fromDate != null && t.isBefore(_fromDate!)) return false;
      if (_toDate != null) {
        final endOfDay = DateTime(
          _toDate!.year,
          _toDate!.month,
          _toDate!.day,
          23,
          59,
          59,
        );
        if (t.isAfter(endOfDay)) return false;
      }
      return true;
    }).toList()..sort((a, b) => b.timestampMillis.compareTo(a.timestampMillis));
  }

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final initial = isFrom ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Map<String, String>? _parseExtra(String? extra) {
    if (extra == null) return null;
    try {
      return Map.fromEntries(
        extra.split(';').map((kv) {
          final parts = kv.split('=');
          return parts.length == 2 ? MapEntry(parts[0], parts[1]) : null;
        }).whereType<MapEntry<String, String>>(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WalletProvider>();
    final wallet = vm.wallets.where((w) => w.id == widget.walletId).firstOrNull;
    final actions = wallet?.history ?? [];
    final filtered = _filtered(actions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filtered.length} entries',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () =>
                          setState(() => _showFilter = !_showFilter),
                      child: Text(_showFilter ? 'Hide filters' : 'Filter'),
                    ),
                    if (_showFilter)
                      TextButton(
                        onPressed: () => setState(() {
                          _fromDate = null;
                          _toDate = null;
                        }),
                        child: const Text('Clear'),
                      ),
                  ],
                ),
              ],
            ),
            if (_showFilter) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(context, true),
                      child: Text(
                        _fromDate != null
                            ? 'From: ${_dateFmt.format(_fromDate!)}'
                            : 'From: any',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(context, false),
                      child: Text(
                        _toDate != null
                            ? 'To: ${_dateFmt.format(_toDate!)}'
                            : 'To: any',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final act = filtered[i];
                  final tstr = _dtFmtHistory.format(
                    DateTime.fromMillisecondsSinceEpoch(act.timestampMillis),
                  );
                  final parsedExtra = _parseExtra(act.extra);
                  String? posSummary;
                  if (parsedExtra != null) {
                    final before = parsedExtra['posBefore'];
                    final after = parsedExtra['posAfter'];
                    final delta = parsedExtra['delta'];
                    final ticker = parsedExtra['ticker'];
                    final timeframe = parsedExtra['timeframe'];
                    if (before != null && after != null) {
                      final sign = (delta?.startsWith('-') ?? false) ? '' : '+';
                      final label = (ticker != null && ticker.isNotEmpty)
                          ? (timeframe != null && timeframe.isNotEmpty
                                ? '$ticker-$timeframe'
                                : ticker)
                          : 'Pos';
                      posSummary =
                          '$label: $before% -> $after% (Δ $sign${delta ?? '0.00'}%)';
                    }
                  }

                  final descToShow = posSummary != null
                      ? act.description.replaceFirst(
                          RegExp(r'\s*[—\-]\s*pos.*$', caseSensitive: false),
                          '',
                        )
                      : act.description;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tstr,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (posSummary != null)
                            Text(
                              posSummary,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          Text(
                            descToShow,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
