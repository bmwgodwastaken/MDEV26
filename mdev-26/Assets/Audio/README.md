# Audio

TODO: put the .wav files in the folders below. The game already calls `Audio.play("<name>")` at the
right moments (see `Scripts/Audio/audio.gd`), so a file with the right name just starts playing.
Missing files are skipped silently. To rename a sound, change the name in the `Audio.play(...)` line.

For each name the game looks in the folder for the current view first (`2D/` or `2.5D/`), then in
`shared/`. So a sound can be one file in `shared/`, or two versions with the same file name in `2D/`
and `2.5D/`:

| File name               | Played when                                  | Where it's called |
|-------------------------|----------------------------------------------|-------------------|
| `footstep_sfx.wav`      | walking on the ground (every 0.35 s)         | `Scripts/Player/2_5d_character.gd` |
| `jump_sfx.wav`          | jump                                         | `Scripts/Player/2_5d_character.gd` |
| `land_sfx.wav`          | feet touch down after being in the air       | `Scripts/Player/2_5d_character.gd` |
| `interact_sfx.wav`      | grabbing / dropping the plank                | `Scripts/Player/2_5d_character.gd` |
| `key_pickup_sfx.wav`    | picking up a key                             | `Scripts/Interaction/key_pickup.gd` |
| `key_use_sfx.wav`       | a key is used on a door or chest             | `Scripts/Interaction/locked_door.gd` |
| `door_unlock_sfx.wav`   | a door or chest opens                        | `Scripts/Interaction/locked_door.gd` |
| `door_locked_sfx.wav`   | pressing E on a door without its key         | `Scripts/Interaction/locked_door.gd` |
| `level_success_sfx.wav` | reaching the exit flag                       | `Scripts/Level/goal.gd` |
| `fail_sfx.wav`          | falling out of the level                     | `Scripts/Player/perspective_switcher.gd` |
| `restart_sfx.wav`       | not wired yet (there is no restart button)   | |
| `switch2.5Dto2D_sfx.wav`| Q: 2.5D to 2D                                | `Scripts/Player/perspective_switcher.gd` |
| `switch2Dto2.5D_sfx.wav`| Q: 2D to 2.5D                                | `Scripts/Player/perspective_switcher.gd` |
| `menu_hover_sfx.wav`    | mouse over a menu button                     | `Scripts/UI/main_menu.gd` and the level buttons |
| `menu_confirm_sfx.wav`  | clicking a menu button                       | `Scripts/UI/main_menu.gd` and the level buttons |
| `menu_back_sfx.wav`     | closing the credits                          | `Scripts/UI/main_menu.gd` |
