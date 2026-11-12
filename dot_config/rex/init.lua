rex.bind("ctrl+q>ctrl+q", "pane.send_key", { key = "ctrl+q" })
rex.bind("ctrl+q>s", "pane.split", { direction = "down" })
rex.bind("ctrl+q>v", "pane.split", { direction = "right" })
rex.bind("ctrl+q>left", "pane.focus", { direction = "left" })
rex.bind("ctrl+q>down", "pane.focus", { direction = "down" })
rex.bind("ctrl+q>up", "pane.focus", { direction = "up" })
rex.bind("ctrl+q>right", "pane.focus", { direction = "right" })
rex.bind("ctrl+q>.", "client.settings")
rex.action{
  name  = "session_step",
  title = "Change session and collapse the others",
  args  = { action = "string" },
  run   = function(ctx, args)
    rex.client.queue(args.action, {})
    rex.client.queue("session.collapse_others", {})
  end,
}
rex.bind("ctrl+q>shift+l", "session_step", { action = "session.previous" })
rex.bind("ctrl+q>shift+h", "session_step", { action = "session.next" })
rex.bind("ctrl+q>shift+s", "session.switch")
rex.bind("ctrl+q>,", "client.tab.rename")
rex.bind("ctrl+q>shift+n", "session.new")
rex.bind("ctrl+q>n", "client.tab.next")
rex.bind("ctrl+q>p", "client.tab.previous")
rex.action({
	name = "session_tab_goto",
	title = "Go to tab N of this session",
	args = { index = "integer" },
	run = function(ctx, args)
		local view, err = rex.session.view({})
		if not view then
			rex.log("error", "session_tab_goto view: " .. tostring(err))
			return { error = err, session_id = ctx.session_id }
		end
		local window = view.windows[args.index]
		if not window then
			return { missing = args.index, session_id = view.session_id, windows = #view.windows }
		end
		local ok, focus_err = rex.session.focus_window({ window_id = window.window_id })
		if not ok then
			rex.log("error", "session_tab_goto focus: " .. tostring(focus_err))
		end
		return { focused = window.window_id, error = focus_err, session_id = view.session_id }
	end,
})
for i = 0, 9 do
	rex.bind("ctrl+q>" .. i, "session_tab_goto", { index = i + 1 })
end

rex.mode("resize", { exclusive = true })
rex.bind("ctrl+q>r", "client.mode.enter", { name = "resize" })
for key, direction in pairs({
	h = "left",
	j = "down",
	k = "up",
	l = "right",
	left = "left",
	down = "down",
	up = "up",
	right = "right",
}) do
	rex.bind("resize/" .. key, "pane.resize", { direction = direction })
end
rex.bind("resize/esc", "client.mode.exit")
rex.bind("ctrl+q>w", "client.sidebar.filter.focus")

rex.host({
	label = "richard-linux-laptop",
	endpoints = {
		"https://gigs-admin@richard-linux-laptop.osiris-tuna.ts.net",
		"http://gigs-admin@richard-linux-laptop.osiris-tuna.ts.net:7297",
	},
})
