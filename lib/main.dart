import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/wallets_list_screen.dart';
import 'screens/wallet_detail_screen.dart';
import 'screens/wallet_history_screen.dart';
import 'screens/donate_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => WalletProvider(),
      child: const RiskManagerApp(),
    ),
  );
}

class RiskManagerApp extends StatelessWidget {
  const RiskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Risk Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      initialRoute: '/wallets',
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';

        if (name == '/wallets') {
          return MaterialPageRoute(
            builder: (ctx) => WalletsListScreen(
              onOpenWallet: (id) =>
                  Navigator.pushNamed(ctx, '/wallet', arguments: id),
              onDonate: () => Navigator.pushNamed(ctx, '/donate'),
            ),
          );
        }

        if (name == '/wallet') {
          final walletId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (ctx) => WalletDetailScreen(
              walletId: walletId,
              onBack: () => Navigator.pop(ctx),
              onOpenHistory: (id) =>
                  Navigator.pushNamed(ctx, '/history', arguments: id),
            ),
          );
        }

        if (name == '/history') {
          final walletId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (ctx) => WalletHistoryScreen(
              walletId: walletId,
              onBack: () => Navigator.pop(ctx),
            ),
          );
        }

        if (name == '/donate') {
          return MaterialPageRoute(
            builder: (ctx) => DonateScreen(onBack: () => Navigator.pop(ctx)),
          );
        }

        return null;
      },
    );
  }
}
