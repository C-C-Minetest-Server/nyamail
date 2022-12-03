local PREFIX = minetest.get_worldpath() .. DIR_DELIM .. "/nyamail/"
minetest.mkdir(PREFIX)

local fs = {}

local cache = {}
function fs:reload()
	local file = io.open(PREFIX .. self.name, "rb")
	if file then
		local content = file:read("*all")
		cache[self.name] = minetest.deserialize(content)
	else
		cache[self.name] = {}
	end
end

function fs:save()
	if not cache[self.name] then return end
	minetest.safe_file_write(PREFIX .. self.name,minetest.serialize(cache[self.name]))
end

function fs:get_mails()
	if not cache[self.name] then
		self:reload()
	end
	return cache[self.name] or {}
end

function fs:send_mail(def)
	if not cache[self.name] then
		self:reload()
	end
	table.insert(cache[self.name],1,def)
	self:save()
end

function fs:delete_mail(mail) -- either mail index or def
	if not cache[self.name] then
		self:reload()
	end
	if type(mail) == "number" then
		table.remove(cache[self.name],mail)
	elseif type(mail) == "table" then -- slower but safer
		for i,cm in ipairs(cache[self.name]) do
			for mk,mv in pairs(mail) do
				if cm[mk] ~= mv then
					return
				end
			end
			-- FULL Match!
			table.remove(cache[self.name],i)
			break
		end
	end
	self:save()
end

nyamail.storage = function(name)
	if type(name) == "userdata" then
		if name.is_player and name:is_player() then
			return nyamail.storage(name:get_player_name())
		end
	elseif type(name) == "string" then
		if minetest.get_auth_handler().get_auth(name) then
			local obj = setmetatable({name=name},{__index=fs})
			return obj
		end
	end
	return false
end

