-- move.lua
local utils = require 'mp.utils'

local function move(action)
    local path = mp.get_property_native("path")
    if not path then
        mp.osd_message("No file")
        return
    end
    -- call external script
    local args = { "/home/tinker/.local/bin/personal/move_video.sh", action, path }
    -- adjust path above to your script path
    local res = utils.subprocess({ args = args, cancellable = false })
    if res.status == 0 then
        mp.osd_message(action:upper() .. ": " .. path)
        mp.command("playlist-next")
    else
        mp.osd_message("Move failed")
    end
end

mp.add_key_binding(nil, "move.keep", function() move("keep") end)
mp.add_key_binding(nil, "move.delete", function() move("delete") end)
