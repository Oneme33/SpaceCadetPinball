// Ported from the decompilation's control.cpp (k4zmu2a/SpaceCadetPinball,
// MIT licence), function by function. Names follow the original.
// ignore_for_file: unnecessary_parenthesis, curly_braces_in_flow_control_structures, non_constant_identifier_names
part of 'original_rules.dart';

mixin _Components on _RulesBase {
  ComponentGroupPart get attack_bump =>
      _part('attack_bumpers') as ComponentGroupPart;
  ComponentGroupPart get launch_bump =>
      _part('launch_bumpers') as ComponentGroupPart;
  BlockerPart get block1 => _part('v_bloc1') as BlockerPart;
  BumperPart get bump1 => _part('a_bump1') as BumperPart;
  BumperPart get bump2 => _part('a_bump2') as BumperPart;
  BumperPart get bump3 => _part('a_bump3') as BumperPart;
  BumperPart get bump4 => _part('a_bump4') as BumperPart;
  BumperPart get bump5 => _part('a_bump5') as BumperPart;
  BumperPart get bump6 => _part('a_bump6') as BumperPart;
  BumperPart get bump7 => _part('a_bump7') as BumperPart;
  DrainPart get drain => _part('drain') as DrainPart;
  SpinnerPart get flag1 => _part('a_flag1') as SpinnerPart;
  SpinnerPart get flag2 => _part('a_flag2') as SpinnerPart;
  FlipperPart get flip1 => _part('a_flip1') as FlipperPart;
  FlipperPart get flip2 => _part('a_flip2') as FlipperPart;
  LightBargraphPart get fuel_bargraph =>
      _part('fuel_bargraph') as LightBargraphPart;
  GatePart get gate1 => _part('v_gate1') as GatePart;
  GatePart get gate2 => _part('v_gate2') as GatePart;
  TextBoxPart get info_text_box => infoPart;
  KickbackPart get kicker1 => _part('a_kick1') as KickbackPart;
  KickbackPart get kicker2 => _part('a_kick2') as KickbackPart;
  KickoutPart get kickout1 => _part('a_kout1') as KickoutPart;
  KickoutPart get kickout2 => _part('a_kout2') as KickoutPart;
  KickoutPart get kickout3 => _part('a_kout3') as KickoutPart;
  LightPart get lite1 => _part('lite1') as LightPart;
  LightPart get lite2 => _part('lite2') as LightPart;
  LightPart get lite3 => _part('lite3') as LightPart;
  LightPart get lite4 => _part('lite4') as LightPart;
  LightPart get lite5 => _part('lite5') as LightPart;
  LightPart get lite6 => _part('lite6') as LightPart;
  LightPart get lite7 => _part('lite7') as LightPart;
  LightPart get lite8 => _part('lite8') as LightPart;
  LightPart get lite9 => _part('lite9') as LightPart;
  LightPart get lite10 => _part('lite10') as LightPart;
  LightPart get lite11 => _part('lite11') as LightPart;
  LightPart get lite12 => _part('lite12') as LightPart;
  LightPart get lite13 => _part('lite13') as LightPart;
  LightPart get lite16 => _part('lite16') as LightPart;
  LightPart get lite17 => _part('lite17') as LightPart;
  LightPart get lite18 => _part('lite18') as LightPart;
  LightPart get lite19 => _part('lite19') as LightPart;
  LightPart get lite20 => _part('lite20') as LightPart;
  LightPart get lite21 => _part('lite21') as LightPart;
  LightPart get lite22 => _part('lite22') as LightPart;
  LightPart get lite23 => _part('lite23') as LightPart;
  LightPart get lite24 => _part('lite24') as LightPart;
  LightPart get lite25 => _part('lite25') as LightPart;
  LightPart get lite26 => _part('lite26') as LightPart;
  LightPart get lite27 => _part('lite27') as LightPart;
  LightPart get lite28 => _part('lite28') as LightPart;
  LightPart get lite29 => _part('lite29') as LightPart;
  LightPart get lite30 => _part('lite30') as LightPart;
  LightPart get lite38 => _part('lite38') as LightPart;
  LightPart get lite39 => _part('lite39') as LightPart;
  LightPart get lite40 => _part('lite40') as LightPart;
  LightPart get lite54 => _part('lite54') as LightPart;
  LightPart get lite55 => _part('lite55') as LightPart;
  LightPart get lite56 => _part('lite56') as LightPart;
  LightPart get lite58 => _part('lite58') as LightPart;
  LightPart get lite59 => _part('lite59') as LightPart;
  LightPart get lite60 => _part('lite60') as LightPart;
  LightPart get lite61 => _part('lite61') as LightPart;
  LightPart get lite62 => _part('lite62') as LightPart;
  LightPart get lite67 => _part('lite67') as LightPart;
  LightPart get lite68 => _part('lite68') as LightPart;
  LightPart get lite69 => _part('lite69') as LightPart;
  LightPart get lite70 => _part('lite70') as LightPart;
  LightPart get lite71 => _part('lite71') as LightPart;
  LightPart get lite72 => _part('lite72') as LightPart;
  LightPart get lite77 => _part('lite77') as LightPart;
  LightPart get lite84 => _part('lite84') as LightPart;
  LightPart get lite85 => _part('lite85') as LightPart;
  LightPart get lite101 => _part('lite101') as LightPart;
  LightPart get lite102 => _part('lite102') as LightPart;
  LightPart get lite103 => _part('lite103') as LightPart;
  LightPart get lite104 => _part('lite104') as LightPart;
  LightPart get lite105 => _part('lite105') as LightPart;
  LightPart get lite106 => _part('lite106') as LightPart;
  LightPart get lite107 => _part('lite107') as LightPart;
  LightPart get lite108 => _part('lite108') as LightPart;
  LightPart get lite109 => _part('lite109') as LightPart;
  LightPart get lite110 => _part('lite110') as LightPart;
  LightPart get lite130 => _part('lite130') as LightPart;
  LightPart get lite131 => _part('lite131') as LightPart;
  LightPart get lite132 => _part('lite132') as LightPart;
  LightPart get lite133 => _part('lite133') as LightPart;
  LightPart get lite169 => _part('lite169') as LightPart;
  LightPart get lite170 => _part('lite170') as LightPart;
  LightPart get lite171 => _part('lite171') as LightPart;
  LightPart get lite195 => _part('lite195') as LightPart;
  LightPart get lite196 => _part('lite196') as LightPart;
  LightPart get lite198 => _part('lite198') as LightPart;
  LightPart get lite199 => _part('lite199') as LightPart;
  LightPart get lite200 => _part('lite200') as LightPart;
  LightPart get lite300 => _part('lite300') as LightPart;
  LightPart get lite301 => _part('lite301') as LightPart;
  LightPart get lite302 => _part('lite302') as LightPart;
  LightPart get lite303 => _part('lite303') as LightPart;
  LightPart get lite304 => _part('lite304') as LightPart;
  LightPart get lite305 => _part('lite305') as LightPart;
  LightPart get lite306 => _part('lite306') as LightPart;
  LightPart get lite307 => _part('lite307') as LightPart;
  LightPart get lite308 => _part('lite308') as LightPart;
  LightPart get lite309 => _part('lite309') as LightPart;
  LightPart get lite310 => _part('lite310') as LightPart;
  LightPart get lite311 => _part('lite311') as LightPart;
  LightPart get lite312 => _part('lite312') as LightPart;
  LightPart get lite313 => _part('lite313') as LightPart;
  LightPart get lite314 => _part('lite314') as LightPart;
  LightPart get lite315 => _part('lite315') as LightPart;
  LightPart get lite316 => _part('lite316') as LightPart;
  LightPart get lite317 => _part('lite317') as LightPart;
  LightPart get lite318 => _part('lite318') as LightPart;
  LightPart get lite319 => _part('lite319') as LightPart;
  LightPart get lite320 => _part('lite320') as LightPart;
  LightPart get lite321 => _part('lite321') as LightPart;
  LightPart get lite322 => _part('lite322') as LightPart;
  LightPart get literoll179 => _part('literoll179') as LightPart;
  LightPart get literoll180 => _part('literoll180') as LightPart;
  LightPart get literoll181 => _part('literoll181') as LightPart;
  LightPart get literoll182 => _part('literoll182') as LightPart;
  LightPart get literoll183 => _part('literoll183') as LightPart;
  LightPart get literoll184 => _part('literoll184') as LightPart;
  LightGroupPart get middle_circle => _part('middle_circle') as LightGroupPart;
  LightGroupPart get lchute_tgt_lights =>
      _part('lchute_tgt_lights') as LightGroupPart;
  LightGroupPart get l_trek_lights => _part('l_trek_lights') as LightGroupPart;
  LightGroupPart get goal_lights => _part('goal_lights') as LightGroupPart;
  LightGroupPart get hyper_lights =>
      _part('hyperspace_lights') as LightGroupPart;
  LightGroupPart get bmpr_inc_lights =>
      _part('bmpr_inc_lights') as LightGroupPart;
  LightGroupPart get bpr_solotgt_lights =>
      _part('bpr_solotgt_lights') as LightGroupPart;
  LightGroupPart get bsink_arrow_lights =>
      _part('bsink_arrow_lights') as LightGroupPart;
  LightGroupPart get bumber_target_lights =>
      _part('bumper_target_lights') as LightGroupPart;
  LightGroupPart get outer_circle => _part('outer_circle') as LightGroupPart;
  LightGroupPart get r_trek_lights => _part('r_trek_lights') as LightGroupPart;
  LightGroupPart get ramp_bmpr_inc_lights =>
      _part('ramp_bmpr_inc_lights') as LightGroupPart;
  LightGroupPart get ramp_tgt_lights =>
      _part('ramp_tgt_lights') as LightGroupPart;
  LightGroupPart get skill_shot_lights =>
      _part('skill_shot_lights') as LightGroupPart;
  LightGroupPart get top_circle_tgt_lights =>
      _part('top_circle_tgt_lights') as LightGroupPart;
  LightGroupPart get top_target_lights =>
      _part('top_target_lights') as LightGroupPart;
  LightGroupPart get worm_hole_lights =>
      _part('worm_hole_lights') as LightGroupPart;
  TextBoxPart get mission_text_box => missionPart;
  OnewayPart get oneway1 => _part('s_onewy1') as OnewayPart;
  OnewayPart get oneway4 => _part('s_onewy4') as OnewayPart;
  OnewayPart get oneway10 => _part('s_onewy10') as OnewayPart;
  PlungerPart get plunger => _part('plunger') as PlungerPart;
  HolePart get ramp_hole => _part('ramp_hole') as HolePart;
  RampPart get ramp => _part('ramp') as RampPart;
  WallPart get rebo1 => _part('v_rebo1') as WallPart;
  WallPart get rebo2 => _part('v_rebo2') as WallPart;
  WallPart get rebo3 => _part('v_rebo3') as WallPart;
  WallPart get rebo4 => _part('v_rebo4') as WallPart;
  RolloverPart get roll1 => _part('a_roll1') as RolloverPart;
  RolloverPart get roll2 => _part('a_roll2') as RolloverPart;
  RolloverPart get roll3 => _part('a_roll3') as RolloverPart;
  RolloverPart get roll4 => _part('a_roll4') as RolloverPart;
  RolloverPart get roll5 => _part('a_roll5') as RolloverPart;
  RolloverPart get roll6 => _part('a_roll6') as RolloverPart;
  RolloverPart get roll7 => _part('a_roll7') as RolloverPart;
  RolloverPart get roll8 => _part('a_roll8') as RolloverPart;
  RolloverPart get roll9 => _part('a_roll9') as RolloverPart;
  RolloverPart get roll110 => _part('a_roll110') as RolloverPart;
  RolloverPart get roll111 => _part('a_roll111') as RolloverPart;
  RolloverPart get roll112 => _part('a_roll112') as RolloverPart;
  RolloverPart get roll179 => _part('a_roll179') as RolloverPart;
  RolloverPart get roll180 => _part('a_roll180') as RolloverPart;
  RolloverPart get roll181 => _part('a_roll181') as RolloverPart;
  RolloverPart get roll182 => _part('a_roll182') as RolloverPart;
  RolloverPart get roll183 => _part('a_roll183') as RolloverPart;
  RolloverPart get roll184 => _part('a_roll184') as RolloverPart;
  SinkPart get sink1 => _part('v_sink1') as SinkPart;
  SinkPart get sink2 => _part('v_sink2') as SinkPart;
  SinkPart get sink3 => _part('v_sink3') as SinkPart;
  SinkPart get sink7 => _part('v_sink7') as SinkPart;
  SoundPart get soundwave3 => _part('soundwave3') as SoundPart;
  SoundPart get soundwave7 => _part('soundwave7') as SoundPart;
  SoundPart get soundwave8 => _part('soundwave8') as SoundPart;
  SoundPart get soundwave9 => _part('soundwave9') as SoundPart;
  SoundPart get soundwave10 => _part('soundwave10') as SoundPart;
  SoundPart get soundwave14_1 => _part('soundwave14') as SoundPart;
  SoundPart get soundwave14_2 => _part('soundwave14') as SoundPart;
  SoundPart get soundwave21 => _part('soundwave21') as SoundPart;
  SoundPart get soundwave23 => _part('soundwave23') as SoundPart;
  SoundPart get soundwave24 => _part('soundwave24') as SoundPart;
  SoundPart get soundwave25 => _part('soundwave25') as SoundPart;
  SoundPart get soundwave26 => _part('soundwave26') as SoundPart;
  SoundPart get soundwave27 => _part('soundwave27') as SoundPart;
  SoundPart get soundwave28 => _part('soundwave28') as SoundPart;
  SoundPart get soundwave30 => _part('soundwave30') as SoundPart;
  SoundPart get soundwave35_1 => _part('soundwave35') as SoundPart;
  SoundPart get soundwave35_2 => _part('soundwave35') as SoundPart;
  SoundPart get soundwave36_1 => _part('soundwave36') as SoundPart;
  SoundPart get soundwave36_2 => _part('soundwave36') as SoundPart;
  SoundPart get soundwave38 => _part('soundwave38') as SoundPart;
  SoundPart get soundwave39 => _part('soundwave39') as SoundPart;
  SoundPart get soundwave40 => _part('soundwave40') as SoundPart;
  SoundPart get soundwave41 => _part('soundwave41') as SoundPart;
  SoundPart get soundwave44 => _part('soundwave44') as SoundPart;
  SoundPart get soundwave45 => _part('soundwave45') as SoundPart;
  SoundPart get soundwave46 => _part('soundwave46') as SoundPart;
  SoundPart get soundwave47 => _part('soundwave47') as SoundPart;
  SoundPart get soundwave48 => _part('soundwave48') as SoundPart;
  SoundPart get soundwave49D => _part('soundwave49D') as SoundPart;
  SoundPart get soundwave50_1 => _part('soundwave50') as SoundPart;
  SoundPart get soundwave50_2 => _part('soundwave50') as SoundPart;
  SoundPart get soundwave52 => _part('soundwave52') as SoundPart;
  SoundPart get soundwave59 => _part('soundwave59') as SoundPart;
  PopupTargetPart get target1 => _part('a_targ1') as PopupTargetPart;
  PopupTargetPart get target2 => _part('a_targ2') as PopupTargetPart;
  PopupTargetPart get target3 => _part('a_targ3') as PopupTargetPart;
  PopupTargetPart get target4 => _part('a_targ4') as PopupTargetPart;
  PopupTargetPart get target5 => _part('a_targ5') as PopupTargetPart;
  PopupTargetPart get target6 => _part('a_targ6') as PopupTargetPart;
  PopupTargetPart get target7 => _part('a_targ7') as PopupTargetPart;
  PopupTargetPart get target8 => _part('a_targ8') as PopupTargetPart;
  PopupTargetPart get target9 => _part('a_targ9') as PopupTargetPart;
  SoloTargetPart get target10 => _part('a_targ10') as SoloTargetPart;
  SoloTargetPart get target11 => _part('a_targ11') as SoloTargetPart;
  SoloTargetPart get target12 => _part('a_targ12') as SoloTargetPart;
  SoloTargetPart get target13 => _part('a_targ13') as SoloTargetPart;
  SoloTargetPart get target14 => _part('a_targ14') as SoloTargetPart;
  SoloTargetPart get target15 => _part('a_targ15') as SoloTargetPart;
  SoloTargetPart get target16 => _part('a_targ16') as SoloTargetPart;
  SoloTargetPart get target17 => _part('a_targ17') as SoloTargetPart;
  SoloTargetPart get target18 => _part('a_targ18') as SoloTargetPart;
  SoloTargetPart get target19 => _part('a_targ19') as SoloTargetPart;
  SoloTargetPart get target20 => _part('a_targ20') as SoloTargetPart;
  SoloTargetPart get target21 => _part('a_targ21') as SoloTargetPart;
  SoloTargetPart get target22 => _part('a_targ22') as SoloTargetPart;
  TripwirePart get trip1 => _part('s_trip1') as TripwirePart;
  TripwirePart get trip2 => _part('s_trip2') as TripwirePart;
  TripwirePart get trip3 => _part('s_trip3') as TripwirePart;
  TripwirePart get trip4 => _part('s_trip4') as TripwirePart;
  TripwirePart get trip5 => _part('s_trip5') as TripwirePart;

  List<SinkPart> get wormholeSinkArray => [sink1, sink2, sink3];
  List<LightPart> get wormholeLightArray1 => [lite5, lite6, lite7];
  List<LightPart> get wormholeLightArray2 => [lite4, lite2, lite3];
}

