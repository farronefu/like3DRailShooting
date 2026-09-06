# Project profile — 2026-09-06

Baseline: `d3c5b57f201fcdf8ff65489a75eeec3931fe8017`, clean main. No repository AGENTS.md or kaishu-workflow/references. Skill fallback workflow applies.

## Measured environment and commands

Godot 4.6 stable official 89cea1439, Compatibility renderer; Python bundled runtime; PowerShell. Repository: `outputs/like3DRailShooting`, working tools in workspace `work/godot`.

From workspace: `work/godot/Godot_v4.6-stable_win64_console.exe --headless --disable-crash-handler --log-file <absolute-work-log> --path outputs/like3DRailShooting --script res://tests/test_game.gd`.

Measured baseline: exit 0, 29 checks, 0 failures; 240-second simulation, 131 kills, score 17250, peak actors 32. Existing environment errors: userdata directory creation (2 messages), Windows root certificate store read (1); no script errors. Explicit Python failure probe printed intentional failure and exited nonzero (requested 7, shell tool wrapper reports 1); thus do not infer success from output alone.

Export presets: `--headless --path <repo> --export-release Web` and `--export-release "Windows Desktop"`, with absolute log path. Earlier release exports succeeded; repeat after this revision. Native preview uses OpenGL3, hidden Godot process and viewport image save. Web served with `tools/serve.py` on loopback 8765.

## Code and impact map

- `scripts/game.gd`: lifecycle, input adapters, fixed-step simulation, scheduling, swept collisions.
- `scripts/flight_rules.gd`: pure input/collision/phase rules; used by game and tests.
- `scripts/hud.gd`: custom canvas UI and buttons; consumes game state.
- `scripts/ships/*`, `resources/ships/*`: replaceable appearances separate from gameplay transforms.
- `scripts/visuals.gd`: cached primitive mesh materials, shared by effects and models.
- `tools/build_*.gd`: offline model generators; GLBs are tracked source assets, not generated on launch.
- `tests/test_game.gd`: SceneTree assertions and full mission simulation.

Generated/imported: `.godot/`, `build/` ignored; `.gdignore` prevents recursive build imports. Export excludes tools/tests/docs/build. Source assets `.glb`, `.wav` and import definitions are tracked. No package manager or external runtime service. Native and Web share scripts; no save data or network gameplay. GitHub publishing updates the public repository; builds remain local.

## Verification policy

Check parser/import, meaningful gameplay regressions including full schedule, both release exports, native rendered artifacts, browser interaction and console. Synthetic joypad events cannot replace physical controller playtesting. Existing sandbox engine warnings remain separate from new script/shader errors. Keep user-facing artifacts beneath outputs.
