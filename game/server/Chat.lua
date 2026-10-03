-- GLOBAL CHAT (Kash 2 Oct 23:29): "/g message" (or "/global") is sent to every server and shows in the normal chat
-- as "[GLOBAL] Name: message". Text is filtered for broadcast; 1 message every 4 seconds per player.
local MessagingService = game:GetService("MessagingService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CH = {}
local TOPIC = "IC_GlobalChat"
local last = {}

function CH.Send(plr, p, text)
	if type(text) ~= "string" then return { ok = false, msg = "Nothing to send" } end
	text = text:gsub("^%s+", ""):gsub("%s+$", "")
	if #text == 0 then return { ok = false, msg = "Type a message after /g" } end
	if #text > 150 then text = text:sub(1, 150) end
	if (last[plr] or 0) + 4 > os.clock() then return { ok = false, msg = "Slow down (global chat)" } end
	last[plr] = os.clock()
	local okF, filtered = pcall(function()
		return TextService:FilterStringAsync(text, plr.UserId):GetNonChatStringForBroadcastAsync()
	end)
	if not okF or type(filtered) ~= "string" then return { ok = false, msg = "Could not send that message" } end
	local name = (p and p.data and p.data.name ~= "" and p.data.name) or plr.DisplayName
	local msg = { n = name, u = plr.Name, t = filtered }
	local okP = pcall(function() MessagingService:PublishAsync(TOPIC, msg) end)
	if not okP then CH.Deliver(msg) end -- Studio / messaging down: at least this server sees it
	return { ok = true }
end

function CH.Deliver(msg)
	local Sync = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Sync")
	if Sync and type(msg) == "table" then Sync:FireAllClients("gchat", msg) end
end

function CH.Start()
	pcall(function()
		MessagingService:SubscribeAsync(TOPIC, function(m) CH.Deliver(m.Data) end)
	end)
	Players.PlayerRemoving:Connect(function(plr) last[plr] = nil end)
	-- the /g and /global chat commands (they fire on the client that typed them; the client forwards the text)
	local TCS = game:GetService("TextChatService")
	local folder = TCS:FindFirstChild("TextChatCommands")
	if folder and not folder:FindFirstChild("IC_Global") then
		local c = Instance.new("TextChatCommand")
		c.Name = "IC_Global"
		c.PrimaryAlias = "/g"
		c.SecondaryAlias = "/global"
		c.Parent = folder
	end
end

return CH