// Score tables (control.cpp, top of file).
const controlBumpScores1 = <int>[500, 1000, 1500, 2000];
const controlRollScores1 = <int>[2000];
const controlBumpScores2 = <int>[1500, 2500, 3500, 4500];
const controlRollScores2 = <int>[500];
const controlReboScore1 = <int>[500];
const controlOneway4Score1 = <int>[15000, 30000, 75000, 30000, 15000, 7500];
const controlRampScore1 = <int>[5000];
const controlRollScore1 = <int>[20000];
const controlRollScore2 = <int>[5000, 25000];
const controlRollScore3 = <int>[10000];
const controlRollScore4 = <int>[500];
const controlFlagScore1 = <int>[500, 2500];
const controlKickoutScore1 = <int>[10000, 0, 20000, 50000, 150000];
const controlSinkScore1 = <int>[2500, 5000, 7500];
const controlTargetScore1 = <int>[500, 5000];
const controlTargetScore2 = <int>[1500, 10000, 50000];
const controlTargetScore3 = <int>[500, 1500];
const controlTargetScore4 = <int>[750];
const controlTargetScore5 = <int>[1000];
const controlTargetScore6 = <int>[750];
const controlTargetScore7 = <int>[750];
const controlRollScore5 = <int>[10000];
const controlKickoutScore2 = <int>[20000];
const controlKickoutScore3 = <int>[50000];

mixin _ScoreTables {}

