import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../models/direction.dart';
import '../models/position.dart';
import '../models/sub_position.dart';
import '../widgets/add_position_dialog.dart';
import '../widgets/estimate_size_dialog.dart';
import '../widgets/reduce_subposition_dialog.dart';

final _dtFmt = DateFormat('yyyy-MM-dd HH:mm');

// ─── Edit wallet max risk dialog ──────────────────────────────────────────────

class _EditWalletMaxDialog extends StatefulWidget {
  final double currentMax;
  final VoidCallback onDismiss;
  final void Function(double newMax) onSave;

  const _EditWalletMaxDialog({
    required this.currentMax,
    required this.onDismiss,
    required this.onSave,
  });

  @override
  State<_EditWalletMaxDialog> createState() => _EditWalletMaxDialogState();
}

class _EditWalletMaxDialogState extends State<_EditWalletMaxDialog> {
  late final TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentMax.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Wallet Max Risk'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              labelText: 'Wallet max risk (fiat)',
              errorText: _error,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => setState(() {
              _error = double.tryParse(v) == null ? 'Invalid number' : null;
            }),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: widget.onDismiss, child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _error == null
              ? () {
                  final v = double.tryParse(_ctrl.text);
                  if (v != null) widget.onSave(v);
                }
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ─── Wallet Detail Screen ─────────────────────────────────────────────────────

class WalletDetailScreen extends StatefulWidget {
  final String walletId;
  final VoidCallback onBack;
  final void Function(String walletId)? onOpenHistory;

  const WalletDetailScreen({
    super.key,
    required this.walletId,
    required this.onBack,
    this.onOpenHistory,
  });

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  bool _showAddPosition = false;
  bool _showEditWallet = false;
  // (positionId, defaultStop, defaultTarget, maxAllowedRisk, direction)
  ({
    String positionId,
    String? defaultStop,
    String? defaultTarget,
    double? maxAllowedRisk,
    String direction,
  })?
  _showAddSub;
  // (positionId, subIndex, currentSize)
  ({String positionId, int subIndex, double currentSize})? _showReduce;

  Set<String> _expandedPositions = {};

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WalletProvider>();
    final wallet = vm.wallets.where((w) => w.id == widget.walletId).firstOrNull;
    final currency = wallet?.currency ?? '\$';

