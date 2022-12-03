local MP = minetest.get_modpath("nyamail")
local function src(name)
	return dofile(MP .. DIR_DELIM .. "src" .. DIR_DELIM .. name .. ".lua")
end

nyamail = {}
nyamail.S = minetest.get_translator("nyamail")

src("storage")
src("register")
src("api")
src("formspec")

