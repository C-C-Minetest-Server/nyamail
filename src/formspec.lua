local S = nyamail.S
local gui = flow.widgets

local function format_date(time)
	return os.date("!%Y-%m-%dT%H:%M:%SZ", time)
end

local function compose_forward(mail)
	return "=== Forwarded Message ===\n" ..
		"From: " .. mail.from .. "\n" ..
		(mail.to and ("To: " .. mail.to .. "\n")) ..
		(mail.cc and ("CC: " .. mail.cc .. "\n")) ..
		"Subject: " .. mail.subject .. "\n" ..
		"Time: " .. format_date(mail.time) .. "\n" ..
		">>> BEGIN ORIGINAL MESSAGE <<<\n" .. mail.body
end

local function es(s) -- Empty String check
	if s == "" then
		return nil
	end
	return s
end

nyamail.gui = flow.make_gui(function(player, ctx)
	local name = player:get_player_name()

	if not ctx.tab then
		ctx.tab = "main"
	end
	if not ctx.mails then
		ctx.mails = table.copy(nyamail.storage(name):get_mails())
	end
	if ctx.tab == "main" then
		local rightbar = { gui.Label { label = S("No mail selected.") } }
		if ctx.form.main_mail_select then
			local selected = ctx.form.main_mail_select
			local mail = ctx.mails[selected]
			if mail then
				rightbar = {
					gui.Button {
						w = 3,
						name = "main_btn_view",
						label = S("View"),
						on_event = function(player,ctx)
							ctx.tab = "view"
							ctx.view_current = selected
							return true
						end,
					},
					gui.Button {
						w = 3,
						name = "main_btn_reply",
						label = S("Reply"),
						on_event = function(player,ctx)
							ctx.tab = "edit"
							ctx.edit_defaults = {
								subject = "Re: " .. mail.subject,
								to = es(mail.reply_to) or es(mail.from),
								body = string.format("\n\n\n=== %s, %s wrote: ===\n",mail.from,format_date(mail.time)) .. mail.body,
								reply_to = (mail.reply_to and mail.reply_to or "") .. "," .. name,
							}
							return true
						end,
					},
					gui.Button {
						w = 3,
						name = "main_btn_delete",
						label = S("Delete"),
						on_event = function(player,ctx)
							nyamail.storage(name):delete_mail(mail)
							ctx.mails = nil
							return true
						end,
					},
				}
			end
		end
		table.insert(rightbar,gui.Button {
			w = 3,
			name = "main_btn_compose",
			label = S("Compose"),
			on_event = function(player,ctx)
				ctx.tab = "edit"
				ctx.edit_defaults = nil
				return true
			end,
			expand = true, align_v = "bottom",
		})
		table.insert(rightbar,gui.Button {
			w = 3,
			name = "main_btn_refresh",
			label = S("Refresh"),
			on_event = function(player,ctx)
				ctx.mails = nil
				return true
			end,
		})
		table.insert(rightbar,gui.ButtonExit {
			w = 3,
			name = "main_btn_exit",
			label = S("Exit"),
		})

		local list = {}
		for _,v in ipairs(ctx.mails) do
			table.insert(list,S("@1: @2",v.from,v.subject))
		end
		return gui.VBox {
			gui.Label { label = S("All E-Mails") },
			gui.HBox {
				gui.Textlist {
					w = 7, h = 6,
					name = "main_mail_select",
					listelems = list,
				},
				gui.VBox(rightbar)
			},
			gui.Label { label = S("Emoji Mail System") },
		}
	elseif ctx.tab == "view" then
		local selected = ctx.view_current
		local mail = ctx.mails[selected]
		return gui.VBox {
			gui.HBox {
				gui.Button {
					w = 0.6, h = 0.6,
					name = "view_back",
					label = "<",
					on_event = function(player,ctx)
						ctx.tab = "main"
						return true
					end,
				},
				gui.Label {
					label = S("Viewing E-Mail")
				}
			},
			gui.Label { label = S("Subject: @1",mail.subject) },
			gui.HBox {
				gui.VBox {
					w = 4,
					gui.Label { label = S("From: @1",mail.from) },
					gui.Label { label = S("CC: @1",mail.cc) },
				},
				gui.VBox {
					w = 4,
					gui.Label { label = S("To: @1",mail.to) },
					gui.Label { label = S("Time: @1",format_date(mail.time)) },
				},
			},
			gui.Textarea {
				w = 4, h = 6,
				default = mail.body
			},
			gui.HBox {
				gui.Button {
					w = 2,
					name = "view_new",
					label = S("New E-Mail"),
					on_event = function(player,ctx)
						ctx.tab = "edit"
						ctx.edit_defaults = nil
						return true
					end,
				},
				gui.Button {
					w = 2,
					name = "view_reply",
					label = S("Reply"),
					on_event = function(player,ctx)
						ctx.tab = "edit"
						ctx.edit_defaults = {
							subject = "Re: " .. mail.subject,
							to = es(mail.reply_to) or es(mail.from),
							body = string.format("\n\n\n=== %s, %s wrote: ===\n",mail.from,format_date(mail.time)) .. mail.body,
							reply_to = (mail.reply_to and (mail.reply_to .. ",") or "") .. name,
						}
						return true
					end,
				},
				gui.Button {
					w = 2,
					name = "view_forward",
					label = S("Forward"),
					on_event = function(player,ctx)
						ctx.tab = "edit"
						ctx.edit_defaults = {
							subject = "Fwd: " .. mail.subject,
							body = compose_forward(mail),
						}
						return true
					end,
				},
				gui.Button {
					w = 2,
					name = "view_delete",
					label = S("Delete"),
					on_event = function(player,ctx)
						nyamail.storage(name):delete_mail(mail)
						ctx.mails = nil
						ctx.tab = "main"
						return true
					end
				},
			}
		}
	elseif ctx.tab == "edit" then
		local defaults = ctx.edit_defaults or {}
		return gui.VBox {
			gui.HBox {
				gui.Button {
					w = 0.6, h = 0.6,
					name = "edit_back",
					label = "<",
					on_event = function(player,ctx)
						ctx.tab = "main"
						return true
					end,
				},
				gui.Label {
					label = S("Composing E-Mail")
				}
			},
			gui.HBox {
				gui.Label { label = S("Subject:") },
				gui.Field {
					name = "edit_subject",
					default = defaults.subject,
					expand = true,
				}
			},
			gui.HBox {
				gui.Label { label = S("To:") },
				gui.Field {
					name = "edit_to",
					default = defaults.to,
					expand = true,
				}
			},
			gui.HBox {
				gui.Label { label = S("Reply To:") },
				gui.Field {
					name = "edit_reply_to",
					default = defaults.reply_to,
					expand = true,
				}
			},
			gui.HBox {
				gui.HBox {
					w = 6,
					gui.Label { label = S("CC:") },
					gui.Field {
						name = "edit_cc",
						default = defaults.cc,
						expand = true,
					}
				},
				gui.HBox {
					w = 6,
					gui.Label { label = S("BCC:") },
					gui.Field {
						name = "edit_bcc",
						default = defaults.bcc,
						expand = true,
					}
				},
			},
			gui.Textarea {
				w = 12, h = 7,
				name = "edit_body",
				default = defaults.body
			},
			gui.HBox {
				gui.Button {
					w = 3,
					name = "edit_submit",
					label = S("Send"),
					expand = true, align_h = "right",
					on_event = function(player,ctx)
						local mail_to_send = {}
						mail_to_send.from = name
						mail_to_send.to = ctx.form.edit_to
						mail_to_send.reply_to = ctx.form.edit_reply_to
						mail_to_send.cc = ctx.form.edit_cc
						mail_to_send.bcc = ctx.form.edit_bcc
						mail_to_send.subject = ctx.form.edit_subject
						mail_to_send.body = ctx.form.edit_body
						nyamail.send_mail(mail_to_send)
						ctx.tab = "main"
						ctx.edit_defaults = nil
						return true
					end,
				}
			}
		}
	end
end)

minetest.register_chatcommand("nyamail",{
	description = S("Access Emoji Mail System"),
	func = function(name,param)
		nyamail.gui:show(minetest.get_player_by_name(name))
		return true, S("Formspec shown.")
	end
})
