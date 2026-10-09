import 'package:flutter/material.dart';

/// Theme, snake-style and food-style catalogs for Snake.
///
/// The art direction is a handcrafted meadow: carved wooden frames, polished
/// toy-like snake bodies, juicy orchard fruit. Every theme stays inside this
/// physical world — the variety comes from different seasons, woods, fruits
/// and creature patterns. No neon, no cyberpunk, no dashboard looks.
class GardenThemeDef {
  final String id;
  final String name;
  final Color backdropDark;
  final Color backdropMid;
  final Color boardLight;
  final Color boardDark;
  final Color frame;
  final Color frameEdge;
  final Color accent;
  final Color accentLight;
  final Color accentDark;
  final Color ink;
  final Color inkDim;
  final Color snakeHead;
  final Color snakeBody;
  final Color food;
  final Color golden;

  const GardenThemeDef({
    required this.id,
    required this.name,
    required this.backdropDark,
    required this.backdropMid,
    required this.boardLight,
    required this.boardDark,
    required this.frame,
    required this.frameEdge,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.ink,
    required this.inkDim,
    required this.snakeHead,
    required this.snakeBody,
    required this.food,
    required this.golden,
  });
}

class GardenThemes {
  /// First 4 are the FREE starter themes. The rest are PRO.
  static const List<String> freeThemeIds = [
    'garden',
    'orchard',
    'night',
    'harvest',
  ];

