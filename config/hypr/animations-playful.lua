-- ==============================================================================
-- Playful animation preset (plan.theme.md §2)
-- ==============================================================================
--
-- Loaded by appearance.lua (via dofile) ONLY when ~/.config/hypr/.anim-preset
-- == "playful". Bouncy curves borrowed from HyprFlux + the rotating gradient
-- border ("rainbow border").
--
-- NOTE (battery): `borderangle ... loop` redraws the border every frame and
-- keeps the GPU awake — that's why it lives here as an OPT-IN preset, not the
-- default. Use `anim-preset.sh off` on battery.

hl.config({ animations = { enabled = true } })

-- Bezier curves (HyprFlux-flavored)
hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })
hl.curve("bounce", { type = "bezier", points = { { 1.1, 1.6 }, { 0.1, 0.85 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("slingshot", { type = "bezier", points = { { 1, -1 }, { 0.15, 1.25 } } })
hl.curve("smoothOut", { type = "bezier", points = { { 0.5, 0 }, { 0.99, 0.99 } } })

-- Windows — pop in with a bounce, slide on move
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "overshot", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "smoothOut", style = "popin 90%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "bounce", style = "slide" })

-- Fade + workspaces
hl.animation({ leaf = "fadeIn", enabled = true, speed = 4, bezier = "smoothOut" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 3, bezier = "smoothOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "overshot", style = "slide" })

-- Layers (launcher / control center)
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "overshot", style = "popin 90%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3, bezier = "smoothOut", style = "popin 92%" })

-- Borders: rotating gradient ("rainbow border"). speed = full-rotation time in
-- ds; 100 = ~10s (slow, calm). Lower = faster spin.
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "liner", style = "loop" })
