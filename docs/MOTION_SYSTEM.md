# CARGame Motion and Animation System

## Purpose

Motion must make CARGame feel responsive, alive, premium, and understandable. It must not distract from sorting decisions, create input latency, or waste battery.

## Principles

1. Immediate response
   - Every tap receives visible feedback within 100 ms.
   - Input feedback starts before long work completes.

2. Causal motion
   - Objects move from their source to their destination.
   - Rewards visibly travel to the resource they modify.
   - Unlock motion points toward newly available content.

3. Hierarchy
   - Common events use small motion.
   - Rare rewards, boss wins, and world completion receive stronger motion.
   - Only one visual event owns attention at a time.

4. Restraint
   - Do not animate every element continuously.
   - Idle motion belongs only to hero, selected, claimable, or premium elements.
   - Off-screen animations must stop.

5. Performance
   - Prefer transforms, opacity, clipping, and lightweight particles.
   - Avoid expensive blur, oversized images, and repainting whole screens.
   - Use RepaintBoundary where profiling proves it useful.

6. Accessibility
   - Add reduced-motion support.
   - Reduced motion removes parallax, long travel, shake, and continuous loops while retaining state feedback.

## Motion tokens

Create one shared implementation such as `GameMotionTokens`.

### Durations

- instant: 80 ms
- fast: 120 ms
- short: 180 ms
- standard: 240 ms
- medium: 320 ms
- long: 500 ms
- reward: 700 ms
- celebration: 1200 ms

### Curves

- press: easeOutCubic
- release: elasticOut or controlled spring
- enter: easeOutCubic
- exit: easeInCubic
- travel: fastOutSlowIn
- value change: easeOutQuart
- ambient: easeInOutSine

### Amplitudes

- button press scale: 0.96-0.98
- selection pop: 1.04-1.10
- idle float: 3-8 logical pixels
- invalid shake: 4-10 logical pixels
- parallax shift: 4-18 logical pixels

## Shared animation components

Implement reusable components rather than screen-local controllers:

- `GamePressable3D`
- `GameEntrance`
- `GameStaggerGroup`
- `GameSelectionPop`
- `GameInvalidShake`
- `GameResourceDelta`
- `GameCoinFlightOverlay`
- `GameStarReveal`
- `GameXpAnimator`
- `GameRewardChestReveal`
- `GameAmbientFloat`
- `GameParallaxLayer`
- `GamePulseHighlight`
- `GameRouteTransitions`
- `GameParticleBurst`
- `GameReducedMotionScope`

## Screen motion specifications

### Splash

- Logo scale-breathing at low amplitude.
- Progress and status crossfade.
- Maximum decorative loops: one.
- Startup services must never wait for decorative animation.

### Home

- World hero uses slow layered parallax.
- Current city landmark floats slightly.
- Resource values interpolate when changed.
- Claimable reward pulses every few seconds, not continuously at high frequency.
- Start button has depth press and spring release.

### World map

- Newly opened path draws once.
- Selected city breathes subtly.
- Completed stars reveal once, then remain static.
- Boss gate has slow ambient glow.
- Scrolling pauses nonessential loops.

### Mission briefing

- Hero enters with scale and fade.
- Boosters pop when selected.
- Locked or unavailable booster shakes once.
- Starting the mission visually gathers selected boosters toward the play area.

### Gameplay

State machine:

```text
idle -> inputAccepted -> resolving -> boardSettling -> idle
                         -> won
                         -> lost
```

No second input is accepted while resolving or settling.

Events:

- Cargo pickup: scale 1.0 to 1.06 with shadow lift.
- Cargo travel: curved translation to target.
- Correct placement: squash, bounce, sparkle.
- Incorrect placement: recoil and short shake.
- Combo: escalating ring, text pop, and particles with a hard intensity cap.
- Hint: target breathes and receives a directional light sweep.
- Shield: metallic flash and impact absorption.
- Extra moves: move counter increments with card-to-counter travel.

### Victory

Sequence:

1. Board freezes and background dims.
2. Victory emblem appears.
3. Stars reveal sequentially.
4. Coins and XP animate.
5. Bonus or chest appears.
6. Actions become enabled.

The primary action must not remain blocked longer than necessary.

### Failure

- Short board desaturation.
- Objective or move counter explains failure.
- Retry appears quickly.
- Avoid long punishment animation.

### Shop

- Product card tilt or light sweep on focus.
- Purchase button presses with depth.
- Successful purchase sends asset/resource toward inventory.
- Insufficient coins shakes the coin chip and purchase control.

## Sound and haptic coupling

- Tap: light click + light haptic.
- Correct placement: short tonal sound + light haptic.
- Combo: pitch and haptic intensity increase within safe cap.
- Reward: layered sound, particle burst, medium haptic.
- Boss/world completion: strongest sequence, but user can skip after first view.

## Lifecycle rules

- Dispose every controller.
- Stop ticker when route is not visible.
- Stop ambient animation while app is paused.
- Do not initialize heavy particle systems during startup.
- Do not keep hidden overlays alive.
- Avoid `AnimationController.repeat` unless the widget is visible and meaningful.

## Testing

Required tests:

- Repeated tap cannot trigger duplicate route or reward.
- Animation completion cannot call disposed state.
- Reduced-motion mode removes loops and travel-heavy effects.
- Result actions become available after reveal.
- Off-screen city cards do not retain tickers.
- Gameplay does not accept input during resolve animation.
- Resource count finishes at exact persisted value.

## Performance acceptance

- Input feedback starts within 100 ms.
- Core gameplay targets 60 FPS on a mid-range Android device.
- Frame-heavy celebration sequences are short and skippable.
- No continuous animation should force full-screen repaint.
- Asset resolution must match display size tier.
