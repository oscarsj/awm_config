-- {{{ Required libraries
local awesome, client, mouse, screen, tag = awesome, client, mouse, screen, tag
local ipairs, string, os, table, tostring, tonumber, type = ipairs, string, os, table, tostring, tonumber, type


-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
local lain      = require("lain")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local freedesktop   = require("freedesktop")
local hotkeys_popup = require("awful.hotkeys_popup").widget
local my_table      = awful.util.table or gears.table -- 4.{0,1} compatibility
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")


-- My module loader
local my_modules = require("awm_kmodules")

-- Load Debian menu entries
local debian = require("debian.menu")
local has_fdo, freedesktop = pcall(require, "freedesktop")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions


local themes = {
    "blackburn",       -- 1
    "copland",         -- 2
    "dremora",         -- 3
    "holo",            -- 4
    "multicolor",      -- 5
    "powerarrow",      -- 6
    "powerarrow-dark", -- 7
    "rainbow",         -- 8
    "steamburn",       -- 9
    "vertex",          -- 10
}

local chosen_theme = themes[1]
local modkey       = "Mod4"
local altkey       = "Mod1"
local terminal     = "sakura"
local editor       = os.getenv("EDITOR") or "nano"
local gui_editor   = "gvim"
local browser      = "firefox"
local guieditor    = "atom"
local scrlocker    = "xscreensaver"

lain.layout.termfair.nmaster           = 3
lain.layout.termfair.ncol              = 1
lain.layout.termfair.center.nmaster    = 3
lain.layout.termfair.center.ncol       = 1
lain.layout.cascade.tile.offset_x      = 2
lain.layout.cascade.tile.offset_y      = 32
lain.layout.cascade.tile.extra_padding = 5
lain.layout.cascade.tile.nmaster       = 5
lain.layout.cascade.tile.ncol          = 2


-- Themes define colours, icons, font and wallpapers.
-- beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
local theme_path = string.format("%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), chosen_theme)
beautiful.init(theme_path)

-- require("theme_customizer")


-- Safe require
require("safe_require")

-- This is used later as the default terminal and editor to run.
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.util.terminal = terminal
awful.layout.layouts = {
--    awful.layout.suit.floating,
--    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
--    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
--    awful.layout.suit.fair.horizontal,
--    awful.layout.suit.spiral,
--    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
--    awful.layout.suit.magnifier,
--    awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() return false, hotkeys_popup.show_help end},
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end}
}

local menu_awesome = { "awesome", myawesomemenu, beautiful.awesome_icon }
local menu_terminal = {
      { "Open: terminal", terminal },
      { "Open: file", "thunar" },
      { "Open: Chrome", "google-chrome" },
      { "Open: VLC", "vlc" },
      { "Open: Steam", "steam" },
      { "SESSION: shutdown", "poweroff"},
      { "SESSION: reboot", "reboot"},
      { "SESSION: lock", "xscreensaver-command -lock"},
      { "SESSION: suspend", "systemctl suspend"}
}

if has_fdo then
    mymainmenu = freedesktop.menu.build({
        before = { menu_awesome },
        after = menu_terminal 
    })
else
    mymainmenu = awful.menu({
        items = {
                  menu_awesome,
                  { "Debian", debian.menu.Debian_menu.Debian },
                  menu_terminal,
                }
    })
end


mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
-- mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock(" %b %d - %R ", 45)


-- Audio widget
local volume_widget = my_modules("awm_simple_amixer_volume")

-- -- Update check widget
-- local pacman_update = my_modules("awm_simple_pacman_widget")()
-- local apt_update = my_modules("awm_simple_pacman_widget"){
--   check = "bash -c 'apt list --upgradable 2>/dev/null | tail -n +2'",
--   update = terminal .. " -e sudo apt upgrade"
--}

-- -- Resources widgets
local monitor_graph = require("monitor_graph")
local cpu_widget = monitor_graph("head -n 1 /proc/stat", 5,
   {previous = -1, 1,1,1,0,1,1,1,1,1,1},
   {previous = -1, 1,1,1,1,1,1,1,1,1,1},
   beautiful.fg_normal,
   .8,
   beautiful.bg_urgent,
   {forced_width = 25}
)
local mem_widget = monitor_graph("free", 5,
   {0,1},
   {1},
   beautiful.fg_normal,
   .8,
   beautiful.bg_urgent,
   {forced_width = 25}
)

local fs_widget = require("fs_widget")
local battery_widget = my_modules("awm_battery_widget")
-- local battery_widget_left_sep = battery_widget and beautiful.create_separator_widget(false, true)
-- local battery_widget_right_sep = battery_widget and beautiful.create_separator_widget(true, true)
if battery_widget then
   battery_widget.on_visible_callback = function(widget, visible)
      battery_widget_left_sep:set_visible(visible)
      battery_widget_right_sep:set_visible(visible)
   end
end

local syncthing_widget = safe_require("awm_simple_syncthing_status")
syncthing_widget = syncthing_widget and syncthing_widget()

--
--
-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, client_menu_toggle_fn()),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

local systray_widget_separators_by_screen_id = {left = {}, right = {}}
awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "一", "二", "三", "四", "五", "六", "七", "八", "九"}, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt{prompt = "> " }
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s, height = beautiful.wibar_height})
    --
    -- Systray separators widget
