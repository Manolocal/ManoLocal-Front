import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/enums/backend_enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/navigation_keys.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badges.dart';
import '../../domain/models/wallet_models.dart';
import '../providers/wallet_provider.dart';

/// Billetera Virtual del Especialista: saldo disponible, congelado, recargas y movimientos.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const List<double> _quickAmounts = [50, 100, 250, 500, 1000];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WalletProvider>().loadWallet();
    });
  }

  Future<void> _openRechargeSheet() async {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController(text: '250');
    final descCtrl = TextEditingController();

    final confirmed = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Recargar saldo a tu billetera',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cada confirmación de trabajo congela \$50.00 MXN que solo se cobran al completarse el servicio.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickAmounts.map((preset) {
                      final selected = amountCtrl.text.trim() ==
                          preset.toStringAsFixed(0);
                      return ChoiceChip(
                        label: Text('\$${preset.toStringAsFixed(0)}'),
                        selected: selected,
                        onSelected: (_) {
                          setModalState(() {
                            amountCtrl.text = preset.toStringAsFixed(0);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setModalState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Monto a recargar (MXN)',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                      hintText: '250.00',
                    ),
                    validator: (v) =>
                        AppValidators.positiveAmount(v, min: 1, max: 100000),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Referencia o nota (opcional)',
                      hintText: 'Ej. Recarga para trabajos de la semana',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final amount = double.parse(
                        amountCtrl.text.trim().replaceAll(',', ''),
                      );
                      Navigator.of(ctx).pop({
                        'monto': amount,
                        'descripcion': descCtrl.text.trim(),
                      });
                    },
                    icon: const Icon(Icons.add_card_rounded),
                    label: const Text('Confirmar Recarga'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirmed == null || !mounted) return;
    final result = await context.read<WalletProvider>().recharge(
          monto: confirmed['monto'] as double,
          descripcion: (confirmed['descripcion'] as String).isEmpty
              ? null
              : confirmed['descripcion'] as String,
        );

    if (result != null && mounted) {
      GlobalNotifier.showSuccessSnackBar(
        '${result.message} (+${AppFormatters.currency(result.transaction.monto)})',
      );
    } else if (mounted) {
      final err = context.read<WalletProvider>().errorMessage;
      if (err != null) GlobalNotifier.showErrorSnackBar(err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final wallet = walletProvider.wallet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billetera Virtual'),
        actions: [
          IconButton(
            tooltip: 'Recargar saldo',
            icon: const Icon(Icons.add_card_rounded),
            onPressed: walletProvider.isRecharging ? null : _openRechargeSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.gray,
        backgroundColor: AppColors.yellow,
        onRefresh: () =>
            walletProvider.loadWallet(filter: walletProvider.selectedFilter),
        child: walletProvider.isLoading && wallet == null
            ? const Center(child: CircularProgressIndicator())
            : walletProvider.errorMessage != null && wallet == null
                ? ErrorStateView(
                    message: walletProvider.errorMessage!,
                    onRetry: () => walletProvider.loadWallet(),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 840),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _WalletHeroCard(
                                wallet: wallet,
                                isRecharging: walletProvider.isRecharging,
                                onRecharge: _openRechargeSheet,
                              ),
                              const SizedBox(height: 14),
                              if (wallet != null &&
                                  wallet.balanceDisponible < 50)
                                AppStatusBanner.warning(
                                  'Necesitas al menos \$50.00 MXN disponibles para confirmar un nuevo trabajo.',
                                  trailing: TextButton(
                                    onPressed: _openRechargeSheet,
                                    child: const Text('Recargar'),
                                  ),
                                )
                              else if (wallet != null)
                                AppStatusBanner.success(
                                  'Tu saldo disponible cubre la cuota fija (\$50 MXN) para aceptar trabajos de inmediato.',
                                ),
                              const SizedBox(height: 22),
                              const SectionHeader(
                                title: 'Historial de movimientos',
                                subtitle:
                                    'Registro auditable de recargas, congelamientos y devoluciones',
                              ),
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ChoiceChip(
                                      label: const Text('Todos'),
                                      selected:
                                          walletProvider.selectedFilter == null,
                                      onSelected: (_) =>
                                          walletProvider.setFilter(null),
                                    ),
                                    const SizedBox(width: 8),
                                    ...TransactionType.values.map(
                                      (type) => Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: ChoiceChip(
                                          label: Text(type.label),
                                          selected:
                                              walletProvider.selectedFilter ==
                                                  type,
                                          onSelected: (_) =>
                                              walletProvider.setFilter(type),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (walletProvider.isLoading &&
                                  walletProvider.transactions.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (walletProvider.transactions.isEmpty)
                                EmptyStateView(
                                  icon: Icons.receipt_long_outlined,
                                  title: 'Sin movimientos registrados',
                                  description:
                                      'Recarga tu billetera para comenzar a confirmar acuerdos de trabajo.',
                                  actionLabel: 'Recargar ahora',
                                  onAction: _openRechargeSheet,
                                )
                              else ...[
                                Card(
                                  child: Column(
                                    children: [
                                      for (var i = 0;
                                          i <
                                              walletProvider
                                                  .transactions.length;
                                          i++) ...[
                                        if (i > 0) const Divider(height: 1),
                                        _TransactionRow(
                                          tx: walletProvider.transactions[i],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (walletProvider.hasMore) ...[
                                  const SizedBox(height: 14),
                                  Center(
                                    child: OutlinedButton(
                                      onPressed: walletProvider.isLoadingMore
                                          ? null
                                          : () => walletProvider
                                              .loadMoreTransactions(),
                                      child: Text(
                                        walletProvider.isLoadingMore
                                            ? 'Cargando...'
                                            : 'Cargar más movimientos',
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _WalletHeroCard extends StatelessWidget {
  final WalletModel? wallet;
  final bool isRecharging;
  final VoidCallback onRecharge;

  const _WalletHeroCard({
    required this.wallet,
    required this.isRecharging,
    required this.onRecharge,
  });

  @override
  Widget build(BuildContext context) {
    final available = wallet?.balanceDisponible ?? 0.0;
    final frozen = wallet?.balanceCongelado ?? 0.0;
    final total = wallet?.balanceTotal ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.yellow.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.yellow,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'Saldo disponible',
                style: TextStyle(
                  color: AppColors.silver,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.graySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'MXN',
                  style: TextStyle(
                    color: AppColors.yellow,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppFormatters.currency(available, withSuffix: false),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.graySurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo congelado',
                        style: TextStyle(
                          color: AppColors.silver,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppFormatters.currency(frozen, withSuffix: false),
                        style: const TextStyle(
                          color: AppColors.yellow,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: AppColors.grayMuted.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo total',
                        style: TextStyle(
                          color: AppColors.silver,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppFormatters.currency(total, withSuffix: false),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isRecharging ? null : onRecharge,
              icon: isRecharging
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gray,
                      ),
                    )
                  : const Icon(Icons.add_rounded),
              label: Text(
                isRecharging ? 'Procesando recarga...' : 'Recargar Saldo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final WalletTransactionModel tx;

  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final (sign, amountColor, icon, iconBg) = switch (tx.tipo) {
      TransactionType.recarga => (
          '+',
          AppColors.success,
          Icons.south_west_rounded,
          AppColors.successSoft,
        ),
      TransactionType.devolucion => (
          '+',
          AppColors.info,
          Icons.replay_rounded,
          AppColors.infoSoft,
        ),
      TransactionType.congelamiento => (
          '•',
          AppColors.warning,
          Icons.ac_unit_rounded,
          AppColors.warningSoft,
        ),
      TransactionType.pago => (
          '-',
          AppColors.error,
          Icons.north_east_rounded,
          AppColors.errorSoft,
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: amountColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.descripcion?.isNotEmpty == true
                      ? tx.descripcion!
                      : tx.tipo.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TransactionTypeBadge(type: tx.tipo),
                    Text(
                      AppFormatters.dateTime(tx.fecha),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$sign${AppFormatters.currency(tx.monto, withSuffix: false)}',
            style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
            ),
          ),
        ],
      ),
    );
  }
}
