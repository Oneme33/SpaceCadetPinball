import 'dart:ui';

import 'package:flame/components.dart';

import '../assets/original_assets.dart';
import '../game_config.dart';

/// The original playfield and scoreboard art.
///
/// The playfield sprite is drawn at screen (0, 0) like the original
/// (`TTableLayer`). It is 470 px tall but the screen is 416: the bottom of
/// the cabinet falls outside the window, exactly as in the original.
class TableArt extends Component {
  TableArt(this.assets);

  final OriginalAssets assets;

  /// Pixel art: no smoothing when scaled up.
  static final _paint = Paint()..filterQuality = FilterQuality.none;

  late final Rect _tableSrc = Rect.fromLTWH(
    0,
    0,
    assets.table.width.toDouble(),
    GameConfig.screenHeight.clamp(0, assets.table.height).toDouble(),
  );

  late final Offset _scoreboardAt = Offset(
    assets.data.scoreboardBitmap.x.toDouble(),
    assets.data.scoreboardBitmap.y.toDouble(),
  );

  @override
  void render(Canvas canvas) {
    canvas
      ..drawImageRect(assets.table, _tableSrc, _tableSrc, _paint)
      ..drawImage(assets.scoreboard, _scoreboardAt, _paint);
  }
}
