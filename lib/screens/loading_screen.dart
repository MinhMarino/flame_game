import 'package:flutter/material.dart';

import '../services/asset_preloader.dart';
import 'home_screen.dart';

/// First screen the app shows. Decodes every image/audio asset up front so
/// the very first level and every level after it start lag-free instead of
/// hitching the first time a new sprite/sound is used mid-gameplay.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _preload();
  }

  Future<void> _preload() async {
    // Keep the splash up for a minimum stretch even if loading finishes
    // instantly (e.g. assets already warm from a previous run) so it never
    // flashes by unreadably - and run the real preload alongside it.
    final minDisplay = Future<void>.delayed(const Duration(milliseconds: 400));
    await Future.wait([
      AssetPreloader.preloadAll(
        onProgress: (p) {
          if (mounted) {
            setState(() => _progress = p);
          }
        },
      ),
      minDisplay,
    ]);

    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1F2937), Color(0xFF111827)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Ant Smasher',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading assets… ${(_progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
