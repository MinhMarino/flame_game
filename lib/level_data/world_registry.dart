import 'package:flutter/material.dart';

import 'models/level_models.dart';

/// Static registry of all world themes. Add World 7+ here without touching gameplay.
class WorldRegistry {
  WorldRegistry._();

  static const List<WorldDefinition> worlds = [
    WorldDefinition(
      id: 1,
      name: 'Kitchen',
      theme: 'kitchen',
      backgroundColor: Color(0xFFD8D8D8),
      accentColor: Color(0xFFD97706),
      surfaceColor: Color(0xFFFFF7ED),
      musicTrackId: 'music_kitchen',
      firstLevel: 1,
      lastLevel: 10,
      description: 'Beginner bugs crawling through the kitchen.',
    ),
    WorldDefinition(
      id: 2,
      name: 'Living Room',
      theme: 'living_room',
      backgroundColor: Color(0xFFE8E0F0),
      accentColor: Color(0xFF7C3AED),
      surfaceColor: Color(0xFFF5F3FF),
      musicTrackId: 'music_living_room',
      firstLevel: 11,
      lastLevel: 20,
      description: 'Faster pests hiding around the sofa.',
    ),
    WorldDefinition(
      id: 3,
      name: 'Garden',
      theme: 'garden',
      backgroundColor: Color(0xFFD1FAE5),
      accentColor: Color(0xFF059669),
      surfaceColor: Color(0xFFECFDF5),
      musicTrackId: 'music_garden',
      firstLevel: 21,
      lastLevel: 30,
      description: 'Swarms of ants and bees in the garden.',
    ),
    WorldDefinition(
      id: 4,
      name: 'Garage',
      theme: 'garage',
      backgroundColor: Color(0xFFE2E8F0),
      accentColor: Color(0xFF475569),
      surfaceColor: Color(0xFFF8FAFC),
      musicTrackId: 'music_garage',
      firstLevel: 31,
      lastLevel: 40,
      description: 'Tough enemies and relentless spawns.',
    ),
    WorldDefinition(
      id: 5,
      name: 'Laboratory',
      theme: 'laboratory',
      backgroundColor: Color(0xFFDBEAFE),
      accentColor: Color(0xFF2563EB),
      surfaceColor: Color(0xFFEFF6FF),
      musicTrackId: 'music_laboratory',
      firstLevel: 41,
      lastLevel: 50,
      description: 'Mutated bugs with complex attack patterns.',
    ),
    WorldDefinition(
      id: 6,
      name: 'Boss Challenge',
      theme: 'boss',
      backgroundColor: Color(0xFF1E1B4B),
      accentColor: Color(0xFFEF4444),
      surfaceColor: Color(0xFF312E81),
      musicTrackId: 'music_boss',
      firstLevel: 51,
      lastLevel: 60,
      description: 'Elite enemies and epic boss encounters.',
    ),
  ];

  static WorldDefinition forLevel(int levelId) {
    final worldId = ((levelId - 1) ~/ 10) + 1;
    return worlds.firstWhere((world) => world.id == worldId);
  }

  static WorldDefinition? byId(int worldId) {
    for (final world in worlds) {
      if (world.id == worldId) {
        return world;
      }
    }
    return null;
  }
}