--    systray_widget_separators_by_screen_id.left[s]  = beautiful.create_separator_widget(false, true)
--    systray_widget_separators_by_screen_id.right[s] = beautiful.create_separator_widget(true, true)

    s.systray = wibox.widget.systray()
    s.systray.visible = true

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            beautiful.separator_widget_left,
            mylauncher,
            pacman_update,
            apt_update,
            beautiful.separator_widget_right_serif,
            beautiful.separator_widget_left_serif,
            s.mytaglist,
            beautiful.separator_widget_right,
            s.mypromptbox,
         },
         s.mytasklist, -- Middle widget
         { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            beautiful.separator_widget_left,
            mykeyboardlayout,
            mykeyboardlayout and beautiful.separator_widget_right_serif,
            mykeyboardlayout and beautiful.separator_widget_left_serif,
	    volume_widget,
	    beautiful.separator_widget_right_serif,
	    cpu_widget and beautiful.separator_widget_left_serif,
	    cpu_widget,
	    cpu_widget and beautiful.separator_widget_right_serif,
	    mem_widget and beautiful.separator_widget_left_serif,
            mem_widget,
            mem_widget and beautiful.separator_widget_right_serif,
            fs_widget and beautiful.separator_widget_left_serif,
           -- fs_widget,
            fs_widget and beautiful.separator_widget_right_serif,
	    syncthing_widget and beautiful.separator_widget_left_serif,
            syncthing_widget,
            syncthing_widget and beautiful.separator_widget_right_serif,
            battery_widget_left_sep,
            battery_widget,
            battery_widget_right_sep,
	    systray_widget_separators_by_screen_id.left[s],
            s.systray,
            systray_widget_separators_by_screen_id.right[s],
            beautiful.separator_widget_left_serif,
            mytextclock,
            beautiful.separator_widget_right,
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                      client.focus = c
                      c:raise()
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"}),

    awful.key({ modkey }, "F12", function () awful.util.spawn("gnome-screensaver-command -l") end)
)

clientkeys = gears.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "(un)maximize", group = "client"}),
    awful.key({ modkey, "Control" }, "m",
        function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end ,
        {description = "(un)maximize vertically", group = "client"}),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(un)maximize horizontally", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen,
		     size_hints_honor = false
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
        },
        class = {
          "Arandr",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Wpa_gui",
          "pinentry",
          "veromix",
          "xtightvncviewer"},

        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = true }
    },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            client.focus = c
            c:raise()
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            client.focus = c
            c:raise()
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}


