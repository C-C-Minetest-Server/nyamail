-- From builtin/game/register.lua:489
local function make_registration()
	local t = {}
	local registerfunc = function(func)
		t[#t + 1] = func
		minetest.callback_origins[func] = {
			mod = core.get_current_modname() or "??",
			name = debug.getinfo(1, "n").name or "??"
		}
	end
	return t, registerfunc
end

nyamail.registered_on_sendmails, nyamail.register_on_sendmail = make_registration()
nyamail.registered_recipent_handlers, nyamail.register_recipent_handler = make_registration()

-- Default recipent handler
nyamail.register_recipent_handler(function(recipent) -- Check for pure usernames
	if minetest.get_auth_handler().get_auth(recipent) then -- Skip non-exist users
		return recipent
	end
end)
