import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const SnakeApp());

class SnakeApp extends StatelessWidget {
  const SnakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Snake',
      tagline: 'Eat, grow and survive in the arcade legend, remixed!',
      emoji: '🐍',
      slug: 'snake',
      howToPlay:
          '• Swipe anywhere (or use the d-pad) to steer the snake.\n• Gobble apples 🍎 to grow — each one is worth 10 points.\n• The snake gets FASTER with every apple. Stay sharp!\n• Hit a wall or bite your own tail and it\'s game over.\n• Your best score is saved — chase it! 🏆',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => SnakeScreen(players: players, callbacks: cb),
    );
  }
}
