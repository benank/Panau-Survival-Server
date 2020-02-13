class 'Notifications'

function Notifications:__init()
	Events:Subscribe("PlayerChat", self, self.PlayerChat)
	WaitforOpt 	= false
	HasSub 		= false

	Events:Subscribe("Notification", self, self.CreateNotification)
end

--[[

	Table with:

	player: player (optional)
	title: string
	subtitle: string (optional)
	title_color: color (optional)
	icon: string (optional)
	preset: string (optional)

]]
function Notifications:CreateNotification(args)
	if args.player then
		Network:Send(args.player, "Notification", args)
	else
		Network:Broadcast("Notification", args)
	end
end

function Notifications:PlayerChat(args)
	
	if IsAdmin(args.player) then
	
		local cmd_args = args.text:split( " " )
	
		if cmd_args[1] == "/information" then
			local text_index = string.find(args.text, "text: ", 1)
			local subtext_index = string.find(args.text, "subtext: ", 1)
        
			if text_index ~=nil then
				if subtext_index ~= nil then
					text 		= 	string.sub(args.text, text_index + 6, subtext_index - 2)
					subtext 	= 	string.sub(args.text, subtext_index + 9)
					WaitforOpt	= 	true
					HasSub		=	true
					Type		=	"Information"
					Chat:Send(args.player, "------------------------------------------------------", Color(200,200,200))
					Chat:Send(args.player, "Please verify you that want to send this notification:", Color(200,200,200))
					Chat:Send(args.player, " ", Color(200,200,200))
					Chat:Send(args.player, "Type: Information", Color(200,200,200))
					Chat:Send(args.player, "Text: " .. text, Color(200,200,200))
					Chat:Send(args.player, "Subtext: " .. subtext, Color(200,200,200))
					Chat:Send(args.player, " ", Color(200,200,200))
					Chat:Send(args.player, "Type /yes to verify", Color(200,200,200))
					Chat:Send(args.player, "------------------------------------------------------", Color(200,200,200))
				else
					WaitforOpt 	= 	true
					HasSub		=	false
					Type		=	"Information"
					text = string.sub(args.text, text_index + 6)
					Chat:Send(args.player, "------------------------------------------------------", Color(200,200,200))
					Chat:Send(args.player, "Please verify that you want to send this notification:", Color(200,200,200))
					Chat:Send(args.player, " ", Color(200,200,200))
					Chat:Send(args.player, "Type: Information", Color(200,200,200))
					Chat:Send(args.player, "Text: " .. text, Color(200,200,200))
					Chat:Send(args.player, " ", Color(200,200,200))
					Chat:Send(args.player, "Type /yes to verify", Color(200,200,200))
					Chat:Send(args.player, "------------------------------------------------------", Color(200,200,200))
				end
        
			return false
			end
	
		end
	
		if cmd_args[1] == "/warning" then
			local text_index = string.find(args.text, "text: ", 1)
			local subtext_index = string.find(args.text, "subtext: ", 1)
        
			if text_index ~=nil then
				if subtext_index ~= nil then
					text 		= 	string.sub(args.text, text_index + 6, subtext_index - 2)
					subtext 	= 	string.sub(args.text, subtext_index + 9)
					WaitforOpt	= 	true
					HasSub		=	true
					Type		=	"Warning"
					Chat:Send(args.player, "------------------------------------------------------", Color(200,200,200))
					Chat:Send(args.player, "Please verify you that want to send this notification:", Color(200,200,200))
					Chat:Send(args.player, " ", Color(200,200,200))
					Chat:Send(args.player, "Type: Warning", Color(200,200,200))
					Chat:Send(args.player, "Text: " .. text, Color(200,200,200))
					Chat:Send(args.player, "Subtext: " .. subtext, Color(200,200,200))
					Chat:Send(args.player, " ", Color(200,200,200))
					Chat:Send(args.player, "Type /yes to verify", Color(200,200,200))
					Chat:Send(args.player, "------------------------------------------------------", Color(200,200,200))
				else
					WaitforOpt 	= 	true
					HasSub		=	false
					Type		=	"Warning"
					text = string.sub(args.text, text_index + 6)
					Chat:Send(args.player, "------------------------------------------------------", Color(200,200,200))
					Chat:Send(args.player, "Please verify that you want to send this notification:", Color(200,200,200))
					Chat:Send(args.player, " ", Color(200,200,200))
					Chat:Send(args.player, "Type: Warning", Color(200,200,200))
					Chat:Send(args.player, "Text: " .. text, Color(200,200,200))
					Chat:Send(args.player, " ", Color(200,200,200))
					Chat:Send(args.player, "Type /yes to verify", Color(200,200,200))
					Chat:Send(args.player, "------------------------------------------------------", Color(200,200,200))
				end
        
			return false
			end
		
		end
	
		if cmd_args[1] == "/upgrade" then
			local text_index = string.find(args.text, "text: ", 1)
			local subtext_index = string.find(args.text, "subtext: ", 1)
			
			if text_index ~=nil then
				if subtext_index ~= nil then
					text 		= 	string.sub(args.text, text_index + 6, subtext_index - 2)
					subtext 	= 	string.sub(args.text, subtext_index + 9)
					WaitforOpt	= 	true
					HasSub		=	true
					Type		=	"Upgrade"
					Chat:Send(args.player, "------------------------------------------------------", Color(200,200,200))
					Chat:Send(args.player, "Please verify you that want to send this notification:", Color(200,200,200))
					Chat:Send(args.player, " ", Color(200,200,200))
					Chat:Send(args.player, "Type: Upgrade", Color(200,200,200))
					Chat:Send(args.player, "Text: " .. text, Color(200,200,200))
					Chat:Send(args.player, "Subtext: " .. subtext, Color(200,200,200))
					Chat:Send(args.player, " ", Color(200,200,200))
					Chat:Send(args.player, "Type /yes to verify", Color(200,200,200))
					Chat:Send(args.player, "------------------------------------------------------", Color(200,200,200))
				else
					WaitforOpt 	= 	true
					HasSub		=	false
					Type		=	"Upgrade"
					text = string.sub(args.text, text_index + 6)
					Chat:Send(args.player, "------------------------------------------------------", Color(200,200,200))
					Chat:Send(args.player, "Please verify that you want to send this notification:", Color(200,200,200))
					Chat:Send(args.player, " ", Color(200,200,200))
					Chat:Send(args.player, "Type: Upgrade", Color(200,200,200))
					Chat:Send(args.player, "Text: " .. text, Color(200,200,200))
					Chat:Send(args.player, " ", Color(200,200,200))
					Chat:Send(args.player, "Type /yes to verify", Color(200,200,200))
					Chat:Send(args.player, "------------------------------------------------------", Color(200,200,200))
				end
        
			return false
			end
	
		end
	
		if cmd_args[1] == "/yes" then
			if WaitforOpt == true then
				if HasSub == true then
					WaitforOpt = false
					HasSub = false
					Network:Broadcast("Notification", {
						title = text, 
						preset = string.lower(Type), 
						subtitle = subtext})
					Type = nil
					Chat:Send(args.player, "Notification has been sent!", Color(0,200,0))
				else
					WaitforOpt = false
					HasSub = false
					Network:Broadcast("Notification", {
						title = text, 
						preset = string.lower(Type)})
					Type = nil
					Chat:Send(args.player, "Notification has been sent!", Color(0,200,0))
				end
			end
			return false
		end
	end
end

Notifications = Notifications()