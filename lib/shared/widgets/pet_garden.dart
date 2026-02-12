import 'dart:math';
import 'package:flutter/material.dart';
import 'animated_monster.dart';

/// Behavior states for garden pets
enum PetBehavior {
  idle,
  walking,
  sleeping,
  playing,
  beingDragged,
}

/// Types of garden decorations
enum DecorationType {
  tree,
  bush,
  rock,
  flower,
  mushroom,
  pond,
}

/// A decoration in the garden
class GardenDecoration {
  final String id;
  final DecorationType type;
  final Offset position;
  final double size;
  final Color? color;
  final bool isObstacle; // Pets should walk around this
  
  const GardenDecoration({
    required this.id,
    required this.type,
    required this.position,
    this.size = 1.0,
    this.color,
    this.isObstacle = false,
  });
  
  /// Get the bounding box for collision detection
  Rect get bounds {
    final baseSize = _getBaseSize();
    return Rect.fromCenter(
      center: position,
      width: baseSize.width * size,
      height: baseSize.height * size,
    );
  }
  
  Size _getBaseSize() {
    switch (type) {
      case DecorationType.tree:
        return const Size(60, 80);
      case DecorationType.bush:
        return const Size(40, 30);
      case DecorationType.rock:
        return const Size(30, 20);
      case DecorationType.flower:
        return const Size(20, 30);
      case DecorationType.mushroom:
        return const Size(20, 25);
      case DecorationType.pond:
        return const Size(80, 50);
    }
  }
}

/// A pet that roams around the garden
class GardenPet {
  final String id;
  final String name;
  final MonsterType type;
  final int level;
  final int rarityLevel;
  
  Offset position;
  Offset targetPosition;
  PetBehavior behavior;
  double direction; // -1 = left, 1 = right
  int behaviorTimer;
  bool isDragging;
  int zIndex; // For layering
  
  GardenPet({
    required this.id,
    required this.name,
    required this.type,
    required this.level,
    required this.position,
    this.rarityLevel = 0,
  })  : targetPosition = position,
        behavior = PetBehavior.idle,
        direction = 1,
        behaviorTimer = 0,
        isDragging = false,
        zIndex = 0;
}

/// The garden widget where pets roam
class PetGarden extends StatefulWidget {
  final List<GardenPet> pets;
  final Function(GardenPet)? onPetTap;
  final VoidCallback? onPositionsChanged;

  const PetGarden({
    super.key,
    required this.pets,
    this.onPetTap,
    this.onPositionsChanged,
  });

  @override
  State<PetGarden> createState() => _PetGardenState();
}

class _PetGardenState extends State<PetGarden> with TickerProviderStateMixin {
  late AnimationController _tickController;
  late AnimationController _decorationAnimController;
  final Random _random = Random();
  
  Size _gardenSize = Size.zero;
  String? _draggingPetId;
  int _maxZIndex = 0;
  
  // Garden decorations - generated once based on garden size
  List<GardenDecoration> _decorations = [];
  bool _decorationsGenerated = false;

  @override
  void initState() {
    super.initState();
    
    // Game tick for updating pet positions/behaviors
    _tickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_updatePets)..repeat();
    
