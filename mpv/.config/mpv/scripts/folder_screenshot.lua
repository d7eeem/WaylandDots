-- template = mp.get_property("screenshot-template")
--
-- function folder_screenshot()
--     folder_filename = string.gsub(string.sub(mp.get_property("filename/no-ext"),1,10), "%s+$", "")
--     named_dir = folder_filename.."/"..template
--     mp.set_property("screenshot-template", named_dir)
-- end
--
-- mp.register_event("file-loaded", folder_screenshot)


local utils = require("mp.utils")
local basedir = mp.get_property("options/screenshot-directory")
mp.register_event("file-loaded", function()
    local filedir = mp.get_property("filename/no-ext")
    local dir = utils.join_path(basedir, filedir)
    mp.set_property("options/screenshot-directory", dir)
end)