mixin _Functions on _RulesBase, _Components, _ScoreTables {
  /// `score_components`: the control function and score table per
  /// component (`TPinballComponent::Control`).
  late final Map<String, (void Function(int, TablePart?), List<int>)> controls =
      {
        'a_bump1': (bumperControl, controlBumpScores1),
        'a_bump2': (bumperControl, controlBumpScores1),
        'a_bump3': (bumperControl, controlBumpScores1),
        'a_bump4': (bumperControl, controlBumpScores1),
        'a_roll3': (reentryLanesRolloverControl, controlRollScores1),
        'a_roll2': (reentryLanesRolloverControl, controlRollScores1),
        'a_roll1': (reentryLanesRolloverControl, controlRollScores1),
        'attack_bumpers': (bumperGroupControl, const []),
        'a_bump5': (bumperControl, controlBumpScores2),
        'a_bump6': (bumperControl, controlBumpScores2),
        'a_bump7': (bumperControl, controlBumpScores2),
        'a_roll112': (launchLanesRolloverControl, controlRollScores2),
        'a_roll111': (launchLanesRolloverControl, controlRollScores2),
        'a_roll110': (launchLanesRolloverControl, controlRollScores2),
        'launch_bumpers': (bumperGroupControl, const []),
        'v_rebo1': (flipperRebounderControl1, controlReboScore1),
        'v_rebo2': (flipperRebounderControl2, controlReboScore1),
        'v_rebo3': (rebounderControl, controlReboScore1),
        'v_rebo4': (rebounderControl, controlReboScore1),
        'a_kick1': (leftKickerControl, const []),
        'a_kick2': (rightKickerControl, const []),
        'v_gate1': (leftKickerGateControl, const []),
        'v_gate2': (rightKickerGateControl, const []),
        's_onewy4': (
          deploymentChuteToEscapeChuteOneWayControl,
          controlOneway4Score1,
        ),
        's_onewy10': (deploymentChuteToTableOneWayControl, const []),
        'v_bloc1': (drainBallBlockerControl, const []),
        'ramp': (launchRampControl, controlRampScore1),
        'ramp_hole': (launchRampHoleControl, const []),
        'a_roll4': (outLaneRolloverControl, controlRollScore1),
        'a_roll8': (outLaneRolloverControl, controlRollScore1),
        'lite17': (extraBallLightControl, const []),
        'a_roll6': (returnLaneRolloverControl, controlRollScore2),
        'a_roll7': (returnLaneRolloverControl, controlRollScore2),
        'a_roll5': (bonusLaneRolloverControl, controlRollScore3),
        'a_roll179': (fuelRollover1Control, controlRollScore4),
        'a_roll180': (fuelRollover2Control, controlRollScore4),
        'a_roll181': (fuelRollover3Control, controlRollScore4),
        'a_roll182': (fuelRollover4Control, controlRollScore4),
        'a_roll183': (fuelRollover5Control, controlRollScore4),
        'a_roll184': (fuelRollover6Control, controlRollScore4),
        'a_flag1': (flagControl, controlFlagScore1),
        'a_kout2': (hyperspaceKickOutControl, controlKickoutScore1),
        'hyperspace_lights': (hyperspaceLightGroupControl, const []),
        'a_flag2': (flagControl, controlFlagScore1),
        'v_sink1': (wormHoleControl, controlSinkScore1),
        'v_sink2': (wormHoleControl, controlSinkScore1),
        'v_sink3': (wormHoleControl, controlSinkScore1),
        'a_flip1': (leftFlipperControl, const []),
        'a_flip2': (rightFlipperControl, const []),
        'plunger': (plungerControl, const []),
        'a_targ1': (boosterTargetControl, controlTargetScore1),
        'a_targ2': (boosterTargetControl, controlTargetScore1),
        'a_targ3': (boosterTargetControl, controlTargetScore1),
        'lite60': (jackpotLightControl, const []),
        'lite59': (bonusLightControl, const []),
        'a_targ6': (medalTargetControl, controlTargetScore2),
        'a_targ5': (medalTargetControl, controlTargetScore2),
        'a_targ4': (medalTargetControl, controlTargetScore2),
        'bumper_target_lights': (medalLightGroupControl, const []),
        'a_targ9': (multiplierTargetControl, controlTargetScore3),
        'a_targ8': (multiplierTargetControl, controlTargetScore3),
        'a_targ7': (multiplierTargetControl, controlTargetScore3),
        'top_target_lights': (multiplierLightGroupControl, const []),
        'a_targ10': (fuelSpotTargetControl, controlTargetScore4),
        'a_targ11': (fuelSpotTargetControl, controlTargetScore4),
        'a_targ12': (fuelSpotTargetControl, controlTargetScore4),
        'a_targ13': (missionSpotTargetControl, controlTargetScore5),
        'a_targ14': (missionSpotTargetControl, controlTargetScore5),
        'a_targ15': (missionSpotTargetControl, controlTargetScore5),
        'a_targ16': (leftHazardSpotTargetControl, controlTargetScore6),
        'a_targ17': (leftHazardSpotTargetControl, controlTargetScore6),
        'a_targ18': (leftHazardSpotTargetControl, controlTargetScore6),
        'a_targ19': (rightHazardSpotTargetControl, controlTargetScore6),
        'a_targ20': (rightHazardSpotTargetControl, controlTargetScore6),
        'a_targ21': (rightHazardSpotTargetControl, controlTargetScore6),
        'a_targ22': (wormHoleDestinationControl, controlTargetScore7),
        'a_roll9': (spaceWarpRolloverControl, controlRollScore5),
        'a_kout3': (blackHoleKickoutControl, controlKickoutScore2),
        'a_kout1': (gravityWellKickoutControl, controlKickoutScore3),
        'drain': (ballDrainControl, const []),
        's_onewy1': (skillShotGate1Control, const []),
        's_trip1': (skillShotGate2Control, const []),
        's_trip2': (skillShotGate3Control, const []),
        's_trip3': (skillShotGate4Control, const []),
        's_trip4': (skillShotGate5Control, const []),
        's_trip5': (skillShotGate6Control, const []),
        'lite200': (shootAgainLightControl, const []),
        'v_sink7': (escapeChuteSinkControl, const []),
      };

  void tableAddExtraBall(double count) {
    hooks.onSpecialAward?.call();
    ++t.extraBalls;
    soundwave28.play();
    info_text_box.display(rc(110), count);
  }

  void tableSetBonusHold() {
    lite58.message(MC.tLightResetAndTurnOn, 0.0);
    info_text_box.display(rc(153), 2.0);
  }

  void tableSetBonus() {
    t.bonusScoreFlag = true;
    lite59.message(MC.tLightTurnOnTimed, 60.0);
    info_text_box.display(rc(105), 2.0);
  }

  void tableSetJackpot() {
    hooks.onSpecialAward?.call();
    t.jackpotScoreFlag = true;
    lite60.message(MC.tLightTurnOnTimed, 60.0);
    info_text_box.display(rc(116), 2.0);
  }

  void tableSetFlagLights() {
    lite20.message(MC.tLightTurnOnTimed, 60.0);
    lite19.message(MC.tLightTurnOnTimed, 60.0);
    lite61.message(MC.tLightTurnOnTimed, 60.0);
    info_text_box.display(rc(152), 2.0);
  }

  void tableSetMultiball(double time) {
    if (t.multiballCount <= 1) {
      t.multiballCount += 3;
      sink1.message(MC.tSinkResetTimer, time);
      sink2.message(MC.tSinkResetTimer, time);
      sink3.message(MC.tSinkResetTimer, time);
      lite38.message(MC.tLightFlasherStartTimed, -1.0);
      lite39.message(MC.tLightFlasherStartTimed, -1.0);
      lite40.message(MC.tLightFlasherStartTimed, -1.0);
      info_text_box.display(rc(117), 2.0);
      // (music)
    }
  }

  void tableBumpBallSinkLock() {
    if (t.multiballCount <= 1) {
      t.multiballCount--;
      if (t.ballLockedCounter == 2) {
        soundwave41.play();
        tableSetMultiball(2.0);
        t.ballLockedCounter = 0;
      } else {
        t.ballLockedCounter = t.ballLockedCounter + 1;
        soundwave44.play();
        info_text_box.display(rc(102), 2.0);
        plunger.message(MC.plungerRelaunchBall, 2.0);
      }
    }
  }

  void tableSetReplay(double value) {
    hooks.onSpecialAward?.call();
    lite199.message(MC.tLightResetAndTurnOn, 0.0);
    info_text_box.display(rc(101), value);
  }

  void cheatBumpRank() {
    var buffer = '';

    final rank = middle_circle.message(MC.tLightGroupGetOnCount, 0.0);
    if (rank < 9) {
      middle_circle.message(MC.tLightGroupResetAndTurnOn, 2.0);
      final rankText = rc(rankRcArray[rank]);
      buffer = fmt(rc(184), [rankText]);
      mission_text_box.display(buffer, 8.0);
      soundwave10.play();
    }
  }

  int specialAddScore(int score, [bool mission = false]) {
    // FT: mission completion applies current jackpot
    if (mission && fullTiltMode) score += t.jackpotScore;

    final bonus = t.bonusScoreFlag;
    final jackpot = t.jackpotScoreFlag;
    final scoreMult = t.scoreMultiplier;

    t.bonusScoreFlag = false;
    t.jackpotScoreFlag = false;
    t.scoreMultiplier = 0;
    final addedScore = addScore(score);
    t.bonusScoreFlag = bonus;
    t.jackpotScoreFlag = jackpot;
    t.scoreMultiplier = scoreMult;

    // FT: each mission starts with jackpot set to 5e5
    if (mission && fullTiltMode) t.jackpotScore = 500000;

    return addedScore;
  }

  int addRankProgress(int rank) {
    var buffer = '';
    int result = 0;

    lite16.message(MC.tLightResetAndTurnOn, 0.0);
    for (int index = rank; _b(index); --index) {
      outer_circle.message(MC.tLightGroupResetAndTurnOn, 2.0);
    }

    final int activeCount = outer_circle.message(MC.tLightGroupGetOnCount, 0.0);
    final int totalCount = outer_circle.message(
      MC.tLightGroupGetLightCount,
      0.0,
    );
    if (activeCount == totalCount) {
      result = 1;
      outer_circle.message(MC.tLightFlasherStartTimedThenStayOff, 5.0);
      middle_circle.message(MC.tLightGroupReset, 0.0);
      final int midActiveCount = middle_circle.message(
        MC.tLightGroupGetOnCount,
        0.0,
      );
      if (midActiveCount < 9) {
        middle_circle.message(MC.tLightGroupResetAndTurnOn, 5.0);
        final rankText = rc(rankRcArray[midActiveCount]);
        buffer = fmt(rc(184), [rankText]);
        mission_text_box.display(buffer, 8.0);
        soundwave10.play();
      }
    } else if (activeCount >= 3 * totalCount / 4) {
      middle_circle.message(MC.tLightGroupAnimationForward, -1.0);
    }
    return result;
  }

  void advanceWormHoleDestination(int flag) {
    final int lite198Msg = lite198.messageField;
    if (lite198Msg != 16 && lite198Msg != 22 && lite198Msg != 23) {
      final int lite4Msg = lite4.messageField;
      if (_b(flag) || _b(lite4Msg)) {
        int val1 = lite4Msg + 1;
        int val2 = val1;
        if (val1 == 4) {
          val1 = 1;
          val2 = 1;
        }
        bsink_arrow_lights.message(MC.tLightSetMessageField, (val2).toDouble());
        bsink_arrow_lights.message(
          MC.tLightSetOnStateBmpIndex,
          (3 - val1).toDouble(),
        );
        if (!lite4.isLit) {
          worm_hole_lights.message(MC.tLightResetAndTurnOn, 0.0);
          bsink_arrow_lights.message(MC.tLightResetAndTurnOn, 0.0);
        }
      }
    }
  }

  void flipperRebounderControl1(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      lite84.message(MC.tLightTurnOnTimed, 0.1);
      final score = scoring(caller, 0);
      addScore(score);
    }
  }

  void flipperRebounderControl2(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      lite85.message(MC.tLightTurnOnTimed, 0.1);
      final int score = scoring(caller, 0);
      addScore(score);
    }
  }

  void rebounderControl(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      addScore(scoring(caller, 0));
    }
  }

  void bumperControl(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      addScore(scoring(caller, (caller as BumperPart).bmpIndex));
    }
  }

  void leftKickerControl(int code, TablePart? caller) {
    if (code == MC.controlTimerExpired && !easyMode)
      gate1.message(MC.tGateEnable, 0.0);
  }

  void rightKickerControl(int code, TablePart? caller) {
    if (code == MC.controlTimerExpired && !easyMode)
      gate2.message(MC.tGateEnable, 0.0);
  }

  void leftKickerGateControl(int code, TablePart? caller) {
    if (code == MC.tGateDisable) {
      lite30.message(MC.tLightFlasherStartTimedThenStayOn, 5.0);
      lite196.message(MC.tLightFlasherStartTimed, 5.0);
    } else if (code == MC.tGateEnable) {
      lite30.message(MC.tLightResetAndTurnOff, 0.0);
      lite196.message(MC.tLightResetAndTurnOff, 0.0);
    }
  }

  void rightKickerGateControl(int code, TablePart? caller) {
    if (code == MC.tGateDisable) {
      lite29.message(MC.tLightFlasherStartTimedThenStayOn, 5.0);
      lite195.message(MC.tLightFlasherStartTimed, 5.0);
    } else if (code == MC.tGateEnable) {
      lite29.message(MC.tLightResetAndTurnOff, 0.0);
      lite195.message(MC.tLightResetAndTurnOff, 0.0);
    }
  }

  void deploymentChuteToEscapeChuteOneWayControl(int code, TablePart? caller) {
    var buffer = '';
    if (code == MC.controlCollision) {
      final int count = skill_shot_lights.message(
        MC.tLightGroupGetOnCount,
        0.0,
      );
      if (_b(count)) {
        soundwave3.play();
        final int score = addScore(scoring(caller, count - 1));
        buffer = fmt(rc(122), [score]);
        info_text_box.display(buffer, 2.0);
        if (!lite56.isLit) {
          l_trek_lights.message(MC.tLightGroupReset, 0.0);
          l_trek_lights.message(MC.tLightResetAndTurnOff, 0.0);
          r_trek_lights.message(MC.tLightGroupReset, 0.0);
          r_trek_lights.message(MC.tLightResetAndTurnOff, 0.0);
        }
        skill_shot_lights.message(MC.tLightGroupFlashWhenOn, 1.0);
      }
    }
  }

  void deploymentChuteToTableOneWayControl(int code, TablePart? caller) {
    if (code == MC.controlCollision)
      skill_shot_lights.message(MC.tLightResetAndTurnOff, 0.0);
  }

  void drainBallBlockerControl(int code, TablePart? caller) {
    final block = (caller as BlockerPart);
    switch (code) {
      case MC.tBlockerEnable:
        {
          block.messageField = 1;
          final blockerDuration = !easyMode
              ? (block.initialDuration).toDouble()
              : -1.0;
          block.message(MC.tBlockerEnable, blockerDuration);
          lite1.message(MC.tLightTurnOnTimed, blockerDuration);
          break;
        }
      case MC.controlTimerExpired:
        {
          if (block.messageField == 1) {
            block.messageField = 2;
            final blockerDuration = (block.extendedDuration).toDouble();
            block.message(MC.tBlockerRestartTimeout, blockerDuration);
            lite1.message(MC.tLightFlasherStartTimed, blockerDuration);
            break;
          } else {
            block.messageField = 0;
            block.message(MC.tBlockerDisable, 0.0);
            break;
          }
        }
      default:
        break;
    }
  }

  void launchRampControl(int code, TablePart? caller) {
    SoundPart sound;
    var buffer = '';

    if (code == MC.controlCollision) {
      int someFlag = 0;
      if (lite54.isLit) {
        someFlag = 1;
        final int addedScore = specialAddScore(t.reflexShotScore);
        buffer = fmt(rc(111), [addedScore]);
        info_text_box.display(buffer, 2.0);
      }
      if (lite55.isLit) someFlag |= 2;
      if (lite56.isLit) someFlag |= 4;
      if (_b(someFlag)) {
        if (someFlag == 1) {
          sound = soundwave21;
        } else if (someFlag < 1 || someFlag > 3) {
          sound = soundwave24;
        } else {
          sound = soundwave23;
        }
      } else {
        addScore(scoring(caller, 0));
        sound = soundwave30;
      }
      sound.play();
    }
  }

  void launchRampHoleControl(int code, TablePart? caller) {
    if (code == MC.controlBallReleased)
      lite54.message(MC.tLightFlasherStartTimed, 5.0);
  }

  void spaceWarpRolloverControl(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      lite27.message(MC.tLightResetAndTurnOn, 0.0);
      lite28.message(MC.tLightResetAndTurnOn, 0.0);
    }
  }

  void reentryLanesRolloverControl(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      if (!lite56.isLit &&
          _b(l_trek_lights.message(MC.tLightGroupGetMessage2, 0.0))) {
        l_trek_lights.message(MC.tLightGroupReset, 0.0);
        l_trek_lights.message(MC.tLightResetAndTurnOff, 0.0);
        r_trek_lights.message(MC.tLightGroupReset, 0.0);
        r_trek_lights.message(MC.tLightResetAndTurnOff, 0.0);
      }

      LightPart light;
      if (roll3 == caller) {
        light = lite8;
      } else if (roll2 == caller) {
        light = lite9;
      } else {
        light = lite10;
      }
      if (!light.flasherOn) {
        if (light.lightOn) {
          if (!fullTiltMode) {
            light.message(MC.tLightResetAndTurnOff, 0.0);
          }
        } else {
          light.message(MC.tLightResetAndTurnOn, 0.0);
          final int activeCount = bmpr_inc_lights.message(
            MC.tLightGroupGetOnCount,
            0.0,
          );
          if (activeCount ==
              bmpr_inc_lights.message(MC.tLightGroupGetLightCount, 0.0)) {
            bmpr_inc_lights.message(MC.tLightFlasherStartTimed, 5.0);
            bmpr_inc_lights.message(MC.tLightTurnOff, 0.0);
            if (bump1.bmpIndex < 3) {
              attack_bump.message(MC.tBumperIncBmpIndex, 0.0);
              info_text_box.display(rc(106), 2.0);
            }
            attack_bump.message(MC.tComponentGroupResetNotifyTimer, 60.0);
          }
        }
      }
      addScore(scoring(caller, 0));
    }
  }

  void bumperGroupControl(int code, TablePart? caller) {
    if (code == MC.controlNotifyTimerExpired) {
      caller!.message(MC.tComponentGroupResetNotifyTimer, 60.0);
      caller.message(MC.tBumperDecBmpIndex, 0.0);
    }
  }

  void launchLanesRolloverControl(int code, TablePart? caller) {
    LightPart light;

    if (code == MC.controlCollision) {
      if (roll112 == caller) {
        light = lite171;
      } else {
        light = lite170;
        if (roll111 != caller) light = lite169;
      }
      if (!light.flasherOn) {
        if (light.lightOn) {
          if (!fullTiltMode) {
            light.message(MC.tLightResetAndTurnOff, 0.0);
          }
        } else {
          light.message(MC.tLightResetAndTurnOn, 0.0);
          final int msg1 = ramp_bmpr_inc_lights.message(
            MC.tLightGroupGetOnCount,
            0.0,
          );
          if (msg1 ==
              ramp_bmpr_inc_lights.message(MC.tLightGroupGetLightCount, 0.0)) {
            ramp_bmpr_inc_lights.message(MC.tLightFlasherStartTimed, 5.0);
            ramp_bmpr_inc_lights.message(MC.tLightTurnOff, 0.0);
            if (bump5.bmpIndex < 3) {
              launch_bump.message(MC.tBumperIncBmpIndex, 0.0);
              info_text_box.display(rc(107), 2.0);
            }
            launch_bump.message(MC.tComponentGroupResetNotifyTimer, 60.0);
          }
        }
      }
      addScore(scoring(caller, 0));
    }
  }

  void outLaneRolloverControl(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      if (lite17.isLit || lite18.isLit) {
        tableAddExtraBall(2.0);
        lite17.message(MC.tLightResetAndTurnOff, 0.0);
        lite18.message(MC.tLightResetAndTurnOff, 0.0);
      } else {
        soundwave26.play();
      }
      if (roll4 == caller) {
        if (lite30.isLit) {
          lite30.message(MC.tLightFlasherStart, 0.0);
          lite196.message(MC.tLightFlasherStart, 0.0);
        }
      } else if (lite29.isLit) {
        lite29.message(MC.tLightFlasherStart, 0.0);
        lite195.message(MC.tLightFlasherStart, 0.0);
      }
      addScore(scoring(caller, 0));
    }
  }

  void extraBallLightControl(int code, TablePart? caller) {
    if (code == MC.tLightResetAndTurnOn) {
      lite17.message(MC.tLightTurnOnTimed, 55.0);
      lite18.message(MC.tLightTurnOnTimed, 55.0);
      extraballLightFlag = 1;
    } else if (code == MC.controlTimerExpired) {
      if (_b(extraballLightFlag)) {
        lite17.message(MC.tLightFlasherStartTimed, 5.0);
        lite18.message(MC.tLightFlasherStartTimed, 5.0);
        extraballLightFlag = 0;
      }
    }
  }

  void returnLaneRolloverControl(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      if (roll6 == caller) {
        if (lite27.isLit) {
          lite59.message(MC.tLightResetAndTurnOff, 0.0);
          lite27.message(MC.tLightResetAndTurnOff, 0.0);
          addScore(scoring(caller, 1));
        } else
          addScore(scoring(caller, 0));
      } else if (roll7 == caller) {
        if (lite28.isLit) {
          lite59.message(MC.tLightResetAndTurnOff, 0.0);
          lite28.message(MC.tLightResetAndTurnOff, 0.0);
          addScore(scoring(caller, 1));
        } else
          addScore(scoring(caller, 0));
      }
    }
  }

  void bonusLaneRolloverControl(int code, TablePart? caller) {
    var buffer = '';

    if (code == MC.controlCollision) {
      if (lite16.isLit) {
        final int addedScore = specialAddScore(t.bonusScore);
        buffer = fmt(rc(104), [addedScore]);
        info_text_box.display(buffer, 2.0);
        lite16.message(MC.tLightResetAndTurnOff, 0.0);
        soundwave50_1.play();
      } else {
        addScore(scoring(caller, 0));
        soundwave25.play();
        info_text_box.display(rc(145), 2.0);
      }
      fuel_bargraph.message(MC.tLightGroupToggleSplitIndex, 11.0);
    }
  }

  void fuelRollover1Control(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      if (fuel_bargraph.message(MC.tLightGroupGetOnCount, 0.0) > 1) {
        literoll179.message(MC.tLightTurnOffTimed, 0.05);
      } else {
        fuel_bargraph.message(MC.tLightGroupToggleSplitIndex, 1.0);
        info_text_box.display(rc(145), 2.0);
      }
      addScore(scoring(caller, 0));
    }
  }

  void fuelRollover2Control(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      if (fuel_bargraph.message(MC.tLightGroupGetOnCount, 0.0) > 3) {
        literoll180.message(MC.tLightTurnOffTimed, 0.05);
      } else {
        fuel_bargraph.message(MC.tLightGroupToggleSplitIndex, 3.0);
        info_text_box.display(rc(145), 2.0);
      }
      addScore(scoring(caller, 0));
    }
  }

  void fuelRollover3Control(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      if (fuel_bargraph.message(MC.tLightGroupGetOnCount, 0.0) > 5) {
        literoll181.message(MC.tLightTurnOffTimed, 0.05);
      } else {
        fuel_bargraph.message(MC.tLightGroupToggleSplitIndex, 5.0);
        info_text_box.display(rc(145), 2.0);
      }
      addScore(scoring(caller, 0));
    }
  }

  void fuelRollover4Control(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      if (fuel_bargraph.message(MC.tLightGroupGetOnCount, 0.0) > 7) {
        literoll182.message(MC.tLightTurnOffTimed, 0.05);
      } else {
        fuel_bargraph.message(MC.tLightGroupToggleSplitIndex, 7.0);
        info_text_box.display(rc(145), 2.0);
      }
      addScore(scoring(caller, 0));
    }
  }

  void fuelRollover5Control(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      if (fuel_bargraph.message(MC.tLightGroupGetOnCount, 0.0) > 9) {
        literoll183.message(MC.tLightTurnOffTimed, 0.05);
      } else {
        fuel_bargraph.message(MC.tLightGroupToggleSplitIndex, 9.0);
        info_text_box.display(rc(145), 2.0);
      }
      addScore(scoring(caller, 0));
    }
  }

  void fuelRollover6Control(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      if (fuel_bargraph.message(MC.tLightGroupGetOnCount, 0.0) > 11) {
        literoll184.message(MC.tLightTurnOffTimed, 0.05);
      } else {
        fuel_bargraph.message(MC.tLightGroupToggleSplitIndex, 11.0);
        info_text_box.display(rc(145), 2.0);
      }
      addScore(scoring(caller, 0));
    }
  }

  void hyperspaceLightGroupControl(int code, TablePart? caller) {
    switch (code) {
      case MC.tLightGroupNull:
        caller!.message(MC.tLightTurnOff, 0.0);
        break;
      case MC.tLightGroupResetAndTurnOn:
        caller!.message(MC.tLightGroupResetAndTurnOn, 2.0);
        caller.message(MC.tLightGroupRestartNotifyTimer, 60.0);
        break;
      case MC.controlNotifyTimerExpired:
        caller!.message(MC.tLightGroupOffsetAnimationBackward, 0.0);
        if (_b(caller.message(MC.tLightGroupGetOnCount, 0.0)))
          caller.message(MC.tLightGroupRestartNotifyTimer, 60.0);
        break;
      default:
        break;
    }
  }

  void wormHoleControl(int code, TablePart? caller) {
    int sinkFlag2;
    final SinkPart sink = (caller as SinkPart);

    if (code == MC.controlCollision) {
      int sinkFlag = 0;
      if (sink1 != sink) {
        sinkFlag = sink2 != sink ? 1 : 0;
        ++sinkFlag;
      }

      final int lite4Msg = lite4.messageField;
      if (_b(lite4Msg)) {
        lite4.messageField = 0;
        worm_hole_lights.message(MC.tLightResetAndTurnOff, 0.0);
        bsink_arrow_lights.message(MC.tLightResetAndTurnOff, 0.0);
        lite110.message(MC.tLightResetAndTurnOff, 0.0);
        if (lite4Msg == sinkFlag + 1) {
          if (t.multiballFlag) {
            if (t.multiballCount == 1) {
              tableBumpBallSinkLock();
              addScore(10000);
              return;
            } else {
              tableSetReplay(4.0);
              addScore(50000);
            }
          } else {
            tableSetReplay(4.0);
            addScore(scoring(sink, 1));
          }

          info_text_box.display(rc(150), 2.0);
          wormholeLightArray1[sinkFlag].message(
            MC.tLightFlasherStartTimedThenStayOff,
            sink.timerTime,
          );
          wormholeLightArray2[sinkFlag].message(
            MC.tLightSetOnStateBmpIndex,
            (2 - sinkFlag).toDouble(),
          );
          wormholeLightArray2[sinkFlag].message(
            MC.tLightFlasherStartTimedThenStayOff,
            sink.timerTime,
          );
          wormholeSinkArray[sinkFlag].message(
            MC.tSinkResetTimer,
            sink.timerTime,
          );
          return;
        }
        addScore(scoring(sink, 2));
        sinkFlag2 = lite4Msg - 1;
      } else {
        addScore(scoring(sink, 0));
        sinkFlag2 = sinkFlag;
      }

      wormholeLightArray1[sinkFlag2].message(
        MC.tLightFlasherStartTimedThenStayOff,
        sink.timerTime,
      );
      wormholeLightArray2[sinkFlag2].message(
        MC.tLightSetOnStateBmpIndex,
        (2 - sinkFlag2).toDouble(),
      );
      wormholeLightArray2[sinkFlag2].message(
        MC.tLightFlasherStartTimedThenStayOff,
        sink.timerTime,
      );
      wormholeSinkArray[sinkFlag2].message(MC.tSinkResetTimer, sink.timerTime);
      info_text_box.display(rc(150), 2.0);
    }
  }

  void leftFlipperControl(int code, TablePart? caller) {
    if (code == MC.tLightTurnOn) {
      bmpr_inc_lights.message(MC.tLightGroupStepBackward, 0.0);
      ramp_bmpr_inc_lights.message(MC.tLightGroupStepBackward, 0.0);
    }
  }

  void rightFlipperControl(int code, TablePart? caller) {
    if (code == MC.tLightTurnOn) {
      bmpr_inc_lights.message(MC.tLightGroupStepForward, 0.0);
      ramp_bmpr_inc_lights.message(MC.tLightGroupStepForward, 0.0);
    }
  }

  void jackpotLightControl(int code, TablePart? caller) {
    if (code == MC.controlTimerExpired) t.jackpotScoreFlag = false;
  }

  void bonusLightControl(int code, TablePart? caller) {
    if (code == MC.controlTimerExpired) t.bonusScoreFlag = false;
  }

  void boosterTargetControl(int code, TablePart? caller) {
    SoundPart? sound;

    if (code == MC.controlCollision && !_b(caller!.messageField)) {
      caller.messageField = 1;
      if (target1.messageField + target2.messageField + target3.messageField !=
          3) {
        addScore(scoring(caller, 0));
        return;
      }
      if (lite61.isLit) {
        if (lite60.isLit) {
          if (lite59.isLit) {
            if (lite58.isLit) {
              addScore(scoring(caller, 1));
            } else {
              tableSetBonusHold();
            }
            sound = soundwave48;
          } else {
            tableSetBonus();
            sound = soundwave46;
          }
        } else {
          tableSetJackpot();
          sound = soundwave45;
        }
      } else {
        final int msg = lite198.messageField;
        if (msg != 15 && msg != 29) {
          tableSetFlagLights();
          sound = soundwave47;
        }
      }
      if (_b(sound)) sound!.play();

      target1.messageField = 0;
      target1.message(MC.tPopupTargetEnable, 0.0);
      target2.messageField = 0;
      target2.message(MC.tPopupTargetEnable, 0.0);
      target3.messageField = 0;
      target3.message(MC.tPopupTargetEnable, 0.0);
      addScore(scoring(caller, 1));
    }
  }

  void medalLightGroupControl(int code, TablePart? caller) {
    switch (code) {
      case MC.tLightGroupNull:
        caller!.message(MC.tLightTurnOff, 0.0);
        break;
      case MC.tLightGroupResetAndTurnOn:
        caller!.message(MC.tLightGroupResetAndTurnOn, 2.0);
        caller.message(MC.tLightGroupRestartNotifyTimer, 30.0);
        break;
      case MC.controlNotifyTimerExpired:
        caller!.message(MC.tLightGroupOffsetAnimationBackward, 0.0);
        if (_b(caller.message(MC.tLightGroupGetOnCount, 0.0)))
          caller.message(MC.tLightGroupRestartNotifyTimer, 30.0);
        break;
      default:
        break;
    }
  }

  void multiplierLightGroupControl(int code, TablePart? caller) {
    switch (code) {
      case MC.tLightGroupNull:
        caller!.message(MC.tLightTurnOff, 0.0);
        break;
      case MC.tLightGroupResetAndTurnOn:
        caller!.message(MC.tLightGroupResetAndTurnOn, 2.0);
        caller.message(MC.tLightGroupRestartNotifyTimer, 30.0);
        break;
      case MC.controlNotifyTimerExpired:
        if (_b(t.scoreMultiplier)) t.scoreMultiplier = t.scoreMultiplier - 1;
        caller!.message(MC.tLightGroupOffsetAnimationBackward, 0.0);
        if (_b(caller.message(MC.tLightGroupGetOnCount, 0.0)))
          caller.message(MC.tLightGroupRestartNotifyTimer, 30.0);
        break;
      case MC.controlEnableMultiplier:
        t.scoreMultiplier = 4;
        caller!.message(MC.tLightResetAndTurnOn, 0.0);
        caller.message(MC.tLightGroupRestartNotifyTimer, 30.0);
        info_text_box.display(rc(160), 2.0);
        break;
      case MC.controlDisableMultiplier:
        t.scoreMultiplier = 0;
        caller!.message(MC.tLightResetAndTurnOff, 0.0);
        caller.message(MC.tLightGroupRestartNotifyTimer, -1.0);
        break;
      default:
        break;
    }
  }

  void fuelSpotTargetControl(int code, TablePart? caller) {
    TablePart? liteComp;

    if (code == MC.controlCollision) {
      if (target10 == caller) {
        liteComp = lite70;
      } else {
        liteComp = lite71;
        if (target11 != caller) liteComp = lite72;
      }
      liteComp.message(MC.tLightFlasherStartTimedThenStayOn, 2.0);
      addScore(scoring(caller, 0));
      if (top_circle_tgt_lights.message(MC.tLightGroupGetOnCount, 0.0) == 3) {
        top_circle_tgt_lights.message(
          MC.tLightFlasherStartTimedThenStayOff,
          2.0,
        );
        fuel_bargraph.message(MC.tLightGroupToggleSplitIndex, 11.0);
        soundwave25.play();
        info_text_box.display(rc(145), 2.0);
      } else {
        soundwave49D.play();
      }
    }
  }

  void missionSpotTargetControl(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      TablePart? lite;
      if (target13 == caller) {
        lite101.messageField |= 1;
        lite = lite101;
      } else if (target14 == caller) {
        lite101.messageField |= 2;
        lite = lite102;
      } else {
        lite101.messageField |= 4;
        lite = lite103;
      }
      lite.message(MC.tLightFlasherStartTimedThenStayOn, 2.0);

      SoundPart sound;
      if (!lite198.isLit || lite198.flasherOn) {
        sound = soundwave52;
      } else
        sound = soundwave49D;
      sound.play();
      addScore(scoring(caller, 0));
      if (ramp_tgt_lights.message(MC.tLightGroupGetOnCount, 0.0) == 3)
        ramp_tgt_lights.message(MC.tLightFlasherStartTimedThenStayOff, 2.0);
    }
  }

  void leftHazardSpotTargetControl(int code, TablePart? caller) {
    TablePart? lite;

    if (code == MC.controlCollision) {
      if (target16 == caller) {
        lite104.messageField |= 1;
        lite = lite104;
      } else if (target17 == caller) {
        lite104.messageField |= 2;
        lite = lite105;
      } else {
        lite104.messageField |= 4;
        lite = lite106;
      }
      lite.message(MC.tLightFlasherStartTimedThenStayOn, 2.0);
      addScore(scoring(caller, 0));
      if (lchute_tgt_lights.message(MC.tLightGroupGetOnCount, 0.0) == 3) {
        soundwave14_1.play();
        gate1.message(MC.tGateDisable, 0.0);
        lchute_tgt_lights.message(MC.tLightFlasherStartTimedThenStayOff, 2.0);
      } else {
        soundwave49D.play();
      }
    }
  }

  void rightHazardSpotTargetControl(int code, TablePart? caller) {
    TablePart? light;

    if (code == MC.controlCollision) {
      if (target19 == caller) {
        lite107.messageField |= 1;
        light = lite107;
      } else if (target20 == caller) {
        lite107.messageField |= 2;
        light = lite108;
      } else {
        lite107.messageField |= 4;
        light = lite109;
      }
      light.message(MC.tLightFlasherStartTimedThenStayOn, 2.0);
      addScore(scoring(caller, 0));
      if (bpr_solotgt_lights.message(MC.tLightGroupGetOnCount, 0.0) == 3) {
        soundwave14_1.play();
        gate2.message(MC.tGateDisable, 0.0);
        bpr_solotgt_lights.message(MC.tLightFlasherStartTimedThenStayOff, 2.0);
      } else {
        soundwave49D.play();
      }
    }
  }

  void wormHoleDestinationControl(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      if (!lite110.isLit) {
        lite110.message(MC.tLightFlasherStartTimedThenStayOn, 3.0);
        info_text_box.display(rc(194), 2.0);
      }
      addScore(scoring(caller, 0));
      advanceWormHoleDestination(1);
    }
  }

  void blackHoleKickoutControl(int code, TablePart? caller) {
    var buffer = '';

    if (code == MC.controlCollision) {
      final int addedScore = addScore(scoring(caller, 0));
      buffer = fmt(rc(181), [addedScore]);
      info_text_box.display(buffer, 2.0);
      caller!.message(MC.tKickoutRestartTimer, -1.0);
    }
  }

  void flagControl(int code, TablePart? caller) {
    if (code == MC.controlSpinnerLoopReset) {
      advanceWormHoleDestination(0);
    } else if (code == MC.controlCollision) {
      final int score = scoring(caller, lite20.isLit ? 1 : 0);
      addScore(score);
    }
  }

  void gravityWellKickoutControl(int code, TablePart? caller, [int score = 0]) {
    var buffer = '';

    switch (code) {
      case MC.controlCollision:
        {
          final addedScore = addScore(scoring(caller, 0));
          buffer = fmt(rc(182), [addedScore]);
          info_text_box.display(buffer, 2.0);
          lite62.message(MC.tLightResetAndTurnOff, 0.0);
          (caller! as KickoutPart).active = false;
          final duration = soundwave7.play();
          caller.message(MC.tKickoutRestartTimer, duration);
          break;
        }
      case MC.controlEnableMultiplier:
        {
          if (score != 0) {
            buffer = fmt(rc(183), [score]);
          } else {
            buffer = fmt('%s', [rc(146)]);
          }
          info_text_box.display(buffer, 2.0);
          lite62.message(MC.tLightFlasherStart, 0.0);
          kickout1.active = true;
          break;
        }
      case MC.reset:
        kickout1.active = false;
        break;
      default:
        break;
    }
  }

  void skillShotGate1Control(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      lite200.message(MC.tLightTurnOnTimed, 5.0);
      if (lite67.isLit) {
        skill_shot_lights.message(MC.tLightGroupReset, 0.0);
        skill_shot_lights.message(MC.tLightResetAndTurnOff, 0.0);
        lite67.message(MC.tLightResetAndTurnOn, 0.0);
        lite54.message(MC.tLightFlasherStartTimed, 5.0);
        lite25.message(MC.tLightFlasherStartTimed, 5.0);
        fuel_bargraph.message(MC.tLightGroupToggleSplitIndex, 11.0);
        soundwave14_2.play();
      }
    }
  }

  void skillShotGate2Control(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      if (lite67.isLit) {
        lite68.message(MC.tLightResetAndTurnOn, 0.0);
        soundwave14_2.play();
      }
    }
  }

  void skillShotGate3Control(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      if (lite67.isLit) {
        lite69.message(MC.tLightResetAndTurnOn, 0.0);
        soundwave14_2.play();
      }
    }
  }

  void skillShotGate4Control(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      if (lite67.isLit) {
        lite131.message(MC.tLightResetAndTurnOn, 0.0);
        soundwave14_2.play();
      }
    }
  }

  void skillShotGate5Control(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      if (lite67.isLit) {
        lite132.message(MC.tLightResetAndTurnOn, 0.0);
        soundwave14_2.play();
      }
    }
  }

  void skillShotGate6Control(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      if (lite67.isLit) {
        lite133.message(MC.tLightResetAndTurnOn, 0.0);
        soundwave14_2.play();
      }
    }
  }

  void shootAgainLightControl(int code, TablePart? caller) {
    if (code == MC.controlTimerExpired) {
      if (_b(caller!.messageField)) {
        caller.messageField = 0;
      } else {
        caller.message(MC.tLightFlasherStartTimedThenStayOff, 5.0);
        caller.messageField = 1;
      }
    }
  }

  void escapeChuteSinkControl(int code, TablePart? caller) {
    if (code == MC.controlCollision) {
      caller!.message(MC.tSinkResetTimer, -1.0);
    }
  }

  void missionControl(int code, TablePart? caller) {
    if (!_b(lite198)) return;

    final int lite198Msg = lite198.messageField;
    switch (code) {
      case MC.tLightGroupCountdownEnded:
        if (fuel_bargraph == caller && lite198Msg > 1) {
          l_trek_lights.message(MC.tLightGroupReset, 0.0);
          l_trek_lights.message(MC.tLightResetAndTurnOff, 0.0);
          r_trek_lights.message(MC.tLightGroupReset, 0.0);
          r_trek_lights.message(MC.tLightResetAndTurnOff, 0.0);
          mission_text_box.display(rc(210), 4.0);
          lite198.messageField = 1;
          missionControl(MC.controlMissionComplete, null);
        }
        break;
      case MC.controlTimerExpired:
        if (fuel_bargraph == caller && _b(lite198Msg)) {
          if (fuel_bargraph.message(MC.tLightGroupGetOnCount, 0.0) == 1) {
            mission_text_box.display(rc(217), 4.0);
          }
          break;
        }
        if (mission_text_box == caller) code = MC.controlMissionStarted;
        break;
      case MC.resume:
        code = MC.controlMissionStarted;
        break;
      default:
        break;
    }

    switch (lite198Msg) {
      case 0:
        waitingDeploymentController(code, caller);
        break;
      case 1:
        selectMissionController(code, caller);
        break;
      case 2:
        practiceMissionController(code, caller);
        break;
      case 3:
        launchTrainingController(code, caller);
        break;
      case 4:
        reentryTrainingController(code, caller);
        break;
      case 5:
        scienceMissionController(code, caller);
        break;
      case 6:
        strayCometController(code, caller);
        break;
      case 7:
        blackHoleThreatController(code, caller);
        break;
      case 8:
        spaceRadiationController(code, caller);
        break;
      case 9:
        bugHuntController(code, caller);
        break;
      case 10:
        alienMenaceController(code, caller);
        break;
      case 11:
        rescueMissionController(code, caller);
        break;
      case 12:
        satelliteController(code, caller);
        break;
      case 13:
        reconnaissanceController(code, caller);
        break;
      case 14:
        doomsdayMachineController(code, caller);
        break;
      case 15:
        cosmicPlagueController(code, caller);
        break;
      case 16:
        secretMissionYellowController(code, caller);
        break;
      case 17:
        timeWarpController(code, caller);
        break;
      case 18:
        maelstromController(code, caller);
        break;
      /*case 19: QuoteController*/
      case 20:
        alienMenacePartTwoController(code, caller);
        break;
      case 21:
        cosmicPlaguePartTwoController(code, caller);
        break;
      case 22:
        secretMissionRedController(code, caller);
        break;
      case 23:
        secretMissionGreenController(code, caller);
        break;
      case 24:
        timeWarpPartTwoController(code, caller);
        break;
      case 25:
        maelstromPartTwoController(code, caller);
        break;
      case 26:
        maelstromPartThreeController(code, caller);
        break;
      case 27:
        maelstromPartFourController(code, caller);
        break;
      case 28:
        maelstromPartFiveController(code, caller);
        break;
      case 29:
        maelstromPartSixController(code, caller);
        break;
      case 30:
        maelstromPartSevenController(code, caller);
        break;
      case 31:
        maelstromPartEightController(code, caller);
        break;
      case 32:
        gameoverController(code, caller);
        break;
      default:
        unselectMissionController(code, caller);
        break;
    }
  }

  void hyperspaceKickOutControl(int code, TablePart? caller) {
    var buffer = '';

    if (code != MC.controlCollision) return;

    final activeCount = hyper_lights.message(MC.tLightGroupGetOnCount, 0.0);
    hyperspaceLightGroupControl(MC.tLightGroupResetAndTurnOn, hyper_lights);
    switch (activeCount) {
      case 0:
        {
          final addedScore = addScore(scoring(caller, 0));
          buffer = fmt(rc(113), [addedScore]);
          info_text_box.display(buffer, 2.0);
          break;
        }
      case 1:
        {
          if (!fullTiltMode) {
            final addedScore = specialAddScore(t.jackpotScore);
            buffer = fmt(rc(115), [addedScore]);
            info_text_box.display(buffer, 2.0);
            t.jackpotScore = 20000;
          } else {
            t.jackpotScore *= 2;
            if (t.jackpotScore > 10000000) t.jackpotScore = 10000000;
            info_text_box.display('Jackpot Doubled', 2.0); // Full Tilt only
          }
          break;
        }
      case 2:
        {
          drainBallBlockerControl(MC.tBlockerEnable, block1);
          final addedScore = addScore(scoring(caller, 2));
          buffer = fmt(rc(103), [addedScore]);
          info_text_box.display(buffer, 2.0);
          break;
        }
      case 3:
        {
          extraBallLightControl(MC.tLightResetAndTurnOn, null);
          final addedScore = addScore(scoring(caller, 3));
          buffer = fmt(rc(109), [addedScore]);
          info_text_box.display(buffer, 2.0);
          break;
        }
      case 4:
        {
          hyper_lights.message(MC.tLightTurnOff, 0.0);
          final int addedScore = addScore(scoring(caller, 4));
          gravityWellKickoutControl(
            MC.controlEnableMultiplier,
            null,
            addedScore,
          );
          break;
        }
      default:
        break;
    }

    int someFlag = 0;
    if (lite25.isLit) {
      someFlag = 1;
      final addedScore = specialAddScore(t.reflexShotScore);
      buffer = fmt(rc(111), [addedScore]);
      info_text_box.display(buffer, 2.0);
    }
    if (lite26.isLit) someFlag |= 2;
    if (lite130.isLit) {
      someFlag |= 4;
      lite130.message(MC.tLightResetAndTurnOff, 0.0);
      multiplierLightGroupControl(
        MC.controlEnableMultiplier,
        top_target_lights,
      );
      bumber_target_lights.message(MC.tLightResetAndTurnOn, 0.0);
      tableSetJackpot();
      tableSetBonus();
      tableSetFlagLights();
      tableSetBonusHold();
      lite27.message(MC.tLightResetAndTurnOn, 0.0);
      lite28.message(MC.tLightResetAndTurnOn, 0.0);
      extraBallLightControl(MC.tLightResetAndTurnOn, null);
      drainBallBlockerControl(MC.tBlockerEnable, block1);

      if (t.multiballFlag) {
        final duration = soundwave41.play();
        tableSetMultiball(duration);
      }
      if (t.jackpotScore < 100000) t.jackpotScore = 100000;
      if (t.bonusScore < 100000) t.bonusScore = 100000;
      gravityWellKickoutControl(MC.controlEnableMultiplier, null);
    }

    SoundPart sound;
    if (_b(someFlag)) {
      if (someFlag == 1) {
        sound = soundwave21;
      } else {
        if (someFlag < (!fullTiltMode ? 1 : 2) || someFlag > 3) {
          final duration = soundwave41.play();
          soundwave36_1.play();
          soundwave50_2.play();
          lite25.message(MC.tLightFlasherStartTimed, duration + 5.0);
          caller!.message(MC.tKickoutRestartTimer, duration);
          return;
        }
        sound = soundwave40;
      }
    } else {
      switch (activeCount) {
        case 1:
          sound = soundwave36_2;
          break;
        case 2:
          sound = soundwave35_2;
          break;
        case 3:
          sound = soundwave38;
          break;
        case 4:
          sound = soundwave39;
          break;
        default:
          sound = soundwave35_1;
          break;
      }
    }
    final duration = sound.play();
    lite25.message(MC.tLightFlasherStartTimed, 5.0);
    caller!.message(MC.tKickoutRestartTimer, duration);
  }

  void plungerControl(int code, TablePart? caller) {
    if (code == MC.plungerFeedBall) {
      missionControl(MC.controlMissionStarted, null);
      if (easyMode && !block1.active)
        drainBallBlockerControl(MC.tBlockerEnable, block1);
    } else if (code == MC.plungerStartFeedTimer) {
      tableUnlimitedBalls = false;
      if (!_b(middle_circle.message(MC.tLightGroupGetOnCount, 0.0)))
        middle_circle.message(MC.tLightGroupOffsetAnimationForward, 0.0);
      if (!lite200.isLit) {
        skill_shot_lights.message(MC.tLightResetAndTurnOff, 0.0);
        lite67.message(MC.tLightResetAndTurnOn, 0.0);
        skill_shot_lights.message(MC.tLightGroupAnimationBackward, 0.25);
        l_trek_lights.message(MC.tLightResetAndTurnOff, 0.0);
        l_trek_lights.message(MC.tLightGroupOffsetAnimationForward, 0.2);
        l_trek_lights.message(MC.tLightGroupAnimationBackward, 0.2);
        r_trek_lights.message(MC.tLightResetAndTurnOff, 0.0);
        r_trek_lights.message(MC.tLightGroupOffsetAnimationForward, 0.2);
        r_trek_lights.message(MC.tLightGroupAnimationBackward, 0.2);
        t.reflexShotScore = 25000;
        multiplierLightGroupControl(
          MC.controlDisableMultiplier,
          top_target_lights,
        );
        fuel_bargraph.message(MC.tLightResetAndTurnOn, 0.0);
        lite200.message(MC.tLightResetAndTurnOn, 0.0);
        gate1.message(MC.tGateDisable, 0.0);
        gate2.message(MC.tGateDisable, 0.0);
      }
      lite200.messageField = 0;
    }
  }

  void medalTargetControl(int code, TablePart? caller) {
    if (code == MC.controlCollision && !_b(caller!.messageField)) {
      caller.messageField = 1;
      if (target6.messageField + target5.messageField + target4.messageField ==
          3) {
        medalLightGroupControl(
          MC.tLightGroupResetAndTurnOn,
          bumber_target_lights,
        );
        final int activeCount =
            bumber_target_lights.message(MC.tLightGroupGetOnCount, 0.0) - 1;
        String text;
        switch (activeCount) {
          case 0:
            addScore(scoring(caller, 1));
            text = rc(154);
            break;
          case 1:
            addScore(scoring(caller, 2));
            text = rc(155);
            break;
          default:
            tableAddExtraBall(4.0);
            text = rc(156);
            break;
        }
        info_text_box.display(text, 2.0);
        target6.messageField = 0;
        target6.message(MC.tPopupTargetEnable, 0.0);
        target5.messageField = 0;
        target5.message(MC.tPopupTargetEnable, 0.0);
        target4.messageField = 0;
        target4.message(MC.tPopupTargetEnable, 0.0);
        return;
      }
      addScore(scoring(caller, 0));
    }
  }

  void multiplierTargetControl(int code, TablePart? caller) {
    if (code == MC.controlCollision && !_b(caller!.messageField)) {
      caller.messageField = 1;
      if (target9.messageField + target8.messageField + target7.messageField ==
          3) {
        addScore(scoring(caller, 1));
        multiplierLightGroupControl(
          MC.tLightGroupResetAndTurnOn,
          top_target_lights,
        );
        final int activeCount = top_target_lights.message(
          MC.tLightGroupGetOnCount,
          0.0,
        );
        String text;
        switch (activeCount) {
          case 1:
            t.scoreMultiplier = 1;
            text = rc(157);
            break;
          case 2:
            t.scoreMultiplier = 2;
            text = rc(158);
            break;
          case 3:
            t.scoreMultiplier = 3;
            text = rc(159);
            break;
          default:
            t.scoreMultiplier = 4;
            text = rc(160);
            break;
        }

        info_text_box.display(text, 2.0);
        target9.messageField = 0;
        target9.message(MC.tPopupTargetEnable, 0.0);
        target8.messageField = 0;
        target8.message(MC.tPopupTargetEnable, 0.0);
        target7.messageField = 0;
        target7.message(MC.tPopupTargetEnable, 0.0);
      } else {
        addScore(scoring(caller, 0));
      }
    }
  }

  void ballDrainControl(int code, TablePart? caller) {
    var buffer = '';

    if (code == MC.controlTimerExpired) {
      if (_b(lite199.messageField)) {
        t.message(MC.gameOver, 0.0);
        if (checkHighScore()) {
          soundwave3.play();
          t.lightGroup.message(MC.tLightFlasherStartTimedThenStayOff, 3.0);
          mission_text_box.display(rc(277), -1.0);
        }
      } else {
        plunger.message(MC.plungerStartFeedTimer, 0.0);
      }
    } else if (code == MC.controlCollision) {
      if (tableUnlimitedBalls) {
        drain.message(MC.reset, 0.0);
        sink3.message(MC.tSinkResetTimer, 0.0);
      } else {
        if (t.tiltLockFlag) {
          lite200.message(MC.tLightResetAndTurnOff, 0.0);
          lite199.message(MC.tLightResetAndTurnOff, 0.0);
          // (music)
        }
        if (lite200.isLit) {
          soundwave27.play();
          lite200.message(MC.tLightResetAndTurnOn, 0.0);
          info_text_box.display(rc(197), -1.0);
          soundwave59.play();
        } else if (lite199.isLit) {
          soundwave27.play();
          lite199.message(MC.tLightResetAndTurnOff, 0.0);
          lite200.message(MC.tLightResetAndTurnOn, 0.0);
          info_text_box.display(rc(196), 2.0);
          soundwave59.play();
          --t.unknownP78;
        } else if (_b(t.multiballCount)) {
          if (t.multiballCount == 1) {
            lite38.message(MC.tLightResetAndTurnOff, 0.0);
            lite39.message(MC.tLightResetAndTurnOff, 0.0);
            // (music)
          } else if (t.multiballCount == 2) {
            lite40.message(MC.tLightResetAndTurnOff, 0.0);
          }
        } else {
          if (!t.tiltLockFlag) {
            final int time = specialAddScore(t.bonusScore);
            buffer = fmt(rc(195), [time]);
            info_text_box.display(buffer, 2.0);
          }
          if (_b(t.extraBalls)) {
            t.extraBalls--;

            String shootAgainText;
            soundwave59.play();
            switch (t.currentPlayer) {
              case 0:
                shootAgainText = rc(198);
                break;
              case 1:
                shootAgainText = rc(199);
                break;
              case 2:
                shootAgainText = rc(200);
                break;
              case 3:
              default:
                shootAgainText = rc(201);
                break;
            }
            info_text_box.display(shootAgainText, -1.0);
          } else {
            t.changeBallCount(t.ballCount - 1);
            if (t.currentPlayer + 1 != t.playerCount || _b(t.ballCount)) {
              t.message(MC.switchToNextPlayer, 0.0);
              lite199.messageField = 0;
            } else {
              lite199.messageField = 1;
            }
            soundwave27.play();
          }
          bmpr_inc_lights.message(MC.tLightResetAndTurnOff, 0.0);
          ramp_bmpr_inc_lights.message(MC.tLightResetAndTurnOff, 0.0);
          lite30.message(MC.tLightResetAndTurnOff, 0.0);
          lite29.message(MC.tLightResetAndTurnOff, 0.0);
          lite1.message(MC.tLightResetAndTurnOff, 0.0);
          lite54.message(MC.tLightResetAndTurnOff, 0.0);
          lite55.message(MC.tLightResetAndTurnOff, 0.0);
          lite56.message(MC.tLightResetAndTurnOff, 0.0);
          lite17.message(MC.tLightResetAndTurnOff, 0.0);
          lite18.message(MC.tLightResetAndTurnOff, 0.0);
          lite27.message(MC.tLightResetAndTurnOff, 0.0);
          lite28.message(MC.tLightResetAndTurnOff, 0.0);
          lite16.message(MC.tLightResetAndTurnOff, 0.0);
          lite20.message(MC.tLightResetAndTurnOff, 0.0);
          hyper_lights.message(MC.tLightResetAndTurnOff, 0.0);
          lite25.message(MC.tLightResetAndTurnOff, 0.0);
          lite26.message(MC.tLightResetAndTurnOff, 0.0);
          lite130.message(MC.tLightResetAndTurnOff, 0.0);
          lite19.message(MC.tLightResetAndTurnOff, 0.0);
          worm_hole_lights.message(MC.tLightResetAndTurnOff, 0.0);
          bsink_arrow_lights.message(MC.tLightResetAndTurnOff, 0.0);
          l_trek_lights.message(MC.tLightResetAndTurnOff, 0.0);
          r_trek_lights.message(MC.tLightResetAndTurnOff, 0.0);
          lite60.message(MC.tLightResetAndTurnOff, 0.0);
          lite59.message(MC.tLightResetAndTurnOff, 0.0);
          lite61.message(MC.tLightResetAndTurnOff, 0.0);
          bumber_target_lights.message(MC.tLightResetAndTurnOff, 0.0);
          top_target_lights.message(MC.tLightResetAndTurnOff, 0.0);
          top_circle_tgt_lights.message(MC.tLightResetAndTurnOff, 0.0);
          ramp_tgt_lights.message(MC.tLightResetAndTurnOff, 0.0);
          lchute_tgt_lights.message(MC.tLightResetAndTurnOff, 0.0);
          bpr_solotgt_lights.message(MC.tLightResetAndTurnOff, 0.0);
          lite110.message(MC.tLightResetAndTurnOff, 0.0);
          skill_shot_lights.message(MC.tLightResetAndTurnOff, 0.0);
          lite77.message(MC.tLightResetAndTurnOff, 0.0);
          lite198.message(MC.tLightResetAndTurnOff, 0.0);
          lite196.message(MC.tLightResetAndTurnOff, 0.0);
          lite195.message(MC.tLightResetAndTurnOff, 0.0);
          fuel_bargraph.message(MC.tLightResetAndTurnOff, 0.0);
          fuel_bargraph.message(MC.reset, 0.0);
          gravityWellKickoutControl(MC.reset, null);
          lite62.message(MC.tLightResetAndTurnOff, 0.0);
          lite4.messageField = 0;
          lite101.messageField = 0;
          lite102.messageField = 0;
          lite103.messageField = 0;
          ramp_tgt_lights.messageField = 0;
          outer_circle.message(MC.tLightGroupReset, 0.0);
          middle_circle.message(MC.tLightGroupReset, 0.0);
          attack_bump.message(MC.reset, 0.0);
          launch_bump.message(MC.reset, 0.0);
          gate1.message(MC.reset, 0.0);
          gate2.message(MC.reset, 0.0);
          block1.message(MC.reset, 0.0);
          target1.message(MC.reset, 0.0);
          target2.message(MC.reset, 0.0);
          target3.message(MC.reset, 0.0);
          target6.message(MC.reset, 0.0);
          target5.message(MC.reset, 0.0);
          target4.message(MC.reset, 0.0);
          target9.message(MC.reset, 0.0);
          target8.message(MC.reset, 0.0);
          target7.message(MC.reset, 0.0);
          if (_b(lite199.messageField))
            lite198.messageField = 32;
          else
            lite198.messageField = 0;
          missionControl(MC.controlMissionComplete, null);
          t.message(MC.clearTiltLock, 0.0);
          if (lite58.isLit)
            lite58.message(MC.tLightResetAndTurnOff, 0.0);
          else
            t.bonusScore = 25000;
        }
      }
    }
  }

  @override
  void tableControlHandler(int code) {
    if (code == MC.setTiltLock) {
      tableUnlimitedBalls = false;
      lite77.message(MC.tLightFlasherStartTimed, 0.0);
    }
  }

  void alienMenaceController(int code, TablePart? caller) {
    if (code != MC.tBumperSetBmpIndex) {
      if (code == MC.controlMissionComplete) {
        attack_bump.message(MC.tBumperSetBmpIndex, 0.0);
        l_trek_lights.message(MC.tLightResetAndTurnOff, 0.0);
        l_trek_lights.message(MC.tLightGroupOffsetAnimationForward, 0.2);
        l_trek_lights.message(MC.tLightGroupAnimationBackward, 0.2);
        r_trek_lights.message(MC.tLightResetAndTurnOff, 0.0);
        r_trek_lights.message(MC.tLightGroupOffsetAnimationForward, 0.2);
        r_trek_lights.message(MC.tLightGroupAnimationBackward, 0.2);
        lite307.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      mission_text_box.display(rc(275), -1.0);
      return;
    }
    if (bump1 == caller) {
      if (_b(bump1.bmpIndex)) {
        lite307.message(MC.tLightResetAndTurnOff, 0.0);
        lite198.messageField = 20;
        missionControl(MC.controlMissionComplete, null);
      }
    }
  }

  void alienMenacePartTwoController(int code, TablePart? caller) {
    var buffer = '';

    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite56.messageField = 8;
        l_trek_lights.message(MC.tLightGroupReset, 0.0);
        l_trek_lights.message(MC.tLightResetAndTurnOff, 0.0);
        r_trek_lights.message(MC.tLightGroupReset, 0.0);
        r_trek_lights.message(MC.tLightResetAndTurnOff, 0.0);
        lite308.message(MC.tLightFlasherStartTimed, 0.0);
        lite311.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      buffer = fmt(rc(208), [lite56.messageField]);
      mission_text_box.display(buffer, -1.0);
      return;
    }
    if (bump1 == caller ||
        bump2 == caller ||
        bump3 == caller ||
        bump4 == caller) {
      lite56.messageField = lite56.messageField - 1;
      if (_b(lite56.messageField)) {
        missionControl(MC.controlMissionStarted, caller);
      } else {
        lite308.message(MC.tLightResetAndTurnOff, 0.0);
        lite311.message(MC.tLightResetAndTurnOff, 0.0);
        lite198.messageField = 1;
        missionControl(MC.controlMissionComplete, null);
        mission_text_box.display(rc(231), 4.0);
        final int addedScore = specialAddScore(750000, true);
        buffer = fmt(rc(179), [addedScore]);
        if (!_b(addRankProgress(7))) {
          mission_text_box.display(buffer, 8.0);
          soundwave9.play();
        }
      }
    }
  }

  void blackHoleThreatController(int code, TablePart? caller) {
    var buffer = '';

    if (code == MC.tBumperSetBmpIndex) {
      if (bump5 == caller) missionControl(MC.controlMissionStarted, caller);
    } else if (code == MC.controlCollision) {
      if (kickout3 == caller && _b(bump5.bmpIndex)) {
        if (lite316.isLit) lite316.message(MC.tLightResetAndTurnOff, 0.0);
        if (lite314.isLit) lite314.message(MC.tLightResetAndTurnOff, 0.0);
        lite198.messageField = 1;
        missionControl(MC.controlMissionComplete, null);
        mission_text_box.display(rc(225), 4.0);
        final int addedScore = specialAddScore(1000000, true);
        buffer = fmt(rc(179), [addedScore]);
        if (!_b(addRankProgress(8))) {
          mission_text_box.display(buffer, 8.0);
          soundwave9.play();
        }
      }
    } else {
      if (code == MC.controlMissionComplete) {
        launch_bump.message(MC.tBumperSetBmpIndex, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      if (_b(bump5.bmpIndex)) {
        mission_text_box.display(rc(224), -1.0);
        if (lite316.isLit) lite316.message(MC.tLightResetAndTurnOff, 0.0);
        if (!lite314.isLit) {
          lite314.message(MC.tLightFlasherStartTimed, 0.0);
        }
      } else {
        mission_text_box.display(rc(223), -1.0);
        if (lite314.isLit) lite314.message(MC.tLightResetAndTurnOff, 0.0);
        if (!lite316.isLit) {
          lite316.message(MC.tLightFlasherStartTimed, 0.0);
        }
      }
    }
  }

  void bugHuntController(int code, TablePart? caller) {
    var buffer = '';

    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite56.messageField = 15;
        target1.messageField = 0;
        target1.message(MC.tPopupTargetEnable, 0.0);
        target2.messageField = 0;
        target2.message(MC.tPopupTargetEnable, 0.0);
        target3.messageField = 0;
        target3.message(MC.tPopupTargetEnable, 0.0);
        target6.messageField = 0;
        target6.message(MC.tPopupTargetEnable, 0.0);
        target5.messageField = 0;
        target5.message(MC.tPopupTargetEnable, 0.0);
        target4.messageField = 0;
        target4.message(MC.tPopupTargetEnable, 0.0);
        target9.messageField = 0;
        target9.message(MC.tPopupTargetEnable, 0.0);
        target8.messageField = 0;
        target8.message(MC.tPopupTargetEnable, 0.0);
        target7.messageField = 0;
        target7.message(MC.tPopupTargetEnable, 0.0);
        top_circle_tgt_lights.message(MC.tLightResetAndTurnOff, 0.0);
        ramp_tgt_lights.message(MC.tLightResetAndTurnOff, 0.0);
        lchute_tgt_lights.message(MC.tLightResetAndTurnOff, 0.0);
        bpr_solotgt_lights.message(MC.tLightResetAndTurnOff, 0.0);
        lite306.message(MC.tLightFlasherStartTimed, 0.0);
        lite308.message(MC.tLightFlasherStartTimed, 0.0);
        lite310.message(MC.tLightFlasherStartTimed, 0.0);
        lite313.message(MC.tLightFlasherStartTimed, 0.0);
        lite319.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      buffer = fmt(rc(226), [lite56.messageField]);
      mission_text_box.display(buffer, -1.0);
      return;
    }
    if (target1 == caller ||
        target2 == caller ||
        target3 == caller ||
        target6 == caller ||
        target5 == caller ||
        target4 == caller ||
        target9 == caller ||
        target8 == caller ||
        target7 == caller ||
        target10 == caller ||
        target11 == caller ||
        target12 == caller ||
        target13 == caller ||
        target14 == caller ||
        target15 == caller ||
        target16 == caller ||
        target17 == caller ||
        target18 == caller ||
        target19 == caller ||
        target20 == caller ||
        target21 == caller ||
        target22 == caller) {
      lite56.messageField = lite56.messageField - 1;
      if (_b(lite56.messageField)) {
        missionControl(MC.controlMissionStarted, caller);
      } else {
        lite306.message(MC.tLightResetAndTurnOff, 0.0);
        lite308.message(MC.tLightResetAndTurnOff, 0.0);
        lite310.message(MC.tLightResetAndTurnOff, 0.0);
        lite313.message(MC.tLightResetAndTurnOff, 0.0);
        lite319.message(MC.tLightResetAndTurnOff, 0.0);
        lite198.messageField = 1;
        missionControl(MC.controlMissionComplete, null);
        mission_text_box.display(rc(227), 4.0);
        final int addedScore = specialAddScore(750000, true);
        buffer = fmt(rc(179), [addedScore]);
        if (!_b(addRankProgress(7))) {
          mission_text_box.display(buffer, 8.0);
          soundwave9.play();
        }
      }
    }
  }

  void cosmicPlagueController(int code, TablePart? caller) {
    var buffer = '';

    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite56.messageField = 75;
        lite20.message(MC.tLightResetAndTurnOn, 0.0);
        lite19.message(MC.tLightResetAndTurnOn, 0.0);
        lite305.message(MC.tLightFlasherStartTimed, 0.0);
        lite312.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      buffer = fmt(rc(240), [lite56.messageField]);
      mission_text_box.display(buffer, -1.0);
      return;
    }
    if (flag1 == caller || flag2 == caller) {
      lite56.messageField = lite56.messageField - 1;
      if (_b(lite56.messageField)) {
        missionControl(MC.controlMissionStarted, caller);
      } else {
        lite305.message(MC.tLightResetAndTurnOff, 0.0);
        lite312.message(MC.tLightResetAndTurnOff, 0.0);
        lite198.messageField = 21;
        missionControl(MC.controlMissionComplete, null);
        lite20.message(MC.tLightResetAndTurnOff, 0.0);
        lite19.message(MC.tLightResetAndTurnOff, 0.0);
      }
    }
  }

  void cosmicPlaguePartTwoController(int code, TablePart? caller) {
    var buffer = '';

    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite310.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      mission_text_box.display(rc(241), -1.0);
      return;
    }
    if (roll9 == caller) {
      lite310.message(MC.tLightResetAndTurnOff, 0.0);
      lite198.messageField = 1;
      missionControl(MC.controlMissionComplete, null);
      mission_text_box.display(rc(242), 4.0);
      final int addedScore = specialAddScore(1750000, true);
      buffer = fmt(rc(179), [addedScore]);
      if (!_b(addRankProgress(11))) {
        mission_text_box.display(buffer, 8.0);
        soundwave9.play();
      }
    }
  }

  void doomsdayMachineController(int code, TablePart? caller) {
    var buffer = '';

    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite56.messageField = 3;
        lite301.message(MC.tLightFlasherStartTimed, 0.0);
        lite320.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      buffer = fmt(rc(238), [lite56.messageField]);
      mission_text_box.display(buffer, -1.0);
      return;
    }
    if (roll4 == caller || roll8 == caller) {
      lite56.messageField = lite56.messageField - 1;
      if (_b(lite56.messageField)) {
        missionControl(MC.controlMissionStarted, caller);
      } else {
        lite301.message(MC.tLightResetAndTurnOff, 0.0);
        lite320.message(MC.tLightResetAndTurnOff, 0.0);
        lite198.messageField = 1;
        missionControl(MC.controlMissionComplete, null);
        mission_text_box.display(rc(239), 4.0);
        final int addedScore = specialAddScore(1250000, true);
        buffer = fmt(rc(179), [addedScore]);
        if (!_b(addRankProgress(9))) {
          mission_text_box.display(buffer, 8.0);
          soundwave9.play();
        }
      }
    }
  }

  void gameoverController(int code, TablePart? caller) {
    var buffer = '';

    if (code == MC.controlMissionComplete) {
      goal_lights.message(MC.tLightResetAndTurnOff, 0.0);
      onGameOverMode();
      flip1.message(MC.gameOver, 0.0);
      flip2.message(MC.gameOver, 0.0);
      mission_text_box.messageField = 0;
      // (music)
      return;
    }
    if (code != MC.controlMissionStarted) return;

    final int missionMsg = mission_text_box.messageField;
    if (_b(missionMsg & 0x100)) {
      final int playerId = missionMsg % 4;
      final int playerScore = t.playerScore(playerId);
      final nextPlayerId = playerId + 1;
      if (playerScore >= 0) {
        String? playerNScoreText;
        switch (nextPlayerId) {
          case 1:
            playerNScoreText = rc(280);
            break;
          case 2:
            playerNScoreText = rc(281);
            break;
          case 3:
            playerNScoreText = rc(282);
            break;
          case 4:
            playerNScoreText = rc(283);
            break;
          default:
            break;
        }
        if (playerNScoreText != null) {
          buffer = fmt(playerNScoreText, [playerScore]);
          mission_text_box.display(buffer, 3.0);
          final int msgField = nextPlayerId == t.playerCount
              ? 0x200
              : nextPlayerId | 0x100;
          mission_text_box.messageField = msgField;
          return;
        }
      }
      mission_text_box.messageField = 0x200;
    }

    if (_b(missionMsg & 0x200)) {
      final int highscoreId = missionMsg % 5;
      final int highScore = t.highScore(highscoreId);
      final nextHidhscoreId = highscoreId + 1;
      if (highScore > 0) {
        String? highScoreNText;
        switch (nextHidhscoreId) {
          case 1:
            highScoreNText = rc(284);
            break;
          case 2:
            highScoreNText = rc(285);
            break;
          case 3:
            highScoreNText = rc(286);
            break;
          case 4:
            highScoreNText = rc(287);
            break;
          case 5:
            highScoreNText = rc(288);
            break;
          default:
            break;
        }
        if (highScoreNText != null) {
          buffer = fmt(highScoreNText, [highScore]);
          mission_text_box.display(buffer, 3.0);
          final int msgField = nextHidhscoreId == 5
              ? 0
              : nextHidhscoreId | 0x200;
          mission_text_box.messageField = msgField;
          return;
        }
      }
    }

    mission_text_box.messageField = 0x100;
    mission_text_box.display(rc(272), 10.0);
  }

  void launchTrainingController(int code, TablePart? caller) {
    var buffer = '';

    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite317.message(MC.tLightFlasherStartTimed, 0.0);
        lite56.messageField = 3;
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      buffer = fmt(rc(211), [lite56.messageField]);
      mission_text_box.display(buffer, -1.0);
      return;
    }
    if (ramp == caller) {
      lite56.messageField = lite56.messageField - 1;
      if (_b(lite56.messageField)) {
        missionControl(MC.controlMissionStarted, caller);
      } else {
        lite317.message(MC.tLightResetAndTurnOff, 0.0);
        lite198.messageField = 1;
        missionControl(MC.controlMissionComplete, null);
        mission_text_box.display(rc(212), 4.0);
        final int addedScore = specialAddScore(500000, true);
        buffer = fmt(rc(179), [addedScore]);
        if (!_b(addRankProgress(6))) {
          mission_text_box.display(buffer, 8.0);
          soundwave9.play();
        }
      }
    }
  }

  void maelstromController(int code, TablePart? caller) {
    var buffer = '';

    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite56.messageField = 3;
        lite303.message(MC.tLightFlasherStartTimed, 0.0);
        lite309.message(MC.tLightFlasherStartTimed, 0.0);
        lite315.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      buffer = fmt(rc(249), [lite56.messageField]);
      mission_text_box.display(buffer, -1.0);
      return;
    }
    if (target1 == caller ||
        target2 == caller ||
        target3 == caller ||
        target6 == caller ||
        target5 == caller ||
        target4 == caller ||
        target9 == caller ||
        target8 == caller ||
        target7 == caller) {
      lite56.messageField = lite56.messageField - 1;
      if (_b(lite56.messageField)) {
        missionControl(MC.controlMissionStarted, caller);
      } else {
        lite303.message(MC.tLightResetAndTurnOff, 0.0);
        lite309.message(MC.tLightResetAndTurnOff, 0.0);
        lite315.message(MC.tLightResetAndTurnOff, 0.0);
        lite198.messageField = 25;
        missionControl(MC.controlMissionComplete, null);
      }
    }
  }

  void maelstromPartEightController(int code, TablePart? caller) {
    var buffer = '';

    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite130.message(MC.tLightResetAndTurnOn, 0.0);
        lite304.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      mission_text_box.display(rc(256), -1.0);
      return;
    }
    if (kickout2 == caller) {
      lite304.message(MC.tLightResetAndTurnOff, 0.0);
      lite130.message(MC.tLightResetAndTurnOff, 0.0);
      lite198.messageField = 1;
      missionControl(MC.controlMissionComplete, null);
      final int addedScore = specialAddScore(5000000, true);
      buffer = fmt(rc(179), [addedScore]);
      info_text_box.display(rc(149), 4.0);
      if (!_b(addRankProgress(18))) {
        mission_text_box.display(buffer, 8.0);
        soundwave9.play();
      }
    }
  }

  void maelstromPartFiveController(int code, TablePart? caller) {
    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite317.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      mission_text_box.display(rc(253), -1.0);
      return;
    }
    if (ramp == caller) {
      lite317.message(MC.tLightResetAndTurnOff, 0.0);
      lite198.messageField = 29;
      missionControl(MC.controlMissionComplete, null);
    }
  }

  void maelstromPartFourController(int code, TablePart? caller) {
    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite56.messageField = 0;
        lite318.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      mission_text_box.display(rc(252), -1.0);
      return;
    }
    if (roll184 == caller) {
      lite318.message(MC.tLightResetAndTurnOff, 0.0);
      lite198.messageField = 28;
      missionControl(MC.controlMissionComplete, null);
    }
  }

  void maelstromPartSevenController(int code, TablePart? caller) {
    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        advanceWormHoleDestination(1);
        sink1.message(MC.tSinkUnknown7, 0.0);
        sink2.message(MC.tSinkUnknown7, 0.0);
        sink3.message(MC.tSinkUnknown7, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      mission_text_box.display(rc(255), -1.0);
      return;
    }
    if (sink1 == caller || sink2 == caller || sink3 == caller) {
      lite198.messageField = 31;
      missionControl(MC.controlMissionComplete, null);
    }
  }

  void maelstromPartSixController(int code, TablePart? caller) {
    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite20.message(MC.tLightResetAndTurnOn, 0.0);
        lite19.message(MC.tLightResetAndTurnOn, 0.0);
        lite305.message(MC.tLightFlasherStartTimed, 0.0);
        lite312.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      mission_text_box.display(rc(254), -1.0);
      return;
    }
    if (flag1 == caller || flag2 == caller) {
      lite305.message(MC.tLightResetAndTurnOff, 0.0);
      lite312.message(MC.tLightResetAndTurnOff, 0.0);
      lite198.messageField = 30;
      missionControl(MC.controlMissionComplete, null);
      lite20.message(MC.tLightResetAndTurnOff, 0.0);
      lite19.message(MC.tLightResetAndTurnOff, 0.0);
    }
  }

  void maelstromPartThreeController(int code, TablePart? caller) {
    var buffer = '';

    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite56.messageField = 5;
        lite301.message(MC.tLightFlasherStartTimed, 0.0);
        lite302.message(MC.tLightFlasherStartTimed, 0.0);
        lite307.message(MC.tLightFlasherStartTimed, 0.0);
        lite316.message(MC.tLightFlasherStartTimed, 0.0);
        lite320.message(MC.tLightFlasherStartTimed, 0.0);
        lite321.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      buffer = fmt(rc(251), [lite56.messageField]);
      mission_text_box.display(buffer, -1.0);
      return;
    }
    if (roll3 == caller ||
        roll2 == caller ||
        roll1 == caller ||
        roll112 == caller ||
        roll111 == caller ||
        roll110 == caller ||
        roll4 == caller ||
        roll8 == caller ||
        roll6 == caller ||
        roll7 == caller ||
        roll5 == caller) {
      lite56.messageField = lite56.messageField - 1;
      if (_b(lite56.messageField)) {
        missionControl(MC.controlMissionStarted, caller);
      } else {
        lite301.message(MC.tLightResetAndTurnOff, 0.0);
        lite302.message(MC.tLightResetAndTurnOff, 0.0);
        lite307.message(MC.tLightResetAndTurnOff, 0.0);
        lite316.message(MC.tLightResetAndTurnOff, 0.0);
        lite320.message(MC.tLightResetAndTurnOff, 0.0);
        lite321.message(MC.tLightResetAndTurnOff, 0.0);
        lite198.messageField = 27;
        missionControl(MC.controlMissionComplete, null);
      }
    }
  }

  void maelstromPartTwoController(int code, TablePart? caller) {
    var buffer = '';

    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite56.messageField = 3;
        lite306.message(MC.tLightFlasherStartTimed, 0.0);
        lite308.message(MC.tLightFlasherStartTimed, 0.0);
        lite310.message(MC.tLightFlasherStartTimed, 0.0);
        lite313.message(MC.tLightFlasherStartTimed, 0.0);
        lite319.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      buffer = fmt(rc(250), [lite56.messageField]);
      mission_text_box.display(buffer, -1.0);
      return;
    }
    if (target10 == caller ||
        target11 == caller ||
        target12 == caller ||
        target13 == caller ||
        target14 == caller ||
        target15 == caller ||
        target16 == caller ||
        target17 == caller ||
        target18 == caller ||
        target19 == caller ||
        target20 == caller ||
        target21 == caller ||
        target22 == caller) {
      lite56.messageField = lite56.messageField - 1;
      if (_b(lite56.messageField)) {
        missionControl(MC.controlMissionStarted, caller);
      } else {
        lite306.message(MC.tLightResetAndTurnOff, 0.0);
        lite308.message(MC.tLightResetAndTurnOff, 0.0);
        lite310.message(MC.tLightResetAndTurnOff, 0.0);
        lite313.message(MC.tLightResetAndTurnOff, 0.0);
        lite319.message(MC.tLightResetAndTurnOff, 0.0);
        lite198.messageField = 26;
        missionControl(MC.controlMissionComplete, null);
      }
    }
  }

  void practiceMissionController(int code, TablePart? caller) {
    var buffer = '';

    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite308.message(MC.tLightFlasherStartTimed, 0.0);
        lite311.message(MC.tLightFlasherStartTimed, 0.0);
        lite56.messageField = 8;
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      buffer = fmt(rc(208), [lite56.messageField]);
      mission_text_box.display(buffer, -1.0);
      return;
    }

    if (bump1 == caller ||
        bump2 == caller ||
        bump3 == caller ||
        bump4 == caller) {
      lite56.messageField = lite56.messageField - 1;
      if (_b(lite56.messageField)) {
        missionControl(MC.controlMissionStarted, caller);
      } else {
        lite308.message(MC.tLightResetAndTurnOff, 0.0);
        lite311.message(MC.tLightResetAndTurnOff, 0.0);
        lite198.messageField = 1;
        missionControl(MC.controlMissionComplete, null);
        mission_text_box.display(rc(209), 4.0);
        final int addedScore = specialAddScore(500000, true);
        buffer = fmt(rc(179), [addedScore]);
        if (!_b(addRankProgress(6))) {
          mission_text_box.display(buffer, 8.0);
          soundwave9.play();
        }
      }
    }
  }

  void reconnaissanceController(int code, TablePart? caller) {
    var buffer = '';

    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite56.messageField = 15;
        lite301.message(MC.tLightFlasherStartTimed, 0.0);
        lite302.message(MC.tLightFlasherStartTimed, 0.0);
        lite307.message(MC.tLightFlasherStartTimed, 0.0);
        lite316.message(MC.tLightFlasherStartTimed, 0.0);
        lite320.message(MC.tLightFlasherStartTimed, 0.0);
        lite321.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      buffer = fmt(rc(235), [lite56.messageField]);
      mission_text_box.display(buffer, -1.0);
      return;
    }
    if (roll3 == caller ||
        roll2 == caller ||
        roll1 == caller ||
        roll112 == caller ||
        roll111 == caller ||
        roll110 == caller ||
        roll4 == caller ||
        roll8 == caller ||
        roll6 == caller ||
        roll7 == caller ||
        roll5 == caller) {
      lite56.messageField = lite56.messageField - 1;
      if (_b(lite56.messageField)) {
        missionControl(MC.controlMissionStarted, null);
      } else {
        lite301.message(MC.tLightResetAndTurnOff, 0.0);
        lite302.message(MC.tLightResetAndTurnOff, 0.0);
        lite307.message(MC.tLightResetAndTurnOff, 0.0);
        lite316.message(MC.tLightResetAndTurnOff, 0.0);
        lite320.message(MC.tLightResetAndTurnOff, 0.0);
        lite321.message(MC.tLightResetAndTurnOff, 0.0);
        lite198.messageField = 1;
        missionControl(MC.controlMissionComplete, null);
        mission_text_box.display(rc(237), 4.0);
        final int addedScore = specialAddScore(1250000, true);
        buffer = fmt(rc(179), [addedScore]);
        if (!_b(addRankProgress(9))) {
          mission_text_box.display(buffer, 8.0);
          soundwave9.play();
        }
      }
    }
  }

  void reentryTrainingController(int code, TablePart? caller) {
    var buffer = '';

    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite56.messageField = 3;
        l_trek_lights.message(MC.tLightResetAndTurnOff, 0.0);
        l_trek_lights.message(MC.tLightGroupOffsetAnimationForward, 0.2);
        l_trek_lights.message(MC.tLightGroupAnimationBackward, 0.2);
        r_trek_lights.message(MC.tLightResetAndTurnOff, 0.0);
        r_trek_lights.message(MC.tLightGroupOffsetAnimationForward, 0.2);
        r_trek_lights.message(MC.tLightGroupAnimationBackward, 0.2);
        lite307.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      buffer = fmt(rc(213), [lite56.messageField]);
      mission_text_box.display(buffer, -1.0);
      return;
    }
    if (roll3 == caller || roll2 == caller || roll1 == caller) {
      lite56.messageField = lite56.messageField - 1;
      if (_b(lite56.messageField)) {
        missionControl(MC.controlMissionStarted, caller);
      } else {
        lite307.message(MC.tLightResetAndTurnOff, 0.0);
        lite198.messageField = 1;
        missionControl(MC.controlMissionComplete, null);
        mission_text_box.display(rc(214), 4.0);
        final int addedScore = specialAddScore(500000, true);
        buffer = fmt(rc(179), [addedScore]);
        if (!_b(addRankProgress(6))) {
          mission_text_box.display(buffer, 8.0);
          soundwave9.play();
        }
      }
    }
  }

  void rescueMissionController(int code, TablePart? caller) {
    var buffer = '';

    switch (code) {
      case MC.controlCollision:
        {
          if (target1 == caller || target2 == caller || target3 == caller) {
            missionControl(MC.controlMissionStarted, caller);
            return;
          }
          if (kickout2 != caller || !lite20.isLit) return;
          lite56.messageField = lite56.messageField - 1;
          if (_b(lite56.messageField)) {
            missionControl(MC.controlMissionStarted, caller);
            return;
          }
          if (lite303.isLit) lite303.message(MC.tLightResetAndTurnOff, 0.0);
          if (lite304.isLit) lite304.message(MC.tLightResetAndTurnOff, 0.0);
          lite198.messageField = 1;
          missionControl(MC.controlMissionComplete, null);
          mission_text_box.display(rc(230), 4.0);
          final int addedScore = specialAddScore(750000, true);
          buffer = fmt(rc(179), [addedScore]);
          if (!_b(addRankProgress(7))) {
            mission_text_box.display(buffer, 8.0);
            soundwave9.play();
          }
          break;
        }
      case MC.controlMissionComplete:
        lite20.message(MC.tLightResetAndTurnOff, 0.0);
        lite19.message(MC.tLightResetAndTurnOff, 0.0);
        lite56.messageField = 1;
        break;
      case MC.controlMissionStarted:
        if (lite20.isLit) {
          mission_text_box.display(rc(229), -1.0);
          if (lite303.isLit) lite303.message(MC.tLightResetAndTurnOff, 0.0);
          if (!lite304.isLit) {
            lite304.message(MC.tLightFlasherStartTimed, 0.0);
          }
        } else {
          mission_text_box.display(rc(228), -1.0);
          if (lite304.isLit) lite304.message(MC.tLightResetAndTurnOff, 0.0);
          if (!lite303.isLit) {
            lite303.message(MC.tLightFlasherStartTimed, 0.0);
          }
        }
        break;
      default:
        break;
    }
  }

  void satelliteController(int code, TablePart? caller) {
    var buffer = '';

    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite56.messageField = 3;
        lite308.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      buffer = fmt(rc(233), [lite56.messageField]);
      mission_text_box.display(buffer, -1.0);
      return;
    }
    if (bump4 == caller) {
      lite56.messageField = lite56.messageField - 1;
      if (_b(lite56.messageField)) {
        missionControl(MC.controlMissionStarted, caller);
      } else {
        lite308.message(MC.tLightResetAndTurnOff, 0.0);
        lite198.messageField = 1;
        missionControl(MC.controlMissionComplete, null);
        mission_text_box.display(rc(234), 4.0);
        final int addedScore = specialAddScore(1250000, true);
        buffer = fmt(rc(179), [addedScore]);
        if (!_b(addRankProgress(9))) {
          mission_text_box.display(buffer, 8.0);
          soundwave9.play();
        }
      }
    }
  }

  void scienceMissionController(int code, TablePart? caller) {
    var buffer = '';

    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite56.messageField = 9;
        target1.messageField = 0;
        target1.message(MC.tPopupTargetEnable, 0.0);
        target2.messageField = 0;
        target2.message(MC.tPopupTargetEnable, 0.0);
        target3.messageField = 0;
        target3.message(MC.tPopupTargetEnable, 0.0);
        target6.messageField = 0;
        target6.message(MC.tPopupTargetEnable, 0.0);
        target5.messageField = 0;
        target5.message(MC.tPopupTargetEnable, 0.0);
        target4.messageField = 0;
        target4.message(MC.tPopupTargetEnable, 0.0);
        target9.messageField = 0;
        target9.message(MC.tPopupTargetEnable, 0.0);
        target8.messageField = 0;
        target8.message(MC.tPopupTargetEnable, 0.0);
        target7.messageField = 0;
        target7.message(MC.tPopupTargetEnable, 0.0);
        lite303.message(MC.tLightFlasherStartTimed, 0.0);
        lite309.message(MC.tLightFlasherStartTimed, 0.0);
        lite315.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      buffer = fmt(rc(215), [lite56.messageField]);
      mission_text_box.display(buffer, -1.0);
      return;
    }
    if (target1 == caller ||
        target2 == caller ||
        target3 == caller ||
        target6 == caller ||
        target5 == caller ||
        target4 == caller ||
        target9 == caller ||
        target8 == caller ||
        target7 == caller) {
      lite56.messageField = lite56.messageField - 1;
      if (_b(lite56.messageField)) {
        missionControl(MC.controlMissionStarted, caller);
      } else {
        lite303.message(MC.tLightResetAndTurnOff, 0.0);
        lite309.message(MC.tLightResetAndTurnOff, 0.0);
        lite315.message(MC.tLightResetAndTurnOff, 0.0);
        lite198.messageField = 1;
        missionControl(MC.controlMissionComplete, null);
        mission_text_box.display(rc(216), 4.0);
        final int addedScore = specialAddScore(750000, true);
        buffer = fmt(rc(179), [addedScore]);
        if (!_b(addRankProgress(9))) {
          mission_text_box.display(buffer, 8.0);
          soundwave9.play();
        }
      }
    }
  }

  void secretMissionGreenController(int code, TablePart? caller) {
    var buffer = '';

    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite6.message(MC.tLightResetAndTurnOn, 0.0);
        lite2.message(MC.tLightSetOnStateBmpIndex, 1.0);
        lite2.message(MC.tLightResetAndTurnOn, 0.0);
        lite2.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      final String v2 = rc(245);
      mission_text_box.display(v2, -1.0);
      return;
    }
    if (sink2 == caller) {
      lite198.messageField = 1;
      missionControl(MC.controlMissionComplete, null);
      mission_text_box.display(rc(246), 4.0);
      final int addedScore = specialAddScore(1500000, true);
      buffer = fmt(rc(179), [addedScore]);
      if (!_b(addRankProgress(10))) {
        mission_text_box.display(buffer, 8.0);
        soundwave9.play();
      }
    }
  }

  void secretMissionRedController(int code, TablePart? caller) {
    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite5.message(MC.tLightResetAndTurnOn, 0.0);
        lite4.message(MC.tLightSetOnStateBmpIndex, 2.0);
        lite4.message(MC.tLightResetAndTurnOn, 0.0);
        lite4.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      mission_text_box.display(rc(244), -1.0);
      return;
    }
    if (sink1 == caller) {
      lite198.messageField = 23;
      missionControl(MC.controlMissionComplete, null);
    }
  }

  void secretMissionYellowController(int code, TablePart? caller) {
    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        worm_hole_lights.message(MC.tLightResetAndTurnOff, 0.0);
        bsink_arrow_lights.message(MC.tLightResetAndTurnOff, 0.0);
        bsink_arrow_lights.message(MC.tLightSetMessageField, 0.0);
        lite110.message(MC.tLightResetAndTurnOff, 0.0);
        lite7.message(MC.tLightResetAndTurnOn, 0.0);
        lite3.message(MC.tLightSetOnStateBmpIndex, 0.0);
        lite3.message(MC.tLightResetAndTurnOn, 0.0);
        lite3.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      mission_text_box.display(rc(243), -1.0);
      return;
    }
    if (sink3 == caller) {
      lite198.messageField = 22;
      missionControl(MC.controlMissionComplete, null);
    }
  }

  void selectMissionController(int code, TablePart? caller) {
    var buffer = '';

    switch (code) {
      case MC.tLightGroupToggleSplitIndex:
      case MC.tLightGroupCountdownEnded:
        if (fuel_bargraph != caller) return;
        missionControl(MC.controlMissionStarted, caller);
        return;
      case MC.controlCollision:
        {
          int missionLevel = 0;
          if (target13 == caller) missionLevel = 1;
          if (target14 == caller) missionLevel = 2;
          if (target15 == caller) missionLevel = 3;
          if (!_b(missionLevel)) {
            if (ramp == caller &&
                lite56.isLit &&
                _b(fuel_bargraph.message(MC.tLightGroupGetOnCount, 0.0))) {
              lite56.message(MC.tLightResetAndTurnOff, 0.0);
              lite198.message(MC.tLightResetAndTurnOn, 0.0);
              outer_circle.message(MC.tLightGroupAnimationBackward, -1.0);
              if (lite317.isLit) lite317.message(MC.tLightResetAndTurnOff, 0.0);
              if (lite318.isLit) lite318.message(MC.tLightResetAndTurnOff, 0.0);
              if (lite319.isLit) lite319.message(MC.tLightResetAndTurnOff, 0.0);
              lite198.messageField = lite56.messageField;
              final scoreId = lite56.messageField - 2;
              missionControl(MC.controlMissionComplete, null);
              final score = !fullTiltMode
                  ? missionSelectScores[scoreId]
                  : 100000;
              final int addedScore = specialAddScore(score);
              buffer = fmt(rc(178), [addedScore]);
              mission_text_box.display(buffer, 4.0);
              // (music)
            }
            return;
          }

          if (lite101.messageField == 7) {
            lite101.messageField = 0;
            missionLevel = 4;
          }

          int missionId;
          final activeCount = middle_circle.message(
            MC.tLightGroupGetOnCount,
            0.0,
          );
          switch (activeCount) {
            case 1:
              switch (missionLevel) {
                case 1:
                  missionId = 3;
                  break;
                case 2:
                  missionId = 4;
                  break;
                case 3:
                  missionId = 2;
                  break;
                default:
                  missionId = 5;
                  break;
              }
              break;
            case 2:
            case 3:
              switch (missionLevel) {
                case 1:
                  missionId = 9;
                  break;
                case 2:
                  missionId = 11;
                  break;
                case 3:
                  missionId = 10;
                  break;
                default:
                  missionId = 16;
                  break;
              }
              break;
            case 4:
            case 5:
              switch (missionLevel) {
                case 1:
                  missionId = 6;
                  break;
                case 2:
                  missionId = 8;
                  break;
                case 3:
                  missionId = 7;
                  break;
                default:
                  missionId = 15;
                  break;
              }
              break;
            case 6:
            case 7:
              switch (missionLevel) {
                case 1:
                  missionId = 12;
                  break;
                case 2:
                  missionId = 13;
                  break;
                case 3:
                  missionId = 14;
                  break;
                default:
                  missionId = 17;
                  break;
              }
              break;
            case 8:
            case 9:
              switch (missionLevel) {
                case 1:
                  missionId = 15;
                  break;
                case 2:
                  missionId = 16;
                  break;
                case 3:
                  missionId = 17;
                  break;
                default:
                  missionId = 18;
                  break;
              }
              break;
            default:
              return;
          }
          lite56.messageField = missionId;
          lite56.message(MC.tLightFlasherStartTimedThenStayOn, 2.0);
          lite198.message(MC.tLightFlasherStart, 0.0);
          missionControl(MC.controlMissionStarted, caller);
          return;
        }
      case MC.controlMissionComplete:
        // (music)
        lite198.message(MC.tLightResetAndTurnOff, 0.0);
        outer_circle.message(MC.tLightGroupReset, 0.0);
        ramp_tgt_lights.message(MC.tLightResetAndTurnOff, 0.0);
        lite56.messageField = 0;
        lite101.messageField = 0;
        l_trek_lights.message(MC.tLightGroupReset, 0.0);
        l_trek_lights.message(MC.tLightResetAndTurnOff, 0.0);
        r_trek_lights.message(MC.tLightGroupReset, 0.0);
        r_trek_lights.message(MC.tLightResetAndTurnOff, 0.0);
        goal_lights.message(MC.tLightResetAndTurnOff, 0.0);
        worm_hole_lights.message(MC.tLightResetAndTurnOff, 0.0);
        bsink_arrow_lights.message(MC.tLightResetAndTurnOff, 0.0);
        break;
      case MC.controlMissionStarted:
        break;
      default:
        return;
    }

    if (_b(fuel_bargraph.message(MC.tLightGroupGetOnCount, 0.0))) {
      if (lite56.isLit && lite56.messageField >= 2) {
        final missionText = rc(missionRcArray[lite56.messageField - 2]);
        buffer = fmt(rc(207), [missionText]);
        mission_text_box.display(buffer, -1.0);
        if (lite318.isLit) lite318.message(MC.tLightResetAndTurnOff, 0.0);
        if (lite319.isLit) lite319.message(MC.tLightResetAndTurnOff, 0.0);
        if (!lite317.isLit) lite317.message(MC.tLightFlasherStartTimed, 0.0);
      } else {
        mission_text_box.display(rc(205), -1.0);
        if (lite317.isLit) lite317.message(MC.tLightResetAndTurnOff, 0.0);
        if (lite318.isLit) lite318.message(MC.tLightResetAndTurnOff, 0.0);
        if (!lite319.isLit) {
          lite319.message(MC.tLightFlasherStartTimed, 0.0);
        }
      }
    } else {
      mission_text_box.display(rc(206), -1.0);
      if (lite317.isLit) lite317.message(MC.tLightResetAndTurnOff, 0.0);
      if (lite319.isLit) lite319.message(MC.tLightResetAndTurnOff, 0.0);
      if (!lite318.isLit) {
        lite318.message(MC.tLightFlasherStartTimed, 0.0);
      }
    }
  }

  void spaceRadiationController(int code, TablePart? caller) {
    var buffer = '';

    if (code == MC.controlCollision) {
      if (target16 == caller || target17 == caller || target18 == caller) {
        if (lite104.messageField == 7) {
          lite104.messageField = 15;
          bsink_arrow_lights.message(MC.tLightFlasherStartTimed, 0.0);
          lite313.message(MC.tLightResetAndTurnOff, 0.0);
          missionControl(MC.controlMissionStarted, caller);
          advanceWormHoleDestination(1);
        }
      } else if ((sink1 == caller || sink2 == caller || sink3 == caller) &&
          lite104.messageField == 15) {
        lite198.messageField = 1;
        missionControl(MC.controlMissionComplete, null);
        mission_text_box.display(rc(222), 4.0);
        final int addedScore = specialAddScore(1000000, true);
        buffer = fmt(rc(179), [addedScore]);
        if (!_b(addRankProgress(8))) {
          mission_text_box.display(buffer, 8.0);
          soundwave9.play();
        }
      }
    } else {
      if (code == MC.controlMissionComplete) {
        lchute_tgt_lights.message(MC.tLightResetAndTurnOff, 0.0);
        lite104.messageField = 0;
        lite313.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code == MC.controlMissionStarted) {
        String text;
        if (lite104.messageField == 15)
          text = rc(221);
        else
          text = rc(276);
        mission_text_box.display(text, -1.0);
      }
    }
  }

  void strayCometController(int code, TablePart? caller) {
    var buffer = '';

    if (code == MC.controlCollision) {
      if (target19 == caller || target20 == caller || target21 == caller) {
        if (lite107.messageField == 7) {
          lite306.message(MC.tLightResetAndTurnOff, 0.0);
          lite304.message(MC.tLightFlasherStartTimed, 0.0);
          lite107.messageField = 15;
          missionControl(MC.controlMissionStarted, caller);
        }
      } else if (kickout2 == caller && lite107.messageField == 15) {
        lite304.message(MC.tLightResetAndTurnOff, 0.0);
        lite198.messageField = 1;
        missionControl(MC.controlMissionComplete, null);
        mission_text_box.display(rc(220), 4.0);
        final int addedScore = specialAddScore(1000000, true);
        buffer = fmt(rc(179), [addedScore]);
        if (!_b(addRankProgress(8))) {
          mission_text_box.display(buffer, 8.0);
          soundwave9.play();
        }
      }
    } else {
      if (code == MC.controlMissionComplete) {
        bpr_solotgt_lights.message(MC.tLightResetAndTurnOff, 0.0);
        lite107.messageField = 0;
        lite306.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code == MC.controlMissionStarted) {
        String text;
        if (lite107.messageField == 15)
          text = rc(219);
        else
          text = rc(218);
        mission_text_box.display(text, -1.0);
      }
    }
  }

  void timeWarpController(int code, TablePart? caller) {
    var buffer = '';

    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite56.messageField = 25;
        lite300.message(MC.tLightFlasherStartTimed, 0.0);
        lite322.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      buffer = fmt(rc(247), [lite56.messageField]);
      mission_text_box.display(buffer, -1.0);
      return;
    }
    if (rebo1 == caller ||
        rebo2 == caller ||
        rebo3 == caller ||
        rebo4 == caller) {
      lite56.messageField = lite56.messageField - 1;
      if (_b(lite56.messageField)) {
        missionControl(MC.controlMissionStarted, caller);
      } else {
        lite300.message(MC.tLightResetAndTurnOff, 0.0);
        lite322.message(MC.tLightResetAndTurnOff, 0.0);
        lite198.messageField = 24;
        missionControl(MC.controlMissionComplete, null);
      }
    }
  }

  void timeWarpPartTwoController(int code, TablePart? caller) {
    var buffer = '';

    if (code != MC.controlCollision) {
      if (code == MC.controlMissionComplete) {
        lite55.message(MC.tLightFlasherStartTimed, -1.0);
        lite26.message(MC.tLightFlasherStartTimed, -1.0);
        lite304.message(MC.tLightFlasherStartTimed, 0.0);
        lite317.message(MC.tLightFlasherStartTimed, 0.0);
      } else if (code != MC.controlMissionStarted) {
        return;
      }
      mission_text_box.display(rc(248), -1.0);
      return;
    }
    if (kickout2 == caller) {
      mission_text_box.display(rc(148), 4.0);
      if (middle_circle.message(MC.tLightGroupGetOnCount, 0.0) > 1) {
        middle_circle.message(MC.tLightGroupOffsetAnimationBackward, 5.0);
        final int rank = middle_circle.message(MC.tLightGroupGetOnCount, 0.0);
        buffer = fmt(rc(274), [rc(rankRcArray[rank - 1])]);
        mission_text_box.display(buffer, 8.0);
      }
    } else {
      if (ramp != caller) return;
      mission_text_box.display(rc(147), 4.0);
      if (middle_circle.message(MC.tLightGroupGetOnCount, 0.0) < 9) {
        final int rank = middle_circle.message(MC.tLightGroupGetOnCount, 0.0);
        middle_circle.message(MC.tLightGroupResetAndTurnOn, 5.0);
        buffer = fmt(rc(273), [rc(rankRcArray[rank])]);
      }
      if (!_b(addRankProgress(12))) {
        mission_text_box.display(buffer, 8.0);
        soundwave10.play();
      }
    }
    specialAddScore(2000000);
    lite55.message(MC.tLightResetAndTurnOff, 0.0);
    lite26.message(MC.tLightResetAndTurnOff, 0.0);
    lite304.message(MC.tLightResetAndTurnOff, 0.0);
    lite317.message(MC.tLightResetAndTurnOff, 0.0);
    lite198.messageField = 1;
    missionControl(MC.controlMissionComplete, null);
    // SpecialAddScore sets the score dirty flag. So next tick it will be redrawn.
  }

  void unselectMissionController(int code, TablePart? caller) {
    lite198.messageField = 1;
    missionControl(MC.controlMissionComplete, null);
  }

  void waitingDeploymentController(int code, TablePart? caller) {
    switch (code) {
      case MC.controlCollision:
        if (oneway4 == caller || oneway10 == caller) {
          lite198.messageField = 1;
          missionControl(MC.controlMissionComplete, null);
        }
        break;
      case MC.controlMissionComplete:
        mission_text_box.clear();
        waitingDeploymentFlag = 0;
        // (music)
        break;
      case MC.controlMissionStarted:
        mission_text_box.display(rc(151), -1.0);
        break;
      default:
        break;
    }
  }
}
