# A11Y-003 Reduced Motion Audit

This file records the current direct Flutter motion primitives outside generated localization code.
The machine validator compares this checked-in baseline with the repository on every CI run, so new direct motion cannot bypass accessibility review silently.

- Audited direct primitive records: 43
- Unique Dart files: 20
- `shared-policy-consumer`: shared motion code governed by `GameMotion` intent/policy.
- `state-listener-not-motion`: `AnimatedBuilder` used only as a Listenable rebuild helper.
- `audited-local-motion`: existing local callsite frozen into the baseline; changes require explicit re-audit.

| Path | Primitive | Count | Classification |
|---|---|---:|---|
| `lib/core/logging/log_viewer_screen.dart` | `AnimatedBuilder(` | 1 | audited-local-motion |
| `lib/core/motion/ambient_motion_background.dart` | `AnimationController(` | 1 | shared-policy-consumer |
| `lib/core/motion/ambient_motion_background.dart` | `AnimatedBuilder(` | 1 | shared-policy-consumer |
| `lib/core/motion/game_action_feedback.dart` | `AnimationController(` | 1 | shared-policy-consumer |
| `lib/core/motion/game_action_feedback.dart` | `AnimatedBuilder(` | 1 | shared-policy-consumer |
| `lib/core/motion/game_action_feedback.dart` | `Timer(` | 1 | shared-policy-consumer |
| `lib/core/motion/game_cinematic_gate.dart` | `AnimationController(` | 1 | shared-policy-consumer |
| `lib/core/motion/game_route.dart` | `PageRouteBuilder` | 1 | shared-policy-consumer |
| `lib/core/motion/game_route.dart` | `FadeTransition(` | 2 | shared-policy-consumer |
| `lib/core/motion/game_route.dart` | `SlideTransition(` | 1 | shared-policy-consumer |
| `lib/core/motion/game_travel_motion.dart` | `AnimationController(` | 1 | shared-policy-consumer |
| `lib/core/motion/game_travel_motion.dart` | `AnimatedBuilder(` | 1 | shared-policy-consumer |
| `lib/core/navigation/game_navigator.dart` | `PageRouteBuilder` | 1 | audited-local-motion |
| `lib/core/theme/three_d_game_icon.dart` | `AnimationController(` | 1 | audited-local-motion |
| `lib/core/theme/three_d_game_icon.dart` | `AnimatedBuilder(` | 1 | audited-local-motion |
| `lib/core/widgets/game_button.dart` | `AnimatedContainer(` | 1 | shared-policy-consumer |
| `lib/core/widgets/game_button.dart` | `AnimatedScale(` | 1 | shared-policy-consumer |
| `lib/core/widgets/game_button.dart` | `AnimatedSlide(` | 1 | shared-policy-consumer |
| `lib/core/widgets/game_button.dart` | `AnimatedSwitcher(` | 1 | shared-policy-consumer |
| `lib/core/widgets/game_panel.dart` | `AnimationController(` | 1 | audited-local-motion |
| `lib/core/widgets/game_panel.dart` | `AnimatedBuilder(` | 1 | audited-local-motion |
| `lib/core/widgets/game_panel.dart` | `AnimatedContainer(` | 1 | audited-local-motion |
| `lib/core/widgets/game_panel.dart` | `AnimatedScale(` | 1 | audited-local-motion |
| `lib/core/widgets/game_panel.dart` | `AnimatedSlide(` | 1 | audited-local-motion |
| `lib/features/game/cargo_motion_tile.dart` | `AnimatedOpacity(` | 1 | audited-local-motion |
| `lib/features/game/cargo_motion_tile.dart` | `AnimatedScale(` | 2 | audited-local-motion |
| `lib/features/game/cargo_motion_tile.dart` | `AnimatedSlide(` | 1 | audited-local-motion |
| `lib/features/game/gameplay_operations_deck.dart` | `AnimatedContainer(` | 1 | audited-local-motion |
| `lib/features/game/gameplay_result_debrief.dart` | `Hero(` | 2 | audited-local-motion |
| `lib/features/home/home_screen.dart` | `AnimatedBuilder(` | 1 | audited-local-motion |
| `lib/features/home/home_screen.dart` | `Hero(` | 2 | audited-local-motion |
| `lib/features/home/home_screen.dart` | `Timer(` | 2 | audited-local-motion |
| `lib/features/levels/city_briefing_screen.dart` | `AnimatedContainer(` | 1 | audited-local-motion |
| `lib/features/levels/city_briefing_screen.dart` | `Hero(` | 2 | audited-local-motion |
| `lib/features/levels/level_select_screen.dart` | `AnimatedBuilder(` | 1 | audited-local-motion |
| `lib/features/progress/progress_hub_screen.dart` | `AnimatedBuilder(` | 1 | audited-local-motion |
| `lib/features/progress/progress_hub_screen.dart` | `Hero(` | 2 | audited-local-motion |
| `lib/features/progress/progress_hub_screen.dart` | `Timer(` | 2 | audited-local-motion |
| `lib/features/settings/settings_screen.dart` | `AnimatedBuilder(` | 2 | state-listener-not-motion |
| `lib/features/shop/shop_screen.dart` | `AnimatedBuilder(` | 1 | audited-local-motion |
| `lib/main.dart` | `AnimationController(` | 1 | audited-local-motion |
| `lib/main.dart` | `AnimatedSwitcher(` | 1 | audited-local-motion |
| `lib/main.dart` | `ScaleTransition(` | 1 | audited-local-motion |
