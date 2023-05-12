nyamail = {}

local backend = nil
nyamail.register_backend = function(def)
	backend = table.copy(def)
	nyamail.register_backend = function()
		error("nyamail: Only one nyamail backend can be installed.")
	end
end
minetest.register_on_mods_loaded(function()
	if backend == nil then
		error("nyamail: Please install one nyamail backend.")
	end
end)

--[[
Backend: table of functions. If not specified, returns boolean indicating success.
- get_received(name,server)
   Get all mails of the player name@server.
- get_sent(name,server)
   Get all mails sent by the player name@server.
- create_mail(mail)
   Create a mail entry.
   mail: table
   - sender: string, the name of the sender.
   - receivers: string, the name(s) of the receiver(s), comma- or space- seperated.
   - cc: string, same as receiver but for Carbon Copies.
   - bcc: string, not to be saved in database, same as receivers but for Blind CC.
   - body: string, the content of the mail.
   return: string, the unique identifier of the mail. False if failed.
- get_mail(id)
   Get a mail entry by its ID.
- delete_mail(id)
   Delete a mail entry. This will also delete all sender and receiver U.
   id: string, the unique identifier of the mail as returned by create_mail(mail).
- associate_sender(id,name,server)
   Set the sender of the mail to name@server.
   This affects the search of sent mails, but not the mail entries.
- unlink_sender(id)
   Unset the sender of the mail.
- unlink_sender_by_name(name,server)
   Unset the senders of mails sent by name@server.
- associate_receiver(id,name,server)
   Set name@server as one of the receivers.
   This affects the search of received mails, but not the mail entries.
- unlink_receiver(id[,name,server])
   Remove the mail from the list of received mails of name@server.
   If name and server are omitted, all receivers are unlinked.
   This also removes the read record.
- unlink_receiver_by_name(name,server)
   Remove all mails in the list of received mails of name@server.
- set_read(id,name,server[,read])
   Set the mail to read, or unread if "read" is set to "false".
]]

nyamail.registered_domain_handlers = {}
nyamail.register_domain_handler = function(domain,func)
	if nyamail.registered_domain_handlers[domain] then
		error("nyamail: A domain handler already exists for the domain " .. domain)
	end
	nyamail.registered_domain_handlers[domain] = func
end
nyamail.default_domain_handler = function(id,mail,name,domain)
	return false
end

--[[
func(id,mail,name,domain)
- id: string
   ID of the mail
- mail: table
   Mail entry
- name: string
- domain: string
   The domain name. The set server domain is used when one is not used.
]]

nyamail.this_domain = minetest.settings:get("nyamail.domain")
if nyamail.this_domain == "" then
	error("nyamail: Please set a domain!")
end
nyamail.register_domain_handler(nyamail.this_domain,function(id,mail,name,domain)
	if not core.get_auth_handler().get_auth(name) then -- Kinda hack, to check whether the player exists
		return false end
	end
	return backend.associate_receiver(id,name,domain)
end)

local function split_at(s)
	if type(s) == "table" then return s end
	local at_pos = string.find(s,"@")
	if at_pos then
		return {string.sub(s,1,at_pos - 1),string.sub(s,at_pos + 1)}
	else
		return {s,nyamail.this_domain}
	end
end

local function split_receivers(receivers)
	if type(receivers) == "table" then return receivers end
	local rtn = {}
	for s in string.gmatch(receivers,"[%s,]+([^%s,]*)") do
		table.insert(rtn,split_at(s))
	end
	return rtn
end

local function construct_receivers_str(receivers)
	local addr_list = {}
	for _,v in ipairs(receivers) do
		table.insert(addr_list,v[1] .. "@" .. v[2])
	end
	return table.concat(addr_list,", ")
end

local function merge_lists(...)
	local lists = {...}
	local rtn = {}
	for _,v in ipairs(lists) do
		table.insert(rtn,v)
	end
	return rtn
end

nyamail.send = function(mail) -- Frontend-friendly function
	local sender = split_at(mail.sender)
	local receivers = split_receivers(mail.receivers or {})

	local cc = split_receivers(mail.cc or {})
	local bcc = split_receivers(mail.bcc or {})

	local rec_mail = {}
	rec_mail.sender = sender[1] .. "@" .. sender[2]
	rec_mail.receivers = construct_receivers_str(receivers)
	rec_mail.cc = construct_receivers_str(cc)
	rec_mail.body = mail.body
	return function(rec_mail,merge_lists(receivers,cc,bcc))
end

nyamail.do_send = function(mail,targets) -- Suitable for complicated usage
	local id = backend.create_mail(mail)
	if id == false then
		return false, "Failed to create mail."
	end

	local fails = {}
	for _,v in ipairs(targets) do
		local name, domain = v[1], v[2]
		local handler = nyamail.registered_domain_handlers[domain] or nyamail.default_domain_handler
		local state = handler(id,rec_mail,name,domain)
		if not state then
			table.insert(fails,v[1] .. "@" .. v[2])
		end
	end
	if #fails > 0 then
		return false, "Failed to send to " .. table.concat(fails,", ")
	else
		return true
	end
end