  static const List<GardenThemeDef> all = [
    GardenThemeDef(
      id: 'garden',
      name: 'Garden Classic',
      backdropDark: Color(0xFF17230F),
      backdropMid: Color(0xFF243818),
      boardLight: Color(0xFF8FBF5F),
      boardDark: Color(0xFF7DB04E),
      frame: Color(0xFF5C3A21),
      frameEdge: Color(0xFF3B2416),
      accent: Color(0xFFD9A62B),
      accentLight: Color(0xFFF2CE6B),
      accentDark: Color(0xFF8A6717),
      ink: Color(0xFFF6F1DF),
      inkDim: Color(0xFFD6CBA8),
      snakeHead: Color(0xFF3FA34D),
      snakeBody: Color(0xFF2E7D3A),
      food: Color(0xFFD64545),
      golden: Color(0xFFFFD23F),
    ),
    GardenThemeDef(
      id: 'orchard',
      name: 'Apple Orchard',
      backdropDark: Color(0xFF1E2A12),
      backdropMid: Color(0xFF2E421C),
      boardLight: Color(0xFFA8C66B),
      boardDark: Color(0xFF96B357),
      frame: Color(0xFF6E4A2A),
      frameEdge: Color(0xFF4A2E17),
      accent: Color(0xFFC93B3B),
      accentLight: Color(0xFFEE7B6B),
      accentDark: Color(0xFF8A2626),
      ink: Color(0xFFF8F2E2),
      inkDim: Color(0xFFD9CFAE),
      snakeHead: Color(0xFF58B04C),
      snakeBody: Color(0xFF3D8A36),
      food: Color(0xFFB83030),
      golden: Color(0xFFFFD23F),
    ),
    GardenThemeDef(
      id: 'night',
      name: 'Night Meadow',
      backdropDark: Color(0xFF0C1520),
      backdropMid: Color(0xFF16242F),
      boardLight: Color(0xFF3E5A66),
      boardDark: Color(0xFF35505C),
      frame: Color(0xFF2A2A30),
      frameEdge: Color(0xFF17171B),
      accent: Color(0xFFF2CE6B),
      accentLight: Color(0xFFFFE5A0),
      accentDark: Color(0xFFA8812E),
      ink: Color(0xFFEEF2F5),
      inkDim: Color(0xFFB9C4CC),
      snakeHead: Color(0xFF6FC06F),
      snakeBody: Color(0xFF3F8A5A),
      food: Color(0xFFE86A6A),
      golden: Color(0xFFFFD23F),
    ),
    GardenThemeDef(
      id: 'harvest',
      name: 'Harvest Field',
      backdropDark: Color(0xFF2B2210),
      backdropMid: Color(0xFF42331A),
      boardLight: Color(0xFFD9B96B),
      boardDark: Color(0xFFCBA95C),
      frame: Color(0xFF7A5230),
      frameEdge: Color(0xFF4E3319),
      accent: Color(0xFFB87333),
      accentLight: Color(0xFFE09E5A),
      accentDark: Color(0xFF7E4F22),
      ink: Color(0xFFFBF4E0),
      inkDim: Color(0xFFE0D2A8),
      snakeHead: Color(0xFF5A8A3C),
      snakeBody: Color(0xFF41682A),
      food: Color(0xFFA31621),
      golden: Color(0xFFFFD23F),
    ),
    GardenThemeDef(
      id: 'berry',
      name: 'Berry Patch',
      backdropDark: Color(0xFF231018),
      backdropMid: Color(0xFF381A26),
      boardLight: Color(0xFF9E6B7E),
      boardDark: Color(0xFF8F5C6F),
      frame: Color(0xFF4A2E3F),
      frameEdge: Color(0xFF2E1B26),
      accent: Color(0xFFD48A9E),
      accentLight: Color(0xFFEFB4C4),
      accentDark: Color(0xFF96556A),
      ink: Color(0xFFF9EDF2),
      inkDim: Color(0xFFDCC3CE),
      snakeHead: Color(0xFF4E8F5A),
      snakeBody: Color(0xFF356E40),
      food: Color(0xFF7D1F3E),
      golden: Color(0xFFFFD23F),
    ),
    GardenThemeDef(
      id: 'pine',
      name: 'Pine Forest',
      backdropDark: Color(0xFF101C16),
      backdropMid: Color(0xFF182C20),
      boardLight: Color(0xFF5E7D63),
      boardDark: Color(0xFF506E56),
      frame: Color(0xFF3E3226),
      frameEdge: Color(0xFF26201A),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ink: Color(0xFFF1EDE0),
      inkDim: Color(0xFFC4BCA4),
      snakeHead: Color(0xFF7FB04C),
      snakeBody: Color(0xFF5A8A36),
      food: Color(0xFFD64545),
      golden: Color(0xFFFFD23F),
    ),
    GardenThemeDef(
      id: 'desert',
      name: 'Desert Dune',
      backdropDark: Color(0xFF2E2114),
      backdropMid: Color(0xFF4A3A20),
      boardLight: Color(0xFFE3C084),
      boardDark: Color(0xFFD6AE72),
      frame: Color(0xFF7A5A34),
      frameEdge: Color(0xFF4E3A1E),
      accent: Color(0xFFB8541E),
      accentLight: Color(0xFFE08A4E),
      accentDark: Color(0xFF7E3A12),
      ink: Color(0xFF2E2114),
      inkDim: Color(0xFF5C4A30),
      snakeHead: Color(0xFF6E8A3C),
      snakeBody: Color(0xFF526A2A),
      food: Color(0xFFA31621),
      golden: Color(0xFFFFD23F),
    ),
    GardenThemeDef(
      id: 'blossom',
      name: 'Cherry Blossom',
      backdropDark: Color(0xFF2A1A20),
      backdropMid: Color(0xFF432A34),
      boardLight: Color(0xFFE8B4C0),
      boardDark: Color(0xFFDDA2B0),
      frame: Color(0xFF5C3A2E),
      frameEdge: Color(0xFF3A2419),
      accent: Color(0xFFC94B6B),
      accentLight: Color(0xFFEE8FA6),
      accentDark: Color(0xFF8A2E44),
      ink: Color(0xFFFBF1F4),
      inkDim: Color(0xFFE2C4CC),
      snakeHead: Color(0xFF58A05A),
      snakeBody: Color(0xFF3F7A42),
      food: Color(0xFFB83030),
      golden: Color(0xFFFFD23F),
    ),
    GardenThemeDef(
      id: 'reef',
      name: 'Reef Shore',
      backdropDark: Color(0xFF0F2230),
      backdropMid: Color(0xFF18364A),
      boardLight: Color(0xFF6BA8B8),
      boardDark: Color(0xFF5C97A8),
      frame: Color(0xFF5E4630),
      frameEdge: Color(0xFF3A2C1C),
      accent: Color(0xFFD9A62B),
      accentLight: Color(0xFFF2CE6B),
      accentDark: Color(0xFF8A6717),
      ink: Color(0xFFF0F5F7),
      inkDim: Color(0xFFBDD2D9),
      snakeHead: Color(0xFF4EA88A),
      snakeBody: Color(0xFF368A6E),
      food: Color(0xFFD64545),
      golden: Color(0xFFFFD23F),
    ),
    GardenThemeDef(
      id: 'mushroom',
      name: 'Mushroom Grove',
      backdropDark: Color(0xFF1C1410),
      backdropMid: Color(0xFF2E231A),
      boardLight: Color(0xFFA8885F),
      boardDark: Color(0xFF977750),
      frame: Color(0xFF5C3A21),
      frameEdge: Color(0xFF3B2416),
      accent: Color(0xFFD64545),
      accentLight: Color(0xFFEE7B6B),
      accentDark: Color(0xFF8A2626),
      ink: Color(0xFFF7F0E2),
      inkDim: Color(0xFFD5C4A6),
      snakeHead: Color(0xFF8A6A4E),
      snakeBody: Color(0xFF6A4E36),
      food: Color(0xFFE8E0D0),
      golden: Color(0xFFFFD23F),
    ),
    GardenThemeDef(
      id: 'cocoa',
      name: 'Cocoa & Cream',
      backdropDark: Color(0xFF241811),
      backdropMid: Color(0xFF3A2718),
      boardLight: Color(0xFFC9A87A),
      boardDark: Color(0xFFBA9868),
      frame: Color(0xFF3B2416),
      frameEdge: Color(0xFF241309),
      accent: Color(0xFFF2CE6B),
      accentLight: Color(0xFFFFE5A0),
      accentDark: Color(0xFFA8812E),
      ink: Color(0xFFF8F1E2),
      inkDim: Color(0xFFDCCAA8),
      snakeHead: Color(0xFF8A6A4E),
      snakeBody: Color(0xFF6E5238),
      food: Color(0xFF7D1F3E),
      golden: Color(0xFFFFD23F),
    ),
    GardenThemeDef(
      id: 'clover',
      name: 'Clover Field',
      backdropDark: Color(0xFF0F240F),
      backdropMid: Color(0xFF1A3A1A),
      boardLight: Color(0xFF7DC47D),
      boardDark: Color(0xFF6EB46E),
      frame: Color(0xFF4A5A2A),
      frameEdge: Color(0xFF2E3A18),
      accent: Color(0xFFF2CE6B),
      accentLight: Color(0xFFFFE5A0),
      accentDark: Color(0xFFA8812E),
      ink: Color(0xFFF2F8F0),
      inkDim: Color(0xFFC2D8C0),
      snakeHead: Color(0xFF3FA34D),
      snakeBody: Color(0xFF2E7D3A),
      food: Color(0xFFD64545),
      golden: Color(0xFFFFD23F),
    ),
    GardenThemeDef(
      id: 'ember',
      name: 'Ember Garden',
      backdropDark: Color(0xFF20120C),
      backdropMid: Color(0xFF38200F),
      boardLight: Color(0xFFA87A5A),
      boardDark: Color(0xFF986C4E),
      frame: Color(0xFF4A2A1A),
      frameEdge: Color(0xFF2E190C),
      accent: Color(0xFFE86A2A),
      accentLight: Color(0xFFF59A5A),
      accentDark: Color(0xFFA8451A),
      ink: Color(0xFFF8F0E4),
      inkDim: Color(0xFFDCC8AE),
      snakeHead: Color(0xFFB8541E),
      snakeBody: Color(0xFF8A3E14),
      food: Color(0xFF4EA84C),
      golden: Color(0xFFFFD23F),
    ),
    GardenThemeDef(
      id: 'frost',
      name: 'Frost Morning',
      backdropDark: Color(0xFF1A2530),
      backdropMid: Color(0xFF2A3E50),
      boardLight: Color(0xFFB8CCD8),
      boardDark: Color(0xFFA8BDCB),
      frame: Color(0xFF3E4E5E),
      frameEdge: Color(0xFF26303C),
      accent: Color(0xFF5E9AC0),
      accentLight: Color(0xFF9AC8E8),
      accentDark: Color(0xFF3A6A8A),
      ink: Color(0xFFF2F6FA),
      inkDim: Color(0xFFC2D0DC),
      snakeHead: Color(0xFF4E8F7A),
      snakeBody: Color(0xFF38705E),
      food: Color(0xFFB83030),
      golden: Color(0xFFFFD23F),
    ),
    GardenThemeDef(
      id: 'sunset',
      name: 'Orchard Sunset',
      backdropDark: Color(0xFF2A1A2E),
      backdropMid: Color(0xFF46283C),
      boardLight: Color(0xFFD89A6B),
      boardDark: Color(0xFFCB885C),
      frame: Color(0xFF5C3A2E),
      frameEdge: Color(0xFF3A2419),
      accent: Color(0xFFF2CE6B),
      accentLight: Color(0xFFFFE5A0),
      accentDark: Color(0xFFA8812E),
      ink: Color(0xFFF9F0E6),
      inkDim: Color(0xFFE0C8B0),
      snakeHead: Color(0xFF7A9A3C),
      snakeBody: Color(0xFF5A762A),
      food: Color(0xFFB83030),
      golden: Color(0xFFFFD23F),
    ),
  ];

