import 'package:forge2d/forge2d.dart';

import '../../dat/pinball_data.dart' as dat;

/// Collision layers and material mapping shared by all table bodies.
///
/// The DAT gives every wall a collision mask (602 attribute): 1 is the
/// playfield, 2 and 4 are raised levels (ramps, upper area). The ball has
/// a mask too, and collides with walls that share a bit. In Box2D the wall
/// carries its mask as category, the ball carries its current layers as
/// mask; ramps change the ball's mask (Phase 4).
abstract final class Collision {
  /// Category bit of balls, outside the DAT's layer bits.
  static const int ballCategory = 1 << 15;

  /// The ball starts on the playfield.
  static const int playfield = 1;

  static Filter wall(int dataMask) =>
      Filter(categoryBits: dataMask, maskBits: Filter.allCategories);

  static Filter ball(int layers) =>
      Filter(categoryBits: ballCategory, maskBits: layers);

  /// Box2D's own response is switched off: no restitution, no friction,
  /// so a contact only stops the ball's approach. The table then applies
  /// the original's response to every hit (`OriginalCollision`), from the
  /// wall's DAT material.
  static SurfaceMaterial material(dat.Material m) =>
      SurfaceMaterial(restitution: 0, friction: 0);

  static SurfaceMaterial get ballMaterial =>
      SurfaceMaterial(restitution: 0, friction: 0);
}
