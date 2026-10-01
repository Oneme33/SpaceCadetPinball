import 'dart:ui';

import 'package:flame/components.dart';

import '../assets/original_assets.dart';
import '../game_config.dart';
import '../graphics.dart';

/// The original playfield and scoreboard art.
///
/// The playfield sprite is drawn at screen (0, 0) like the original
/// (`TTableLayer`). It is 470 px tall but the screen is 416: the bottom of
/// the cabinet falls outside the window, exactly as in the original.
class TableArt extends Component {
  TableArt(this.assets, this.graphics);

  final OriginalAssets assets;
  final Graphics graphics;

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
    final data = assets.data;
    graphics
      ..drawBitmapRect(
        canvas,
        assets.table,
        data.tableGroup,
        _tableSrc,
        _tableSrc,
      )
      ..drawBitmap(
        canvas,
        assets.scoreboard,
        data.dat.indexOf('background'),
        _scoreboardAt,
      );
  }
}
