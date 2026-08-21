import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../core/providers/subscription_provider.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  // Debug builds must never request the live unit — impressions we generate
  // while developing count as invalid traffic and can get the AdMob account
  // suspended. Google's test unit always fills, so the banner stays visible
  // during development.
  static const _testAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const _liveAdUnitId = 'ca-app-pub-4569730514519597/3412890107';
  static String get _adUnitId => kDebugMode ? _testAdUnitId : _liveAdUnitId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _ad = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _ad = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<SubscriptionProvider>().isPro;
    if (isPro || !_loaded || _ad == null) return const SizedBox.shrink();

    return Container(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _ad!),
    );
  }
}
