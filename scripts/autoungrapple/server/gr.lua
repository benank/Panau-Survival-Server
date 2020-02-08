function tp(args,sender)
	sender:SetPosition(sender:GetPosition())
end
Network:Subscribe("TPME", tp)