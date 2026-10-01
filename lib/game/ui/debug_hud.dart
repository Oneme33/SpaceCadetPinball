import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle;

import '../debug/debug_layer.dart';
import '../input/input_bindings.dart';
import '../space_cadet_game.dart';

/// FPS, game phase, physics steps, held inputs and ball speed.
///
/// The text is rebuilt four times a second, not every frame, so the HUD
/// itself does not allocate per frame.
class DebugHud extends PositionComponent {
  DebugHud({required this.game, required this.layer})
    : super(position: Vector2(4, 4));

  final SpaceCadetGame game;
  final DebugLayer layer;

  static final _text = TextPaint(
    style: const TextStyle(
      color: Color(0xFF00FF66),
      fontSize: 8,
      fontFamily: 'monospace',
    ),
  );

  final _fps = FpsComponent();
  double _sinceRefresh = 0;
  int _stepsAtRefresh = 0;
  String _line = '';

  @override
  Future<void> onLoad() async => add(_fps);

  @override
  void update(double dt) {
    super.update(dt);
    _sinceRefresh += dt;
    if (_sinceRefresh < 0.25) return;
    final steps = game.physics.totalSteps;
    final stepRate = (steps - _stepsAtRefresh) / _sinceRefresh;
    _stepsAtRefresh = steps;
    _sinceRefresh = 0;
    final held = GameAction.values
        .where(game.input.isHeld)
        .map((a) => a.name)
        .join(' ');
    _line =
        'FPS ${_fps.fps.toStringAsFixed(0)}  '
        'physics ${stepRate.toStringAsFixed(0)} Hz  '
        '${game.gameState.phase.name}\n'
        'balls ${game.rules.t.ballCount} in play ${game.table.multiballCount}  '
        'speed ${_speed()} u/s  plunger ${game.table.plunger.boost.toStringAsFixed(0)}  '
        'held: $held\n'
        '${_pointer()}  click = place ball, G = walls\n'
        'last: ${game.lastPartEvent ?? '–'}  layer ${_layer()}';
  }

  String _speed() {
    final balls = game.table.balls;
    return balls.isEmpty ? '–' : balls.first.speed.toStringAsFixed(1);
  }

  String _layer() {
    final balls = game.table.balls;
    return balls.isEmpty ? '–' : '${balls.first.layers}';
  }

  String _pointer() {
    final p = layer.pointerTable;
    if (p == null) return 'table –';
    return 'table (${p.$1.toStringAsFixed(2)}, ${p.$2.toStringAsFixed(2)})';
  }

  @override
  void render(Canvas canvas) => _text.render(canvas, _line, Vector2.zero());
}
