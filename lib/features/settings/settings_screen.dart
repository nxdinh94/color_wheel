import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/persistence/progress_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(appProgressProvider);
    final controller = ref.read(appProgressProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          children: [
            SwitchListTile.adaptive(
              title: const Text('Sound'),
              subtitle: const Text('Soft clicks while you play'),
              value: progress.soundEnabled,
              onChanged: controller.setSound,
            ),
            SwitchListTile.adaptive(
              title: const Text('Haptics'),
              subtitle: const Text('Gentle touch feedback'),
              value: progress.hapticsEnabled,
              onChanged: controller.setHaptics,
            ),
          ],
        ),
      ),
    );
  }
}