    // Animation controller for decorations (wind sway, etc.)
    _decorationAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tickController.dispose();
    _decorationAnimController.dispose();
    super.dispose();
  }
  
  /// Generate random decorations for the garden
  void _generateDecorations() {
    if (_decorationsGenerated || _gardenSize == Size.zero) return;
    _decorationsGenerated = true;
    
    final decorations = <GardenDecoration>[];
    
    // Add 2-3 trees
    for (int i = 0; i < 2 + _random.nextInt(2); i++) {
      decorations.add(GardenDecoration(
        id: 'tree_$i',
        type: DecorationType.tree,
        position: _randomPosition(padding: 80, avoidCenter: true),
        size: 0.8 + _random.nextDouble() * 0.4,
        isObstacle: true,
      ));
    }
    
    // Add a pond (sometimes)
    if (_random.nextDouble() > 0.5) {
      decorations.add(GardenDecoration(
        id: 'pond_0',
        type: DecorationType.pond,
        position: _randomPosition(padding: 100, avoidCenter: true),
        size: 0.9 + _random.nextDouble() * 0.3,
        isObstacle: true,
      ));
    }
    
    // Add 3-5 bushes
    for (int i = 0; i < 3 + _random.nextInt(3); i++) {
      decorations.add(GardenDecoration(
        id: 'bush_$i',
        type: DecorationType.bush,
        position: _randomPosition(padding: 50),
        size: 0.7 + _random.nextDouble() * 0.5,
        isObstacle: false,
      ));
    }
    
    // Add 2-4 rocks
    for (int i = 0; i < 2 + _random.nextInt(3); i++) {
      decorations.add(GardenDecoration(
        id: 'rock_$i',
        type: DecorationType.rock,
        position: _randomPosition(padding: 40),
        size: 0.6 + _random.nextDouble() * 0.6,
        isObstacle: false,
      ));
    }
    
    // Add 5-8 flowers
    final flowerColors = [
      Colors.pink.shade300,
      Colors.yellow.shade400,
      Colors.purple.shade300,
      Colors.red.shade300,
      Colors.orange.shade300,
      Colors.blue.shade300,
    ];
    for (int i = 0; i < 5 + _random.nextInt(4); i++) {
      decorations.add(GardenDecoration(
        id: 'flower_$i',
        type: DecorationType.flower,
        position: _randomPosition(padding: 30),
        size: 0.8 + _random.nextDouble() * 0.4,
        color: flowerColors[_random.nextInt(flowerColors.length)],
      ));
    }
    
    // Add 2-4 mushrooms
    for (int i = 0; i < 2 + _random.nextInt(3); i++) {
      decorations.add(GardenDecoration(
        id: 'mushroom_$i',
        type: DecorationType.mushroom,
        position: _randomPosition(padding: 30),
        size: 0.7 + _random.nextDouble() * 0.5,
        color: _random.nextBool() ? Colors.red : Colors.brown.shade300,
      ));
    }
    
    _decorations = decorations;
  }
  
  Offset _randomPosition({double padding = 50, bool avoidCenter = false}) {
    double x, y;
    int attempts = 0;
    
    do {
      x = padding + _random.nextDouble() * (_gardenSize.width - padding * 2);
      y = padding + _random.nextDouble() * (_gardenSize.height - padding * 2 - 60);
      attempts++;
      
      // Avoid center area if requested (for large decorations)
      if (avoidCenter) {
        final centerX = _gardenSize.width / 2;
        final centerY = _gardenSize.height / 2;
        if ((x - centerX).abs() < 100 && (y - centerY).abs() < 80) {
          continue;
        }
      }
      break;
    } while (attempts < 20);
    
    return Offset(x, y);
  }

  void _updatePets() {
    if (_gardenSize == Size.zero) return;
    
    bool needsUpdate = false;
    
    for (final pet in widget.pets) {
      // Skip behavior updates for dragged pet
      if (pet.isDragging) continue;
      
      final oldPosition = pet.position;
      final oldBehavior = pet.behavior;
      
      _updatePetBehavior(pet);
      _updatePetPosition(pet);
      
      if (oldPosition != pet.position || oldBehavior != pet.behavior) {
        needsUpdate = true;
      }
    }
    
    if (needsUpdate) {
      setState(() {});
    }
  }

  void _updatePetBehavior(GardenPet pet) {
    pet.behaviorTimer--;
    
    if (pet.behaviorTimer <= 0) {
      // Choose new behavior
      final roll = _random.nextDouble();
      
      if (roll < 0.4) {
        // Idle
        pet.behavior = PetBehavior.idle;
        pet.behaviorTimer = 60 + _random.nextInt(120); // 3-9 seconds
      } else if (roll < 0.75) {
        // Walk to new position
        pet.behavior = PetBehavior.walking;
        pet.behaviorTimer = 80 + _random.nextInt(100); // 4-9 seconds
        
        // Pick random target within bounds, avoiding obstacles
        pet.targetPosition = _findValidTargetPosition();
        
        // Update direction based on target
        if (pet.targetPosition.dx < pet.position.dx) {
          pet.direction = -1;
        } else {
          pet.direction = 1;
        }
      } else if (roll < 0.9) {
        // Sleep
        pet.behavior = PetBehavior.sleeping;
        pet.behaviorTimer = 100 + _random.nextInt(150); // 5-12 seconds
      } else {
        // Play (bounce around)
        pet.behavior = PetBehavior.playing;
        pet.behaviorTimer = 40 + _random.nextInt(60); // 2-5 seconds
      }
    }
  }
  
  /// Find a valid position that doesn't collide with obstacles
  Offset _findValidTargetPosition() {
    const padding = 50.0;
    int attempts = 0;
    
    while (attempts < 15) {
      final candidate = Offset(
        padding + _random.nextDouble() * (_gardenSize.width - padding * 2 - 60),
        padding + _random.nextDouble() * (_gardenSize.height - padding * 2 - 60),
      );
      
      // Check if this position collides with any obstacle
      bool collides = false;
      for (final dec in _decorations) {
        if (dec.isObstacle) {
          final petBounds = Rect.fromCenter(center: candidate, width: 60, height: 60);
          if (petBounds.overlaps(dec.bounds)) {
            collides = true;
            break;
          }
        }
      }
      
      if (!collides) return candidate;
      attempts++;
    }
    
    // Fallback: return center-ish position
    return Offset(_gardenSize.width / 2, _gardenSize.height / 2);
  }

  void _updatePetPosition(GardenPet pet) {
    if (pet.behavior == PetBehavior.walking) {
      // Move towards target
      final dx = pet.targetPosition.dx - pet.position.dx;
      final dy = pet.targetPosition.dy - pet.position.dy;
      final distance = sqrt(dx * dx + dy * dy);
      
      if (distance > 2) {
        const speed = 1.5;
        pet.position = Offset(
          pet.position.dx + (dx / distance) * speed,
          pet.position.dy + (dy / distance) * speed,
        );
      } else {
        // Reached target, go idle
        pet.behavior = PetBehavior.idle;
        pet.behaviorTimer = 30 + _random.nextInt(60);
      }
    } else if (pet.behavior == PetBehavior.playing) {
      // Bouncy movement
      pet.position = Offset(
        pet.position.dx + _random.nextDouble() * 4 - 2,
        pet.position.dy + _random.nextDouble() * 4 - 2,
      );
      
      // Keep in bounds
      pet.position = Offset(
        pet.position.dx.clamp(20, _gardenSize.width - 80),
        pet.position.dy.clamp(20, _gardenSize.height - 80),
      );
    }
  }

  void _onPetDragStart(GardenPet pet, DragStartDetails details) {
    setState(() {
      pet.isDragging = true;
      pet.behavior = PetBehavior.beingDragged;
      _draggingPetId = pet.id;
      
      // Bring to front by increasing z-index
      _maxZIndex++;
      pet.zIndex = _maxZIndex;
    });
  }

  void _onPetDragUpdate(GardenPet pet, DragUpdateDetails details) {
    if (pet.id != _draggingPetId) return; // Only update the pet we started dragging
    
    setState(() {
      // Update position with drag delta
      pet.position = Offset(
        (pet.position.dx + details.delta.dx).clamp(10, _gardenSize.width - 70),
        (pet.position.dy + details.delta.dy).clamp(10, _gardenSize.height - 100),
      );
      
      // Update direction based on drag direction
      if (details.delta.dx < -1) {
        pet.direction = -1;
      } else if (details.delta.dx > 1) {
        pet.direction = 1;
      }
    });
  }

  void _onPetDragEnd(GardenPet pet, DragEndDetails details) {
    if (pet.id != _draggingPetId) return; // Only end drag for the pet we started dragging
    
    setState(() {
      pet.isDragging = false;
      pet.behavior = PetBehavior.idle;
      pet.behaviorTimer = 60 + _random.nextInt(60); // Stay idle for a bit after drop
      _draggingPetId = null;
    });
    
    // Notify that positions changed (for persistence)
    widget.onPositionsChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _gardenSize = Size(constraints.maxWidth, constraints.maxHeight);
        
        // Generate decorations once we know the garden size
        _generateDecorations();
        
        // Initialize pet positions if needed
        for (final pet in widget.pets) {
          if (pet.position == Offset.zero) {
            pet.position = _findValidTargetPosition();
          }
        }

        // Sort pets by z-index for proper layering
        final sortedPets = List<GardenPet>.from(widget.pets)
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
        
        // Sort decorations by y position for depth effect
        final sortedDecorations = List<GardenDecoration>.from(_decorations)
          ..sort((a, b) => a.position.dy.compareTo(b.position.dy));

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF87CEEB), // Sky blue at top
                Color(0xFF98D8AA), // Light green
                Color(0xFF4a7a4a), // Darker grass at bottom
              ],
              stops: [0.0, 0.3, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Sky decorations (clouds, sun)
              ..._buildSkyDecorations(),
              
              // Background decorations (trees, large objects)
              ...sortedDecorations
                  .where((d) => d.type == DecorationType.tree || d.type == DecorationType.pond)
                  .map((d) => _buildDecoration(d)),
              
              // Ground decorations (bushes, rocks, flowers, mushrooms)
              ...sortedDecorations
                  .where((d) => d.type != DecorationType.tree && d.type != DecorationType.pond)
                  .map((d) => _buildDecoration(d)),
              
              // Pets (sorted by z-index)
              ...sortedPets.map((pet) => _buildPetWidget(pet)),
              
              // Foreground grass
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(child: _buildForegroundGrass()),
              ),
              
              // Drag hint
              if (_draggingPetId == null && widget.pets.isNotEmpty)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_rounded, color: Colors.white54, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Tap pets for info • Drag to move',
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  List<Widget> _buildSkyDecorations() {
    return [
      // Sun
      Positioned(
        top: 20,
        right: 30,
        child: AnimatedBuilder(
          animation: _decorationAnimController,
          builder: (context, child) {
            return Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.yellow.shade300,
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.3 + _decorationAnimController.value * 0.2),
                    blurRadius: 20 + _decorationAnimController.value * 10,
                    spreadRadius: 5 + _decorationAnimController.value * 5,
                  ),
                ],
              ),
            );
          },
        ),
      ),
      // Clouds
      _buildCloud(left: 50, top: 30, scale: 1.0),
      _buildCloud(left: 200, top: 50, scale: 0.7),
      if (_gardenSize.width > 400)
        _buildCloud(left: _gardenSize.width - 150, top: 40, scale: 0.8),
    ];
  }
  
  Widget _buildCloud({required double left, required double top, required double scale}) {
    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: _decorationAnimController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_decorationAnimController.value * 5, 0),
            child: Opacity(
              opacity: 0.8,
              child: Transform.scale(
                scale: scale,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(-10, -5),
                      child: Container(
                        width: 40,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(-20, 0),
                      child: Container(
                        width: 25,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDecoration(GardenDecoration decoration) {
    Widget child;
    
    switch (decoration.type) {
      case DecorationType.tree:
        child = _buildTree(decoration);
      case DecorationType.bush:
        child = _buildBush(decoration);
      case DecorationType.rock:
        child = _buildRock(decoration);
      case DecorationType.flower:
        child = _buildFlower(decoration);
      case DecorationType.mushroom:
        child = _buildMushroom(decoration);
      case DecorationType.pond:
        child = _buildPond(decoration);
    }
    
    return Positioned(
      left: decoration.position.dx - (decoration.bounds.width / 2),
      top: decoration.position.dy - (decoration.bounds.height / 2),
      child: child,
    );
  }
  
  Widget _buildTree(GardenDecoration dec) {
    final size = dec.size;
    return AnimatedBuilder(
      animation: _decorationAnimController,
      builder: (context, child) {
        return Transform.rotate(
          angle: sin(_decorationAnimController.value * pi * 2) * 0.02,
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 60 * size,
            height: 90 * size,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Trunk
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 15 * size,
                    height: 35 * size,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D4037),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // Foliage layers
                Positioned(
                  bottom: 25 * size,
                  child: Container(
                    width: 55 * size,
                    height: 40 * size,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 45 * size,
                  child: Container(
                    width: 45 * size,
                    height: 35 * size,
                    decoration: BoxDecoration(
                      color: const Color(0xFF388E3C),
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 60 * size,
                  child: Container(
                    width: 30 * size,
                    height: 25 * size,
                    decoration: BoxDecoration(
                      color: const Color(0xFF43A047),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildBush(GardenDecoration dec) {
    final size = dec.size;
    return AnimatedBuilder(
      animation: _decorationAnimController,
      builder: (context, child) {
        return Transform.scale(
          scaleX: 1.0 + sin(_decorationAnimController.value * pi * 2) * 0.02,
          child: SizedBox(
            width: 40 * size,
            height: 25 * size,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(
                    width: 25 * size,
                    height: 20 * size,
                    decoration: BoxDecoration(
                      color: const Color(0xFF558B2F),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 22 * size,
                    height: 18 * size,
                    decoration: BoxDecoration(
                      color: const Color(0xFF689F38),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  left: 10 * size,
                  bottom: 5 * size,
                  child: Container(
                    width: 20 * size,
                    height: 22 * size,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7CB342),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildRock(GardenDecoration dec) {
    final size = dec.size;
    return Container(
      width: 25 * size,
      height: 18 * size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade400,
            Colors.grey.shade600,
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12 * size),
          topRight: Radius.circular(8 * size),
          bottomLeft: Radius.circular(10 * size),
          bottomRight: Radius.circular(14 * size),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFlower(GardenDecoration dec) {
    final size = dec.size;
    final color = dec.color ?? Colors.pink;
    
    return AnimatedBuilder(
      animation: _decorationAnimController,
      builder: (context, child) {
        return Transform.rotate(
          angle: sin(_decorationAnimController.value * pi * 2) * 0.1,
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 20 * size,
            height: 30 * size,
            child: CustomPaint(
              painter: _FlowerPainter(color: color, size: size),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMushroom(GardenDecoration dec) {
    final size = dec.size;
    final isRed = dec.color == Colors.red;
    
    return SizedBox(
      width: 20 * size,
      height: 25 * size,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Stem
          Positioned(
            bottom: 0,
            child: Container(
              width: 8 * size,
              height: 12 * size,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Cap
          Positioned(
            bottom: 8 * size,
            child: Container(
              width: 18 * size,
              height: 14 * size,
              decoration: BoxDecoration(
                color: isRed ? Colors.red.shade600 : Colors.brown.shade400,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10 * size),
                  topRight: Radius.circular(10 * size),
                  bottomLeft: Radius.circular(4 * size),
                  bottomRight: Radius.circular(4 * size),
                ),
              ),
            ),
          ),
          // Spots (if red mushroom)
          if (isRed) ...[
            Positioned(
              bottom: 14 * size,
              left: 4 * size,
              child: Container(
                width: 4 * size,
                height: 4 * size,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 12 * size,
              right: 5 * size,
              child: Container(
                width: 3 * size,
                height: 3 * size,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildPond(GardenDecoration dec) {
    final size = dec.size;
    
    return AnimatedBuilder(
      animation: _decorationAnimController,
      builder: (context, child) {
        return SizedBox(
          width: 80 * size,
          height: 45 * size,
          child: Stack(
            children: [
              // Water base
              Container(
                width: 80 * size,
                height: 45 * size,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.blue.shade300,
                      Colors.blue.shade500,
                      Colors.blue.shade700,
                    ],
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(40 * size, 22 * size),
                  ),
                  border: Border.all(
                    color: Colors.brown.shade400,
                    width: 3,
                  ),
                ),
              ),
              // Ripple effect
              Center(
                child: Container(
                  width: (30 + _decorationAnimController.value * 15) * size,
                  height: (15 + _decorationAnimController.value * 8) * size,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3 - _decorationAnimController.value * 0.2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(20 * size, 10 * size),
                    ),
                  ),
                ),
              ),
              // Lily pad
              Positioned(
                right: 15 * size,
                top: 15 * size,
                child: Container(
                  width: 15 * size,
                  height: 12 * size,
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(8 * size, 6 * size),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildForegroundGrass() {
    return SizedBox(
      height: 30,
      child: CustomPaint(
        size: Size(_gardenSize.width, 30),
        painter: _ForegroundGrassPainter(),
      ),
    );
  }

  Widget _buildPetWidget(GardenPet pet) {
    final isDragging = pet.isDragging;
    final isAnotherPetBeingDragged = _draggingPetId != null && _draggingPetId != pet.id;
    
    return Positioned(
      key: ValueKey(pet.id), // Important: stable key prevents widget rebuild issues
      left: pet.position.dx,
      top: pet.position.dy,
      child: IgnorePointer(
        // Ignore pointer on other pets while dragging one
        ignoring: isAnotherPetBeingDragged,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_draggingPetId == null) {
              widget.onPetTap?.call(pet);
            }
          },
          onPanStart: (details) => _onPetDragStart(pet, details),
          onPanUpdate: (details) => _onPetDragUpdate(pet, details),
          onPanEnd: (details) => _onPetDragEnd(pet, details),
          child: AnimatedScale(
            scale: isDragging ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: isDragging
                  ? BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    )
                  : null,
              child: Opacity(
                opacity: isAnotherPetBeingDragged ? 0.6 : 1.0,
                child: _GardenPetWidget(pet: pet),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GardenPetWidget extends StatelessWidget {
  final GardenPet pet;

  const _GardenPetWidget({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: pet.isDragging ? Colors.black87 : Colors.black54,
            borderRadius: BorderRadius.circular(8),
            border: pet.isDragging 
                ? Border.all(color: Colors.white30, width: 1)
                : null,
          ),
          child: Text(
            pet.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        // Pet with behavior animation
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(pet.direction, 1.0),
          child: _buildPetWithBehavior(),
        ),
        // Shadow (smaller when dragging since pet is "lifted")
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: pet.isDragging ? 30 : 40,
          height: pet.isDragging ? 6 : 10,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(pet.isDragging ? 0.15 : 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }

  Widget _buildPetWithBehavior() {
    Widget monster = AnimatedMonster(
      type: pet.type,
      size: 50,
      rarityLevel: pet.rarityLevel,
    );

    switch (pet.behavior) {
      case PetBehavior.sleeping:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Opacity(opacity: 0.7, child: monster),
            const Positioned(
              top: -5,
              right: -5,
              child: Text('💤', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      case PetBehavior.playing:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            monster,
            const Positioned(
              top: -8,
              right: -5,
              child: Text('✨', style: TextStyle(fontSize: 14)),
            ),
          ],
        );
      case PetBehavior.beingDragged:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            monster,
            const Positioned(
              top: -10,
              left: 0,
              right: 0,
              child: Center(
                child: Text('😊', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        );
      case PetBehavior.walking:
      case PetBehavior.idle:
      default:
        return monster;
    }
  }
}

// Custom painters for decorations
class _FlowerPainter extends CustomPainter {
  final Color color;
  final double size;
  _FlowerPainter({required this.color, this.size = 1.0});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final stemPaint = Paint()
      ..color = const Color(0xFF3a6a3a)
      ..strokeWidth = 2 * size
      ..style = PaintingStyle.stroke;

    // Stem
    canvas.drawLine(
      Offset(canvasSize.width / 2, canvasSize.height),
      Offset(canvasSize.width / 2, canvasSize.height * 0.4),
      stemPaint,
    );

    // Petals
    final petalPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(canvasSize.width / 2, canvasSize.height * 0.3);
    for (int i = 0; i < 5; i++) {
      final angle = i * 3.14159 * 2 / 5;
      final petalCenter = Offset(
        center.dx + cos(angle) * 5 * size,
        center.dy + sin(angle) * 5 * size,
      );
      canvas.drawCircle(petalCenter, 4 * size, petalPaint);
    }

    // Center
    canvas.drawCircle(center, 3 * size, Paint()..color = Colors.yellow.shade600);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ForegroundGrassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3d6b3d)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    
    for (double x = 0; x < size.width; x += 15) {
      path.lineTo(x, size.height - 10 - (x % 30 == 0 ? 15 : 8));
      path.lineTo(x + 7, size.height);
    }
    
    path.lineTo(size.width, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
