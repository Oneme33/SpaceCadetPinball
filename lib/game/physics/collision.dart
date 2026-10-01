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

  /// The original's material on the wall side of a contact.
  ///
  /// Elasticity is a restitution coefficient. Smoothness is how much of the
  /// tangential speed survives a hit, so friction is roughly its
  /// complement. Box2D mixes friction as sqrt(a·b) and restitution as
  /// max(a, b); the ball uses friction 1 and restitution 0, so walls store
  /// friction squared to come out at (1 − smoothness).
  ///
  /// TODO: VERIFY AGAINST ORIGINAL SPACE CADET — tune in Phase 8; the
  /// original's collision response is not a Coulomb model.
  static SurfaceMaterial material(dat.Material m) {
    final friction = 1 - m.smoothness;
    return SurfaceMaterial(
      restitution: m.elasticity,
      friction: friction * friction,
    );
  }

  static SurfaceMaterial get ballMaterial =>
      SurfaceMaterial(restitution: 0, friction: 1);
}