    return Scaffold(
      appBar: AppBar(
        title: Text(wallet?.name ?? 'Wallet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: wallet == null
          ? const Center(child: Text('Wallet not found'))
          : Stack(
              children: [
                _buildContent(context, wallet, currency, vm),
                if (_showEditWallet)
                  _EditWalletMaxDialog(
                    currentMax: wallet.walletMaxRisk,
                    onDismiss: () => setState(() => _showEditWallet = false),
                    onSave: (newMax) {
                      vm.updateWallet(wallet.copyWith(walletMaxRisk: newMax));
                      setState(() => _showEditWallet = false);
                    },
                  ),
                if (_showAddPosition)
                  AddPositionDialog(
                    remainingAllowed: wallet.remainingMaxRisk(),
                    currency: currency,
                    onDismiss: () => setState(() => _showAddPosition = false),
                    onAdd: (ticker, stop, maxRisk, target, dirStr, tf) {
                      final dir = dirStr == 'LONG'
                          ? Direction.long
                          : Direction.short;
                      final pos = Position(
                        ticker: ticker,
                        timeframe: tf,
                        direction: dir,
                        stopLossPrice: stop.isEmpty
                            ? null
                            : double.tryParse(stop),
                        maximumAllowedRisk: double.tryParse(maxRisk) ?? 0.0,
                        targetPrice: target.isEmpty
                            ? null
                            : double.tryParse(target),
                      );
                      vm.addPositionToWallet(wallet.id, pos);
                      setState(() => _showAddPosition = false);
                    },
                  ),
                if (_showAddSub != null)
                  EstimateSizeDialog(
                    defaultStop: _showAddSub!.defaultStop,
                    defaultTarget: _showAddSub!.defaultTarget,
                    maxAllowedRisk: _showAddSub!.maxAllowedRisk,
                    direction: _showAddSub!.direction,
                    currency: currency,
                    onDismiss: () => setState(() => _showAddSub = null),
                    onAdd:
                        (
                          entryStr,
                          stopStr,
                          riskFlatStr,
                          riskPctStr,
                          targetStr,
                        ) {
                          final entry = double.tryParse(entryStr) ?? 0.0;
                          final stop = double.tryParse(stopStr) ?? 0.0;
                          final riskFlat = double.tryParse(riskFlatStr) ?? 0.0;
                          final (
                            sizeAsset,
                            sizeWallet,
                          ) = Position.estimateSizeForRisk(
                            entry,
                            stop,
                            riskFlat,
                          );
                          final dir = _showAddSub!.direction == 'LONG'
                              ? Direction.long
                              : Direction.short;
                          final sub = SubPosition(
                            entryPrice: entry,
                            direction: dir,
                            sizeInAsset: sizeAsset,
                            sizeInWalletCurrency: sizeWallet,
                            targetPrice: targetStr.isEmpty
                                ? null
                                : double.tryParse(targetStr),
                            stopLossPrice: stop,
                          );
                          vm.addSubPositionToPosition(
                            wallet.id,
                            _showAddSub!.positionId,
                            sub,
                          );
                          setState(() => _showAddSub = null);
                        },
                  ),
                if (_showReduce != null)
                  ReduceSubpositionDialog(
                    currentSizeInAsset: _showReduce!.currentSize,
                    onDismiss: () => setState(() => _showReduce = null),
                    onReduce: (unitsStr, pctStr) {
                      final isPercent = pctStr.isNotEmpty;
                      final amt = isPercent
                          ? (double.tryParse(pctStr) ?? 0.0)
                          : (double.tryParse(unitsStr) ?? 0.0);
                      if (amt > 0) {
                        vm.reduceSubposition(
                          wallet.id,
                          _showReduce!.positionId,
                          _showReduce!.subIndex,
                          amt,
                          isPercent: isPercent,
                        );
                      }
                      setState(() => _showReduce = null);
                    },
                  ),
              ],
            ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    wallet,
    String currency,
    WalletProvider vm,
  ) {
    final walletMaxStr = wallet.walletMaxRisk.toStringAsFixed(2);
    final currentRiskStr = wallet.totalRisk().toStringAsFixed(2);
    final totalMaxStr = wallet.totalMaxRisk().toStringAsFixed(2);
    final positions = wallet.positions as List<Position>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wallet max authorized risk: $currency$walletMaxStr'),
              Text('Current max risk (positions sum): $currency$totalMaxStr'),
              Text('Current risk: $currency$currentRiskStr'),
              const SizedBox(height: 4),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => _showEditWallet = true),
                    child: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => setState(() => _showAddPosition = true),
                    child: const Text('Add Position'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: widget.onOpenHistory != null
                        ? () => widget.onOpenHistory!(wallet.id)
                        : null,
                    child: const Text('History'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: positions.isEmpty
              ? const Center(child: Text('No positions yet. Tap Add Position.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: positions.length,
                  itemBuilder: (ctx, idx) => _buildPositionCard(
                    ctx,
                    idx,
                    positions[idx],
                    wallet.id,
                    currency,
                    vm,
                    wallet,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPositionCard(
    BuildContext context,
    int idx,
    Position pos,
    String walletId,
    String currency,
    WalletProvider vm,
    wallet,
  ) {
    final isExpanded = _expandedPositions.contains(pos.id);
    final pct = pos.currentSizePercent().toStringAsFixed(2);
    final stop = pos.stopLossPrice?.toStringAsFixed(2) ?? '-';
    final maxRisk = pos.maximumAllowedRisk.toStringAsFixed(2);
    final currentRisk = pos.totalCurrentRisk().toStringAsFixed(2);
    final targetStr = pos.targetPrice?.toStringAsFixed(2) ?? '-';
    final lastMillis = pos.subPositions.isEmpty
        ? pos.createdAtMillis
        : pos.subPositions
              .map((s) => s.openedAtMillis)
              .reduce((a, b) => a > b ? a : b);
    final lastUpdateStr = _dtFmt.format(
      DateTime.fromMillisecondsSinceEpoch(lastMillis),
    );

    // Risk-weighted R:R: each subposition's R:R is weighted by its share of
    // total position risk (currentRisk). Only subpositions with a valid target
    // and non-zero risk-per-unit contribute; the weights are re-normalised
    // among those contributors so the result always sums to 1.
    final String avgRRStr = () {
      final totalRisk = pos.totalCurrentRisk();
      if (totalRisk == 0) return '-';

      double weightedSum = 0;
      double weightSum = 0;
      for (final sp in pos.subPositions) {
        if (sp.targetPrice == null) continue;
        final reward = (sp.targetPrice! - sp.entryPrice).abs();
        final riskPerUnit = (sp.entryPrice - sp.stopLossPrice).abs();
        if (riskPerUnit == 0) continue;
        final rr = reward / riskPerUnit;
        final weight = sp.currentRisk() / totalRisk;
        weightedSum += rr * weight;
        weightSum += weight;
      }
      if (weightSum == 0) return '-';
      // Re-normalise in case some subpositions were excluded
      return (weightedSum / weightSum).toStringAsFixed(2);
    }();
    final tf = pos.timeframe;
    final headerText = tf.isEmpty
        ? '${pos.ticker} ($pct%)'
        : '${pos.ticker} - $tf ($pct%)';
    final isLong = pos.direction == Direction.long;
    final chipColor = isLong
        ? const Color(0xFF2E7D32)
        : const Color(0xFFB71C1C);
    final arrow = isLong ? '▲ ' : '▼ ';
    final bgColor = idx % 2 == 0 ? Colors.transparent : const Color(0xFFE0E0E0);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      if (isExpanded) {
                        _expandedPositions = Set.from(_expandedPositions)
                          ..remove(pos.id);
                      } else {
                        _expandedPositions = Set.from(_expandedPositions)
                          ..add(pos.id);
                      }
                    }),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                headerText,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: chipColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$arrow${pos.direction}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Stop: $stop',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Max risk: $currency$maxRisk',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Current risk: $currency$currentRisk',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Target: $targetStr',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Avg R:R: $avgRRStr',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Last update: $lastUpdateStr',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(
                        () => _showAddSub = (
                          positionId: pos.id,
                          defaultStop: pos.stopLossPrice?.toString(),
                          defaultTarget: pos.targetPrice?.toString(),
                          maxAllowedRisk: pos.maximumAllowedRisk,
                          direction: pos.direction.toString(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _confirmDeletePosition(
                        context,
                        pos,
                        walletId,
                        vm,
                        wallet,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isExpanded)
            ...pos.subPositions.asMap().entries.map(
              (e) => _buildSubPositionCard(
                context,
                e.key,
                e.value,
                pos.id,
                walletId,
                currency,
                vm,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubPositionCard(
    BuildContext context,
    int idx,
    SubPosition sp,
    String positionId,
    String walletId,
    String currency,
    WalletProvider vm,
  ) {
    final openedStr = _dtFmt.format(
      DateTime.fromMillisecondsSinceEpoch(sp.openedAtMillis),
    );
    final risk = sp.currentRisk().toStringAsFixed(2);
    final subBgColor = idx % 2 == 0
        ? const Color(0xFFEAF6FF)
        : const Color(0xFFBBDDF5);

    String rrForSub = '-';
    if (sp.targetPrice != null) {
      final reward = (sp.targetPrice! - sp.entryPrice).abs();
      final riskPerUnit = (sp.entryPrice - sp.stopLossPrice).abs();
      if (riskPerUnit > 0) {
        rrForSub = (reward / riskPerUnit).toStringAsFixed(2);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: subBgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF9EC3E9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${sp.direction} • $openedStr',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Stop: ${sp.stopLossPrice}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Current risk: $currency$risk',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Current size: ${sp.sizeInAsset}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Current size (fiat): $currency${sp.sizeInWalletCurrency.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Entry price: ${sp.entryPrice}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Target: ${sp.targetPrice ?? '-'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'R:R: $rrForSub',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Text(
                    '-',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => setState(
                    () => _showReduce = (
                      positionId: positionId,
                      subIndex: idx,
                      currentSize: sp.sizeInAsset,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () =>
                      vm.removeSubposition(walletId, positionId, idx),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePosition(
    BuildContext context,
    Position pos,
    String walletId,
    WalletProvider vm,
    wallet,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete position'),
        content: Text(
          "Are you sure you want to delete position '${pos.ticker}'? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final originalIndex = (wallet.positions as List<Position>)
                  .indexWhere((p) => p.id == pos.id);
              vm.deletePosition(walletId, pos.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Deleted '${pos.ticker}'"),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () => vm.addPositionAt(
                      walletId,
                      pos,
                      originalIndex < 0 ? 0 : originalIndex,
                    ),
                  ),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
