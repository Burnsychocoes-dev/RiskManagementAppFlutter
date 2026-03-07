import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../models/wallet.dart';
import '../widgets/add_wallet_dialog.dart';

/// Equivalent to WalletsListScreen in Kotlin — shows all wallets.
class WalletsListScreen extends StatefulWidget {
  final void Function(String walletId) onOpenWallet;
  final VoidCallback? onDonate;

  const WalletsListScreen({
    super.key,
    required this.onOpenWallet,
    this.onDonate,
  });

  @override
  State<WalletsListScreen> createState() => _WalletsListScreenState();
}

class _WalletsListScreenState extends State<WalletsListScreen> {
  bool _showAdd = false;

  void _showDeleteConfirm(
    BuildContext context,
    Wallet wallet,
    List<Wallet> wallets,
    WalletProvider vm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete wallet'),
        content: Text(
          "Are you sure you want to delete wallet '${wallet.name}'? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final originalIndex = wallets.indexWhere(
                (w) => w.id == wallet.id,
              );
              vm.deleteWallet(wallet.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Deleted '${wallet.name}'"),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () => vm.addWalletAt(wallet, originalIndex),
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WalletProvider>();
    final wallets = vm.wallets;

    return Scaffold(
      appBar: AppBar(title: const Text('Wallets')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _showAdd = true),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: widget.onDonate != null
          ? TextButton(
              onPressed: widget.onDonate,
              child: const Text(
                '💰 Saved from a stupid mistake? Donate!',
                style: TextStyle(decoration: TextDecoration.underline),
                textAlign: TextAlign.center,
              ),
            )
          : null,
      body: Stack(
        children: [
          wallets.isEmpty
              ? const Center(child: Text('No wallets yet. Tap + to add one.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: wallets.length,
                  itemBuilder: (ctx, i) {
                    final wallet = wallets[i];
                    final cur = wallet.currency;
                    final riskStr = wallet.totalRisk().toStringAsFixed(2);
                    final maxRiskStr = wallet.walletMaxRisk.toStringAsFixed(2);
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    wallet.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    'Current risk: $cur$riskStr / $cur$maxRiskStr',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      widget.onOpenWallet(wallet.id),
                                  child: const Text('Open'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _showDeleteConfirm(
                                    context,
                                    wallet,
                                    wallets,
                                    vm,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
          if (_showAdd)
            AddWalletDialog(
              onDismiss: () => setState(() => _showAdd = false),
              onAdd: (name, maxRisk, currency) {
                final safeMax = double.tryParse(maxRisk) ?? 0.0;
                vm.addWallet(name, safeMax, currency: currency);
                setState(() => _showAdd = false);
              },
            ),
        ],
      ),
    );
  }
}
