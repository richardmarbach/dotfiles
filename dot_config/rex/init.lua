rex.action{
  name  = "session_step",
  title = "Change session and collapse the others",
  args  = { action = "string" },
  run   = function(ctx, args)
    rex.client.queue(args.action, {})
    rex.client.queue("session.collapse_others", {})
  end,
}
rex.bind("ctrl+cmd+up", "session_step", { action = "session.previous" })
rex.bind("ctrl+cmd+down", "session_step", { action = "session.next" })
rex.bind("shift+cmd+r", "session.rename")
rex.bind("shift+cmd+i", "client.tab.rename")
rex.bind("alt+cmd+f", "client.sidebar.filter.focus")

rex.mode("resize", { exclusive = true })
rex.bind("alt+cmd+r", "client.mode.enter", { name = "resize" })
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

rex.host({
	label = "richard-linux-laptop",
	endpoints = {
		"https://gigs-admin@richard-linux-laptop.osiris-tuna.ts.net",
		"http://gigs-admin@richard-linux-laptop.osiris-tuna.ts.net:7297",
	},
})
