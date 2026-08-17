import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/subscription_provider.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  static const _productId = 'expensebeam_pro_monthly';

  bool _loading = false;
  bool _iapAvailable = false;
  ProductDetails? _product;

  @override
  void initState() {
    super.initState();
    _initIAP();
  }

  Future<void> _initIAP() async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      setState(() => _iapAvailable = false);
      return;
    }
    final response =
        await InAppPurchase.instance.queryProductDetails({_productId});
    if (response.productDetails.isNotEmpty) {
      setState(() {
        _iapAvailable = true;
        _product = response.productDetails.first;
      });
    } else {
      setState(() => _iapAvailable = true);
    }

    InAppPurchase.instance.purchaseStream.listen(_onPurchaseUpdate);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != _productId) continue;

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final ok = await context.read<SubscriptionProvider>().verifyPurchase(
              purchaseToken: purchase.verificationData.serverVerificationData,
              productId: purchase.productID,
            );
        await InAppPurchase.instance.completePurchase(purchase);
        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Welcome to Pro! All features unlocked.')),
          );
          Navigator.pop(context);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  void _subscribe() {
    if (_product == null) return;
    setState(() => _loading = true);
    final param = PurchaseParam(productDetails: _product!);
    InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
  }

  void _restore() async {
    setState(() => _loading = true);
    await InAppPurchase.instance.restorePurchases();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Upgrade to Pro',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHero(),
            const SizedBox(height: 24),
            _buildFeatureTable(),
            const SizedBox(height: 28),
            _buildCTA(),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loading ? null : _restore,
              child: const Text('Restore Purchase',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Subscription auto-renews monthly. Cancel anytime in Google Play.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: Colors.amber, size: 48),
          const SizedBox(height: 12),
          const Text(
            'ExpenseBeam Pro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'AI-powered finance at your fingertips',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white30),
            ),
            child: const Text(
              '\$6.99 / month',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTable() {
    const rows = [
      _FeatureRow('Expense & income tracking', true, true),
      _FeatureRow('Accounts & net worth', true, true),
      _FeatureRow('Savings goals & planning', true, true),
      _FeatureRow('Basic dashboard stats', true, true),
      _FeatureRow('Banner ads', true, false),
      _FeatureRow('AI voice expense entry', false, true),
      _FeatureRow('AI financial chat assistant', false, true),
      _FeatureRow('100 AI requests / month', false, true),
      _FeatureRow('24h AI response caching', false, true),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.fieldBorder),
      ),
      child: Column(
        children: [
          _tableHeader(),
          const Divider(height: 1),
          ...rows.map((r) => r.buildRow()),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Expanded(child: SizedBox()),
          _headerCell('Free'),
          _headerCell('Pro', accent: true),
        ],
      ),
    );
  }

  Widget _headerCell(String label, {bool accent = false}) {
    return SizedBox(
      width: 56,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: accent ? AppTheme.accent : AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCTA() {
    if (!_iapAvailable) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'In-app purchases are not available on this device.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.warning),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _loading ? null : _subscribe,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.accent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                'Subscribe — \$6.99/month',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

class _FeatureRow {
  final String label;
  final bool free;
  final bool pro;

  const _FeatureRow(this.label, this.free, this.pro);

  Widget buildRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: AppTheme.primary)),
          ),
          _check(free),
          _check(pro, accent: true),
        ],
      ),
    );
  }

  Widget _check(bool value, {bool accent = false}) {
    return SizedBox(
      width: 56,
      child: Icon(
        value ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: value
            ? (accent ? AppTheme.accent : AppTheme.success)
            : AppTheme.fieldBorder,
        size: 20,
      ),
    );
  }
}
