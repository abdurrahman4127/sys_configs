-- autosave-position.lua
--
-- mpv only writes its watch-later entry at two moments: on quit, and when
-- `loadfile` replaces the current playlist. Everything since the last of those
-- events is lost if the process dies another way: power loss, reboot, SIGKILL
-- after a timeout, a hung network/NTFS read, a crash.
--
-- This script calls the `write-watch-later-config` command periodically while a
-- video is playing, so an abrupt termination loses at most `interval` seconds
-- of progress instead of the whole file.
--
-- Configure in mpv.conf:
--   script-opts=autosave-position-interval=10   # seconds; 0 disables the script
--   script-opts=autosave-position-min-delta=5   # only write if position moved 5s
--
-- It never saves at EOF, so a finished video keeps mpv's own behaviour instead
-- of pinning the resume point to the last frame.

local mp = require 'mp'
local options = require 'mp.options'

local opts = {
    interval = 10,
    min_delta = 5,
}

options.read_options(opts, "autosave-position")

if opts.interval and opts.interval > 0 then
    local last_saved = -math.huge

    local function save()
        -- nothing loaded, or the file already finished
        if mp.get_property_native("idle-active") then return end
        if mp.get_property_native("eof-reached") then return end

        local pos = mp.get_property_number("playback-time")
        if not pos or pos < 1 then return end

        -- avoid pointless writes while paused / sitting on the same frame
        if math.abs(pos - last_saved) < opts.min_delta then return end

        if mp.command("write-watch-later-config") then
            last_saved = pos
        end
    end

    mp.add_periodic_timer(opts.interval, save)
end