  static GardenThemeDef byId(String id, {GardenThemeDef? custom}) {
    if (id == 'custom') return custom ?? all.first;
    return all.firstWhere((t) => t.id == id, orElse: () => all.first);
  }

  static bool isProTheme(String id) =>
      !freeThemeIds.contains(id) && id != 'custom';
}

/// Snake body styles. 0-2 = FREE, 3+ = PRO.
class SnakeStyles {
  static const names = [
    'Garden Green',
    'Emerald Stripe',
    'Crimson Viper',
    'Cobalt Racer',
    'Honey Stripe',
    'Stone Python',
    'Amethyst Coil',
    'Onyx Slither',
    'River Teal',
    'Sunbeam',
  ];
  static const descriptions = [
    'Classic glossy garden snake',
    'Bold striped racer',
    'Red-banded wild viper',
    'Blue lightning stripes',
    'Golden honey bands',
    'Stone-scaled python',
    'Royal purple coil',
    'Shadow-black serpent',
    'Cool river teal',
    'Warm sunbeam stripes',
  ];

  /// Style indices free players may use.
  static const freeCount = 3;
  static bool isPro(int index) => index >= freeCount;

  static const List<Color> heads = [
    Color(0xFF3FA34D),
    Color(0xFF2FA060),
    Color(0xFFB03A2E),
    Color(0xFF2E6FD8),
    Color(0xFFD9A62B),
    Color(0xFF7A6A58),
    Color(0xFF8A5FB0),
    Color(0xFF3A3A44),
    Color(0xFF2E9E9A),
    Color(0xFFE8A83C),
  ];
  static const List<Color> bodies = [
    Color(0xFF2E7D3A),
    Color(0xFF1F7A48),
    Color(0xFF8A241D),
    Color(0xFF1F4FA0),
    Color(0xFFA67C1B),
    Color(0xFF5C4E40),
    Color(0xFF6A4688),
    Color(0xFF26262E),
    Color(0xFF1F7A76),
    Color(0xFFC07E24),
  ];

  /// Paint pattern per style: 0 plain, 1 stripes, 2 scales, 3 rings.
  static const List<int> patterns = [0, 1, 0, 1, 1, 2, 0, 3, 0, 1];
}

/// Food styles. 0-2 = FREE, 3+ = PRO. The golden bonus food always renders
/// golden, in every style.
class FoodStyles {
  static const names = [
    'Red Apple',
    'Cherry',
    'Blueberry',
    'Star Fruit',
    'Honey Cookie',
    'Mushroom',
    'Emerald Gem',
    'Leaf Sprout',
  ];
  static const descriptions = [
    'Classic orchard apple',
    'Twin garden cherries',
    'Blueberry bunch',
    'Golden star fruit',
    'Sweet honey cookie',
    'Forest mushroom',
    'Polished emerald gem',
    'Fresh leaf sprout',
  ];

  /// Style indices free players may use.
  static const freeCount = 3;
  static bool isPro(int index) => index >= freeCount;
}
