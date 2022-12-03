local S = nyamail.S

function nyamail.parse_raw_recipents(rawstr)
	local recipents = {}
	for x in string.gmatch(rawstr, '([^,]+)') do
		for _,f in ipairs(nyamail.registered_recipent_handlers) do
			local r = f(x)
			if r then
				if type(r) == "string" then
					table.insert(recipents,r)
				elseif r == true then -- the function says: IGNORE THIS.
					-- Silence is Golden.
				else
					for _,v in ipairs(r) do
						table.insert(recipents,v)
					end
				end
				break
			end
		end
	end
	return recipents
end

function nyamail.raw_sendmail(name,def)
	local storage = nyamail.storage(name)
	if storage then
		storage:send_mail(def)
		if minetest.get_player_by_name(name) then
			minetest.chat_send_player(name,S("You have a mail from @1! Check your mailbox using the command /nyamail.\nSubject: @2",def.from, def.subject))
		end
	end
end

function nyamail.send_mail(def)
	-- def: table
	--  from: string, representing the mail sender
	--  to: string, representing the mail receiver(s)
	--  cc: optional string, representing the Carbon Copy receiver(s)
	--  bcc: optional string, Blind Carbon Copy recipent(s)
	--  reply_to: optinal string, replacing `from` to be the player(s) receiving the email
	--            when the user want to give a reply
	--  disallow_reply: bool, disallow any reply if set to true
	--  time: Time of sending
	--  subject: string, the subject of the mail
	--  body: string, body text of the mail
	if not def.from then
		def.from = "system:" .. (minetest.get_current_modname() or "unknown")
	end
	if not def.subject then
		def.subject = "NO SUBJECT " .. os.time()
	end
	if not def.time then
		def.time = os.time(os.date("!*t"))
	end

	for _,f in ipairs(nyamail.registered_on_sendmails) do
		f(def) -- callbacks CAN modify the mail!
	end

	local to = def.to and nyamail.parse_raw_recipents(def.to) or {}
	local cc = def.cc and nyamail.parse_raw_recipents(def.cc) or {}
	local bcc = def.bcc and nyamail.parse_raw_recipents(def.bcc) or {}

	if ((to and #to or 0) + (cc and #cc or 0) + (bcc and #bcc or 0)) == 0 then
		return -- No recipents!
	end

	local mail_to_send = table.copy(def)
	def.bcc = nil -- Hide BCC from recipents
	for _,t in ipairs({to,cc,bcc}) do
		for _,name in ipairs(t) do
			if name ~= def.from then -- Never send mail back to the sender
				nyamail.raw_sendmail(name,mail_to_send)
			end
		end
	end
end


