-- XLIN for Hyprland 0.55+ (Lua config). hyprland.lua loads this with:  require("xlin")
-- Older Hyprland (hyprland.conf) uses xlin.conf instead; the two files do the same things.
--
-- Colours and window opacity are generated files next to this one (xlin theme / xlin opacity).

pcall(require, "xlin-colors")   -- the theme's border and shadow colours (generated)

local terminal = "xlin term"

-- ---- autostart ------------------------------------------------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("xlin start")
end)
hl.env("XCURSOR_THEME", "XLIN")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "XLIN")
hl.env("HYPRCURSOR_SIZE", "24")

-- ---- look: clean, rounded, smooth -------------------------------------------
hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,
        border_size = 1,
        layout = "dwindle",
        resize_on_border = true,
    },
    decoration = {
        rounding = 11,
        -- Fullscreen windows (Super+F) are always fully opaque. Window transparency is in
        -- xlin-opacity.lua (change it with: xlin opacity 0.85)
        fullscreen_opacity = 1.0,
        blur = { enabled = true, size = 8, passes = 3, vibrancy = 0.15 },
        shadow = { enabled = true, range = 30, render_power = 3 },
    },
    animations = { enabled = true },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },
    dwindle = { preserve_split = true },
})

hl.curve("xlinOut",  { type = "bezier", points = { { 0.22, 1 }, { 0.36, 1 } } })
hl.curve("xlinSoft", { type = "bezier", points = { { 0.4, 0 },  { 0.2, 1 } } })
hl.animation({ leaf = "windows",          enabled = true, speed = 5, bezier = "xlinOut",  style = "popin 90%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 4, bezier = "xlinSoft", style = "popin 90%" })
hl.animation({ leaf = "fade",             enabled = true, speed = 4, bezier = "xlinSoft" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 4, bezier = "xlinOut",  style = "popin 94%" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 3, bezier = "xlinSoft", style = "popin 94%" })
hl.animation({ leaf = "fadeLayers",       enabled = true, speed = 4, bezier = "xlinSoft" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 4, bezier = "xlinOut" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "xlinOut",  style = "slidevert" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 5, bezier = "xlinOut",  style = "slide" })

pcall(require, "xlin-opacity")  -- window transparency (generated)

-- ---- blur behind bar, run bar, launcher, control panel -----------------------
for _, ns in ipairs({ "^waybar$", "^rofi$", "^xlin-start$", "^swaync-control-center$", "^xlin-desktop$", "^nwg-dock$" }) do
    hl.layer_rule({ match = { namespace = ns }, blur = true, ignore_alpha = 0.3 })
end

-- ---- XLIN windows: floating, centred, a fixed size ---------------------------
local function app(name, w, h, extra)
    local rule = { match = { class = "^(dev\\.xlin\\." .. name .. ")$" }, float = true, size = { w, h }, center = true }
    for k, v in pairs(extra or {}) do rule[k] = v end
    hl.window_rule(rule)
end
app("Settings", 920, 640)
app("Debug", 840, 620)
app("Media", 900, 560)
app("Store", 820, 620)
app("Monitor", 760, 600)
app("Welcome", 600, 500)
app("Calculator", 300, 420)
app("Notes", 360, 470)
app("Clock", 320, 420)
app("Calendar", 340, 430)
app("Screenshot", 300, 336)
-- the Files window gets the big size, not its small rename / new-folder dialogs
hl.window_rule({ match = { class = "^(dev\\.xlin\\.Files)$" }, float = true, center = true })
hl.window_rule({ match = { class = "^(dev\\.xlin\\.Files)$", title = "^(Files)$" }, size = { 900, 600 } })
-- the "Add app shortcut" picker and the "Apps and widgets" gallery of the desktop
app("Desktop", 380, 520)
hl.window_rule({ match = { class = "^(dev\\.xlin\\.Desktop)$", title = "^(Apps and widgets)$" }, size = { 640, 600 } })
-- menus: they open in place, top right under the bar
app("Tools", 300, 380, { center = false })
app("Power", 290, 300, { center = false })
app("Session", 200, 282, { center = false })
hl.window_rule({ match = { class = "^(dev\\.xlin\\.(Tools|Power|Session))$" }, move = "(monitor_w-window_w-12) 46" })

-- ---- shortcuts ---------------------------------------------------------------------
-- Every key is the first letter of what it does.
--   APPS                               WINDOWS
--   Super (tap)   launcher             Super+Q            close window (Quit)
--   Super+Space   launcher             Super+F            fullscreen
--   Super+Return  terminal             Super+Shift+F      floating on/off (Float)
--   Super+T       terminal (Terminal)  Alt+Tab            next window
--   Super+E       files (Explorer)     Super+arrows       move focus
--   Super+S       Settings             Super+Shift+arrows move the window
--   Super+C       Control panel        Super+Ctrl+arrows  resize the window
--   Super+U       Utilities (tools)    Super+drag         move (left) / resize (right)
--   Super+N       Notes (Shift: quick note)
--   Super+B       Battery menu
--   SYSTEM                             WORKSPACES
--   Super+L       Lock                 Super+1..4         go to workspace
--   Super+P       Power menu           Super+Shift+1..4   send window there
--   Super+V       Clipboard history    Super+scroll       next / previous workspace
--   Super+D       Dark / light         Print              screenshot (Shift: full, Alt: window)
--   Super+W       Wallpaper (next)     Super+Shift+Q      quit Hyprland (log out)
--   Super+/       show this list

local function bind(keys, action, flags)
    hl.unbind(keys)             -- drop any older bind of the same keys, so nothing fires twice
    hl.bind(keys, action, flags)
end
local function run(keys, cmd, flags)
    bind(keys, hl.dsp.exec_cmd(cmd), flags)
end

-- Hyprland's own example binds that XLIN does not use (they would clash with XLIN's keys)
for _, k in ipairs({ "SUPER + R", "SUPER + J", "SUPER + 0", "SUPER + SHIFT + 0", "SUPER + M", "SUPER + SHIFT + S" }) do
    hl.unbind(k)
end

-- apps
run("SUPER + SPACE", "xlin launcher")
-- tapping Super on its own opens the Launcher (xlin ignores it when Super was part of another shortcut)
run("Super_L", "xlin superkey", { release = true })
run("Super_R", "xlin superkey", { release = true })
run("SUPER + Return", terminal)
run("SUPER + T", terminal)
run("SUPER + E", "xlin files")
run("SUPER + S", "xlin settings")
run("SUPER + C", "xlin panel")
run("SUPER + U", "xlin tools")
run("SUPER + M", "xlin monitor")
run("SUPER + H", "xlin unhide")
run("SUPER + SHIFT + D", "xlin showdesktop")
-- right-click on the empty desktop: small menu (new note, widgets, wallpaper ...). The click still reaches the
-- app under the pointer; xlin checks that nothing is there.
run("mouse:273", "xlin desktop-menu", { non_consuming = true })
run("SUPER + N", "xlin tools notes")
run("SUPER + SHIFT + N", "xlin note")
run("SUPER + B", "xlin power")

-- system
run("SUPER + L", "xlin lock")
run("SUPER + V", "xlin clipboard")
run("Print", "xlin screenshot region")
run("SHIFT + Print", "xlin screenshot full")
run("ALT + Print", "xlin screenshot window")
run("SUPER + SHIFT + S", "xlin screenshot region")
run("SUPER + P", "xlin session")
run("SUPER + D", "xlin theme toggle")
run("SUPER + W", "xlin wallpaper next")
run("SUPER + slash", "xlin keys menu")
bind("SUPER + SHIFT + Q", hl.dsp.exit())

-- windows
bind("SUPER + Q", hl.dsp.window.close())
bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
bind("SUPER + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)

for _, d in ipairs({ "left", "right", "up", "down" }) do
    bind("SUPER + " .. d, hl.dsp.focus({ direction = d }))
    bind("SUPER + SHIFT + " .. d, hl.dsp.window.move({ direction = d }))
end
local resize = {
    left  = { -40, 0 }, right = { 40, 0 }, up = { 0, -40 }, down = { 0, 40 },
}
for d, xy in pairs(resize) do
    bind("SUPER + CTRL + " .. d, hl.dsp.window.resize({ x = xy[1], y = xy[2], relative = true }), { repeating = true })
end

-- workspaces; touchpad: three fingers left / right = workspace, up = Launcher, down = show desktop
-- Hyprland's own example config already has the same three-finger swipe; drop it first, or Hyprland
-- shows a "gesture will be overshadowed" error. (Only when it is really there.)
do
    local f = io.open((os.getenv("HOME") or "") .. "/.config/hypr/hyprland.lua", "r")
    local text = f and f:read("*a") or ""
    if f then f:close() end
    if text:find('direction%s*=%s*"horizontal"') then
        hl.gesture({ fingers = 3, direction = "horizontal", action = "unset" })
    end
end
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up", action = function() hl.exec_cmd("xlin launcher") end })
hl.gesture({ fingers = 3, direction = "down", action = function() hl.exec_cmd("xlin showdesktop") end })

for i = 1, 4 do
    bind("SUPER + " .. i, hl.dsp.focus({ workspace = i }))
    bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- volume and brightness keys (work on the lock screen too)
local media = { locked = true, repeating = true }
run("XF86AudioRaiseVolume", "xlin osd volume up", media)
run("XF86AudioLowerVolume", "xlin osd volume down", media)
run("XF86AudioMute", "xlin osd volume mute", { locked = true })
run("XF86MonBrightnessUp", "xlin osd brightness up", media)
run("XF86MonBrightnessDown", "xlin osd brightness down", media)
