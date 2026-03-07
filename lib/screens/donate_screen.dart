import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Equivalent to DonateScreen in Kotlin.
class DonateScreen extends StatelessWidget {
  final VoidCallback onBack;

  const DonateScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    const entries = [
      ('Solana (SOL)', 'GrmXWnhpbyR4KKVpNfMK3ynU8nRbeekoLzkgeMnGe3pS'),
      (
        'Ethereum / Monad / Base / Polygon / Hype',
        '0xE91C88a34C3d6e4bC7E28908b64f25DBAe5e5AC9',
      ),
      (
        'Bitcoin — Taproot (bc1p…)',
        'bc1pjttf4vz26ceg02mmtrz44szdj7ha36ha2w8apv3fdan5w8vez8rqws0cen',
      ),
      (
        'Bitcoin — Native SegWit (bc1q…)',
        'bc1pjttf4vz26ceg02mmtrz44szdj7ha36ha2w8apv3fdan5w8vez8rqws0cen',
      ),
      (
        'Sui (SUI)',
        '0x44f6529df408f76034044898dd9c23fe2fff71535ec80b41ca59eab5c4007bd8',
      ),
    ];
    const contactEmail = 'riskmanagementmona@gmail.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support the project ☕'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'If this app helped you avoid a bad trade or manage your risk better, consider buying me a coffee! 🙏',
            ),
          ),
          ...entries.map((e) => _DonationCard(label: e.$1, address: e.$2)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          contactEmail,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.content_copy),
                    onPressed: () {
                      Clipboard.setData(
                        const ClipboardData(text: contactEmail),
                      );
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Copied!')));
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final String label;
  final String address;

  const _DonationCard({required this.label, required this.address});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    address,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.content_copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: address));
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Copied!')));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