-- {{{ Added by Kuro

-- Layout change notification
require("layoutnotification")

-- My modules
my_modules("awm_brightness") -- Brightness
my_modules("awm_kborderless") -- Remove borders

-- Quake terminal
local quakeconsoles = require("quake"){
   terminal = terminal,
   height = 0.4,
   border_width = 1,
   vert = "top",
}
root.keys(awful.util.table.join(root.keys(), awful.util.table.join(
   awful.key({ modkey }, "BackSpace"      , function() quakeconsoles:toggle() end),
   awful.key({ modkey, "Shift" }, "Return", function() quakeconsoles:toggle() end)
)))


-- Menu + ontop only on floating clients
my_modules("awm_titleless")(function(c) return quakeconsoles:is_quake_console(c) end)

local gmath = require("gears.math")


local function smart_mod4_arrow(direction)
   return function(s, dir)
      s = s or awful.screen.focused()
      direction = dir or direction

      for _, t in pairs(s.selected_tags) do
         if #(t:clients()) > 0 then
            awful.tag.viewidx(direction, s)
            return
         end
      end

      -- This part is from awful/tag.lua
      local tags = s.tags
      local sel_tag_index = 0
      local showntags = {}
      for _, t in ipairs(tags) do
         if not awful.tag.getproperty(t, "hide") then
            table.insert(showntags, t)
            if t == s.selected_tag then
               sel_tag_index = #showntags
            end
         end
      end

      awful.tag.viewnone(s)
      for i = 1, #showntags do
         local tag = showntags[gmath.cycle(#showntags, sel_tag_index + i * direction)]
         if #(tag:clients()) > 0 then
            tag.selected = true
            return
         end
      end
   end
end


--- Keys
root.keys(awful.util.table.join(root.keys(), awful.util.table.join(
    -- Ranger & thunar (file explorers)
    awful.key({ modkey,           }, "e", function () awful.spawn(terminal.." -e ranger") end, {description = "open file explorer (ranger)", group = "launcher"}),
    awful.key({ modkey, "Shift"   }, "e", function () awful.spawn("thunar") end,               {description = "open file explorer (thunar)", group = "launcher"}),

    -- Add screenlock program and key
    awful.key({ modkey,           }, "b", function () awful.spawn("xscreensaver-command -lock") end,                {description = "lock screen"                , group = "awesome"}),

    -- Add Xrandr
    awful.key({ modkey, "Shift"   }, "s", my_modules("awm_dbusxrandr"),                        {description = "Change screen layout"       , group = "awesome"}),

    -- Bind PrintScrn to capture a screen
    awful.key({}, "Print", function()
      local screenshotName = "screenshot_"..os.date("%Y-%m-%dT%H%M%S")..".png"
      awful.spawn.with_line_callback("import -window root -quality 98 "..screenshotName, {exit = function() naughty.notify{text = "Screenshot: "..screenshotName} end})
    end,                                                                                       {description = "take screenshot"            , group = "awesome"}),
    -- Bind Shift PrintScrn to capture a screen interactive
    awful.key({"Shift"}, "Print", function()
      local screenshotName = "screenshot_"..os.date("%Y-%m-%dT%H%M%S")..".png"
      awful.spawn.with_line_callback("import              -quality 98 "..screenshotName, {exit = function() naughty.notify{text = "Screenshot: "..screenshotName} end})
    end,                                                                                       {description = "take screenshot interactive", group = "awesome"}),

    -- Smart Mod+Right/Left
    awful.key({ modkey,           }, "Left",  smart_mod4_arrow(-1),   {description = "view previous or non empty", group = "tag"}),
    awful.key({ modkey,           }, "Right", smart_mod4_arrow(1),    {description = "view next or non empty",     group = "tag"}),
    -- Also on Mod+U/I
    awful.key({ modkey,           }, "u", smart_mod4_arrow(-1),       {description = "view previous or non empty", group = "tag"}),
    awful.key({ modkey,           }, "i", smart_mod4_arrow(1),        {description = "view next or non empty",     group = "tag"}),
    -- Remap urgent to mod+Y
    awful.key({ modkey,           }, "ñ", awful.client.urgent.jumpto, {description = "jump to urgent client",      group = "client"}),

    -- Mod Up, Down, y change focus screen
    awful.key({ modkey,           }, "y", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey,           }, "Up", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey            }, "Down", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"})

)))




-- Startup programs

awful.spawn.with_shell("~/.screenlayout/casa.sh")
awful.spawn.with_shell("nm-applet") -- networkManager applet
-- }}}
