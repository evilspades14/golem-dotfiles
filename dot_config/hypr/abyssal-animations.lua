-- ~/.config/hypr/animations.lua
-- "Abyssal" — slow, heavy, underwater motion for Hyprland 0.55+ (Lua config)
--
-- Load it from hyprland.lua with:   require("animations")
-- Docs: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
--
-- Design idea: you're moving through deep water.
--   * Nothing bounces. Motion is viscous: overdamped springs and long ease-outs.
--   * Windows *surface* (a faint buoyant bob) and *sink* when closed.
--   * Workspaces are depths: switching moves you up/down the water column.
--   * The border drifts like bioluminescence (optional, see flag below).
-- Speed is in deciseconds (10 = 1s). Unset leaves inherit from their parent.

-- Slowly rotating gradient border. This is the signature abyssal effect with a
-- two-or-three-stop blue/purple gradient, but "loop" forces a new frame every
-- refresh, which costs battery/GPU. Off by default.
local DRIFTING_BORDER = true

hl.config({
    animations = { enabled = true },
})

---------------------------------------------------------------------------
-- CURVES
---------------------------------------------------------------------------
-- Springs. Critical damping ≈ 2*sqrt(stiffness*mass).
-- dampening ABOVE that = overdamped (no overshoot, just drag).
-- dampening BELOW that = underdamped (overshoots / bobs).

hl.curve("current", { type = "spring", mass = 1, stiffness = 45, dampening = 17 }) -- ratio ~1.27, thick/viscous
hl.curve("drag",    { type = "spring", mass = 1, stiffness = 60, dampening = 20 }) -- ratio ~1.29, moving/resizing
hl.curve("buoy",    { type = "spring", mass = 1, stiffness = 80, dampening = 14 }) -- ratio ~0.78, one soft bob

-- Beziers
hl.curve("tide",   { type = "bezier", points = { {0.45, 0},    {0.2, 1}    } }) -- slow in, slow out
hl.curve("surge",  { type = "bezier", points = { {0.16, 1},    {0.3, 1}    } }) -- long, soft ease-out
hl.curve("sink",   { type = "bezier", points = { {0.32, 0},    {0.67, 0}   } }) -- ease-in, accelerates away
hl.curve("murk",   { type = "bezier", points = { {0.4, 0.1},   {0.6, 0.9}  } }) -- gentle, near-symmetrical
hl.curve("linear", { type = "bezier", points = { {0, 0},       {1, 1}      } })

---------------------------------------------------------------------------
-- ANIMATIONS
---------------------------------------------------------------------------

-- Baseline everything else inherits from
hl.animation({ leaf = "global", enabled = true, speed = 9, bezier = "tide" })

-- Windows: emerge from the murk (small scale-up, slow fade), sink away on close.
-- Moving/resizing feels like pushing through water.
hl.animation({ leaf = "windows",     enabled = true, speed = 7, spring = "drag" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 7, spring = "buoy",  style = "popin 80%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 5, bezier = "sink",  style = "popin 60%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 7, spring = "drag" })
-- Alternative: windows rise from below the screen instead of scaling up.
-- hl.animation({ leaf = "windowsIn",  enabled = true, speed = 8, spring = "current", style = "slide bottom" })
-- hl.animation({ leaf = "windowsOut", enabled = true, speed = 6, bezier = "sink",    style = "slide bottom" })

-- Fades: slow materialise, quicker dissolve; dimming eases like light fading with depth
hl.animation({ leaf = "fade",       enabled = true, speed = 6, bezier = "murk" })
hl.animation({ leaf = "fadeIn",     enabled = true, speed = 7, bezier = "murk" })
hl.animation({ leaf = "fadeOut",    enabled = true, speed = 4, bezier = "sink" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 6, bezier = "murk" }) -- focus glow shifts slowly
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 6, bezier = "murk" })
hl.animation({ leaf = "fadeDim",    enabled = true, speed = 8, bezier = "tide" })

-- Layers (bars, launchers, notifications): drift in softly, dissolve out
hl.animation({ leaf = "layers",    enabled = true, speed = 6, bezier = "surge", style = "popin 92%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 4, bezier = "sink",  style = "popin 95%" })

-- Borders: colour changes (focus) ease slowly; optional drifting gradient
hl.animation({ leaf = "border", enabled = true, speed = 9, bezier = "murk" })
if DRIFTING_BORDER then
    hl.animation({ leaf = "borderangle", enabled = true, speed = 80, bezier = "linear", style = "loop" })
else
    hl.animation({ leaf = "borderangle", enabled = false })
end

-- Workspaces as depth: slide vertically with a fade. Arriving is a long glide,
-- departing is quicker so the old workspace doesn't linger in the way.
hl.animation({ leaf = "workspaces",    enabled = true, speed = 8, bezier = "surge", style = "slidefadevert 30%" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 8, bezier = "surge", style = "slidefadevert 30%" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 6, bezier = "tide",  style = "slidefadevert 30%" })

-- Scratchpad / special workspace: rises up from the deep, sinks back down
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 7, spring = "current", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 5, bezier = "sink",    style = "slidevert" })

-- Zoom (magnifier zoomFactor)
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 8, bezier = "surge" })

---------------------------------------------------------------------------
-- TWEAK IDEAS
---------------------------------------------------------------------------
-- * Feels sluggish?  Lower `speed` across the board; keep the curves, they carry the character.
-- * Not heavy enough? Lower stiffness on "drag"/"current" (60 -> 40) and keep dampening above ~2*sqrt(stiffness).
-- * Want a hint of life? Swap windowsMove's "drag" for "buoy".
-- * Drifting border pairs best with a slow, low-contrast gradient in your general.col.* settings
--   (e.g. deep navy -> indigo -> violet at a very low angle of contrast).
