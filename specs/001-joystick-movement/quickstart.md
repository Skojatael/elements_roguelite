# Quickstart: Player Movement Joystick Controls

**Branch**: `001-joystick-movement` | **Date**: 2026-02-19

Use this guide to verify the feature works end-to-end after implementation.

---

## Prerequisites

- Godot 4.6 installed and `project.godot` opened in the editor.
- The `001-joystick-movement` branch is checked out.
- All tasks in `tasks.md` are marked complete.

---

## Step 1: Verify scene structure in the Editor

Open each scene and confirm the node hierarchy matches the design:

**`scenes/ui/hud/Joystick.tscn`**
```
Joystick (Control)
├── Base (TextureRect)   ← joystick background circle
└── Knob (TextureRect)   ← draggable thumb
```
Script attached: `Joystick.gd`

**`scenes/ui/hud/ExplorationHUD.tscn`**
```
ExplorationHUD (CanvasLayer)
├── Joystick (instance of Joystick.tscn)
├── SkillButton (instance of SkillButton.tscn)
└── DodgeButton (instance of DodgeButton.tscn)
```

**`scenes/player/Player.tscn`**
```
Player (CharacterBody2D or Node2D)
└── MovementComponent (Node, script: MovementComponent.gd)
```

**`scenes/core/Main.tscn`**
```
Main (Node2D, script: Main.gd)
├── [DungeonRoom or world node]
│   └── Player
└── ExplorationHUD
```

---

## Step 2: Run the project

Press **F5** (or click the play button) to launch from `Bootstrap.tscn`.
Navigate to a gameplay scene where Main.tscn is active.

---

## Step 3: Test basic movement

On a touch device or using Godot's touch emulation (Project → Project Settings →
Input Devices → Pointing → Emulate Touch From Mouse):

1. Press and hold within the joystick circle area (bottom-left corner).
2. Drag upward. **Expected**: character moves toward the top of the room.
3. Drag right. **Expected**: character moves right.
4. Drag diagonally (up-right). **Expected**: character moves diagonally.
5. Release. **Expected**: character stops within one frame.

---

## Step 4: Test analog speed

1. Drag the joystick knob only 25% of the way to the edge.
   **Expected**: character moves noticeably slower than at full drag.
2. Drag to the edge.
   **Expected**: character moves at maximum speed.
3. Drag less than ~8 pixels from centre (dead zone).
   **Expected**: character does not move.

---

## Step 5: Test visual feedback

1. Press the joystick.
   **Expected**: the knob visually offsets in the drag direction.
2. Release.
   **Expected**: the knob snaps back to centre within 0.1 s.
3. Drag 360° slowly.
   **Expected**: the knob follows the finger continuously at all angles.

---

## Step 6: Test multi-touch (if device available)

1. Press joystick with one finger and a skill button with another simultaneously.
   **Expected**: character continues moving; skill button input is not swallowed
   by the joystick.

---

## Step 7: Verify HUD visibility rules

1. Open the main menu. **Expected**: joystick is NOT visible.
2. Open the upgrade/meta screen. **Expected**: joystick is NOT visible.
3. Enter a dungeon room. **Expected**: joystick IS visible.

---

## Acceptance: Feature Complete When

- [ ] All directional drag tests pass (Step 3)
- [ ] Analog speed scales correctly (Step 4)
- [ ] Visual knob feedback works (Step 5)
- [ ] No multi-touch interference (Step 6)
- [ ] Joystick hidden on non-gameplay screens (Step 7)
