class_name LevelFlow
## Remembers things between a level and the Level Complete screen.
## The exit sets them just before the screen opens; each level clears them when it loads.

## The level the "Next Level" button should open ("" = none).
static var next_level := ""
## True when the exit's zoom-in handed over to the screen, so the screen should zoom out from black.
static var play_intro := false
