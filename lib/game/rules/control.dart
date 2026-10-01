import '../table/parts/part.dart';
import '../table/parts/solid_parts.dart';
import '../table/space_cadet_table.dart';
import '../ui/text_box.dart';
import 'score_manager.dart';

/// The original rules (`control.cpp`): every component's events go to its
/// control function, which scores, lights lights and drives missions.
///
/// Ported function by function, keeping the original names. Components
/// without a ported function do nothing yet — no points are made up.
class Control {
  Control({
    required this.table,
    required this.score,
    required this.info,
    required this.mission,
  });

  final SpaceCadetTable table;
  final ScoreManager score;
  final TextBox info, mission;

  // Score tables (control.cpp, top of file).
  static const bumpScores1 = [500, 1000, 1500, 2000];
  static const bumpScores2 = [1500, 2500, 3500, 4500];
  static const reboScore1 = [500];

  late final Map<String, void Function(PartEvent)> _handlers = {
    for (final n in ['a_bump1', 'a_bump2', 'a_bump3', 'a_bump4'])
      n: (e) => _bumperControl(e, bumpScores1),
    for (final n in ['a_bump5', 'a_bump6', 'a_bump7'])
      n: (e) => _bumperControl(e, bumpScores2),
    'v_rebo1': (e) => _flipperRebounderControl(e, 'lite84'),
    'v_rebo2': (e) => _flipperRebounderControl(e, 'lite85'),
    'v_rebo3': _rebounderControl,
    'v_rebo4': _rebounderControl,
  };

  /// Names of the components whose control function is ported.
  Iterable<String> get ported => _handlers.keys;

  void handle(PartEvent e) => _handlers[e.part.name]?.call(e);

  /// A message box finished a message (`ControlTimerExpired` on a text
  /// box). Used by the mission logic (Phase 6).
  void handleTextBoxExpired(TextBox box) {}

  /// `BumperControl`: the score of the bumper's current level.
  void _bumperControl(PartEvent e, List<int> scores) {
    if (e.kind != PartEventKind.collision) return;
    final bumper = e.part as BumperPart;
    score.add(scores[bumper.bmpIndex.clamp(0, scores.length - 1)]);
  }

  /// `FlipperRebounderControl1/2`: flash the light above the slingshot.
  void _flipperRebounderControl(PartEvent e, String light) {
    if (e.kind != PartEventKind.collision) return;
    table.light(light)?.turnOnTimed(0.1);
    score.add(reboScore1[0]);
  }

  /// `RebounderControl`.
  void _rebounderControl(PartEvent e) {
    if (e.kind != PartEventKind.collision) return;
    score.add(reboScore1[0]);
  }
}
